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
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser admin created.')
else:
    print('Superuser admin already exists.')
"

echo "Seeding gallery photos if needed..."
python manage.py shell -c "
from slider.models import Slide
import os

# Check if slides exist and their files are actually present
needs_seed = False
if Slide.objects.count() == 0:
    needs_seed = True
else:
    # Verify at least one image file exists on disk
    for s in Slide.objects.all():
        if s.image and hasattr(s.image, 'file') and hasattr(s.image.file, 'path'):
            if not os.path.exists(s.image.file.path):
                print('Stale slide records found (missing files). Re-seeding...')
                from filer.models.imagemodels import Image as FilerImage
                Slide.objects.all().delete()
                FilerImage.objects.all().delete()
                needs_seed = True
                break
        else:
            Slide.objects.all().delete()
            needs_seed = True
            break

if needs_seed:
    import urllib.request, tempfile
    from django.core.files import File as DjangoFile
    from filer.models.imagemodels import Image as FilerImage

    photos = [
        ('Марсианский закат', 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=1200&q=80'),
        ('Млечный путь', 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1200&q=80'),
        ('Солнечное затмение', 'https://images.unsplash.com/photo-1532693322450-2f6e7e4f2ba4?w=1200&q=80'),
        ('Туманность Ориона', 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=1200&q=80'),
        ('Космонавт в открытом космосе', 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=1200&q=80'),
    ]

    for i, (title, url) in enumerate(photos):
        try:
            tmp_path = os.path.join(tempfile.gettempdir(), f'slide_{i}.jpg')
            urllib.request.urlretrieve(url, tmp_path)
            with open(tmp_path, 'rb') as f:
                filer_image = FilerImage.objects.create(
                    original_filename=f'slide_{i}.jpg',
                    file=DjangoFile(f, name=f'slide_{i}.jpg'),
                )
            Slide.objects.create(title=title, image=filer_image, order=i)
            os.remove(tmp_path)
            print(f'  Created slide: {title}')
        except Exception as e:
            print(f'  Error creating slide {title}: {e}')
    print(f'Seeded {Slide.objects.count()} slides.')
else:
    print(f'Slides already exist ({Slide.objects.count()}), skipping seed.')
"

echo "Migrator finished successfully."
