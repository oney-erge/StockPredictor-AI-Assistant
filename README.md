# StockPredictor

A local research workbench for stock ideas: price models, signal fusion, trade
plans with risk limits, backtests, a FastAPI service and a Streamlit dashboard,
with optional news summaries from a local LLM.

> Research and decision-support software. It is not financial advice and it
> never places brokerage orders.

## Quick start

```powershell
.\run.bat          # Windows
```

```bash
./run.command      # macOS
./run.sh           # Linux
```

The launcher installs a pinned `uv`, syncs the locked environment, starts the
API (port 8000) and the dashboard (port 8501), and opens the dashboard. Run it
again with `doctor`, `repair`, `docker`, `logs` or `stop`, for example
`.\run.ps1 doctor`.

## What it does

- **Scan and analyze.** Score a watchlist or one symbol with fused model and
  technical signals over an intraday, swing or position horizon.
- **Plan trades.** Entry, stop, target and invalidation levels sized by the
  risk settings in `configs/default.yaml`.
- **Backtest.** Replay the scanner and simulator over history with the same
  risk limits.
- **Read the news.** Per-symbol summaries through a local model served by
  [LocalDeploy](https://github.com/oney-erge/LocalDeploy).
- **Keep a journal.** Local review notes for each idea, stored on your machine.

## Documentation

- [docs/USAGE.md](docs/USAGE.md): running the services, the CLI, API routes,
  configuration, the local news LLM and the trader agent.
- [traders.mind.md](traders.mind.md): the trader-style reasoning checklist.
- `docs/`: planning notes for upcoming work.

## Development

```bash
uv sync --frozen
uv run --frozen pytest
uv run --frozen ruff check .
```

## License

[MIT](LICENSE)
