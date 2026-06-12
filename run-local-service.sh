#!/bin/zsh

set -euo pipefail

ROOT=${0:A:h}
SERVICE=${1:-}

cd "$ROOT"
mkdir -p "$ROOT/logs/local"
mkdir -p "$ROOT/.runtime"
echo $$ >"$ROOT/.runtime/$SERVICE.pid"
exec >>"$ROOT/logs/local/$SERVICE.log" 2>&1

set -a
source .env
set +a

export PATH="$HOME/.dotnet:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export ASPNETCORE_ENVIRONMENT=Production
export ASPNETCORE_URLS=http://127.0.0.1:5000
export ConnectionStrings__DefaultConnection="Host=127.0.0.1;Port=5432;Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD}"
export Mqtt__Host=127.0.0.1
export Mqtt__Port=1883
export Mqtt__Username="${MQTT_BROKER_USERNAME}"
export Mqtt__Password="${MQTT_BROKER_PASSWORD}"
export Cors__Origins__0=http://localhost:5173
export Jwt__Secret="${JWT_SECRET}"
export Auth__Username="${SAIC_USER}"
export Auth__Password="${SAIC_PASSWORD}"
export Auth__CookieSecure=false

case "$SERVICE" in
  api)
    cd "$ROOT/src/GarageStack.Api"
    exec dotnet bin/Debug/net10.0/GarageStack.Api.dll
    ;;
  worker)
    cd "$ROOT/src/GarageStack.Worker"
    exec dotnet bin/Debug/net10.0/GarageStack.Worker.dll
    ;;
  frontend)
    cd "$ROOT/frontend"
    exec node node_modules/vite/bin/vite.js --host 127.0.0.1
    ;;
  *)
    echo "Unknown GarageStack service: $SERVICE"
    exit 1
    ;;
esac
