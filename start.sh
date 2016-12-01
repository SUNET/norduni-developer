#!/bin/sh

if [ ! -f norduni/compose.yml ]; then
    echo "Run $0 from the norduni-developer top level directory"
    exit 1
fi

#
# Set up entrys in /etc/hosts for the containers with externally accessible services
#
(printf "172.16.21.100\t postgres.norduni.docker\n";
    printf "172.16.21.110\t neo4j.norduni.docker\n";
    printf "172.16.21.120\t noclook.norduni.docker\n";
    printf "127.0.0.1\t nginx.norduni.docker\n";
) \
    | while read line; do
    if ! grep -q "^${line}$" /etc/hosts; then
        echo "$0: Adding line '${line}' to /etc/hosts"
        if [ "x`whoami`" = "xroot" ]; then
            echo "${line}" >> /etc/hosts
        else
            echo "${line}" | sudo tee -a /etc/hosts
        fi
    else
        echo "Line '${line}' already in /etc/hosts"
    fi
done


./bin/docker-compose -f norduni/compose.yml rm -f --all
./bin/docker-compose -f norduni/compose.yml up $*
