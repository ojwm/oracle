# Container Engine

> Not to be confused with the [Oracle multitenant container database (CDB)](https://www.oracle.com/uk/database/container-database/).

Oracle Database can be run in a container, using a container engine such as [Podman](https://docs.podman.io) or [Docker](https://www.docker.com).

Images can be [built from source](https://github.com/oracle/docker-images) but there are community maintained [Oracle XE images](https://github.com/gvenzl/oci-oracle-xe) available.

1. Run a container, providing a password through `ORACLE_PASSWORD`, which will be used for the `SYS` and `SYSTEM` users.

   ```sh
   podman run -d -p 1521:1521 -e ORACLE_PASSWORD=<your_password> gvenzl/oracle-xe:slim
   ```

1. Check the container is running.

   ```sh
   $ podman ps -a                                                             
   CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS            PORTS                   NAMES
   6c5800535262  docker.io/gvenzl/oracle-xe:slim              8 seconds ago  Up 8 seconds ago  0.0.0.0:1521->1521/tcp  pensive_khorana
   ```

1. Connect to the database, e.g. using [SQLcl](../README.md).
