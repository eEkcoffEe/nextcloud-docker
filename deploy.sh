#!/bin/bash
#===============================================================================
# Nextcloud Docker Deployment Script
# Автоматическая установка и настройка Nextcloud с Docker
#===============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Запустите скрипт от root (sudo ./deploy.sh)"
        exit 1
    fi
    log_success "Проверка прав root пройдена"
}

# Проверка Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_warning "Docker не найден. Устанавливаю..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    fi
    
    if ! command -v docker compose &> /dev/null; then
        log_warning "Docker Compose не найден. Устанавливаю..."
        apt-get update && apt-get install -y docker-compose-plugin
    fi
    
    log_success "Docker и Docker Compose установлены"
}

# Ввод домена
get_domain() {
    echo ""
    log_info "=== Настройка домена ==="
    echo ""
    
    # Автоопределение через curl
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")
    
    if [ -n "$PUBLIC_IP" ]; then
        log_info "Ваш публичный IP: $PUBLIC_IP"
    fi
    
    read -p "Введите домен для Nextcloud (например: cloud.example.com): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        log_error "Домен не может быть пустым"
        exit 1
    fi
    
    log_success "Домен: $DOMAIN"
}

# Проверка SSL сертификатов
check_ssl() {
    echo ""
    log_info "=== Проверка SSL сертификатов ==="
    echo ""
    
    # Проверяем, есть ли уже сертификаты
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log_success "SSL сертификат уже существует для $DOMAIN"
        CERT_EXISTS=true
        return
    fi
    
    CERT_EXISTS=false
    
    # Проверяем, доступен ли порт 80
    if ! netstat -tlnp 2>/dev/null | grep -q ":80 " && ! ss -tlnp 2>/dev/null | grep -q ":80 "; then
        log_info "Порт 80 свободен"
    else
        log_warning "Порт 80 занят. Certbot может не работать."
        read -p "Продолжить? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
    
    # Проверяем, разрешён ли домен
    log_info "Проверка доступности домена..."
    if command -v dig &> /dev/null; then
        RESOLVED_IP=$(dig +short "$DOMAIN" | head -1)
    else
        RESOLVED_IP=$(nslookup "$DOMAIN" 2>/dev/null | grep "Address" | tail -1 | awk '{print $2}')
    fi
    
    if [ -n "$RESOLVED_IP" ]; then
        log_success "Домен $DOMAIN разрешается в $RESOLVED_IP"
        
        if [ "$RESOLVED_IP" != "$PUBLIC_IP" ] && [ -n "$PUBLIC_IP" ]; then
            log_warning "IP домена ($RESOLVED_IP) не совпадает с вашим IP ($PUBLIC_IP)"
            read -p "Продолжить? (y/n): " CONTINUE
            if [ "$CONTINUE" != "y" ]; then
                exit 1
            fi
        fi
    else
        log_warning "Не удалось разрешить домен $DOMAIN"
        log_warning "Убедитесь, что домен указывает на этот сервер"
        read -p "Продолжить без проверки? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
}

# Установка Certbot
install_certbot() {
    if [ "$CERT_EXISTS" = true ]; then
        return
    fi
    
    log_info "Установка Certbot..."
    apt-get update
    apt-get install -y certbot
    
    # Получение сертификата
    log_info "Получение SSL сертификата..."
    
    if command -v nginx &> /dev/null; then
        certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    else
        # Standalone mode (требует остановки nginx на порту 80)
        log_warning "Nginx не найден. Используем standalone mode."
        certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    fi
    
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log_success "SSL сертификат успешно получен"
    else
        log_error "Не удалось получить SSL сертификат"
        log_warning "Продолжаю без HTTPS (не рекомендуется для продакшена)"
    fi
}

# Создание директорий
create_directories() {
    log_info "Создание директорий..."
    
    mkdir -p html config apps data db-data letsencrypt talk-signaling talk-recording notify-push
    
    log_success "Директории созданы"
}

# Генерация паролей
generate_passwords() {
    log_info "Генерация безопасных паролей..."
    
    DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    HPB_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    TURN_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
    
    # Сохранение паролей в файл
    cat > .env << EOF
# Nextcloud Database
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=$DB_PASSWORD

# Nextcloud Admin
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=$ADMIN_PASSWORD

# Redis
REDIS_PASSWORD=$REDIS_PASSWORD

# HPB Signaling
HPB_SECRET=$HPB_SECRET

# TURN Server
TURN_SECRET=$TURN_SECRET
EOF
    
    chmod 600 .env
    log_success "Пароли сгенерированы и сохранены в .env"
}

# Создание docker-compose.yml
create_docker_compose() {
    log_info "Создание docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
services:
  # Database - PostgreSQL
  db:
    image: postgres:15-alpine
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-nextcloud}
      - POSTGRES_USER=${POSTGRES_USER:-nextcloud}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ./db-data:/var/lib/postgresql/data
    networks:
      - nextcloud-net

  # Redis - for caching
  redis:
    image: redis:alpine
    container_name: nextcloud-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    networks:
      - nextcloud-net

  # Nextcloud with Talk
  nextcloud:
    image: nextcloud:stable-apache
    container_name: nextcloud-app
    restart: unless-stopped
    environment:
      - POSTGRES_HOST=db
      - POSTGRES_DB=${POSTGRES_DB:-nextcloud}
      - POSTGRES_USER=${POSTGRES_USER:-nextcloud}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_HOST_PASSWORD=${REDIS_PASSWORD}
      - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER:-admin}
      - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
      - NEXTCLOUD_TRUSTED_DOMAINS=${DOMAIN}
      - OVERWRITEPROTOCOL=https
      - OVERWRITEHOST=${DOMAIN}
      - OVERWRITECLIURL=https://${DOMAIN}
    volumes:
      - ./html:/var/www/html
      - ./config:/var/www/html/config
      - ./apps:/var/www/html/custom_apps
      - ./data:/var/www/html/data
    depends_on:
      - db
      - redis
    networks:
      - nextcloud-net
    expose:
      - "80"

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: nextcloud-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/www/certbot:/var/www/certbot:ro
    depends_on:
      - nextcloud
    networks:
      - nextcloud-net

networks:
  nextcloud-net:
    driver: bridge
EOF
    
    log_success "docker-compose.yml создан"
}

# Создание nginx.conf
create_nginx_config() {
    log_info "Создание nginx.conf..."
    
    cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    # HTTP server for ACME challenge and redirect
    server {
        listen 80;
        listen [::]:80;
        server_name ${DOMAIN};

        # ACME challenge for Let's Encrypt
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        # Redirect to HTTPS
        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name ${DOMAIN};

        # SSL certificates
        ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Nextcloud
        location / {
            proxy_pass http://nextcloud:80;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-Port \$server_port;

            # Increase max body size for file uploads
            client_max_body_size 10G;

            # Timeout for Talk video calls
            proxy_read_timeout 600;
            proxy_send_timeout 600;
        }

        # Well-known URLs for Nextcloud
        location /.well-known/carddav {
            return 301 \$scheme://\$host/remote.php/dav;
        }

        location /.well-known/caldav {
            return 301 \$scheme://\$host/remote.php/dav;
        }

        location /.well-known/webfinger {
            return 301 \$scheme://\$host/index.php/.well-known/webfinger;
        }

        location /.well-known/nodeinfo {
            return 301 \$scheme://\$host/index.php/.well-known/nodeinfo;
        }

        # Deny access to sensitive files
        location ~ /\.ht {
            deny all;
        }

        location ~ /(data|config|\.htaccess) {
            deny all;
        }
    }
}
EOF
    
    log_success "nginx.conf создан"
}

# Запуск Nextcloud
start_nextcloud() {
    log_info "Запуск Nextcloud..."
    
    docker compose up -d
    
    log_info "Ожидание запуска сервисов (30 секунд)..."
    sleep 30
    
    # Проверка статуса
    if docker compose ps | grep -q "Running"; then
        log_success "Nextcloud запущен"
    else
        log_error "Ошибка запуска Nextcloud"
        exit 1
    fi
}

# Вывод информации
show_info() {
    echo ""
    echo "==============================================================================="
    log_success "Nextcloud успешно развёрнут!"
    echo "==============================================================================="
    echo ""
    echo "📍 URL: https://${DOMAIN}"
    echo "👤 Admin: admin"
    echo "🔑 Password: $(grep NEXTCLOUD_ADMIN_PASSWORD .env | cut -d'=' -f2)"
    echo ""
    echo "📁 Директории:"
    echo "   - Конфигурация: $(pwd)/config"
    echo "   - Данные: $(pwd)/data"
    echo "   - Приложения: $(pwd)/apps"
    echo ""
    echo "🔧 Управление:"
    echo "   - Запуск: docker compose up -d"
    echo "   - Остановка: docker compose down"
    echo "   - Логи: docker compose logs -f"
    echo ""
    echo "📝 Пароли сохранены в: $(pwd)/.env"
    echo ""
    echo "==============================================================================="
}

# Основная функция
main() {
    echo ""
    echo "==============================================================================="
    echo "  Nextcloud Docker Deployment Script"
    echo "  Автоматическая установка Nextcloud с Docker"
    echo "==============================================================================="
    echo ""
    
    check_root
    check_docker
    get_domain
    check_ssl
    install_certbot
    create_directories
    generate_passwords
    create_docker_compose
    create_nginx_config
    start_nextcloud
    show_info
}

# Запуск
main "$@"
