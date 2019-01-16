#!/bin/bash

sudo systemctl stop mongod.service
sudo mv /tmp/mongod.conf /etc
sudo mv /tmp/mongodb.key /etc
sudo chown mongodb /etc/mongodb.key
sudo chmod 0600 /etc/mongodb.key
sudo mkfs.xfs /dev/disk/by-id/google-mongopd
sudo rm -Rf /var/lib/mongodb/*
sudo mount /dev/disk/by-id/google-mongopd /var/lib/mongodb/
sudo chown mongodb:mongodb /var/lib/mongodb/
echo "/dev/disk/by-id/google-mongopd /var/lib/mongodb xfs defaults 0 0" | sudo tee --append /etc/fstab

sudo systemctl start mongod.service
sudo systemctl enable mongod.service
sleep 10
cat << EOF > /tmp/createuser
use admin
db.createUser(
   {
     user: "root",
     pwd: "thispasswordisnotverysecretitwillbechanged",
     roles: [ "root" ]
   }
)
db.createUser({user: "stackdriver",pwd: "ieceeg1Iib",roles: ["clusterMonitor"]})
EOF

sudo mongo admin < /tmp/createuser
sudo sed -i 's/#//g' /etc/mongod.conf
sudo systemctl restart mongod.service