#! /bin/bash


#MAINTAINER "Daniel Cascales Romero" <devopstech253@gmail.com>

LOGFILE="/var/log/gs-backup-$(date +'%Y-%m-%d').log";
SOURCE="/tmp"; # seperar directorios si hay m�s de uno
BUCKETNAME="first-bucket";
DESTINATION="gs://"$BUCKETNAME"";
PASSWORD="password";
COMPRESS="yes" # yes or no 

#Check if the user is root, to be able to install some packages during the script 
if [ $UID -eq 0 ]; then 

echo -e "\n"
echo -e  "1. Simple script for backup folder to gcp bucket. Remember install gcloud sdk and execute $ gcloud init for get permissions"
echo -e "Also dont forget to create your bucket and replace the variable BUCKETNAME in this script with your bucket name \n"
sleep 4

# Check the connectivity 
echo -e "2. Checking connectivity... "
echo "[##########.....]"
sleep 2
echo "[###############.....]"
sleep 2
echo "[####################.....OK!]"
ping -c 3 google.com  > /dev/null 2>&1 


if [ $? -eq 0 ]; then
echo -e "Conectividad correcta \n"
else
	echo -e "Conectividad no correcta \n"
	exit 1
fi 

# Check if the bucket exists
echo -e "Checking if the bucket exists... \n"
gsutil ls -al gs://"$BUCKETNAME" > /dev/null 2>&1
if [ $? -eq 0  ]; then
echo "Bucket "$BUCKETNAME" exists!"
else
echo "The bucket "$BUCKETNAME" dont exists!! Create it using the console from web broser or following this example: gsutil mb -p [PROJECT_NAME] -c [STORAGE_CLASS] -l [BUCKET_LOCATION] -b on gs://[BUCKET_NAME]/"
exit 1
fi


#Enable object versioning
echo -e "Object versioning allows you to restore objects if you accidentally delete them. It is turned on or off at the bucket level. If versioning is turned on, uploading to an existing object creates a new version. If versioning is turned off, uploading to an existing object overwrites the current version. Enable object versioning in your bucket: \n"

echo -e "Setting on versioning...."
gsutil versioning set on gs://"$BUCKETNAME"
echo -e "\n"

# Configure lifecycle as you need

cat <<EOF>> /tmp/lifecycle-config.json 
{
  "rule":
  [
   {
    "action": { "type": "Delete" },
    "condition": { "isLive": false, "numNewerVersions": 2 }
   },
   {
    "action": { "type": "Delete" },
    "condition": { "isLive": false, "age": 1 }
   }
  ]
}
EOF

chmod +x /tmp/lifecycle-config.json

# Apply
gsutil lifecycle set /tmp/lifecycle-config.json gs://$BUCKETNAME

#Delete the file 
rm -rf /tmp/lifecycle-config.json

# Prepare the local path
# Check the size of the path
for S in ${DIRTOCOMPRESS}; do
 DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);
 echo "Starting scan "$SOURCE" directory.
 Amount of data to be scanned is "$DIRSIZE".";
done

echo -e "\n"




# Copy the code to the bucket. Depend of the variable COMPRESS=yes/no will compress the files from $SOURCE directory. 
if [ $COMPRESS == "yes" ]; then
apt-get install p7zip-full -y
cd $SOURCE
echo -e "Compressing "$SOURCE"..."
7z a -mhe=on -p{$PASSWORD} backup-$SOURCE.7z *
echo -e "Copying the files to the "$BUCKETNAME" \n"
gsutil -m cp backup-$SOURCE.7z gs://$BUCKETNAME
else
     echo -e "Copying the files on "$SOURCE" without compression and encryption to "$BUCKETNAME" \n"
     gsutil -m cp -r $SOURCE gs://$BUCKETNAME
fi
#End the first condition of the script
else 
	echo -e "You are not root"
	exit 1 
fi 
exit 0
