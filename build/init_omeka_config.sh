# !/command/with-contenv bash

# Create Omeka-S database.ini file
echo "Creating Omeka S database.ini file ..."
echo "user     = \"$MYSQL_USER\"" > /var/www/omeka-s/config/database.ini
echo "password = \"$MYSQL_PASSWORD\"" >> /var/www/omeka-s/config/database.ini
echo "dbname   = \"$MYSQL_DATABASE\"" >> /var/www/omeka-s/config/database.ini
echo "host     = \"$MYSQL_HOST\"" >> /var/www/omeka-s/config/database.ini
chmod 644 /var/www/omeka-s/config/database.ini
