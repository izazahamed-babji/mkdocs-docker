FROM python:3.12-slim-bookworm AS builder

COPY requirements.txt .

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip & pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim-bookworm

COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8000

RUN mkdocs new app

WORKDIR /app

ENTRYPOINT ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
