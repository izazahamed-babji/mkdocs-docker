FROM python:3.12-slim-bookworm AS builder

COPY requirements.txt .

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip & pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim-bookworm

COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8000

COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
