FROM public.ecr.aws/lambda/python:3.11

# Copy shared library and all backend service code (needed for imports and tests)
COPY backend/      /app/backend/

# Install test dependencies + every service's runtime dependencies
RUN pip install --no-cache-dir \
      pytest pytest-asyncio httpx boto3 requests && \
    pip install --no-cache-dir -r /app/backend/auth-service/requirements.txt && \
    pip install --no-cache-dir -r /app/backend/workouts-service/requirements.txt && \
    pip install --no-cache-dir -r /app/backend/analytics-service/requirements.txt

# Lambda handlers
# test-runner Lambda uses handler.handler (default CMD)
# migrate Lambda overrides CMD to migrate_handler.handler via image_config in Terraform
COPY backend/tests/lambda_handler.py  ${LAMBDA_TASK_ROOT}/handler.py
COPY backend/tests/migrate_handler.py ${LAMBDA_TASK_ROOT}/migrate_handler.py

CMD ["handler.handler"]
