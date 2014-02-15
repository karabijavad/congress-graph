example cypher queries:

returns state name, gender name, number of those genders which have served a term for that state
MATCH (s:State)<-[:represents]-(t:Term)<-[:term]-(l:Legislator)-[:gender]->(g:Gender)
RETURN s.name, g.name, count(g) as count order by count desc

returns party name, religion name, number of legislators which are of that religion and in that party
MATCH (p:Party)<-[:party]-(t:Term)<-[:term]-(l:Legislator)-[:religion]->(r:Religion)
RETURN p.name, r.name, count(r) as count order by count desc

download / install
curl -O http://dist.neo4j.org/neo4j-community-2.0.1-unix.tar.gz
&& tar xf neo4j-community-2.0.1-unix.tar.gz

start:
neo4j-community-2.0.1/bin/neo4j start

access page:
127.0.0.1:7474

stop:
neo4j-community-2.0.1/bin/neo4j stop
