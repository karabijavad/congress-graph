note: this only works on jruby, as it uses the http://github.com/karabijavad/cadet gem, which accesses the neo4j java api.

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

returns party name, religion name, number of legislators which are of that religion and in that party
```
MATCH (p:Party)<-[:party]-(t:Term)<-[:term]-(l:Legislator)-[:religion]->(r:Religion)
RETURN p.name, r.name, count(r) as count order by count desc
```

bills are related to legislators
```
(:Legislator)<-[:sponsor]-(:Bill)-[:cosponsor]->(:Legislator)
```

what subjects are each religion most sponsoring?
```
neo4j-sh (?)$ MATCH (r:Religion) WITH r MATCH r<-[:religion]-()<-[:sponsor]-(b)-[:subject]->(s) RETURN r.name, s.name, count(s.name) AS score ORDER BY score desc LIMIT 25;
+----------------------------------------------------------------------+
| r.name           | s.name                                    | score |
+----------------------------------------------------------------------+
| "Roman Catholic" | "Government operations and politics"      | 3835  |
| "Roman Catholic" | "Congress"                                | 2249  |
| "Roman Catholic" | "Economics and public finance"            | 2218  |
| "Jewish"         | "Government operations and politics"      | 2217  |
| "Roman Catholic" | "Health"                                  | 2141  |
| "Roman Catholic" | "Law"                                     | 1904  |
| "Roman Catholic" | "Commerce"                                | 1796  |
| "Baptist"        | "Government operations and politics"      | 1653  |
| "Episcopalian"   | "Government operations and politics"      | 1615  |
| "Roman Catholic" | "International affairs"                   | 1594  |
| "Roman Catholic" | "Labor and employment"                    | 1589  |
| "Roman Catholic" | "Social welfare"                          | 1532  |
| "Jewish"         | "Health"                                  | 1519  |
| "Presbyterian"   | "Government operations and politics"      | 1517  |
| "Roman Catholic" | "Foreign trade and international finance" | 1470  |
| "Roman Catholic" | "Crime and law enforcement"               | 1445  |
| "Roman Catholic" | "Education"                               | 1419  |
| "Roman Catholic" | "Congressional reporting requirements"    | 1373  |
| "Roman Catholic" | "Science, technology, communications"     | 1367  |
| "Catholic"       | "Government operations and politics"      | 1356  |
| "Jewish"         | "Economics and public finance"            | 1282  |
| "Roman Catholic" | "Armed forces and national security"      | 1275  |
| "Roman Catholic" | "Finance and financial sector"            | 1216  |
| "Roman Catholic" | "Families"                                | 1213  |
| "Roman Catholic" | "Taxation"                                | 1197  |
+----------------------------------------------------------------------+
```

```
MATCH (ca:Committee)-[:member]->(l:Legislator)<-[:sponsor]-(b:Bill)-[:subject_top_term]->(s)
WITH ca.name as Committee, s.name as Bill_Subject, count(s) as count order by count desc LIMIT 10
RETURN Committee + " sponsored " + Bill_Subject + " " + count + " times."

Senate Committee on Finance sponsored Foreign trade and international finance 1275 times.
Health sponsored Health 1142 times.
House Committee on Energy and Commerce sponsored Health 1135 times.
House Committee on Ways and Means sponsored Taxation 962 times.
Senate Committee on Finance sponsored Health 960 times.
Health Care sponsored Foreign trade and international finance 921 times.
Oversight and Investigations sponsored Health 848 times.
Taxation and IRS Oversight sponsored Foreign trade and international finance 826 times.
House Committee on Foreign Affairs sponsored International affairs 802 times.
Environment and the Economy sponsored Health 771 times.
```