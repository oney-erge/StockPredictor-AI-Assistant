#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
no_browser=0; [ "${1:-}" = --no-browser ] && no_browser=1
[ -f configs/default.yaml ] || cp configs/default.example.yaml configs/default.yaml
mkdir -p .logs
python=.venv/bin/python
check(){ if command -v curl >/dev/null 2>&1; then curl -fsS --max-time 2 "$1" >/dev/null; else wget -qO- --timeout=2 "$1" >/dev/null; fi; }
wait_url(){ for _ in $(seq 1 120); do check "$1" 2>/dev/null && return; sleep .5; done; return 1; }
start_service(){ local name=$1 url=$2; shift 2; local pidfile=".logs/$name.pid"; if check "$url" 2>/dev/null; then echo "$name already running at $url"; return; fi; nohup "$@" >".logs/$name.out.log" 2>".logs/$name.err.log" & echo $! > "$pidfile"; wait_url "$url" || { tail -n 80 ".logs/$name.err.log"; return 1; }; echo "$name ready at $url"; }
start_service stockpredictor-api-8000 http://127.0.0.1:8000/health "$python" -m stockpredictor.cli api --config configs/default.yaml --host 127.0.0.1 --port 8000
start_service stockpredictor-dashboard-8501 http://127.0.0.1:8501 "$python" -m stockpredictor.cli dashboard --config configs/default.yaml --server-port 8501
echo "StockPredictor is ready at http://127.0.0.1:8501"
if [ "$no_browser" -eq 0 ]; then command -v open >/dev/null 2>&1 && open http://127.0.0.1:8501 || command -v xdg-open >/dev/null 2>&1 && xdg-open http://127.0.0.1:8501 || true; fi
