#!/bin/bash
export DOMAINS="crosskey.netdelta.io"
export WEBMASTER_MAIL="ian.tibble@netdelta.io"
export DOMAINS WEBMASTER_MAIL

#RESULT=`mysqlshow --user=root --password=myDatabase| grep -v Wildcard | grep -o myDatabase`
#if [ "$RESULT" == "myDatabase" ]; then
#    echo YES
#fi

mkdir -pv /srv/netdelta
chown -vR mysql /var/lib/mysql
chgrp -vR mysql /var/lib/mysql
useradd -s /bin/bash -d /home/iantibble -m iantibble
groupadd web
usermod -G web iantibble
usermod -G web www-data
#mkdir /var/www
chown -R www-data:web /var/www
chown -R iantibble:web /srv/netdelta
chown -R iantibble:web /srv/staging
mkdir -v /home/iantibble/jango
mkdir -v /home/iantibble/logs
ln -s /srv/netdelta /home/iantibble/jango/netdelta

echo "sleeping 10"
sleep 10
service mysql start
service rabbitmq-server start
mysql -e 'CREATE DATABASE IF NOT EXISTS netdelta CHARACTER SET utf8 COLLATE utf8_unicode_ci;' --user=root --password=ankSQL4r4

#certbot -n --expand --apache --agree-tos --email $WEBMASTER_MAIL --domains $DOMAINS
# -------Setting letsencrypt certs where we already have the certs issued
if [ "$1" == "le" ]
then
	echo "will configure letsencrypt certs"
	a2dissite crosskey-django.conf 
	a2ensite crosskey-django-le.conf 
fi

# -------Setting netdelta Django project environment
cd /srv/netdelta
echo "starting project netdelta"
su -m iantibble -c "django-admin startproject netdelta"
#django-admin startproject netdelta

echo "starting app nd"
su -m iantibble -c "django-admin startapp nd"
#django-admin startapp nd

rsync -azrl /srv/staging/ /srv/netdelta/

su -m iantibble -c "python manage.py makemigrations nd"
# migrate db, so we have the latest db schema
su -m iantibble -c "python manage.py migrate"

echo "from django.contrib.auth.models import User; User.objects.filter(email='itibble@gmail.com').delete(); User.objects.create_superuser('admin', 'itibble@gmail.com', 'octl1912')" | python manage.py shell

/usr/local/bin/fixperms.bash
service apache2 restart

# start celery worker
#su -m iantibble -c "python manage.py celery worker --loglevel=info -B"
#nohup su -m iantibble -c "python manage.py celery worker --loglevel=info -B"
#python manage.py runserver 0.0.0.0:9500 > /home/iantibble/logs/netdelta-django.losu - m g
su -m iantibble -c "python manage.py celery worker --loglevel=info -B | tee /home/iantibble/logs/netdelta-celery.log"
tail -f /dev/null
