# Проект: Автоматизация развертывания окружения в Yandex Cloud

## Описание проекта

Проект содержит полную автоматизацию создания и настройки инфраструктуры в Yandex Cloud с использованием:
- **Terraform** для создания инфраструктуры (ВМ, сети, безопасность)
- **Ansible** для настройки окружения и деплоя приложений

## Структура проекта

```
├── infra/                          # Terraform конфигурация
│   ├── main.tf                     # Основная конфигурация инфраструктуры
│   ├── variables.tf                # Переменные Terraform
│   ├── terraform.tfstate           # Состояние Terraform
│   └── terraform.tfstate.backup    # Резервная копия состояния
│
├── ansible/                        # Ansible конфигурация
│   ├── ansible.cfg                 # Конфигурация Ansible
│   ├── README.md                   # Документация по Ansible
│   │
│   ├── inventory/                  # Inventory файлы
│   │   └── hosts.yml               # Описание хостов
│   │
│   ├── group_vars/                 # Групповые переменные
│   │   ├── all.yml                 # Глобальные переменные
│   │   └── dev_servers.yml         # Переменные для dev серверов
│   │
│   ├── playbooks/                  # Ansible playbooks
│   │   ├── setup-environment.yml   # Настройка окружения
│   │   ├── deploy-app.yml          # Деплой приложения
│   │   └── check-status.yml        # Проверка статуса
│   │
│   ├── templates/                  # Jinja2 шаблоны
│   │   ├── nginx-site.conf.j2      # Конфигурация Nginx
│   │   ├── app.service.j2          # Systemd сервис
│   │   └── jail.local.j2           # Конфигурация Fail2Ban
│   │
│   ├── logs/                       # Логи выполнения playbooks
│   │   ├── example_setup-environment_20240315_143022.log
│   │   ├── example_deploy-app_20240315_144511.log
│   │   └── example_check-status_20240315_145022.log
│   │
│   └── scripts/                    # Вспомогательные скрипты
│       ├── run-playbook.sh         # Запуск playbooks с логированием
│       ├── get-terraform-ips.sh    # Получение IP из Terraform
│       └── run-with-terraform-ips.sh # Автоматический запуск с IP
│
└── PROJECT_SUMMARY.md              # Этот файл
```

## Созданная инфраструктура

### Сетевая архитектура:
- **Сеть**: default-network
- **Внешняя подсеть**: 172.16.0.0/24 (для bastion host)
- **Внутренняя подсеть**: 172.16.1.0/24 (для рабочих ВМ)

### Виртуальные машины:
1. **Bastion Host** (bastion-host)
   - Образ: nat-instance-ubuntu-2204
   - 2 vCPU, 2 GB RAM, 20 GB диск
   - Публичный IP + внутренний IP (172.16.1.254)
   - Роль: NAT gateway и точка входа

2. **Рабочие ВМ** (dev-vm1, dev-vm2)
   - Образ: ubuntu-2204-lts
   - 2 vCPU, 2 GB RAM, 10 GB диск
   - Только внутренние IP (172.16.1.x)
   - Доступ через bastion host

### Группы безопасности:
- **external_sg**: SSH доступ к bastion (порт 22)
- **internal_sg**: SSH внутри сети (порт 22)
- **work_vm_sg**: HTTP/HTTPS и порт приложения (80, 443, 3000)

## Установленное ПО (через Ansible)

### Системные пакеты:
- curl, wget, unzip, vim, htop
- git, build-essential
- Python 3 и pip
- Node.js 18 и npm
- Docker и Docker Compose

### Веб-сервер:
- **Nginx** с оптимизированной конфигурацией
  - Gzip сжатие
  - Безопасные заголовки
  - Проксирование на приложение (порт 3000)
  - Обслуживание статических файлов

### Безопасность:
- **UFW Firewall** (порты 22, 80, 443)
- **Fail2Ban** защита от брутфорс атак
- **SSH** настройка:
  - Отключен root login
  - Отключена аутентификация по паролю
  - Только ключи SSH

### Приложение:
- Пользователь и группа `app`
- Директории `/opt/app` и `/var/log/webapp`
- Systemd сервис для автозапуска
- Логирование в systemd journal

## Быстрый старт

### 1. Создание инфраструктуры
```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 2. Настройка окружения
```bash
cd ../ansible

# Автоматическое получение IP из Terraform и запуск
./get-terraform-ips.sh
./run-with-terraform-ips.sh setup-environment.yml

# Или вручную с указанием IP
./run-playbook.sh setup-environment.yml <BASTION_IP>
```

### 3. Деплой приложения
```bash
# Обновите app.repository в group_vars/all.yml
./run-with-terraform-ips.sh deploy-app.yml
```

### 4. Проверка статуса
```bash
./run-with-terraform-ips.sh check-status.yml
```

## Логирование

Все выполнения Ansible playbooks автоматически логируются в директорию `ansible/logs/` с временными метками.

### Примеры логов:

**Настройка окружения** (`logs/example_setup-environment_20240315_143022.log`):
- 24 задачи выполнены успешно
- Установлены все системные пакеты
- Настроен Nginx и безопасность
- Время выполнения: ~15 минут

**Деплой приложения** (`logs/example_deploy-app_20240315_144511.log`):
- Остановка → обновление кода → установка зависимостей → запуск
- Проверка статуса приложения
- Время выполнения: ~3 минуты

**Проверка статуса** (`logs/example_check-status_20240315_145022.log`):
- Мониторинг системных ресурсов
- Статус всех сервисов
- Health check приложения
- Время выполнения: ~1 минута

## Возможности для расширения

1. **SSL/TLS сертификаты** - добавить Let's Encrypt
2. **База данных** - PostgreSQL/MySQL в отдельной ВМ
3. **Мониторинг** - Prometheus + Grafana
4. **CI/CD** - интеграция с GitLab/GitHub Actions
5. **Масштабирование** - Load Balancer для нескольких ВМ
6. **Backup** - автоматическое резервное копирование

## Безопасность

Проект включает базовые меры безопасности:
- Изоляция сетей (bastion architecture)
- Firewall правила (UFW)
- Защита от брутфорс (Fail2Ban)
- Безопасная конфигурация SSH
- Безопасные заголовки HTTP

Для production рекомендуется дополнительно:
- SSL сертификаты
- WAF (Web Application Firewall)
- Регулярные обновления безопасности
- Мониторинг и алерты
- Аудит доступа

## Поддержка

Все конфигурации хорошо документированы и содержат комментарии на русском языке. Ansible playbooks используют теги для гибкого выполнения отдельных частей настройки.

Для устранения неполадок см. раздел "Устранение неполадок" в `ansible/README.md`.