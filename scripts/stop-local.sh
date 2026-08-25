#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
for file in .logs/stockpredictor-api-8000.pid .logs/stockpredictor-dashboard-8501.pid; do
  [ -f "$file" ] || continue; pid=$(cat "$file" 2>/dev/null || true)
  case "$pid" in ''|*[!0-9]*) rm -f "$file"; continue ;; esac
  command_line=$(ps -p "$pid" -o command= 2>/dev/null || true)
  case "$command_line" in *stockpredictor*) kill "$pid" 2>/dev/null || true ;; *) echo "PID $pid is not StockPredictor; leaving it alone." >&2 ;; esac
  rm -f "$file"
done
echo "StockPredictor local services stopped."
