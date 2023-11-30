# PgBouncer Docker image

A very minimal PgBouncer Docker image based on Alpine Linux.

### Features

- Tiny image size (about 10 MB)
- Fully configurable via environment variables
- Support for multiple databases
- Support for standalone user administration database 
- Support for custom configuration file

### Quickstart

```bash
docker run --rm \
    -e DB_URL="postgres://<user>:<password>@<hostname>:<port>/<database_name>" \
    -p 5432:5432 \
    litehex/pgbouncer
```

Or add credentials separately:

```bash
docker run --rm \
  -e DB_NAME=mydb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=secret-password \
  -e DB_HOST=postgres \
  -p 5432:5432 \
  litehex/pgbouncer
```

Manage PgBouncer via special administration database `pgbouncer`:

```bash
psql "postgresql://<user>:<password>@localhost:5432/pgbouncer"
```

### Environment variables

To configure, please refer to official [PgBouncer documentation](https://www.pgbouncer.org/config.html) and use them as
environment variables with the following format:

```txt
  # -e <PGBOUNCER_OPTION>=<value>
```

##### Example:

```bash
docker run --rm \
  -e MAX_CLIENT_CONN=100 \
  -e DEFAULT_POOL_SIZE=20 \
  -p 5432:5432 \
  litehex/pgbouncer
```

### Examples

#### Use a custom configuration

Please not e that by going this way you cannot use any option from environment variables.
This method is only useful if you just want to run PgBouncer on Docker.

```bash
docker run --rm \
  -v /path/to/pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini \
  -p 5432:5432 \
  litehex/pgbouncer
```

#### Use docker-compose and the ability to use multiple databases

To define multiple databases, you have to provide environment variables with the following format:

```txt
DB_<name>_URL = <connection_string>
```

```yaml
version: '3'
services:
  storage-bouncer:
    container_name: 'storage-bouncer'
    image: 'litehex/pgbouncer:latest'
    restart: unless-stopped
    ports:
      - '5432:5432'
    environment:
      - DB_URL_READ=postgres://<user>:<password>@<hostname>:<port>/<database_name>
      - DB_URL_WRITE=postgres://<user>:<password>@<hostname>:<port>/<database_name>
```

#### Create an admin user and connect to PgBouncer

For defining an admin you have to use `ADMIN_USERS` and `ADMIN_PASSWORD` environment variables, it will create a user
with given credentials and adds it to config file.

##### 1. Create credentials

```bash
export ADMIN_USER=superuser
export ADMIN_PASSWORD=$(openssl rand -base64 32)
```

##### 2. Add credentials to docker command

```bash
docker run --rm \
  -e DB_URL_CATS=postgres://<user>:<password>@<hostname>:<port>/<database_name> \
  -e ADMIN_USERS=$ADMIN_USER \
  -e ADMIN_PASSWORD=$ADMIN_PASSWORD \
  -p 5432:5432 \
  litehex/pgbouncer
```

##### 3. Connect to PgBouncer admin database

```bash
echo $ADMIN_PASSWORD | psql -h localhost -p 5432 -U $ADMIN_USER pgbouncer
# Or
psql "postgresql://$ADMIN_USER:$ADMIN_PASSWORD@localhost:5432/pgbouncer"
```

### Credits

This project was inspired by [`edoburu/docker-pgbouncer`](https://github.com/edoburu/docker-pgbouncer) and thanks
to [`edoburu`](https://github.com/edoburu) for their great work.

### License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details