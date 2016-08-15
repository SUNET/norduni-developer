#!/bin/bash
set -e

pushd `dirname $0` > /dev/null
DEV_DIR="$(pwd)"
popd > /dev/null
VIRTUAL_ENV="/var/opt/norduni_environment"
MANAGE_PY="/var/opt/norduni/norduni/src/niweb/manage.py"
NOCLOOK_DIR="/var/opt/norduni/norduni/src/scripts"
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
sleep 7

msg "Changing password for user neo4j"
echo "curl --user neo4j:neo4j -D - -H "Content-Type: application/json" --data '{"password" : "docker"}' http://localhost:7474/user/neo4j/password"
curl --user neo4j:neo4j -D - -H "Content-Type: application/json" --data '{"password" : "docker"}' http://localhost:7474/user/neo4j/password

msg "Restarting neo4j"
echo "docker stop norduni_neo4j_1 && docker start norduni_neo4j_1"
docker stop norduni_neo4j_1 && docker start norduni_neo4j_1

msg "Stopping NOCLook"
echo "docker stop norduni_noclook_1"
docker stop norduni_noclook_1

msg "Drop, Create DB"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/drop-create-grant.sql"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/drop-create-grant.sql

msg "Import DB"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/postgres.sql $DB_NAME"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/postgres.sql $DB_NAME

msg "Starting NOCLook"
echo "docker start norduni_noclook_1"
docker start norduni_noclook_1

msg "Python migrate"
echo "docker exec -it norduni_noclook_1 $VIRTUAL_ENV/bin/python $MANAGE_PY migrate"
docker exec -it norduni_noclook_1 $VIRTUAL_ENV/bin/python $MANAGE_PY migrate

msg "Create superuser"
echo "docker exec -it norduni_noclook_1 $VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser"
docker exec -it norduni_noclook_1 $VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser

msg "Reset DB sequences"
echo "docker exec -it norduni_postgres_1 psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME"
docker exec -it norduni_postgres_1 psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME

msg "Importing neo4j data from json"
echo "docker exec -it norduni_noclook_1 cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C neo4j-only.conf -I"
docker exec -u ni -it norduni_noclook_1 bash -c "cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C neo4j-only.conf -I"
