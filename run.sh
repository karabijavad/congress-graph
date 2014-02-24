#!/bin/bash

rm -rf neo4j-community-2.0.1/data/graph.db/* && bundle exec ruby --server -J-Xmn2048m -J-Xms4096m -J-Xmx4096m $@ congress-graph.rb
