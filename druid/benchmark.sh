#!/bin/bash

sudo apt-get update
sudo apt install openjdk-8-jdk -y
sudo update-alternatives --config java

# Install

VERSION=0.23.0

wget -O"apache-druid-${VERSION}-bin.tar.gz" "https://dlcdn.apache.org/druid/${VERSION}/apache-druid-${VERSION}-bin.tar.gz"
tar xf apache-druid-${VERSION}-bin.tar.gz
./apache-druid-${VERSION}/bin/verify-java

# Have to increase indexer memory limit
sed -i 's MaxDirectMemorySize=1g MaxDirectMemorySize=5g g' apache-druid-$VERSION/conf/druid/single-server/medium/middleManager/runtime.properties

# Disable cache to test query performance
sed -i 's druid.historical.cache.useCache=true druid.historical.cache.useCache=false g' apache-druid-$VERSION/conf/druid/single-server/medium/historical/runtime.properties
sed -i 's druid.historical.cache.populateCache=true druid.historical.cache.populateCache=false g' apache-druid-$VERSION/conf/druid/single-server/medium/historical/runtime.properties

# Druid launcher does not start Druid as a daemon. Run it in background
./apache-druid-${VERSION}/bin/start-single-server-medium &

# Load the data

wget --continue 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
gzip -d hits.tsv.gz

./apache-druid-${VERSION}/bin/post-index-task --file ingest.json --url http://localhost:8081

# Run the queries
./run.sh

# stop Druid services
kill %1

du -bcs ./apache-druid-${VERSION}/var