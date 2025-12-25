# Nextcloud Docker Deployment

Автоматическое развертывание Nextcloud с HTTPS в Docker-контейнерах.

## Обзор

Этот проект предоставляет автоматизированное развертывание Nextcloud с использованием Docker Compose. Система включает в себя:

- Nextcloud (веб-приложение для синхронизации и хранения файлов)
- Nginx (веб-сервер с SSL-терминацией)
- PostgreSQL (база данных)
- Redis (система кэширования)

## Требования

- Docker
- Docker Compose (plugin для Docker)
- Свободный порт 8443 на сервере

## Установка

1. Убедитесь, что Docker и Docker Compose установлены на вашем сервере
2. Запустите скрипт установки:

```bash
./scripts/setup.sh
```

Скрипт выполнит следующие действия:
- Создаст необходимые директории
- Сгенерирует самоподписанный SSL-сертификат
- Запустит все необходимые контейнеры

## Доступ к Nextcloud

После успешного запуска сервис будет доступен по адресу:

```
https://10.1.9.60:8443/
```

> **Примечание:** При первом посещении сайта вы увидите предупреждение безопасности из-за использования самоподписанного SSL-сертификата. Это нормально - просто подтвердите исключение безопасности в браузере.

## Конфигурация

Основные параметры конфигурации находятся в файле `.env`:

- `SERVER_IP` - IP-адрес сервера (по умолчанию 10.1.9.60)
- `HTTPS_PORT` - порт для HTTPS (по умолчанию 8443)
- `POSTGRES_PASSWORD` - пароль для базы данных PostgreSQL
- `NEXTCLOUD_ADMIN_PASSWORD` - пароль администратора Nextcloud
- Переменные для volume-ов (NEXTCLOUD_VOLUME, POSTGRES_VOLUME, REDIS_VOLUME) определены для справки, но не используются в docker-compose.yml
- Переменная для сети (NETWORK_NAME) также определена для справки, но не используется в docker-compose.yml

## Сервисы

### Nginx
- Прослушивает порт 8443
- Обеспечивает SSL-терминацию
- Перенаправляет запросы в контейнер Nextcloud

### Nextcloud
- Веб-приложение для хранения и синхронизации файлов
- Использует PostgreSQL для хранения данных и Redis для кэширования

### PostgreSQL
- База данных для хранения метаданных Nextcloud
- Использует персистентное хранилище

### Redis
- Система кэширования для повышения производительности
- Настроен с ограничением памяти 256 МБ

## Безопасность

Конфигурация включает в себя следующие меры безопасности:

- Заголовки HSTS, X-Frame-Options, X-XSS-Protection и другие
- Ограничение доступа к чувствительным директориям
- Использование безопасных параметров SSL
- Настройка кэширования для защиты от атак

## Управление

Для остановки сервисов:
```bash
cd nextcloud-docker
docker compose down
```

Для перезапуска сервисов:
```bash
cd nextcloud-docker
docker compose up -d
```

Для просмотра статуса сервисов:
```bash
cd nextcloud-docker
docker compose ps
```

## Устранение неполадок

### Сертификат безопасности
Если вы получаете предупреждение о небезопасном соединении, это связано с использованием самоподписанного сертификата. В большинстве браузеров можно добавить исключение безопасности.

### Порт 80 уже занят
Проект настроен таким образом, что не использует порт 80, а работает только на порту 8443 с HTTPS.

## Резервное копирование и восстановление

### Резервное копирование базы данных

Для создания резервной копии базы данных PostgreSQL используйте следующую команду:

```bash
export PGPASSWORD=nextcloud_db_password
docker exec nextcloud-docker-postgres-1 pg_dump -U nextcloud -d nextcloud > /path/to/backup/nextcloud_backup_$(date +%F).sql
```

Для резервного копирования всех баз данных:

```bash
export PGPASSWORD=nextcloud_db_password
docker exec nextcloud-docker-postgres-1 pg_dumpall -U nextcloud > /path/to/backup/nextcloud_backup_$(date +%F).sql
```

### Восстановление из резервной копии

Для восстановления из резервной копии, созданной командой `pg_dumpall`:

```bash
export PGPASSWORD=nextcloud_db_password
docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -d postgres < /path/to/backup_file.sql
```

Для восстановления из резервной копии, созданной командой `pg_dump`:

```bash
export PGPASSWORD=nextcloud_db_password
docker exec -i nextcloud-docker-postgres-1 pg_restore -U nextcloud -d nextcloud --clean --no-acl --no-owner < /path/to/backup_file.sql
```

**Важно**: Перед восстановлением рекомендуется остановить все контейнеры командой `docker compose down`, выполнить восстановление, а затем запустить контейнеры снова командой `docker compose up -d`.