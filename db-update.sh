#!/bin/bash
set -e

VIRTUAL_ENV="/var/opt/norduni_environment"
NOCLOOK_DIR="/var/opt/norduni/norduni/src/scripts"

function now (){
  date +"%Y-%m-%d %H:%M:%S"
}

function msg(){
  echo "> $1 - $(now)"
}

msg "Importing neo4j data from json"
echo "docker exec -it norduni_noclook_1 cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C full-update.conf -I"
docker exec -u ni -it norduni_noclook_1 bash -c "cd $NOCLOOK_DIR && $VIRTUAL_ENV/bin/python noclook_consumer.py -C full-update.conf -I"
