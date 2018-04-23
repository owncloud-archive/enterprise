FROM owncloud/base:latest

LABEL maintainer="ownCloud DevOps <devops@owncloud.com>" \
  org.label-schema.name="ownCloud Enterprise" \
  org.label-schema.vendor="ownCloud GmbH" \
  org.label-schema.schema-version="1.0"

ADD owncloud-enterprise-complete-*.tar.bz2 /var/www/
ADD user_ldap.tar.gz /var/www/owncloud/apps/

RUN find /var/www/owncloud \( \! -user www-data -o \! -group www-data \) -print0 | xargs -r -0 chown www-data:www-data
