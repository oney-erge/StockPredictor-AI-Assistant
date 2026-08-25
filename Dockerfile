FROM ghcr.io/astral-sh/uv:0.12.5@sha256:e85be844203885286c60ffad8a858d48afb6c5a5c237ca0e67f12e74b8f174b1 AS uv

FROM python:3.11-slim-bookworm@sha256:0bee7276f83efd4a1ee05bbbf4281d95ed28e079220a9457f25a93e3f1e3c31b
COPY --from=uv /uv /uvx /bin/
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1
RUN useradd --create-home --uid 10001 stockpredictor
WORKDIR /app
COPY pyproject.toml uv.lock README.md ./
COPY src/ ./src/
COPY configs/ ./configs/
COPY traders.mind.md ./
RUN uv sync --frozen --no-editable && mkdir -p /app/data && chown -R stockpredictor:stockpredictor /app
USER stockpredictor
VOLUME ["/app/data"]
EXPOSE 8000 8501
