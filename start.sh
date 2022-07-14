export DB_SERVER=127.0.0.1
export MONGO_URL="mongodb://$DB_SERVER/qhd"
export MONGO_OPLOG_URL="mongodb://$DB_SERVER/local"
export MULTIPLE_INSTANCES_COLLECTION_NAME=calendar_instances
export ROOT_URL=http://127.0.0.1:4000/calendar
export NODE_TLS_REJECT_UNAUTHORIZED=0
export PORT=4000
meteor run --port 4000
