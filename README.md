```
./bootstrap.sh
./run.sh
neo4j-community-2.0.1/bin/neo4j start
```

then, try these queries out:

returns state name, gender name, number of those genders which have served a term for that state
```
MATCH (s:State)<-[:represents]-(t:Term)<-[:term]-(l:Legislator)-[:gender]->(g:Gender)
RETURN s.name, g.name, count(g) as count order by count desc
```
```
returns party name, religion name, number of legislators which are of that religion and in that party
MATCH (p:Party)<-[:party]-(t:Term)<-[:term]-(l:Legislator)-[:religion]->(r:Religion)
RETURN p.name, r.name, count(r) as count order by count desc
```
