# norduni-developer repo

## How?

To start a postgresql and neo4j database just run `start.sh`. After that start NOCLook using runserver or pycharm.

TODO: Create a docker image for NOCLook.

### Import data
To reinitialize the databases using the latest backups you first need to symlink the norduni and nistore repo under the sources dir.

    norduni-developer
    ├── sources
    │   ├── norduni -> /.../norduni/
    │   └── nistore -> /.../nistore/

Start the databases using `start.sh` and then just run `db-restore.sh`.
