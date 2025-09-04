# !/command/with-contenv bash

cd /var/www/omeka-s

# Create Omeka-S database.ini file
echo "Creating Omeka S database.ini file ..."
echo "user     = \"$MYSQL_USER\"" > /var/www/omeka-s/config/database.ini
echo "password = \"$MYSQL_PASSWORD\"" >> /var/www/omeka-s/config/database.ini
echo "dbname   = \"$MYSQL_DATABASE\"" >> /var/www/omeka-s/config/database.ini
echo "host     = \"$MYSQL_HOST\"" >> /var/www/omeka-s/config/database.ini
chmod 644 /var/www/omeka-s/config/database.ini

# Update APPLICATION_ENV in .htaccess
echo "Patch Omeka S .htaccess file ..."
APPLICATION_ENV=${APPLICATION_ENV:-production}
sed -i "s/_APPLICATION_ENV_/$APPLICATION_ENV/" .htaccess