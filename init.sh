#!/bin/bash

mysql --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD $RADIUS_DB_NAME  < /etc/freeradius/3.0/main/mysql/schema.sql
mysql --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD $RADIUS_DB_NAME  < /etc/freeradius/3.0/main/mysql/nas.sql
mysql --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD $RADIUS_DB_NAME  < /var/www/daloradius/contrib/db/mysql-daloradius.sql


sed -i 's/password = "radpass"/password = "'$RADIUS_DB_PWD'"/' /etc/freeradius/sql.conf
sed -i 's/#port = 3306/port = 3306/' /etc/freeradius/sql.conf
sed -i 's/#server = localhost/server = radius/' /etc/freeradius/3.0/sql.conf
sed -i -e 's/$INCLUDE sql.conf/\n$INCLUDE sql.conf/g' /etc/freeradius/radiusd.conf
sed -i -e 's|$INCLUDE sql/mysql/counter.conf|\n$INCLUDE sql/mysql/counter.conf|g' /etc/freeradius/radiusd.conf
sed -i -e 's|authorize {|authorize {\nsql|' /etc/freeradius/sites-available/inner-tunnel
sed -i -e 's|session {|session {\nsql|' /etc/freeradius/sites-available/inner-tunnel 
sed -i -e 's|authorize {|authorize {\nsql|' /etc/freeradius/sites-available/default
sed -i -e 's|session {|session {\nsql|' /etc/freeradius/sites-available/default
sed -i -e 's|accounting {|accounting {\nsql|' /etc/freeradius/sites-available/default

sed -i -e 's|auth_badpass = no|auth_badpass = yes|g' /etc/freeradius/radiusd.conf
sed -i -e 's|auth_goodpass = no|auth_goodpass = yes|g' /etc/freeradius/radiusd.conf
sed -i -e 's|auth = no|auth = yes|g' /etc/freeradius/radiusd.conf

sed -i -e 's|\t#  See "Authentication Logging Queries" in sql.conf\n\t#sql|#See "Authentication Logging Queries" in sql.conf\n\tsql|g' /etc/freeradius/sites-available/inner-tunnel 
sed -i -e 's|\t#  See "Authentication Logging Queries" in sql.conf\n\t#sql|#See "Authentication Logging Queries" in sql.conf\n\tsql|g' /etc/freeradius/sites-available/default

sed -i -e 's|sqltrace = no|sqltrace = yes|g' /etc/freeradius/sql.conf



sed -i -e "s/readclients = yes/nreadclients = yes/" /etc/freeradius/sql.conf
echo -e "\nATTRIBUTE Usage-Limit 3000 string\nATTRIBUTE Rate-Limit 3001 string" >> /etc/freeradius/dictionary



#================DALORADIUS=========================
sed -i "s/$configValues\['CONFIG_DB_PASS'\] = '';/$configValues\['CONFIG_DB_PASS'\] = '"$RADIUS_DB_PWD"';/" /var/www/daloradius/library/daloradius.conf.php
sed -i "s/$configValues\['CONFIG_DB_USER'\] = 'root';/$configValues\['CONFIG_DB_USER'\] = '"$RADIUS_DB_USER"';/" /var/www/daloradius/library/daloradius.conf.php

if [ -n "$CLIENT_NET" ]; then
echo "client $CLIENT_NET {
    	secret          = $CLIENT_SECRET
    	shortname       = clients
}" >> /etc/freeradius/clients.conf
fi 


#======== DELETE INIT CODE ==
echo "#!/bin/bash

echo Waiting for MySQL daemon to brought up...
until mysql --host=radius --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD &> /dev/null; do
    sleep 1
done
echo MySQL is up. Continuing...

php7.2-fpm & 
nginx & 
/usr/sbin/freeradius -X" > /init.sh


mkdir /run/php & \

echo Waiting for MySQL daemon to brought up...
until mysql --host=radius --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD &> /dev/null; do
    sleep 1
done
echo MySQL is up. Continuing...

php7.2-fpm & \
nginx & \
/usr/sbin/freeradius -X

echo "Inited and STARTED"
