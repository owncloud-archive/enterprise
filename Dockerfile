FROM owncloud/owncloud-base:latest

# download ownCloud
ARG OWNCLOUD_TARBALL=""
ARG USER=""
ARG PASS=""

RUN curl -u $USER:$PASS -sLo - ${OWNCLOUD_TARBALL} | tar xfj - -C /var/www/ \
  && chown -R www-data.www-data /var/www/owncloud

# Configure your setup here
ENV OWNCLOUD_DOMAIN=myown.cloud.com
