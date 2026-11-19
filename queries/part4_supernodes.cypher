 // Запит 1. Пошук топ-20 вузлів із найбільшою кількістю зв'язків
MATCH (n)
OPTIONAL MATCH (n)-[r]-()
WITH n, count(r) AS connections
RETURN
    labels(n) AS nodeLabels,
    CASE
        WHEN n:User THEN toString(n.userId)
        WHEN n:Movie THEN n.title
        WHEN n:Genre THEN n.name
    END AS nodeName,
    connections
ORDER BY connections DESC
LIMIT 20;


// Запит 2. Пошук жанрових супервузлів за кількістю зв'язків HAS_GENRE

MATCH (g:Genre)
OPTIONAL MATCH (g)<-[r:HAS_GENRE]-(:Movie)
RETURN
    g.name AS genre,
    count(r) AS connections
ORDER BY connections DESC;


// Запит 3. Статистика кількості зв'язків за типами вузлів

MATCH (n)
OPTIONAL MATCH (n)-[r]-()

WITH n, count(r) AS connections

RETURN
    head(labels(n)) AS nodeType,
    count(*) AS nodeCount,
    round(avg(connections) * 100.0) / 100.0
        AS avgConnections,
    percentileCont(connections, 0.5)
        AS medianConnections,
    max(connections) AS maxConnections

ORDER BY maxConnections DESC;


// Запит 4. Пошук користувачів із найбільшою кількістю зв'язків RATED

MATCH (u:User)-[r:RATED]->(:Movie)
WITH u, count(r) AS connections
RETURN
    u.userId AS userId,
    connections
ORDER BY connections DESC
LIMIT 10;


