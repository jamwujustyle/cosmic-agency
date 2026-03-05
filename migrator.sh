#!/bin/bash
set -e

echo "Waiting for MySQL database at $DB_HOST:$DB_PORT..."

# Wait until nc can successfully connect to the DB port
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done

echo "MySQL database is up!"

# Create database if it doesn't exist (using mysql client via python to avoid needing mysql-client pkg in image)
cat << 'EOF' > create_db.py
import os
import pymysql

host = os.environ.get("DB_HOST", "127.0.0.1")
port = int(os.environ.get("DB_PORT", 3306))
user = os.environ.get("DB_USER", "root")
password = os.environ.get("DB_PASSWORD", "")
db_name = os.environ.get("DB_NAME", "slider_db")

try:
    # Connect without specifying database to create it if it doesn't exist
    conn = pymysql.connect(host=host, port=port, user=user, password=password)
    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    conn.commit()
    cursor.close()
    conn.close()
    print(f"Database {db_name} ensured.")
except Exception as e:
    print(f"Error checking/creating database: {e}")
    # Don't exit with code 1 here, let Django handle connection errors if any
EOF

python create_db.py
rm create_db.py

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
