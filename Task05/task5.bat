#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите название, год выпуска, средний рейтинг и rank_by_avg_rating (RANK по убыванию среднего рейтинга). Оставить 10 фильмов с наибольшим рангом."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH movie_avgs AS (
    SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.id
)
SELECT title, year, ROUND(avg_rating, 2) AS avg_rating,
       RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
FROM movie_avgs
ORDER BY rank_by_avg_rating
LIMIT 10;"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов. Рассчитать средний рейтинг avg_rating по жанру и ранг жанра по убыванию среднего рейтинга (RANK)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres(id, genre, rest) AS (
    SELECT id, 
           substr(genres, 1, instr(genres || '|', '|') - 1),
           substr(genres, instr(genres || '|', '|') + 1)
    FROM movies
    UNION ALL
    SELECT id,
           substr(rest, 1, instr(rest || '|', '|') - 1),
           substr(rest, instr(rest || '|', '|') + 1)
    FROM split_genres
    WHERE rest <> ''
),
genre_avgs AS (
    SELECT sg.genre, AVG(r.rating) AS avg_rating
    FROM split_genres sg
    JOIN ratings r ON sg.id = r.movie_id
    GROUP BY sg.genre
)
SELECT genre, ROUND(avg_rating, 2) AS avg_rating,
       RANK() OVER (ORDER BY avg_rating DESC) AS rank
FROM genre_avgs
ORDER BY rank;"
echo " "

echo "3. Посчитайте количество фильмов в каждом жанре. Выведите genre и movie_count, отсортируйте по убыванию количества."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres(id, genre, rest) AS (
    SELECT id, 
           substr(genres, 1, instr(genres || '|', '|') - 1),
           substr(genres, instr(genres || '|', '|') + 1)
    FROM movies
    UNION ALL
    SELECT id,
           substr(rest, 1, instr(rest || '|', '|') - 1),
           substr(rest, instr(rest || '|', '|') + 1)
    FROM split_genres
    WHERE rest <> ''
)
SELECT genre, COUNT(DISTINCT id) AS movie_count
FROM split_genres
GROUP BY genre
ORDER BY movie_count DESC;"
echo " "

echo "4. Найдите жанры, в которых чаще всего оставляют теги. Выведите genre, tag_count и tag_share (доля в % от общего числа тегов)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres(id, genre, rest) AS (
    SELECT id, 
           substr(genres, 1, instr(genres || '|', '|') - 1),
           substr(genres, instr(genres || '|', '|') + 1)
    FROM movies
    UNION ALL
    SELECT id,
           substr(rest, 1, instr(rest || '|', '|') - 1),
           substr(rest, instr(rest || '|', '|') + 1)
    FROM split_genres
    WHERE rest <> ''
),
genre_tags AS (
    SELECT sg.genre, COUNT(t.id) AS tag_count
    FROM split_genres sg
    JOIN tags t ON sg.id = t.movie_id
    GROUP BY sg.genre
)
SELECT genre, tag_count,
       ROUND(tag_count * 100.0 / (SELECT COUNT(*) FROM tags), 2) AS tag_share
FROM genre_tags
ORDER BY tag_count DESC;"
echo " "

echo "5. Для каждого пользователя рассчитайте: общее количество оценок, средний рейтинг, дату первой и последней оценки. Выведите user_id, rating_count, avg_rating, first_rating_date, last_rating_date. Топ-10 по количеству оценок."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT user_id,
       COUNT(*) AS rating_count,
       ROUND(AVG(rating), 2) AS avg_rating,
       datetime(MIN(timestamp), 'unixepoch') AS first_rating_date,
       datetime(MAX(timestamp), 'unixepoch') AS last_rating_date
FROM ratings
GROUP BY user_id
ORDER BY rating_count DESC
LIMIT 10;"
echo " "

echo "6. Сегментируйте пользователей: Комментаторы (tags > ratings), Оценщики (ratings > tags), Активные (ratings >= 10 AND tags >= 10), Пассивные (ratings < 5 AND tags < 5). Выведите user_id, число оценок, число тегов, категорию (CASE)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH user_stats AS (
    SELECT u.id AS user_id,
           COALESCE(r_cnt.cnt, 0) AS rating_count,
           COALESCE(t_cnt.cnt, 0) AS tag_count
    FROM users u
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM ratings GROUP BY user_id) r_cnt ON u.id = r_cnt.user_id
    LEFT JOIN (SELECT user_id, COUNT(*) AS cnt FROM tags GROUP BY user_id) t_cnt ON u.id = t_cnt.user_id
)
SELECT user_id, rating_count, tag_count,
       CASE 
           WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные'
           WHEN tag_count > rating_count THEN 'Комментаторы'
           WHEN rating_count > tag_count THEN 'Оценщики'
           WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные'
           ELSE 'Другое'
       END AS category
FROM user_stats
ORDER BY user_id;"
echo " "

echo "7. Для каждого пользователя выведите имя и последний фильм, который он оценил (по timestamp). Если нет оценок — NULL в полях фильма. Результат: user_id, name, last_rated_movie_title, last_rating_timestamp."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH last_rating AS (
    SELECT r.user_id, r.movie_id, r.timestamp,
           ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp DESC) AS rn
    FROM ratings r
)
SELECT u.id AS user_id, u.name,
       m.title AS last_rated_movie_title,
       datetime(lr.timestamp, 'unixepoch') AS last_rating_timestamp
FROM users u
LEFT JOIN last_rating lr ON u.id = lr.user_id AND lr.rn = 1
LEFT JOIN movies m ON lr.movie_id = m.id
ORDER BY u.id;"
echo " "