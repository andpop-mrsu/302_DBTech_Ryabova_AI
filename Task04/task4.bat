#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.first_name || ' ' || u1.surname AS user1, u2.first_name || ' ' || u2.surname AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movieId = r2.movieId AND r1.userId < r2.userId JOIN users u1 ON r1.userId = u1.userId JOIN users u2 ON r2.userId = u2.userId JOIN movies m ON r1.movieId = m.movieId LIMIT 100;"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, u.first_name || ' ' || u.surname AS user_name, r.rating, strftime('%Y-%m-%d', r.timestamp) AS rating_date FROM ratings r JOIN users u ON r.userId = u.userId JOIN movies m ON r.movieId = m.movieId ORDER BY r.timestamp ASC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH MovieAverages AS (SELECT movieId, AVG(rating) AS avg_rating FROM ratings GROUP BY movieId), RankedAverages AS (SELECT movieId, avg_rating, MAX(avg_rating) OVER() as max_avg, MIN(avg_rating) OVER() as min_avg FROM MovieAverages) SELECT m.title, m.year, ra.avg_rating, CASE WHEN ra.avg_rating = ra.max_avg THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM RankedAverages ra JOIN movies m ON ra.movieId = m.movieId WHERE ra.avg_rating = ra.max_avg OR ra.avg_rating = ra.min_avg ORDER BY m.year, m.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.rating) AS total_ratings, AVG(r.rating) AS avg_rating FROM ratings r JOIN users u ON r.userId = u.userId WHERE u.gender = 'M' AND strftime('%Y', r.timestamp) BETWEEN '2011' AND '2014';"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, AVG(r.rating) AS avg_rating, COUNT(DISTINCT r.userId) AS user_count FROM movies m JOIN ratings r ON m.movieId = r.movieId GROUP BY m.movieId ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movieId, genre, rest) AS (SELECT movieId, '', genres || '|' FROM movies UNION ALL SELECT movieId, substr(rest, 0, instr(rest, '|')), substr(rest, instr(rest, '|') + 1) FROM split_genres WHERE rest <> '') SELECT genre, COUNT(*) as count FROM split_genres WHERE genre <> '' GROUP BY genre ORDER BY count DESC LIMIT 1;"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT surname || ' ' || first_name || '|' || strftime('%Y-%m-%d', registration_date) AS user_info FROM users ORDER BY registration_date DESC LIMIT 10;"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE Years(year) AS (SELECT 2005 UNION ALL SELECT year + 1 FROM Years WHERE year < 2026) SELECT year, strftime('%Y-%m-%d', year || '-11-25') AS date, CASE strftime('%w', year || '-11-25') WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS day_of_week FROM Years;"
echo " "