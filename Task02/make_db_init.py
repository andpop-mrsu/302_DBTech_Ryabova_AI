import csv
import os
import sys

# ---------- НАСТРОЙКИ ----------
# Пути к исходным файлам (лежат в той же папке Task02)
DATASET_DIR = os.path.dirname(os.path.abspath(__file__))
MOVIES_FILE = os.path.join(DATASET_DIR, 'movies.csv')
RATINGS_FILE = os.path.join(DATASET_DIR, 'ratings.csv')
TAGS_FILE = os.path.join(DATASET_DIR, 'tags.csv')
USERS_FILE = os.path.join(DATASET_DIR, 'users.txt')  # файл .txt, а не .csv

# Имя выходного SQL-файла
OUTPUT_SQL = os.path.join(DATASET_DIR, 'db_init.sql')

# ---------- ФУНКЦИЯ ДЛЯ ЭКРАНИРОВАНИЯ СТРОК ----------
def sql_escape(value):
    """Экранирует одиночные кавычки для SQL."""
    if value is None:
        return 'NULL'
    s = str(value)
    s = s.replace("'", "''")
    return f"'{s}'"

# ---------- ОТКРЫВАЕМ SQL-ФАЙЛ ДЛЯ ЗАПИСИ ----------
with open(OUTPUT_SQL, 'w', encoding='utf-8') as f:
    # Удаляем таблицы, если они есть
    f.write("DROP TABLE IF EXISTS movies;\n")
    f.write("DROP TABLE IF EXISTS ratings;\n")
    f.write("DROP TABLE IF EXISTS tags;\n")
    f.write("DROP TABLE IF EXISTS users;\n\n")

    # ---------- СОЗДАНИЕ ТАБЛИЦ ----------
    f.write("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);\n\n""")

    f.write("""CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);\n\n""")

    f.write("""CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);\n\n""")

    f.write("""CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);\n\n""")

    # ---------- ЗАГРУЗКА MOVIES ----------
    print("Обработка movies.csv...")
    with open(MOVIES_FILE, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            movie_id = row['movieId']
            title = row['title']
            genres = row['genres']
            year = 'NULL'
            # Извлекаем год из названия, если он в скобках
            if '(' in title and ')' in title:
                year_str = title[title.rfind('(')+1:title.rfind(')')]
                if year_str.isdigit():
                    year = year_str
            f.write(f"INSERT INTO movies (id, title, year, genres) VALUES ({movie_id}, {sql_escape(title)}, {year}, {sql_escape(genres)});\n")
    f.write("\n")

    # ---------- ЗАГРУЗКА RATINGS ----------
    print("Обработка ratings.csv...")
    with open(RATINGS_FILE, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            user_id = row['userId']
            movie_id = row['movieId']
            rating = row['rating']
            timestamp = row['timestamp']
            f.write(f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({user_id}, {movie_id}, {rating}, {timestamp});\n")
    f.write("\n")

    # ---------- ЗАГРУЗКА TAGS ----------
    print("Обработка tags.csv...")
    with open(TAGS_FILE, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            user_id = row['userId']
            movie_id = row['movieId']
            tag = row['tag']
            timestamp = row['timestamp']
            f.write(f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({user_id}, {movie_id}, {sql_escape(tag)}, {timestamp});\n")
    f.write("\n")

    # ---------- ЗАГРУЗКА USERS ----------
    print("Обработка users.txt...")
    # В файле users.txt нет строки заголовков и разделитель — вертикальная черта '|'
    # Поэтому явно указываем названия колонок через fieldnames
    with open(USERS_FILE, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(
            csvfile,
            delimiter='|',
            fieldnames=['userId', 'name', 'email', 'gender', 'register_date', 'occupation']
        )
        for row in reader:
            user_id = row['userId']
            name = row['name']
            email = row['email']
            gender = row['gender']
            register_date = row['register_date']
            occupation = row['occupation']
            f.write(f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({user_id}, {sql_escape(name)}, {sql_escape(email)}, {sql_escape(gender)}, {sql_escape(register_date)}, {sql_escape(occupation)});\n")

print(f"Готово! SQL-скрипт сохранён в {OUTPUT_SQL}")