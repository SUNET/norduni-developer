#!/bin/bash
set -e

pushd `dirname $0` > /dev/null
DEV_DIR="$(dirname $PWD)"
popd > /dev/null
VIRTUAL_ENV="../sources/norduni/env"
MANAGE_PY="../sources/norduni/src/niweb/manage.py"
NOCLOOK_DIR="../sources/norduni/src/scripts"
NEO4J_DIR="../data/neo4j"
DB_NAME="norduni"
SQL_DUMP="./sql/postgres.sql.gz"

# These should not change
postgres_id="norduni_postgres_1"

function now (){
  date +"%Y-%m-%d %H:%M:%S"
}

function msg(){
  echo "> $1 - $(now)"
}

msg "Starting docker compose environment"
echo "../bin/docker-compose -f ../norduni/compose.yml up -d"
../bin/docker-compose -f ../norduni/compose.yml up -d
../bin/docker-compose -f ../norduni/compose.yml stop norduni

msg "Stopping neo4j"
echo "../bin/docker-compose -f ../norduni/compose.yml stop neo4j"
../bin/docker-compose -f ../norduni/compose.yml stop neo4j

msg "Removing neo4j data"
echo "sudo rm -rf $NEO4J_DIR/data/*"
sudo rm -rf $NEO4J_DIR/data/*

msg "Setting neo4j user password to \"docker\""
../bin/docker-compose -f ../norduni/compose.yml run neo4j bin/neo4j-admin set-initial-password docker

msg "Starting neo4j again"
echo "../bin/docker-compose -f ../norduni/compose.yml start neo4j"
../bin/docker-compose -f ../norduni/compose.yml start neo4j

msg "Waiting for neo4j to start"
until $(curl --output /dev/null --silent --head --fail http://localhost:7474); do
    printf '.';
    sleep 1;
done

msg "Adding indexes to neo4j"
echo "curl -D - -H "Content-Type: application/json" -u neo4j:docker --data '{"name" : "node_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/node/"
curl -D - -H "Content-Type: application/json" -u neo4j:docker --data '{"name" : "node_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/node/
echo "curl -D - -H "Content-Type: application/json" -u neo4j:docker --data '{"name" : "relationship_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/relationship/"
curl -D - -H "Content-Type: application/json" -u neo4j:docker --data '{"name" : "relationship_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/relationship/


msg "Drop, Create DB"
cat << EOM | docker exec -i $postgres_id psql -q postgres postgres
DROP DATABASE norduni;
CREATE DATABASE norduni;
GRANT ALL PRIVILEGES ON DATABASE norduni to ni;
ALTER USER ni CREATEDB;
EOM

msg "Import DB from $SQL_DUMP"
gunzip -c $SQL_DUMP | docker exec -i $postgres_id psql -q -o /dev/null norduni ni

msg "Python migrate"
echo "$VIRTUAL_ENV/bin/python $MANAGE_PY migrate --settings=niweb.settings.dev"
$VIRTUAL_ENV/bin/python $MANAGE_PY migrate --settings=niweb.settings.dev

msg "Create superuser"
echo "$VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser --settings=niweb.settings.dev"
$VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser --settings=niweb.settings.dev

msg "Reset postgres sequences"
cat <<EOM | docker exec -i $postgres_id psql -q -o /dev/null norduni ni
BEGIN;
SELECT setval(pg_get_serial_sequence('"noclook_nodetype"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "noclook_nodetype";
SELECT setval(pg_get_serial_sequence('"noclook_nodehandle"','handle_id'), coalesce(max("handle_id"), 1), max("handle_id") IS NOT null) FROM "noclook_nodehandle";
SELECT setval(pg_get_serial_sequence('"noclook_uniqueidgenerator"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "noclook_uniqueidgenerator";
SELECT setval(pg_get_serial_sequence('"noclook_nordunetuniqueid"','id'), coalesce(max("id"), 1), max("id") IS NOT null) FROM "noclook_nordunetuniqueid";
COMMIT;
EOM

msg "Importing neo4j data from json"
echo "tar xvf neo4j_data.tar.gz"
tar xvf neo4j_data.tar.gz
echo "$VIRTUAL_ENV/bin/python $NOCLOOK_DIR/noclook_consumer.py -C load_demo.conf -I"
DJANGO_SETTINGS_MODULE=niweb.settings.dev $VIRTUAL_ENV/bin/python $NOCLOOK_DIR/noclook_consumer.py -C load_demo.conf -I

msg "Stopping docker compose environment"
echo "../bin/docker-compose -f ../norduni/compose.yml down"
../bin/docker-compose -f ../norduni/compose.yml down

msg "Done"

echo "***************************************************************************************************"
echo "Go to parent directory and run start.sh and open your browser to http://localhost:8000 to view demo"
echo "***************************************************************************************************"
