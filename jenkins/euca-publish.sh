#!/bin/bash 

SERVER1=$1
VERSION_TO_PUBLISH=$2

echo >>Begin staging
echo ">>Publishing version $VERSION_TO_PUBLISH"

echo ">>Ensure target directory exists ..."
ssh -T root@${SERVER1} "sudo mkdir -p /var/www/html/eucaProd"
ssh -T root${SERVER1} "sudo mkdir -p /var/www/html/eucaProd/$VERSION_TO_PUBLISH"

echo ">>Ensure target directory has correct ownership..."
ssh root@${SERVER1} "sudo chown -R root:www-data /var/www/html/eucaProd/"

echo ">>rsync /var/www/html/euca-incoming/$VERSION_TO_PUBLISH  to /var/www/html/eucaProd/$VERSION_TO_PUBLISH "
rsync -avr --delete   /var/www/html/euca-incoming/$VERSION_TO_PUBLISH root@${SERVER1}:/var/www/html/eucaProd

ssh root@${SERVER1} 'sudo chmod 777 /var/www/html/hphelionFransProd/.htaccess'

#sudo rsync -avr --delete   ServerArtifacts/htaccess.with.rewrite.rules root@${SERVER1}:/var/www/html/hphelionFransProd/ 
scp ServerArtifacts/htaccess.with.rewrite.rules root@${SERVER1}:/var/www/html/hphelionFransProd/.htaccess


echo ">>set permissions for security"
scp ServerArtifacts/htaccess.with.rewrite.rules root@${SERVER1}:/var/www/html/hphelionFransProd/.htaccess
ssh root@${SERVER1} 'sudo chmod 755 $(find /var/www/html/hphelionFransProd -type d)'
ssh root@${SERVER1} 'sudo chmod 644 $(find /var/www/html/hphelionFransProd -type f) && chmod 444 /var/www/html/hphelionFransProd/.htaccess'


ssh root@${SERVER1} 'sudo rm /var/www/html/hphelionFransProd/eucalyptus' || true
ssh root@${SERVER1} 'sudo ln -s /var/www/html/eucaProd /var/www/html/hphelionFransProd/eucalyptus' || true



echo ">>Staging complete"
