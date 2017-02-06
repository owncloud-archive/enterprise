# ownCloud: Enterprise

[![](https://images.microbadger.com/badges/image/owncloud/enterprise.svg)](https://microbadger.com/images/owncloud/enterprise "Get your own image badge on microbadger.com")

This is our ownCloud image for the enterprise edition, it is based on our [base container](https://registry.hub.docker.com/u/owncloud/base/). Additionally we have also preinstalled the richdocuments app.


## Usage

```bash
docker run -ti \
  --name owncloud \
  owncloud/enterprise:latest
```


### Launch with plain `docker`

First of all you have to start the required MariaDB and Redis:

```bash
docker run -d --name redis webhippie/redis:latest

docker run -d \
  --name mariadb \
  -e MARIADB_ROOT_PASSWORD=owncloud \
  -e MARIADB_USERNAME=owncloud \
  -e MARIADB_PASSWORD=owncloud \
  -e MARIADB_DATABASE=owncloud \
  --volume ./mysql:/var/lib/mysql \
  webhippie/mariadb:latest
```

Then you can start the ownCloud web server, you can customize the used environment variables within the `.env` file:

```bash
source .env

docker run -d \
  --name owncloud \
  --link mariadb:mariadb \
  --link redis:redis \
  -p 80:80 \
  -p 443:443 \
  -e OWNCLOUD_DOMAIN=${DOMAIN} \
  -e OWNCLOUD_DB_TYPE=mysql \
  -e OWNCLOUD_DB_NAME=owncloud \
  -e OWNCLOUD_DB_USERNAME=owncloud \
  -e OWNCLOUD_DB_PASSWORD=owncloud \
  -e OWNCLOUD_DB_HOST=db \
  -e OWNCLOUD_ADMIN_USERNAME=${ADMIN_USERNAME} \
  -e OWNCLOUD_ADMIN_PASSWORD=${ADMIN_PASSWORD} \
  -e OWNCLOUD_REDIS_ENABLED=true \
  -e OWNCLOUD_REDIS_HOST=redis \
  --volume ./data:/mnt/data:z \
  owncloud/enterprise:${VERSION}
```


### Launch with `docker-compose`

Create and start the ownCloud stack based on these commands:

```bash
source .env
docker-compose up -d
```

More commands of interest:

```bash
docker-compose exec owncloud bash
docker-compose stop
docker-compose start
docker-compose down
```

By default this will start redis, mariadb and ownCloud containers, the `data` directory gets used to store the content persistent. The container ports `80` and `443` are getting bound like it is confiogured within the `.env` file.


## Build locally

The available versions should be already pushed to the Docker Hub, but in case you want to try a change locally you can always execute the following command to get this image built locally:

```
source .env
USER=username PASS=password IMAGE_NAME=owncloud/enterprise:${VERSION} ./hooks/build
```


### Custom certificates

By default we are generating self-signed certificates on startup of the containers, you can replace the certificates with your own certificates when you place them into `data/certs/ssl-cert.crt` and `data/certs/ssl-cert.key`, than they are getting used automatically.


### Accessing the ownCloud

By default you can access the ownCloud instance at [https://localhost/](https://localhost/) as long as you have not changed the port binding. The initial user gets set by the environment variables `ADMIN_USERNAME` and `ADMIN_PASSWORD`, per default it's set to `admin` for username and password.


### Build image from tarball

1. Download ownCloud Enterprise ```owncloud-enterprise-complete-9.1.3.tar.bz2``` from the Customer Download Center to this folder.
2. Comment out the first `curl` command for downloading the tarball from the URL within the `Dockerfile`
3. Remove the comment from the `ADD` command within the `Dockerfile`
4. Build the ownCloud Enterprise docker image based on the `Dockerfile` as mentioned above.


## Versions

* [latest](https://github.com/owncloud-docker/enterprise/tree/master) available as ```owncloud/enterprise:latest``` at [Docker Hub](https://registry.hub.docker.com/u/owncloud/enterprise/)


## Volumes

* /mnt/data


## Ports

* 80
* 443


## Available environment variables

**None**


## Available environment variables

```
OWNCLOUD_DOMAIN ${HOSTNAME}
OWNCLOUD_IPADDRESS $(hostname -i)
OWNCLOUD_LOGLEVEL 0
OWNCLOUD_DB_TYPE sqlite
OWNCLOUD_DB_HOST
OWNCLOUD_DB_NAME owncloud
OWNCLOUD_DB_USERNAME
OWNCLOUD_DB_PASSWORD
OWNCLOUD_DB_PREFIX
OWNCLOUD_DB_TIMEOUT 180
OWNCLOUD_DB_FAIL true
OWNCLOUD_ADMIN_USERNAME admin
OWNCLOUD_ADMIN_PASSWORD admin
OWNCLOUD_REDIS_ENABLED false
OWNCLOUD_REDIS_HOST redis
OWNCLOUD_REDIS_PORT 6379
OWNCLOUD_MEMCACHED_ENABLED false
OWNCLOUD_MEMCACHED_HOST memcached
OWNCLOUD_MEMCACHED_PORT 11211
```


## Issues, Feedback and Ideas

Open an [Issue](https://github.com/owncloud-docker/base/issues)


## Contributing

Fork -> Patch -> Push -> Pull Request


## Authors

* [Felix Boehm](https://github.com/felixboehm)
* [Thomas Boerger](https://github.com/tboerger)


## License

MIT


## Copyright

```
Copyright (c) 2017 Felix Böhm <felix@owncloud.com>
```
