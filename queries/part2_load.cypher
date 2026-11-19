// MovieLens 1M — Частина 2. Завантаження даних (версія відповідно до виконаних запитів)
// Запускати кожен запит окремо в Neo4j Browser, у наведеному порядку.

// 1. Обмеження унікальності (автоматично створюють індекси).
CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id_unique IF NOT EXISTS
FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name_unique IF NOT EXISTS
FOR (g:Genre) REQUIRE g.name IS UNIQUE;

// 2. Вузли User.
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

// 3. Вузли Movie: title зберігає повну назву з роком, year — числовий рік.
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
WITH row,
     CASE WHEN row.title =~ '.*[(][0-9]{4}[)]$'
          THEN toInteger(substring(row.title, size(row.title) - 5, 4))
          ELSE null END AS movieYear
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title,
    m.year = movieYear;

// 4. Жанри та зв'язки HAS_GENRE.
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

// 5. RATED — пакетами по 5000 записів, без паралельного запису.
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS
   FROM 'file:///ratings.csv' AS row
   RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toFloat(row.rating),
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 5000, parallel: false}
)
YIELD batches, total, failedBatches, failedOperations, errorMessages
RETURN batches, total, failedBatches, failedOperations, errorMessages;

// 6. Перевірка кількості вузлів і зв'язків (окремі запити).
MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH (:Movie)-[r:HAS_GENRE]->(:Genre) RETURN count(r) AS genreRelationships;
MATCH (:User)-[r:RATED]->(:Movie) RETURN count(r) AS ratings;
