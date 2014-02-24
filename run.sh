#!/bin/bash
rm -rf neo4j-community-2.0.1/data/graph.db/* && bundle exec ruby $@ congress-graph.rb
