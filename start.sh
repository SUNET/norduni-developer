#!/bin/sh

if [ ! -f norduni/compose.yml ]; then
    echo "Run $0 from the norduni-developer top level directory"
    exit 1
fi

#
# Set up entrys in /etc/hosts for the containers with externally accessible services
#
(printf "172.16.21.100\tpostgres.norduni_dev postgres.norduni.docker\n";
    printf "172.16.21.110\tneo4j.norduni_dev neo4j.norduni.docker\n";
    printf "172.16.21.120\tnoclook.norduni_dev noclook.norduni.docker\n";
    printf "172.16.21.130\tnginx.norduni_dev nginx.norduni.docker\n";
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
