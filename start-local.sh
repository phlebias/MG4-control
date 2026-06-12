#!/bin/zsh

set -euo pipefail

ROOT=${0:A:h}
LOG_DIR="$ROOT/logs/local"
RUNTIME_DIR="$ROOT/.runtime"

cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing $ROOT/.env"
  exit 1
fi

export PATH="$HOME/.dotnet:$PATH"
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
mkdir -p "$LOG_DIR" "$RUNTIME_DIR"

set -a
source .env
set +a

if ! colima status >/dev/null 2>&1; then
  echo "Starting Docker..."
  colima start --cpu 4 --memory 6
fi

for container in mosquitto saic-mqtt garagestack-postgres-live; do
  if ! docker inspect "$container" >/dev/null 2>&1; then
    echo "Required container '$container' is missing. Run the initial setup again."
    exit 1
  fi
  docker start "$container" >/dev/null
done

echo "Waiting for PostgreSQL..."
for _ in {1..30}; do
  if docker exec garagestack-postgres-live \
    pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! docker exec garagestack-postgres-live \
  pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
  echo "PostgreSQL did not become ready."
  exit 1
fi

echo "Building backend..."
dotnet build GarageStack.slnx --nologo --verbosity quiet

start_service() {
  local name=$1
  local session="garagestack-$name"
  local pid_file="$RUNTIME_DIR/$name.pid"

  if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
    kill "$(<"$pid_file")"
    sleep 1
  fi
  screen -S "$session" -X quit >/dev/null 2>&1 || true
  screen -dmS "$session" /bin/zsh "$ROOT/run-local-service.sh" "$name"
  echo "Started $name."
}

start_service api
start_service worker
start_service frontend

echo "Waiting for GarageStack..."
for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:5173/ >/dev/null 2>&1 &&
    curl -sS -o /dev/null http://127.0.0.1:5000/api/auth/me; then
    echo
    echo "GarageStack is ready: http://localhost:5173"
    exit 0
  fi
  sleep 1
done

echo "GarageStack did not become ready. Check $LOG_DIR"
exit 1
