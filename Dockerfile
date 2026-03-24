# Base Image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies (needed for some python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Set environment variables
ENV FLASK_APP=src/web_app.py
ENV PYTHONUNBUFFERED=1

# Expose the port the app runs on
EXPOSE 5000

# Run the application with Gunicorn
# 4 Workers for concurrency, binding to 0.0.0.0 for external access
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "src.web_app:create_app()"]
