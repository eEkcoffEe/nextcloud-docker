# Инструкция по восстановлению базы данных Nextcloud из резервной копии

## Общая информация

Данная инструкция описывает процесс восстановления базы данных Nextcloud из резервной копии в случае, если были удалены Docker тома с помощью команды `docker compose down -v`.

## Подготовка

1. Убедитесь, что у вас есть резервная копия базы данных в формате SQL
2. Определите местоположение файла резервной копии (например, `/srv/mergerfs/pool1/docker-backup/backup_YYYY-MM-DD.sql`)

## Пошаговая инструкция

### 1. Остановка всех сервисов

```bash
cd nextcloud-docker
docker compose down
```

### 2. Запуск только PostgreSQL сервиса

```bash
docker compose up postgres -d
```

### 3. Ожидание запуска PostgreSQL

Подождите около 10 секунд, чтобы PostgreSQL полностью запустился:

```bash
sleep 10
```

### 4. Подготовка базы данных

Пересоздайте схему базы данных:

```bash
docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO nextcloud; GRANT ALL ON SCHEMA public TO public;"
```

### 5. Восстановление базы данных из резервной копии

Замените путь к файлу резервной копии на актуальный:

```bash
docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud < /srv/mergerfs/pool1/docker-backup/backup_YYYY-MM-DD.sql
```

### 6. Проверка восстановления

Проверьте, что таблицы созданы правильно:

```bash
docker exec -it nextcloud-docker-postgres-1 psql -U nextcloud -c "\dt"
```

Вы должны увидеть список таблиц (около 140+ таблиц для полноценной установки Nextcloud).

### 7. Запуск всех сервисов

```bash
docker compose up -d
```

### 8. Проверка работоспособности

После запуска всех сервисов проверьте, что Nextcloud работает корректно:

- Откройте веб-браузер и перейдите по адресу `https://ВАШ_IP:843`
- Убедитесь, что все пользователи и данные присутствуют
- Проверьте, что приложения работают корректно

## Возможные проблемы и решения

### Проблема: Ошибка доступа к базе данных

**Решение:** Проверьте, что имя пользователя и пароль в файле `.env` совпадают с теми, что использовались при создании резервной копии.

### Проблема: Nextcloud требует установки

**Решение:** Это может происходить, если конфигурационный файл Nextcloud был удален. Восстановите его из резервной копии или убедитесь, что директория `/srv/mergerfs/pool1/nextcloud` содержит все необходимые данные.

### Проблема: Ошибки кеширования

**Решение:** Очистите кеш Nextcloud:

```bash
docker exec -it nextcloud-docker-nextcloud-1 php occ cache:clear
```

## Рекомендации

1. Регулярно создавайте резервные копии базы данных и файлов пользователей
2. Храните резервные копии в безопасном месте, отличном от основного сервера
3. Периодически проверяйте целостность резервных копий, восстанавливая их в тестовой среде
4. При обновлении Nextcloud всегда создавайте резервную копию перед обновлением

## Возможные ошибки их решения

### Ошибка "Could not resolve OCA\Talk\Share\RoomShareProvider"

**Причина:** Восстановленная база данных содержит ссылки на приложение "Talk" (внутреннее имя "spreed"), которое не установлено в текущем образе Nextcloud.

**Решение:**
1. Удалите ссылки на приложение из базы данных:
   ```bash
   docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -c "DELETE FROM oc_appconfig WHERE appid = 'spreed';"
   docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -c "DELETE FROM oc_migrations WHERE app = 'spreed';"
   docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -c "DELETE FROM oc_jobs WHERE class LIKE '%Spreed%' OR class LIKE '%Talk%';"
   ```
2. Выполните ремонтную процедуру:
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 php occ maintenance:repair
   ```

### Ошибки, связанные с отсутствием файлов в appdata

**Причина:** После восстановления базы данных могут отсутствовать кешированные файлы приложений в директории appdata.

**Решение:**
1. Создайте недостающие директории и файлы:
   ```bash
   mkdir -p /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/appstore
   touch /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/appstore/apps.json
   touch /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/appstore/appapi_apps.json
   touch /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/appstore/categories.json
   touch /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/appstore/discover.json
   mkdir -p /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/theming/global/0
   mkdir -p /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/avatar/admin
   ```
2. Установите правильные права доступа:
   ```bash
   chown -R 33:33 /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/
   ```

### Ошибки, связанные с правами доступа к файлам

**Причина:** Файлы в директории appdata имеют неправильные права доступа, и контейнер Nextcloud не может их читать или записывать.

**Решение:**
1. Установите правильные права доступа:
   ```bash
   chown -R 33:33 /srv/mergerfs/pool1/nextcloud/appdata_oc5k7ahc0t1q/
   ```

### Ошибка "Внутренняя ошибка сервера" при открытии приложений

**Причина:** Может быть вызвана различными причинами, включая отсутствующие файлы, неправильные права доступа или проблемы с базой данных.

**Решение:**
1. Проверьте логи Nextcloud:
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 cat /var/www/html/data/nextcloud.log
   ```
2. Выполните ремонтную процедуру:
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 php occ maintenance:repair
   ```
3. Обновите статус данных:
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 php occ maintenance:data-fingerprint
   ```

### Ошибка "The table with name 'oc_talk_proxy_messages' already exists" при установке приложения Talk

**Причина:** Восстановленная база данных содержит таблицы приложения Talk, но само приложение не было установлено должным образом. При попытке установить приложение возникает конфликт из-за уже существующих таблиц.

**Решение:**
1. Удалите существующие таблицы приложения Talk из базы данных:
   ```bash
   docker exec -i nextcloud-docker-postgres-1 psql -U nextcloud -c "DROP TABLE IF EXISTS oc_talk_proxy_messages, oc_talk_attachments, oc_talk_attendees, oc_talk_bans, oc_talk_bots_conversation, oc_talk_bots_server, oc_talk_bridges, oc_talk_commands, oc_talk_consent, oc_talk_internalsignaling, oc_talk_invitations, oc_talk_phone_numbers, oc_talk_poll_votes, oc_talk_polls, oc_talk_reminders, oc_talk_retry_ocm, oc_talk_rooms, oc_talk_sessions, oc_talk_thread_attendees, oc_talk_threads;"
   ```
2. Включите приложение Talk (внутреннее имя "spreed"):
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 php occ app:enable spreed
   ```
3. Выполните ремонтную процедуру:
   ```bash
   docker exec -it nextcloud-docker-nextcloud-1 php occ maintenance:repair
   ```

## Рекомендуемая процедура резервного копирования

Для надежного резервного копирования вашей системы рекомендуется использовать следующую команду:

```bash
docker exec nextcloud-docker-postgres-1 pg_dumpall -U nextcloud > /srv/mergerfs/pool1/docker-backup/backup_$(date +%F).sql && cd /root/nextcloud-docker && docker compose down && snapraid sync && docker compose up -d
```

**Пояснение:**
1. `pg_dumpall` - создает полный дамп всех баз данных PostgreSQL
2. `docker compose down` - останавливает все сервисы перед синхронизацией
3. `snapraid sync` - синхронизирует данные с резервными дисками
4. `docker compose up -d` - запускает все сервисы в фоновом режиме

**Альтернативный подход (для большей надежности):**
Для большей надежности можно использовать следующую процедуру:
```bash
# Остановка только nextcloud-сервисов для минимизации времени простоя
docker compose stop nextcloud nginx

# Создание бэкапа
docker exec nextcloud-docker-postgres-1 pg_dump -U nextcloud nextcloud > /srv/mergerfs/pool1/docker-backup/nextcloud_backup_$(date +%F).sql

# Синхронизация данных
snapraid sync

# Запуск сервисов
docker compose up -d nextcloud nginx
```

Этот подход позволяет избежать полной остановки базы данных и других сервисов, что может быть критично для других приложений.
