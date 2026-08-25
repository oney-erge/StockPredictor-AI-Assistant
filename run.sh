#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
action=run; case "${1:-}" in run|doctor|repair|docker|stop|logs) action=$1; shift ;; esac
no_browser=0; for arg in "$@"; do [ "$arg" = --no-browser ] && no_browser=1 || { echo "unknown option: $arg" >&2; exit 2; }; done
uv_version=0.12.5; api_url=http://127.0.0.1:8000; dashboard_url=http://127.0.0.1:8501
find_uv(){ command -v uv 2>/dev/null || { [ -x "$HOME/.local/bin/uv" ] && { echo "$HOME/.local/bin/uv"; return; }; [ -x "$HOME/.cargo/bin/uv" ] && { echo "$HOME/.cargo/bin/uv"; return; }; return 1; }; }
retry(){ local label=$1; shift; for n in 1 2 3; do "$@" && return; [ "$n" -eq 3 ] && { echo "$label failed" >&2; return 1; }; sleep $((1 << (n-1))); done; }
install_uv(){ local file; file=$(mktemp); if command -v curl >/dev/null 2>&1; then retry "uv download" curl -fsSL "https://astral.sh/uv/${uv_version}/install.sh" -o "$file"; elif command -v wget >/dev/null 2>&1; then retry "uv download" wget -qO "$file" "https://astral.sh/uv/${uv_version}/install.sh"; else echo "curl or wget is required" >&2; return 1; fi; sh "$file"; rm -f "$file"; find_uv; }
check(){ if command -v curl >/dev/null 2>&1; then curl -fsS --max-time 2 "$1" >/dev/null; else wget -qO- --timeout=2 "$1" >/dev/null; fi; }
wait_url(){ for _ in $(seq 1 120); do check "$1" 2>/dev/null && return; sleep .5; done; return 1; }
open_url(){ [ "$no_browser" -eq 1 ] && return; command -v open >/dev/null 2>&1 && open "$dashboard_url" || command -v xdg-open >/dev/null 2>&1 && xdg-open "$dashboard_url" || true; }
docker_running(){ command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && [ -n "$(docker compose ps --quiet 2>/dev/null)" ]; }
case "$action" in
 docker) command -v docker >/dev/null 2>&1 || { echo "Docker is not installed." >&2; exit 1; }; docker info >/dev/null 2>&1 || { echo "Docker engine is not running." >&2; exit 1; }; docker compose up -d --build; wait_url "$api_url/health" && wait_url "$dashboard_url" || { docker compose logs; exit 1; }; echo "StockPredictor is ready at $dashboard_url"; open_url; exit 0 ;;
 stop) docker_running && exec docker compose down; exec ./scripts/stop-local.sh ;;
 logs) docker_running && exec docker compose logs --follow; exec tail -n 100 -F .logs/*.log ;;
esac
uv=$(find_uv || true)
if [ "$action" = doctor ]; then [ -n "$uv" ] || { echo "uv is missing. Run ./run.sh once." >&2; exit 1; }; "$uv" run --frozen --no-sync python -c "import stockpredictor; print('Environment: ready')"; check "$api_url/health" 2>/dev/null && echo "API: $api_url" || echo "API: not running"; check "$dashboard_url" 2>/dev/null && echo "Dashboard: $dashboard_url" || echo "Dashboard: not running"; exit 0; fi
[ -n "$uv" ] || uv=$(install_uv); sync=(sync --frozen); [ "$action" = repair ] && sync+=(--reinstall); retry "dependency synchronization" "$uv" "${sync[@]}"
launch_args=()
[ "$no_browser" -eq 1 ] && launch_args+=(--no-browser)
exec ./scripts/start-local.sh "${launch_args[@]}"
