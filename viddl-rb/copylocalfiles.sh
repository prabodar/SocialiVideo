
USER=$(whoami)
cp /home/$USER/$1 /var/www/html/
rename 's/ /_/g' /var/www/html/*
