FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY backend /app
COPY assets/data /assets/data

ENV QIBRA_ASSETS_ROOT=/assets/data
ENV QIBRA_HOST=0.0.0.0
ENV QIBRA_PORT=8000

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
