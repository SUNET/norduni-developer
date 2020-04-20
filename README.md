# norduni-developer repo

## How?

To start a postgresql and neo4j database just run `start.sh`. After that start NOCLook using runserver or pycharm.

TODO: Create a docker image for NOCLook.

### Import data
To reinitialize the databases using the latest backups you first need to symlink the [norduni](https://github.com/NORDUnet/ni) and [sri-front](https://github.com/SUNET/sri-front) repo under the sources dir.

    norduni-developer
    ├── sources
    │   ├── norduni -> /.../norduni/
    │   └── sri-front -> /.../sri-front/

Start the databases using `start.sh` and then just run `db-restore.sh`.

### Run demo
To run the demo set up the norduni source as above and run `load_demo.sh` from the demo subdirectory. The settings at the top of load_demo.sh expects there to be a virtual environment called `env` in the norduni source directory.
