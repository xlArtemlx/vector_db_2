// ------------------------------------------------------------
// Запит 1. Thriller: усі фільми із середньою оцінкою > 4.0.
// ------------------------------------------------------------
MATCH (g:Genre {name: 'Thriller'})<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH m, avg(r.rating) AS avgRating, count(r) AS ratingsCount
WHERE avgRating > 4.0
RETURN m.movieId AS movieId,
       m.title AS title,
       round(avgRating * 100.0) / 100.0 AS averageRating,
       ratingsCount
ORDER BY averageRating DESC, ratingsCount DESC, title;

// ------------------------------------------------------------
// Запит 2. Користувачі, які поставили 5 більш ніж 50 фільмам.
// ------------------------------------------------------------
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5.0
WITH u, count(DISTINCT m) AS fiveStarMovies
WHERE fiveStarMovies > 50
RETURN u.userId AS userId,
       fiveStarMovies
ORDER BY fiveStarMovies DESC, userId;

// ------------------------------------------------------------
// Запит 3. Фільми, високо оцінені ОБОМА користувачами 1 і 2.
// ------------------------------------------------------------
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4.0 AND r2.rating >= 4.0
RETURN m.movieId AS movieId,
       m.title AS title,
       r1.rating AS ratingUser1,
       r2.rating AS ratingUser2
ORDER BY title;

// ------------------------------------------------------------
// Запит 4. Жанри з високими середніми оцінками та достатньою
// вибіркою (мінімум 1000 оцінок на жанр, середня >= 4.0).
// Додатково: стандартне відхилення для аналізу стабільності.
// ------------------------------------------------------------
MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH g,
     count(r) AS ratingsCount,
     avg(r.rating) AS avgRating,
     stDevP(r.rating) AS ratingStdDev
WHERE ratingsCount >= 1000 AND avgRating >= 4.0
RETURN g.name AS genre,
       ratingsCount,
       round(avgRating * 100.0) / 100.0 AS averageRating,
       round(ratingStdDev * 100.0) / 100.0 AS ratingStdDev
ORDER BY averageRating DESC, ratingsCount DESC;

// ------------------------------------------------------------
// Запит 5. Рекомендації для userId = 1.
// "Схожі" — >= 3 спільних фільми з оцінкою >= 4 від обох.
// Беремо 50 користувачів з найбільшим перетином, рекомендуємо
// фільми з їхніми оцінками >=4, яких користувач 1 НЕ оцінював.
// Для рекомендації потрібно >= 2 прихильники серед схожих.
// ------------------------------------------------------------
MATCH (target:User {userId: 1})-[rt:RATED]->(common:Movie)<-[rs:RATED]-(similar:User)
WHERE rt.rating >= 4.0
  AND rs.rating >= 4.0
  AND similar <> target
WITH target, similar, count(DISTINCT common) AS commonHighRated
WHERE commonHighRated >= 3
ORDER BY commonHighRated DESC, similar.userId
LIMIT 50
MATCH (similar)-[r:RATED]->(candidate:Movie)
WHERE r.rating >= 4.0
  AND NOT EXISTS {
    MATCH (target)-[:RATED]->(candidate)
  }
WITH candidate,
     count(DISTINCT similar) AS supporters,
     avg(r.rating) AS avgSupporterRating,
     sum(commonHighRated) AS similarityScore
WHERE supporters >= 2
RETURN candidate.movieId AS movieId,
       candidate.title AS title,
       supporters,
       round(avgSupporterRating * 100.0) / 100.0 AS averageSupporterRating,
       similarityScore
ORDER BY similarityScore DESC, supporters DESC, averageSupporterRating DESC
LIMIT 10;

// ------------------------------------------------------------
// Запит 6. Найкоротший ланцюжок між User 1 та User 2 через
// ребра RATED (не через Genre). Максимальна довжина 6 хопів.
// ------------------------------------------------------------
MATCH (u1:User {userId: 1}), (u2:User {userId: 2})
MATCH p = shortestPath((u1)-[:RATED*..6]-(u2))
RETURN length(p) AS hops,
       [n IN nodes(p) |
         CASE WHEN n:User
              THEN 'User ' + toString(n.userId)
              ELSE 'Movie ' + toString(n.movieId)
         END
       ] AS pathNodes,
       p AS graphPath;
