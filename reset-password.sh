#!/bin/bash
set -e

# This script runs on every container start (via ENTRYPOINT) to ensure the
# postgres user password matches the POSTGRES_PASSWORD environment variable.
# It handles the case where the data directory already exists (existing volume)
# because docker-entrypoint-initdb.d scripts only run on first initialization.

PGDATA="${PGDATA:-/var/lib/postgresql/data}"

if [ -n "$POSTGRES_PASSWORD" ] && [ -d "$PGDATA/global" ]; then
    echo "Existing data directory detected — resetting postgres user password to match POSTGRES_PASSWORD..."

    # Start a temporary PostgreSQL instance with trust auth so we can connect
    # without a password, regardless of what's stored in pg_hba.conf.
    pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start

    psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
        ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';
EOSQL

    pg_ctl -D "$PGDATA" -m fast -w stop
    echo "Password reset complete."
fi

# Hand off to the official postgres entrypoint, which handles normal startup,
# first-time initialization, and running initdb scripts.
exec docker-entrypoint.sh "$@"
