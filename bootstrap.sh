#!/bin/bash
mkdir .bundle/
bundle install --path .bundle/

curl -O http://dist.neo4j.org/neo4j-community-2.0.1-unix.tar.gz
tar xf neo4j-community-2.0.1-unix.tar.gz
rm neo4j-community-2.0.1-unix.tar.gz

cd data/
git clone https://github.com/unitedstates/congress-data.git --depth=1
git clone https://github.com/unitedstates/congress-legislators.git --depth=1

