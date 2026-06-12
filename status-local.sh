#!/bin/zsh

set -u

ROOT=${0:A:h}
RUNTIME_DIR="$ROOT/.runtime"
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

if colima status >/dev/null 2>&1; then
  echo "Docker: running"
else
  echo "Docker: stopped"
fi

for name in api worker frontend; do
  pid_file="$RUNTIME_DIR/$name.pid"
  if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
    echo "$name: running"
  else
    echo "$name: stopped"
  fi
done

if curl -fsS http://127.0.0.1:5173/ >/dev/null 2>&1; then
  echo "Dashboard: http://localhost:5173"
else
  echo "Dashboard: unavailable"
fi
