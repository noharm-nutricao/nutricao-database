#!/bin/bash
set -e

dnf update -y
dnf install -y docker unzip awscli docker-compose-plugin

systemctl enable docker
systemctl start docker

mkdir -p /opt/nitra/database
mkdir -p /opt/nitra/postgres-data

cat > /opt/nitra/.env <<EOF
POSTGRES_DB=${db_name}
POSTGRES_USER=${db_user}
POSTGRES_PASSWORD=${db_password}
EOF

cat > /opt/nitra/docker-compose.yml <<'EOF'
services:
  postgres:
    image: postgres:16
    container_name: nitra-postgres
    restart: always
    env_file:
      - .env
    ports:
      - "5432:5432"
    volumes:
      - /opt/nitra/postgres-data:/var/lib/postgresql/data
    shm_size: 128mb
    mem_limit: 750m

  flyway:
    image: flyway/flyway:10
    container_name: nitra-flyway
    depends_on:
      - postgres
    env_file:
      - .env
    volumes:
      - /opt/nitra/database/migrations/flyway:/flyway/sql
      - /opt/nitra/database/flyway/flyway.conf:/flyway/conf/flyway.conf
    command: migrate
EOF

cd /opt/nitra
docker compose up -d postgres