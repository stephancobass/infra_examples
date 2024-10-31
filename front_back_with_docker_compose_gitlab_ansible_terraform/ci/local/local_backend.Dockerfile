FROM python:3.11-slim

EXPOSE 8000
WORKDIR /app

RUN apt-get update && \
    #apt-get install -y --no-install-recommends netcat && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY pyproject.toml poetry.lock alembic.ini ./
COPY ./app ./app

RUN  /usr/local/bin/python -m pip install --upgrade pip

RUN pip install poetry && \
    poetry install --no-dev

# CMD poetry run uvicorn --host 0.0.0.0 app.main:app
CMD poetry run alembic upgrade head && poetry run uvicorn --proxy-headers --forwarded-allow-ips="*" --host 0.0.0.0 app.main:app
