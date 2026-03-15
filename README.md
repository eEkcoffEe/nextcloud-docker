# Nextcloud Docker Deployment

Автоматическое развёртывание Nextcloud с Docker и Docker Compose.

## 🚀 Быстрый старт

### Требования

- Linux (Ubuntu/Debian/CentOS)
- root доступ
- Домен, указывающий на сервер
- Порты 80 и 443 открыты

### Установка

```bash
# Клонируйте репозиторий
git clone git@github.com:eEkcoffEe/nextcloud-docker.git
cd nextcloud-docker

# Запустите скрипт развёртывания
sudo ./deploy.sh
```

### Интерактивная установка

Скрипт запросит:
1. **Домен** (например: `cloud.example.com`)
2. **Проверит SSL** (автоматически получит сертификат Let's Encrypt)
3. **Сгенерирует пароли** (сохранятся в `.env`)

## 📁 Структура проекта

```
nextcloud-docker/
├── deploy.sh              # Скрипт развёртывания
├── docker-compose.yml     # Docker Compose конфигурация
├── nginx.conf            # Nginx конфигурация
├── .env                  # Переменные окружения (пароли)
├── config/               # Nextcloud конфигурация
├── data/                 # Данные пользователей
├── apps/                 # Приложения Nextcloud
├── db-data/              # База данных PostgreSQL
├── html/                 # Nextcloud файлы
├── talk-signaling/       # HPB Signaling (опционально)
├── talk-recording/       # Запись звонков (опционально)
└── letsencrypt/          # SSL сертификаты
```

## 🔧 Управление

### Запуск

```bash
docker compose up -d
```

### Остановка

```bash
docker compose down
```

### Просмотр логов

```bash
docker compose logs -f
```

### Обновление

```bash
docker compose pull
docker compose up -d
```

## 🔐 Безопасность

### Пароли

Все пароли генерируются автоматически и сохраняются в `.env`:

```bash
# Просмотр паролей
cat .env

# Смена пароля администратора
docker exec -u www-data nextcloud-app php occ user:resetpassword admin
```

### SSL/TLS

- Автоматическое получение сертификата Let's Encrypt
- TLS 1.2 и 1.3
- HSTS заголовок

### Брандмауэр

Откройте необходимые порты:

```bash
# UFW
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp

# Firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
```

## 📱 Nextcloud Talk

### Звонки

- **До 4 участников**: Работает из коробки (P2P)
- **5+ участников**: Требуется HPB (High-Performance Backend)

### Настройка HPB (опционально)

Для звонков с большим количеством участников:

```bash
# Включить HPB в админке Nextcloud
# Настройки → Администрирование → Talk → High-Performance Backend
```

## 🔧 Конфигурация

### Переменные окружения

| Переменная | Описание | Пример |
|------------|----------|--------|
| `DOMAIN` | Домен Nextcloud | `cloud.example.com` |
| `POSTGRES_PASSWORD` | Пароль БД | (генерируется) |
| `NEXTCLOUD_ADMIN_PASSWORD` | Пароль админа | (генерируется) |
| `REDIS_PASSWORD` | Пароль Redis | (генерируется) |

### Порты

| Порт | Протокол | Описание |
|------|----------|----------|
| 80 | TCP | HTTP (редирект на HTTPS) |
| 443 | TCP | HTTPS |
| 3478 | TCP/UDP | TURN (опционально) |

## 🛠️ Troubleshooting

### Nextcloud не запускается

```bash
# Проверка логов
docker compose logs nextcloud-app

# Перезапуск
docker compose restart nextcloud-app
```

### Ошибки SSL

```bash
# Проверка сертификата
certbot certificates

# Перевыпуск
certbot renew --force-renewal
```

### Проблемы с базой данных

```bash
# Проверка подключения
docker exec nextcloud-db pg_isready

# Логи БД
docker logs nextcloud-db
```

### Сброс пароля администратора

```bash
docker exec -u www-data nextcloud-app php occ user:resetpassword admin
```

## 📊 Производительность

### Рекомендуемые ресурсы

| Компоненты | CPU | RAM | Диск |
|------------|-----|-----|------|
| До 5 пользователей | 2 ядра | 2 GB | 20 GB |
| До 20 пользователей | 4 ядра | 4 GB | 50 GB |
| До 100 пользователей | 8 ядер | 8 GB | 100 GB+ |

### Оптимизация

1. **Redis** - уже настроен для кэширования
2. **PostgreSQL** - используется вместо SQLite
3. **PHP OPcache** - включён по умолчанию
4. **Nginx** - быстрый reverse proxy

## 📝 Резервное копирование

### Бэкап данных

```bash
# Остановить Nextcloud
docker compose down

# Создать архив
tar -czf nextcloud-backup-$(date +%Y%m%d).tar.gz config/ data/ db-data/ .env

# Запустить Nextcloud
docker compose up -d
```

### Восстановление

```bash
# Остановить Nextcloud
docker compose down

# Распаковать архив
tar -xzf nextcloud-backup-YYYYMMDD.tar.gz

# Запустить Nextcloud
docker compose up -d
```

## 🔗 Ссылки

- [Официальная документация Nextcloud](https://docs.nextcloud.com/)
- [Docker Hub Nextcloud](https://hub.docker.com/_/nextcloud)
- [Nextcloud Talk](https://nextcloud.com/talk/)

## 📄 Лицензия

Этот проект распространяется под лицензией AGPL-3.0.

## 👤 Автор

eEkcoffEe - [GitHub](https://github.com/eEkcoffEe)
