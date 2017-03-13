#!/bin/bash

DIR=./test-queries
AUTH="$ADMIN_LOGIN:$ADMIN_PASSWORD"
URL=http://localhost:8093/query/service

curl -u $AUTH http://localhost:8091/pools | python -m json.tool > $DIR/pools.json
curl -u $AUTH http://localhost:8091/pools/default/buckets | python -m json.tool > $DIR/buckets.json
curl -u $AUTH http://localhost:8091/pools/default/buckets/models | python -m json.tool > $DIR/models.json
curl -u $AUTH http://localhost:8091/pools/default/buckets/files | python -m json.tool > $DIR/files.json
curl -u $AUTH $URL -d "statement=select count(*) from models" | python -mjson.tool > $DIR/count-star.json
curl -u $AUTH $URL -d "statement=select count(*) from models where _type='Portfolio'" | python -mjson.tool > $DIR/portfolios.json
curl -u $AUTH $URL -d "statement=select * from system:indexes" | python -mjson.tool > $DIR/indexes.json
