# norduni-developer repo

## How?

To start just run `start.sh`. If it is the first time starting after cloning the repo begin by running `before_first_run.sh`.

That should start a Neo4j database, a PostgreSQL database, a Nginx webserver and the NOCLook application.

The script will ask you for sudo rights to write in your hosts file. The following entrys will be added.

172.16.21.100   postgres.norduni.docker
172.16.21.110   neo4j.norduni.docker
172.16.21.120   noclook.norduni.docker
172.16.21.130   nginx.norduni.docker

If you see no errors in the output you should be able to open your browser to nginx.norduni.docker and see the NOCLook app.


### Import data
To reinitialize the databases using the latest backups you first need to symlink the norduni and nistore repo under the sources dir.

    norduni-developer
    ├── sources
    │   ├── norduni -> /.../norduni/
    │   └── nistore -> /.../nistore/

Start the databases using `start.sh` and then just run `db-restore.sh`.

### Automatic reload of code
When a norduni repository is located under sources the NOCLook container will automatically reload the application if files are changed.

