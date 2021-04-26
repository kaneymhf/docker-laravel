#!/bin/sh
#
set -x
#

sed -i "s~PHP_TZ~$PHP_TZ~g" /etc/php7/conf.d/10-timezone.ini

# Replaces Enviroment
# sed -i "s/APPLICATION/$APPLICATION/g" /etc/nginx/conf.d/default.conf

# Adjusts Laravel Permissions
#chmod 777 -R /www/$APPLICATION/storage /www/$APPLICATION/bootstrap/cache

# Starts Supervisor
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
