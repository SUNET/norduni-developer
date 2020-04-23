#!/bin/sh

if [ ! -f norduni/compose.yml ]; then
    echo "Run $0 from the norduni-developer top level directory"
    exit 1
fi

# add ni.localenv.loc to hosts file
(printf '127.0.0.1\tsri.localenv.loc\n';
) \
    | while read -r line; do
    if ! grep -q "^${line}$" /etc/hosts; then
	echo "$0: Adding line '${line}' to /etc/hosts"
	if [ "$(whoami)" = "root" ]; then
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
