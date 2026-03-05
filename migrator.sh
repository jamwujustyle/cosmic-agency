#!/bin/bash
set -e

echo "Waiting for MySQL database at $DB_HOST:$DB_PORT..."

# Wait for MySQL and create the database using pymysql (handles DNS + connection retries)
python -c "
import os, sys, time, pymysql

host = os.environ.get('DB_HOST', '127.0.0.1')
port = int(os.environ.get('DB_PORT', 3306))
user = os.environ.get('DB_USER', 'root')
password = os.environ.get('DB_PASSWORD', '')
db_name = os.environ.get('DB_NAME', 'slider_db')

for attempt in range(1, 31):
    try:
        conn = pymysql.connect(host=host, port=port, user=user, password=password, connect_timeout=3)
        cursor = conn.cursor()
        cursor.execute(f'CREATE DATABASE IF NOT EXISTS \`{db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;')
        conn.commit()
        cursor.close()
        conn.close()
        print(f'MySQL is up! Database {db_name} ensured.')
        sys.exit(0)
    except Exception as e:
        print(f'Attempt {attempt}/30: {e}')
        time.sleep(2)

print('ERROR: Could not connect to MySQL after 30 attempts.')
sys.exit(1)
"

echo "Generating missing migrations if any..."
python manage.py makemigrations --noinput

echo "Applying migrations..."
python manage.py migrate --noinput

echo "Ensuring default admin user exists..."
# Create a superuser non-interactively if none exists
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser admin created.')
else:
    print('Superuser admin already exists.')
"

echo "Migrator finished successfully."
