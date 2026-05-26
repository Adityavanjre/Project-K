# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set up environment variables for Hugging Face Space
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV KALI_WEB_PORT=7860
ENV OLLAMA_HOST=0.0.0.0:11434

# Install system dependencies (curl, git)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama (Linux binary)
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set up a new user named "user" with user ID 1000 (Required for Hugging Face Spaces)
RUN useradd -m -u 1000 user

# Switch to the new user and set the working directory
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH
WORKDIR $HOME/app

# Copy the requirements file and install dependencies
COPY --chown=user:user requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt huggingface_hub

# Copy the entire KALI workspace into the container
COPY --chown=user:user . .

# Expose the HF Space port and Ollama port
EXPOSE 7860 11434

# Make the startup script executable
RUN chmod +x start.sh

# Run the master startup script
CMD ["./start.sh"]
