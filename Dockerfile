FROM python:3.12-slim

# Prevent Python from writing pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# Prevent Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY req.pip /app/
RUN pip install --upgrade pip && pip install -r req.pip

# Copy project
COPY . /app/

# Entrypoint to run django commands
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
