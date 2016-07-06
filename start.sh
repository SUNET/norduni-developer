#!/bin/sh

if [ ! -f norduni/compose.yml ]; then
    echo "Run $0 from the norduni-developer top level directory"
    exit 1
fi

./bin/docker-compose -f norduni/compose.yml rm -f --all
./bin/docker-compose -f norduni/compose.yml up $*
