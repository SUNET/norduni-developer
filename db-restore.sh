#!/bin/bash
set -e

pushd `dirname $0` > /dev/null
DEV_DIR="$(pwd)"
popd > /dev/null
VIRTUAL_ENV="./sources/norduni/env"
MANAGE_PY="./sources/norduni/src/niweb/manage.py"
NOCLOOK_DIR="./sources/norduni/src/scripts"
NEO4J_DIR="./data/neo4j"
DB_NAME="norduni"

function now (){
  date +"%Y-%m-%d %H:%M:%S"
}

function msg(){
  echo "> $1 - $(now)"
}

msg "Stopping neo4j"
echo "docker stop norduni_neo4j_1"
docker stop norduni_neo4j_1


msg "Removing neo4j data"
echo "sudo rm -rf $NEO4J_DIR/data/*"
sudo rm -rf $NEO4J_DIR/data/*


msg "Starting neo4j again"
echo "docker start norduni_neo4j_1"
docker start norduni_neo4j_1

msg "Waiting for neo4j to start"
sleep 5

msg "Adding indexes to neo4j"
echo "curl -D - -H "Content-Type: application/json" --data '{"name" : "node_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/node/"
curl -D - -H "Content-Type: application/json" --data '{"name" : "node_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/node/
echo "curl -D - -H "Content-Type: application/json" --data '{"name" : "relationship_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/relationship/"
curl -D - -H "Content-Type: application/json" --data '{"name" : "relationship_auto_index","config" : {"type" : "fulltext","provider" : "lucene"}}' -X POST http://localhost:7474/db/data/index/relationship/


msg "Drop, Create DB"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/drop-create-grant.sql"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/drop-create-grant.sql

msg "Import DB"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/postgres.sql $DB_NAME"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/postgres.sql $DB_NAME

msg "Python migrate"
echo "$VIRTUAL_ENV/bin/python $MANAGE_PY migrate --settings=niweb.settings.dev"
$VIRTUAL_ENV/bin/python $MANAGE_PY migrate --settings=niweb.settings.dev

msg "Create superuser"
echo "$VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser --settings=niweb.settings.dev"
$VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser --settings=niweb.settings.dev

msg "Reset DB sequences"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME

msg "Importing neo4j data from json"
echo "cd $NOCLOOK_DIR"
cd $NOCLOOK_DIR
echo "$DEV_DIR/$VIRTUAL_ENV/bin/python noclook_consumer.py -C $DEV_DIR/noclook/neo4j-only.conf -I"
DJANGO_SETTINGS_MODULE=niweb.settings.dev $DEV_DIR/$VIRTUAL_ENV/bin/python noclook_consumer.py -C $DEV_DIR/noclook/neo4j-only.conf -I

