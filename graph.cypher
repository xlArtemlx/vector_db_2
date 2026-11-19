MATCH (u:User {userId: 1})-[r:RATED]->(m:Movie)
MATCH (m)-[hg:HAS_GENRE]->(g:Genre)
RETURN u, r, m, hg, g
LIMIT 25;
