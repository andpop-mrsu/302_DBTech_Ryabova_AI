PRAGMA foreign_keys = ON;

-- 1. Добавление пяти новых пользователей (себя и 4 соседей)
-- Дата регистрации по умолчанию CURRENT_TIMESTAMP ставится автоматически
INSERT INTO users (email, last_name, first_name, gender, occupation_id) VALUES 
('ryabova@example.com', 'Ryabova', 'Anna', 'F', (SELECT id FROM occupations WHERE name = 'student')), -- Вы
('sosed1@example.com', 'Sosedov', 'Ivan', 'M', (SELECT id FROM occupations WHERE name = 'student')),
('sosed2@example.com', 'Petrova', 'Elena', 'F', (SELECT id FROM occupations WHERE name = 'student')),
('sosed3@example.com', 'Smirnov', 'Alex', 'M', (SELECT id FROM occupations WHERE name = 'student')),
('sosed4@example.com', 'Kuznetsova', 'Maria', 'F', (SELECT id FROM occupations WHERE name = 'student'));

-- 2. Добавление трех новых фильмов разных жанров
INSERT INTO movies (title, year) VALUES 
('Dune: Part Two', 2024),
('The Grand Budapest Hotel', 2014),
('Spider-Man: No Way Home', 2021);

-- Привязываем жанры к новым фильмам (используем подзапросы по названиям)
-- Dune: Part Two (Sci-Fi, Adventure)
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
((SELECT id FROM movies WHERE title = 'Dune: Part Two'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
((SELECT id FROM movies WHERE title = 'Dune: Part Two'), (SELECT id FROM genres WHERE name = 'Adventure'));

-- The Grand Budapest Hotel (Comedy, Drama)
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
((SELECT id FROM movies WHERE title = 'The Grand Budapest Hotel'), (SELECT id FROM genres WHERE name = 'Comedy')),
((SELECT id FROM movies WHERE title = 'The Grand Budapest Hotel'), (SELECT id FROM genres WHERE name = 'Drama'));

-- Spider-Man: No Way Home (Action, Adventure, Fantasy)
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
((SELECT id FROM movies WHERE title = 'Spider-Man: No Way Home'), (SELECT id FROM genres WHERE name = 'Action')),
((SELECT id FROM movies WHERE title = 'Spider-Man: No Way Home'), (SELECT id FROM genres WHERE name = 'Adventure')),
((SELECT id FROM movies WHERE title = 'Spider-Man: No Way Home'), (SELECT id FROM genres WHERE name = 'Fantasy'));

-- 3. Добавление трех новых отзывов от себя (Ryabova) о добавленных фильмах
INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES 
((SELECT id FROM users WHERE last_name = 'Ryabova'), (SELECT id FROM movies WHERE title = 'Dune: Part Two'), 5.0, strftime('%s', 'now')),
((SELECT id FROM users WHERE last_name = 'Ryabova'), (SELECT id FROM movies WHERE title = 'The Grand Budapest Hotel'), 4.5, strftime('%s', 'now')),
((SELECT id FROM users WHERE last_name = 'Ryabova'), (SELECT id FROM movies WHERE title = 'Spider-Man: No Way Home'), 4.0, strftime('%s', 'now'));