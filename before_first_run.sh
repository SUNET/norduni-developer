#!/bin/sh

if [ ! -f norduni/compose.yml ]; then
    echo "Run $0 from the norduni-developer top level directory"
    exit 1
fi

VIRTUAL_ENV="/var/opt/norduni_environment"
MANAGE_PY="/var/opt/norduni/norduni/src/niweb/manage.py"

./bin/docker-compose -f norduni/compose.yml pull
./bin/docker-compose -f norduni/compose.yml run noclook bash -c "$VIRTUAL_ENV/bin/python $MANAGE_PY migrate && $VIRTUAL_ENV/bin/python $MANAGE_PY createsuperuser"
