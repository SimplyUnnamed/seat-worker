#!/bin/bash
find . -maxdepth 1 ! -name . exec rm -r {} \; && \
   tar cf - --one-file-system 0C /usr/src/seat . | tar xf-


#Starting up
echo "Starting first run"

php -r "file_exist('.env') || copy('.env.example', '.env')"

#run migrations

php artisan migrate

#SDE
php artisan eve:update:sde -n

#Seed Scheduler
php artisan db:seed --class=Seat\\Console\\database\\seeds\\ScheduleSeeder

#Install defined plugins
#need to be passed to the container as env variables
echo "installing / updating plugins"

plugins=`echo -n ${SEAT_PLUGINS} | sed 's/,/ /g'`

if [ ! "$plugins" == "" ]; then

  echo "Install Plugins: ${SEAT_PLUGINS}"

  composer require ${plugins} --no-update

  composer update ${plugins} --no-scripts --no-dev --no-ansi --no-progress

  php artisan vendor:publish --force --all

  php artisan migrate

fi

echo "Plugins Installed"
echo "Cleaning Up"
composer dump-autoload

echo "fixing perms"
chown -R www-data:www-data /var/www/seat

php artisan horizon
