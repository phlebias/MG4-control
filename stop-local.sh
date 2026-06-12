#!/bin/zsh

set -euo pipefail

ROOT=${0:A:h}
RUNTIME_DIR="$ROOT/.runtime"
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

for name in frontend worker api; do
  session="garagestack-$name"
  pid_file="$RUNTIME_DIR/$name.pid"
  stopped=false

  if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
    pid=$(<"$pid_file")
    kill "$pid"
    for _ in {1..10}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.2
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid"
    fi
    stopped=true
  fi

  if screen -ls | grep -q "[.]$session"; then
    screen -S "$session" -X quit >/dev/null 2>&1 || true
    stopped=true
  fi

  rm -f "$pid_file"
  if [[ "$stopped" == true ]]; then
    echo "Stopped $name."
  fi
done

if colima status >/dev/null 2>&1; then
  docker stop saic-mqtt mosquitto garagestack-postgres-live >/dev/null 2>&1 || true
fi

echo "GarageStack is stopped."
