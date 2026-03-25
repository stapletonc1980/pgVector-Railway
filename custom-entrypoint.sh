#!/bin/bash
set -e
# Call the default entrypoint so Postgres starts
/docker-entrypoint.sh postgres &

# Wait for postgres to be ready
until pg_isready -h localhost -p 5432; do
  sleep 2
done

# Reset password to match env var via local trust connection
if [ -n "$POSTGRES_PASSWORD" ]; then
  psql -h /var/run/postgresql -U "$POSTGRES_USER" -d postgres -c "ALTER USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" 2>/dev/null || true
fi

# Run your SQL every time
psql -h /var/run/postgresql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /init.sql 2>/dev/null || true

wait
