#!/bin/bash
set -e

# Start postgres in background
docker-entrypoint.sh postgres &
PG_PID=$!

# Wait for it to be ready
until pg_isready -h /var/run/postgresql -U postgres 2>/dev/null; do
  sleep 1
done

# Reset password to match env var
if [ -n "$POSTGRES_PASSWORD" ]; then
  psql -h /var/run/postgresql -U postgres -d postgres -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';" 2>/dev/null || true
  echo "Password synced with POSTGRES_PASSWORD env var"
fi

# Run init.sql
psql -h /var/run/postgresql -U postgres -d "${PGDATABASE:-railway}" -f /init.sql 2>/dev/null || true

# Wait for postgres to exit
wait $PG_PID
