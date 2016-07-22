FROM owncloud/owncloud-base:latest

# download ownCloud
ARG OWNCLOUD_TARBALL=""
RUN curl -sLo - ${OWNCLOUD_TARBALL} | tar xfj - -C /var/www/
ADD conf/config.php /var/www/owncloud/config/config.php
RUN chown -R www-data.www-data /var/www/owncloud

# Configure your setup here
ENV OWNCLOUD_DOMAIN=myown.cloud.com
