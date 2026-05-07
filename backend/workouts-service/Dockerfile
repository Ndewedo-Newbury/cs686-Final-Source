FROM python:3.11-slim
WORKDIR /app
COPY backend/workouts-service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/workouts-service/app/ ./app/
COPY shared/ ./shared/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
