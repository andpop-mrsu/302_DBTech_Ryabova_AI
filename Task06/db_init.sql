PRAGMA foreign_keys = ON;

-- Удаляем старые таблицы (в правильном порядке из-за внешних ключей)
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS occupations;

-- Справочник профессий (3НФ)
CREATE TABLE occupations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

-- Пользователи
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- Ограничение: не может быть двух пользователей с одинаковым e-mail
    email TEXT NOT NULL UNIQUE, 
    -- Разделяем фамилию и имя для удобства поиска
    last_name TEXT NOT NULL, 
    first_name TEXT NOT NULL,
    -- Ограничение: пол только 'M' или 'F'
    gender TEXT CHECK (gender IN ('M', 'F')) NOT NULL, 
    register_date TEXT DEFAULT CURRENT_TIMESTAMP,
    occupation_id INTEGER,
    FOREIGN KEY (occupation_id) REFERENCES occupations(id) ON DELETE SET NULL
);

-- Фильмы (название, год)
CREATE TABLE movies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    year INTEGER CHECK (year >= 1888)
);

-- Жанры (справочник, 3НФ)
CREATE TABLE genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

-- Связующая таблица фильмы-жанры (многие-ко-многим)
CREATE TABLE movie_genres (
    movie_id INTEGER,
    genre_id INTEGER,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- Оценки (отзывы)
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    -- Ограничение: рейтинг от 0 до 5
    rating REAL CHECK (rating >= 0 AND rating <= 5) NOT NULL, 
    timestamp INTEGER NOT NULL,
    -- Нельзя удалить фильм, если по нему есть отзывы
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE RESTRICT, 
    -- При удалении пользователя автоматически удаляются все его отзывы
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE 
);

-- Теги (если нужны, оставляем)
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Индексы для ускорения запросов
CREATE INDEX idx_users_last_name ON users(last_name);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_year ON movies(year);

-- ==========================================
-- ЗАПОЛНЕНИЕ ДАННЫМИ (на основе вашей лабы 5)
-- ==========================================

-- Заполняем профессии (примерные)
INSERT INTO occupations (name) VALUES 
('student'), ('engineer'), ('teacher'), ('other');

-- Заполняем пользователей (разбиваем имена на части, назначаем email и пол)
INSERT INTO users (email, last_name, first_name, gender, occupation_id) VALUES 
('ivanov@example.com', 'Ivanov', 'Ivan', 'M', 1),
('maria@example.com', 'Smirnova', 'Maria', 'F', 2),
('alex@example.com', 'Petrov', 'Alex', 'M', 1),
('elena@example.com', 'Sidorova', 'Elena', 'F', 3),
('petr@example.com', 'Kuznetsov', 'Petr', 'M', 4);

-- Заполняем фильмы
INSERT INTO movies (title, year) VALUES 
('Inception', 2010),
('The Matrix', 1999),
('Titanic', 1997),
('The Godfather', 1972),
('Interstellar', 2014),
('The Hangover', 2009),
('Joker', 2019),
('Avengers', 2012),
('Forrest Gump', 1994),
('Shrek', 2001);

-- Заполняем жанры (уникальные)
INSERT INTO genres (name) VALUES 
('Action'), ('Sci-Fi'), ('Drama'), ('Romance'), ('Crime'), 
('Comedy'), ('Fantasy'), ('Adventure'), ('Animation'), ('Thriller'), ('Mystery');

-- Связываем фильмы и жанры (заполняем movie_genres)
-- Inception (Action, Sci-Fi)
INSERT INTO movie_genres (movie_id, genre_id) VALUES 
((SELECT id FROM movies WHERE title = 'Inception'), (SELECT id FROM genres WHERE name = 'Action')),
((SELECT id FROM movies WHERE title = 'Inception'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
-- The Matrix (Action, Sci-Fi)
((SELECT id FROM movies WHERE title = 'The Matrix'), (SELECT id FROM genres WHERE name = 'Action')),
((SELECT id FROM movies WHERE title = 'The Matrix'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
-- Titanic (Drama, Romance)
((SELECT id FROM movies WHERE title = 'Titanic'), (SELECT id FROM genres WHERE name = 'Drama')),
((SELECT id FROM movies WHERE title = 'Titanic'), (SELECT id FROM genres WHERE name = 'Romance')),
-- The Godfather (Crime, Drama)
((SELECT id FROM movies WHERE title = 'The Godfather'), (SELECT id FROM genres WHERE name = 'Crime')),
((SELECT id FROM movies WHERE title = 'The Godfather'), (SELECT id FROM genres WHERE name = 'Drama')),
-- Interstellar (Sci-Fi, Drama)
((SELECT id FROM movies WHERE title = 'Interstellar'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
((SELECT id FROM movies WHERE title = 'Interstellar'), (SELECT id FROM genres WHERE name = 'Drama')),
-- The Hangover (Comedy)
((SELECT id FROM movies WHERE title = 'The Hangover'), (SELECT id FROM genres WHERE name = 'Comedy')),
-- Joker (Drama, Crime)
((SELECT id FROM movies WHERE title = 'Joker'), (SELECT id FROM genres WHERE name = 'Drama')),
((SELECT id FROM movies WHERE title = 'Joker'), (SELECT id FROM genres WHERE name = 'Crime')),
-- Avengers (Action, Fantasy)
((SELECT id FROM movies WHERE title = 'Avengers'), (SELECT id FROM genres WHERE name = 'Action')),
((SELECT id FROM movies WHERE title = 'Avengers'), (SELECT id FROM genres WHERE name = 'Fantasy')),
-- Forrest Gump (Drama, Romance)
((SELECT id FROM movies WHERE title = 'Forrest Gump'), (SELECT id FROM genres WHERE name = 'Drama')),
((SELECT id FROM movies WHERE title = 'Forrest Gump'), (SELECT id FROM genres WHERE name = 'Romance')),
-- Shrek (Comedy, Fantasy)
((SELECT id FROM movies WHERE title = 'Shrek'), (SELECT id FROM genres WHERE name = 'Comedy')),
((SELECT id FROM movies WHERE title = 'Shrek'), (SELECT id FROM genres WHERE name = 'Fantasy'));

-- Заполняем оценки (ratings) от наших пользователей
INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES 
((SELECT id FROM users WHERE last_name = 'Ivanov'), (SELECT id FROM movies WHERE title = 'Inception'), 5.0, 1600000000),
((SELECT id FROM users WHERE last_name = 'Ivanov'), (SELECT id FROM movies WHERE title = 'The Matrix'), 4.5, 1600000100),
((SELECT id FROM users WHERE last_name = 'Smirnova'), (SELECT id FROM movies WHERE title = 'Inception'), 4.0, 1600000200),
((SELECT id FROM users WHERE last_name = 'Smirnova'), (SELECT id FROM movies WHERE title = 'Titanic'), 5.0, 1600000300),
((SELECT id FROM users WHERE last_name = 'Petrov'), (SELECT id FROM movies WHERE title = 'The Godfather'), 5.0, 1600000400),
((SELECT id FROM users WHERE last_name = 'Petrov'), (SELECT id FROM movies WHERE title = 'Interstellar'), 4.0, 1600000500),
((SELECT id FROM users WHERE last_name = 'Sidorova'), (SELECT id FROM movies WHERE title = 'Inception'), 5.0, 1600000600),
((SELECT id FROM users WHERE last_name = 'Sidorova'), (SELECT id FROM movies WHERE title = 'The Hangover'), 3.5, 1600000700),
((SELECT id FROM users WHERE last_name = 'Kuznetsov'), (SELECT id FROM movies WHERE title = 'Joker'), 4.5, 1600000800),
((SELECT id FROM users WHERE last_name = 'Kuznetsov'), (SELECT id FROM movies WHERE title = 'Avengers'), 4.0, 1600000900);