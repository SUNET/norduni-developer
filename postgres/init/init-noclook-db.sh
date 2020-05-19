#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER ni;
    ALTER USER "ni" WITH PASSWORD 'docker';
    CREATE DATABASE norduni;
    GRANT ALL PRIVILEGES ON DATABASE norduni TO ni;
    ALTER USER ni CREATEDB;
EOSQL
