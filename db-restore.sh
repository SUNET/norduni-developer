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
echo "docker stop neo4j.norduni.docker"
docker stop neo4j.norduni.docker


msg "Removing neo4j data"
echo "sudo rm -rf $NEO4J_DIR/data/*"
sudo rm -rf $NEO4J_DIR/data/*


msg "Starting neo4j again"
echo "docker start neo4j.norduni.docker"
docker start neo4j.norduni.docker

msg "Waiting for neo4j to start"
sleep 7

msg "Changing password for user neo4j"
echo "curl --user neo4j:neo4j -D - -H "Content-Type: application/json" --data '{"password" : "docker"}' http://localhost:7474/user/neo4j/password"
curl --user neo4j:neo4j -D - -H "Content-Type: application/json" --data '{"password" : "docker"}' http://localhost:7474/user/neo4j/password

msg "Restarting neo4j"
echo "docker stop neo4j.norduni.docker && docker start neo4j.norduni.docker"
docker stop neo4j.norduni.docker && docker start neo4j.norduni.docker

msg "Stopping NOCLook"
echo "docker stop noclook.norduni.docker"
docker stop noclook.norduni.docker

msg "Drop, Create DB"
echo "docker exec -it postgres.norduni.docker psql --username postgres -f /sql/drop-create-grant.sql"
docker exec -it postgres.norduni.docker psql --username postgres -f /sql/drop-create-grant.sql

msg "Import DB"
echo "docker exec -it postgres.norduni.docker gunzip -c /sql/postgres.sql.gz | psql --username postgres $DB_NAME"
docker exec -it postgres.norduni.docker bash -c "gunzip -c /sql/postgres.sql.gz | /usr/bin/psql --username postgres $DB_NAME"

msg "Starting NOCLook"
echo "docker start noclook.norduni.docker"
docker start noclook.norduni.docker

msg "Python migrate"
echo "docker exec -it noclook.norduni.docker $VIRTUAL_ENV/bin/python $MANAGE_PY migrate"
docker exec -it noclook.norduni.docker $VIRTUAL_ENV/bin/python $MANAGE_PY migrate

msg "Create superuser"
echo "docker exec -it noclook.norduni.docker $VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser"
docker exec -it noclook.norduni.docker $VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser

msg "Reset DB sequences"
echo "docker exec -it postgres.norduni.docker psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME"
docker exec -it postgres.norduni.docker psql --username postgres -f /sql/reset-sequences-noclook.sql $DB_NAME

msg "Importing neo4j data from json"
echo "docker exec -it noclook.norduni.docker cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C neo4j-only.conf -I"
docker exec -u ni -it noclook.norduni.docker bash -c "cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C neo4j-only.conf -I"
