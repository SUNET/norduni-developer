#!/bin/bash
set -e

docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --create node_auto_index -t Node"
docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --set-config node_auto_index type fulltext -t Node"
docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --get-config node_auto_index -t Node"
docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --create relationship_auto_index -t Relationship"
docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --set-config relationship_auto_index type fulltext -t Relationship"
docker exec -t norduni_neo4j_1 /var/lib/neo4j/bin/neo4j-shell -v -c "index --get-config relationship_auto_index -t Relationship"

