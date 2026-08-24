FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY functions ./functions

ENV PYTHONUNBUFFERED=1

CMD ["python", "functions/validator/worker.py"]
