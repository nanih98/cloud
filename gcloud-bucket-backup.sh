#! /bin/bash


#MAINTAINER "Daniel Cascales Romero" <daniel.cascales@ackstorm.com>

LOGFILE="/var/log/gs-backup-$(date +'%Y-%m-%d').log";
DIRTOCOMPRESS="/srv"; # seperar directorios si hay m�s de uno
BUCKETNAME="backup-server-files";
SOURCE=


echo -e  "Simple script for backup folder to gcp bucket. Remember install gcloud sdk and execute $ gcloud init for get permissions"
echo -e "Also dont forget to create your bucket and replace the variable BUCKETNAME in this script with your bucket name \n"
sleep 4


gcloud auth list



for S in ${DIRTOCOMPRESS}; do
 DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);
 echo "Starting scan "$S" directory.
 Amount of data to be scanned is "$DIRSIZE".";
done

echo -e "\n"

echo -e "Object versioning allows you to restore objects if you accidentally delete them. It is turned on or off at the bucket level. If versioning is turned on, uploading to an existing object creates a new version. If versioning is turned off, uploading to an existing object overwrites the current version. Enable object versioning in your bucket: \n"

echo -e "Setting on versioning...." 
gsutil versioning set on gs://"$BUCKETNAME"
echo -e "\n"


echo -e "Do you want to compress all the files with secure password [yes/no]:"
read answer 

if [ $answer == "yes" ]; then
echo -e "Installing p7zip-full (debian based)... \n"
sleep 2
sudo apt-get install p7zip-full -y 
echo -e "Enter the password:"
read password
cd $DIRTOCOMPRESS
echo -e "Compressing "$DIRSIZE"..."
7z a -p{$password} backup-$DIRTOCOMPRESS.7z *
echo -e "Copying the files to the "$BUCKETNAME" \n"
gsutil -m cp backup-$DIRTOCOMPRESS.7z gs://$BUCKETNAME
else
echo -e "Copying the files without compressing and encryption..\n"
gsutil -m cp -r $DIRTOCOMPRESS gs://$BUCKETNAME 
fi

exit 0
