#!/bin/bash

echo Waiting for MySQL daemon to be ready...
until mysql --host=$RADIUS_DB_HOST --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD &> /dev/null; do
    sleep 1
done
echo MySQL is up. Continuing...

mysql --host=$RADIUS_DB_HOST --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD $RADIUS_DB_NAME  < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

sed -i 's/dialect = "sqlite"/dialect = "mysql"/' /etc/freeradius/3.0/mods-available/sql
sed -i 's/#\s*server = localhost/server = '$RADIUS_DB_HOST'/' /etc/freeradius/3.0/mods-available/sql
sed -i 's/#\s*port = 3306/port = 3306/' /etc/freeradius/3.0/mods-available/sql
sed -i 's/password = "radpass"/password = "'$RADIUS_DB_PWD'"/' /etc/freeradius/3.0/mods-available/sql
sed -i -e 's|authorize {|authorize {\nsql|' /etc/freeradius/3.0/sites-available/inner-tunnel
sed -i -e 's|session {|session {\nsql|' /etc/freeradius/3.0/sites-available/inner-tunnel 
sed -i -e 's|authorize {|authorize {\nsql|' /etc/freeradius/3.0/sites-available/default
sed -i -e 's|session {|session {\nsql|' /etc/freeradius/3.0/sites-available/default
sed -i -e 's|accounting {|accounting {\nsql|' /etc/freeradius/3.0/sites-available/default

sed -i -e 's|auth_badpass = no|auth_badpass = yes|g' /etc/freeradius/3.0/radiusd.conf
sed -i -e 's|auth_goodpass = no|auth_goodpass = yes|g' /etc/freeradius/3.0/radiusd.conf
sed -i -e 's|auth = no|auth = yes|g' /etc/freeradius/3.0/radiusd.conf

sed -i -e 's|\t#  See "Authentication Logging Queries" in sql.conf\n\t#sql|#See "Authentication Logging Queries" in sql.conf\n\tsql|g' /etc/freeradius/3.0/sites-available/inner-tunnel 
sed -i -e 's|\t#  See "Authentication Logging Queries" in sql.conf\n\t#sql|#See "Authentication Logging Queries" in sql.conf\n\tsql|g' /etc/freeradius/3.0/sites-available/default


sed -i -e "s/readclients = yes/nreadclients = yes/" /etc/freeradius/3.0/mods-available/sql
echo -e "\nATTRIBUTE Usage-Limit 3000 string\nATTRIBUTE Rate-Limit 3001 string" >> /etc/freeradius/3.0/dictionary




if [ -n "$CLIENT_NET" ]; then
echo "client $CLIENT_NET {
    	secret          = $CLIENT_SECRET
    	shortname       = clients
}" >> /etc/freeradius/3.0/clients.conf
fi


#======== DELETE INIT CODE ==
echo "#!/bin/bash

echo Waiting for MySQL daemon to be ready...
until mysql --host=mysql --user=$RADIUS_DB_USER --password=$RADIUS_DB_PWD &> /dev/null; do
    sleep 1
done
echo MySQL is up. Continuing...
nginx &
/usr/sbin/freeradius -X" > /init.sh

echo "debug printf"
mkdir /run/php & \
nginx & \
/usr/sbin/freeradius -X

echo "Inited and STARTED"
