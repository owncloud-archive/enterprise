# ownCloud / enterprise

## Build your ownCloud enterprise image.

1. git clone or download this repository, with version you want to use
2. Download ownCloud Enterprise ```owncloud-enterprise-complete-9.0.3.tar.bz2``` from ownCloud's Customer Download Center to this folder.
3. Edit configurations in the Dockerfile
4. Build and run your ownCloud Enterprise Dockerfile

Now you can use the image `owncloud/enterprise` exactly like `owncloud/server`
Further instructions see [owncloud/server](https://github.com/owncloud-docker/server)

### Use docker-compose

Create and start ownCloud Enterprise stack

```bash
docker-compose up -d
```

Install and configure ownCloud

```bash
docker-compose exec owncloud owncloud-config.sh
```

### Manual build

```bash
docker build -t owncloud/enterprise .
```


## Versions

Versions can be found as branches of this repository

* [latest](https://github.com/owncloud-docker/enterprise/tree/master) download [zip](https://github.com/owncloud-docker/enterprise/archive/master.zip)
* [9.0.3](https://github.com/owncloud-docker/enterprise/tree/9.0.3) download [zip](https://github.com/owncloud-docker/enterprise/archive/9.0.3.zip)

