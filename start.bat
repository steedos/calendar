set DB_SERVER=192.168.0.23
set MONGO_URL=mongodb://%DB_SERVER%/steedos
set MONGO_OPLOG_URL=mongodb://%DB_SERVER%/local
set MULTIPLE_INSTANCES_COLLECTION_NAME=calendar_instances
set ROOT_URL=http://127.0.0.1:4000/calendar
meteor run --port 4000