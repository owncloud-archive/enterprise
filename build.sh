#!/bin/bash

source .env

USER=$1
echo -n Password: 
read -s PASS

VALID=$(curl -u $USER:$PASS -s -w"%{http_code}" -X PROPFIND $OWNCLOUD_TARBALL -o /dev/null)
[[ $VALID == 401 ]] && echo "Credentials wrong"
[[ $VALID == 503 ]] && echo "Customer Portal in Maintenace Mode, please try again later"
[[ ! $VALID == 207 ]] && echo "Download Error" && exit 1

echo "ownCloud Enterprise Credentials correct"
echo "Building ownCloud enterprise $VERSION"
echo $OWNCLOUD_TARBALL

#docker pull owncloud/owncloud-base
docker build -t owncloud/enterprise:$VERSION --build-arg OWNCLOUD_TARBALL=$OWNCLOUD_TARBALL --build-arg USER=$USER --build-arg PASS=$PASS --no-cache .

