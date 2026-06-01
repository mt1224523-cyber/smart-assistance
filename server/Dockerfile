# syntax=docker/dockerfile:1.7
# Multi-stage : on installe les dépendances dans une couche jetable, puis on copie
# uniquement les paquets installés et le code dans une image runtime minimale.

FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

COPY requirements.txt ./
RUN pip install --prefix=/install -r requirements.txt

# ---------- runtime ----------
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/install/bin:${PATH}" \
    PYTHONPATH="/install/lib/python3.12/site-packages"

# Utilisateur non-root.
RUN groupadd --system app && useradd --system --gid app --uid 10001 --home /app app

WORKDIR /app

COPY --from=builder /install /install
COPY --chown=app:app main.py ./

USER app

ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys,os; \
port=os.environ.get('PORT','8000'); \
sys.exit(0 if urllib.request.urlopen(f'http://127.0.0.1:{port}/health', timeout=3).status == 200 else 1)"

# Shell-form pour permettre l'expansion de $PORT (injecté par Render, Fly, etc.).
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 2
