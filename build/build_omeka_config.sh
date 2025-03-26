# !/command/with-contenv bash
rm -f /var/www/omeka-s/config/database.ini
echo "user     = \"$MYSQL_USER\"" >/var/www/omeka-s/config/database.ini
echo "password = \"$MYSQL_PASSWORD\"" >>/var/www/omeka-s/config/database.ini
echo "dbname   = \"$MYSQL_DATABASE\"" >>/var/www/omeka-s/config/database.ini
echo "host     = \"$MYSQL_HOST\"" >>/var/www/omeka-s/config/database.ini
echo "Created Omeka-S database.ini in /var/www/omeka-s/config/ ..."
