# שלב 1 - build environment מבוסס Debian slim עם כל הכלים הדרושים
FROM python:3.9-slim AS build

WORKDIR /app

# התקנת חבילות מערכת נדרשות לבניית mysqlclient ועוד
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# העתקת קובץ התלויות והתקנתם
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# העתקת קבצי האפליקציה
COPY app.py .
COPY dbcontext.py .
COPY person.py .
COPY static/ ./static/
COPY templates/ ./templates/

# שלב 2 - סביבה מינימלית להרצה מבוססת Alpine
FROM python:3.9-alpine

WORKDIR /app

# התקנת ספריות מערכת דרושות ל-runtimes (כדי mysqlclient יעבוד)
RUN apk update && apk add --no-cache \
    mariadb-dev \
    musl-dev \
    gcc \
    libffi-dev

# העתקת התלויות מה-build stage
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# העתקת קבצי האפליקציה מה-build stage
COPY --from=build /app /app

# חשיפת פורט 8080 במכולה
EXPOSE 8080

# משתני סביבה להגדרת Flask שיקשיב ל-0.0.0.0 ופורט 5000
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000

# פקודת הרצת האפליקציה
CMD ["python", "app.py"]

