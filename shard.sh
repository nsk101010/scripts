##### Killing the existing Mongo processes ################
for i in `ps -ef | egrep 'shardsvr|configsvr|replSet|configdb' | grep -v egrep | awk -F" " '{print $2}'`; do kill -9 $i; done

##### Creating Mongo data & log files ################

rm -rf /root/mongodb-3.2/data/* 
mkdir -p /root/mongodb-3.2/data/ /root/mongodb-3.2/data/logs

cd /root/mongodb-3.2/data/

mkdir -p config1 config2 config3 arbiter1 arbiter2 arbiter3 router shard1_1 shard1_2 shard2_1 shard2_2 shard3_1 shard3_2

cd /root/mongodb-3.2/bin

##### Starting the Mongo Config,Shard,Arbiter & Router services ################

## Config Serve"rs.#####
mongod --configsvr --dbpath /root/mongodb-3.2/data/config1 --logpath /root/mongodb-3.2/data/logs/config1.log --port 39000 --config /etc/mongod.conf &
mongod --configsvr --dbpath /root/mongodb-3.2/data/config2 --logpath /root/mongodb-3.2/data/logs/config2.log --port 39001 --config /etc/mongod.conf &
mongod --configsvr --dbpath /root/mongodb-3.2/data/config3 --logpath /root/mongodb-3.2/data/logs/config3.log --port 39002 --config /etc/mongod.conf &

## Replica Set 1 ######
mongod --shardsvr --replSet rs1 --dbpath /root/mongodb-3.2/data/shard1_1 --logpath /root/mongodb-3.2/data/logs/shard1_1.log --port 27010 --config /etc/mongod.conf &
mongod --shardsvr --replSet rs1 --dbpath /root/mongodb-3.2/data/shard1_2 --logpath /root/mongodb-3.2/data/logs/shard1_2.log --port 27011 --config /etc/mongod.conf &

## Replica Set 2 ######
mongod --shardsvr --replSet rs2 --dbpath /root/mongodb-3.2/data/shard2_1 --logpath /root/mongodb-3.2/data/logs/shard2_1.log --port 27020 --config /etc/mongod.conf &
mongod --shardsvr --replSet rs2 --dbpath /root/mongodb-3.2/data/shard2_2 --logpath /root/mongodb-3.2/data/logs/shard2_2.log --port 27021 --config /etc/mongod.conf &

## Replica Set 3 ######
mongod --shardsvr --replSet rs3 --dbpath /root/mongodb-3.2/data/shard3_1 --logpath /root/mongodb-3.2/data/logs/shard3_1.log --port 27030 --config /etc/mongod.conf &
mongod --shardsvr --replSet rs3 --dbpath /root/mongodb-3.2/data/shard3_2 --logpath /root/mongodb-3.2/data/logs/shard3_2.log --port 27031 --config /etc/mongod.conf &

## Arbite"rs.####
mongod --replSet rs1 --dbpath /root/mongodb-3.2/data/arbiter1 --logpath /root/mongodb-3.2/data/logs/arbiter1.log --port 27012 --config /etc/mongod.conf &
mongod --replSet rs2 --dbpath /root/mongodb-3.2/data/arbiter2 --logpath /root/mongodb-3.2/data/logs/arbiter2.log --port 27022 --config /etc/mongod.conf &
mongod --replSet rs3 --dbpath /root/mongodb-3.2/data/arbiter3 --logpath /root/mongodb-3.2/data/logs/arbiter3.log --port 27032 --config /etc/mongod.conf &

sleep 200

mongos --configdb 10.0.2.15:39000,10.0.2.15:39001,10.0.2.15:39002 --logpath /root/mongodb-3.2/data/logs/router.log --port 10000 &

sleep 200
mongo 10.0.2.15:27010/admin --eval "rs.initiate()"
mongo 10.0.2.15:27020/admin --eval "rs.initiate()"
mongo 10.0.2.15:27030/admin --eval "rs.initiate()"

sleep 100
echo -e \n\n Replica sets are being added. \n\n

mongo 10.0.2.15:27010/admin --eval "rs.add(\"10.0.2.15:27011\")"
mongo 10.0.2.15:27020/admin --eval "rs.add(\"10.0.2.15:27021\")"
mongo 10.0.2.15:27030/admin --eval "rs.add(\"10.0.2.15:27031\")"

mongo 10.0.2.15:27010/admin --eval "rs.addArb(\"10.0.2.15:27012\")"
mongo 10.0.2.15:27020/admin --eval "rs.addArb(\"10.0.2.15:27022\")"
mongo 10.0.2.15:27030/admin --eval "rs.addArb(\"10.0.2.15:27032\")"

sleep 200
mongo 10.0.2.15:10000/admin --eval "sh.addShard(\"rs1/localhost.localdomain:27010,10.0.2.15:27011\")"
mongo 10.0.2.15:10000/admin --eval "sh.addShard(\"rs2/localhost.localdomain:27020,10.0.2.15:27021\")"
mongo 10.0.2.15:10000/admin --eval "sh.addShard(\"rs3/localhost.localdomain:27030,10.0.2.15:27031\")"

----------------------------------------------------

mongo –port 10000
sh.status()
use shrdb
db.createCollection("shrcol")
db.shrcol.ensureIndex({“user_id” : 1})
show collections
db.shrcol.find()
sh.enableSharding(“shrdb”)
use admin
db.runCommand( { shardCollection: “shrdb.shrcol”, key : {user_id:1}})
sh.startBalancer()
sh.isBalancerRunning()
sh.getBalancerState()
use shrdb
for(var i=1; i <= 1000000 ; i++){db.shrcol.insert({ “user_id” : i, “name” : “DBFry.COM is now in-association with DBVersity.COM”})}
sh.status()
show dbs
use shrdb
show collections
db.shrcol.find()
db.shrcol.count()
mongo –port 27010
use shrdb
db.shrcol.count()
Similarly check for 27020, 27030
