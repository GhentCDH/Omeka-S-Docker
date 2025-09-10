# !/command/with-contenv bash

cd /var/www/omeka-s

# Create Omeka-S database.ini file
echo "Creating Omeka S database.ini file ..."
echo "user     = \"${MYSQL_USER:-omeka}\"" > /var/www/omeka-s/config/database.ini
echo "password = \"${MYSQL_PASSWORD:-omeka}\"" >> /var/www/omeka-s/config/database.ini
echo "dbname   = \"${MYSQL_DATABASE:-omeka}\"" >> /var/www/omeka-s/config/database.ini
echo "host     = \"${MYSQL_HOST:-db}\"" >> /var/www/omeka-s/config/database.ini
echo "port     = ${MYSQL_PORT:-3306}" >> /var/www/omeka-s/config/database.ini
chmod 644 /var/www/omeka-s/config/database.ini

# Update APPLICATION_ENV in .htaccess
echo "Patch Omeka S .htaccess file ..."
APPLICATION_ENV=${APPLICATION_ENV:-production}
sed -i "s/_APPLICATION_ENV_/$APPLICATION_ENV/" .htaccess