#!/bin/bash

set -e

docker exec -it norduni_postgres_1 pg_dump -U ni norduni | gzip > sql/postgres.sql.gz
. ../sources/norduni/env/bin/activate
mkdir -p $PWD/json/
../sources/norduni/src/scripts/noclook_producer.py -O $PWD/json/
tar -cvzf $PWD/neo4j_data.tar.gz ./json/* --remove-files
rmdir $PWD/json/
