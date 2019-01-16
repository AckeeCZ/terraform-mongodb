storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27017
  bindIp: 0.0.0.0
#replication:
#  replSetName: ${rs}
#security:
#  authorization: "enabled"
#  keyFile: /etc/mongodb.key