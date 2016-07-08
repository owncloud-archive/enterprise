FROM owncloud/server:9.0.3

ADD owncloud-enterprise-complete-9.0.3.tar.bz2 /var/www/
RUN chown -R www-data.www-data /var/www/owncloud

# Configure your setup here
ENV OWNCLOUD_DOMAIN=owncloud.com
