# Ansible Playbook для настройки окружения в Yandex Cloud

Данный Ansible playbook предназначен для автоматической настройки окружения на виртуальных машинах в Yandex Cloud.

## Структура проекта

```
ansible/
├── ansible.cfg                 # Конфигурация Ansible
├── inventory/
│   └── hosts.yml              # Inventory файл с описанием хостов
├── group_vars/
│   ├── all.yml                # Глобальные переменные
│   └── dev_servers.yml        # Переменные для dev серверов
├── playbooks/
│   ├── setup-environment.yml  # Основной playbook для настройки
│   ├── deploy-app.yml         # Playbook для деплоя приложения
│   └── check-status.yml       # Playbook для проверки статуса
├── templates/
│   ├── nginx-site.conf.j2     # Шаблон конфигурации Nginx
│   ├── app.service.j2         # Шаблон systemd сервиса
│   └── jail.local.j2          # Шаблон конфигурации Fail2Ban
├── run-playbook.sh            # Скрипт для удобного запуска
└── logs/                      # Директория для логов (создается автоматически)
```

## Что устанавливается

### Системные пакеты:
- curl, wget, unzip, vim, htop
- git
- build-essential
- Python 3 и pip
- Node.js 18
- Docker и Docker Compose

### Веб-сервер:
- Nginx с оптимизированной конфигурацией
- Gzip сжатие
- Настройки безопасности

### Безопасность:
- UFW Firewall (порты 22, 80, 443)
- Fail2Ban для защиты от брутфорс атак
- Настройка SSH (отключение root, пароли)

### Приложение:
- Создание пользователя и директорий
- Systemd сервис для автозапуска
- Логирование

## Предварительные требования

1. **Ansible установлен** на машине управления:
```bash
pip install ansible
```

2. **SSH ключи настроены** для доступа к серверам

3. **Виртуальные машины созданы** в Yandex Cloud (используйте Terraform из директории `../infra/`)

## Настройка

### 1. Обновите inventory файл

Отредактируйте `inventory/hosts.yml`:
- Замените `{{ bastion_public_ip }}` на реальный IP bastion host
- Проверьте внутренние IP адреса dev серверов

### 2. Настройте переменные

В `group_vars/all.yml`:
- Укажите URL вашего git репозитория в `app.repository`
- Настройте домен в `nginx.server_name`

### 3. Проверьте SSH подключение

```bash
# Проверка доступа к bastion
ssh bastion@<BASTION_IP>

# Проверка доступа к dev серверам через bastion
ssh -J bastion@<BASTION_IP> dev_tf@172.16.1.10
```

## Использование

### Первоначальная настройка серверов

```bash
cd ansible
./run-playbook.sh setup-environment.yml <BASTION_IP>
```

Пример:
```bash
./run-playbook.sh setup-environment.yml 51.250.1.100
```

### Деплой приложения

```bash
./run-playbook.sh deploy-app.yml <BASTION_IP>
```

### Проверка статуса серверов

```bash
./run-playbook.sh check-status.yml <BASTION_IP>
```

### Запуск с дополнительными опциями

```bash
# Выполнить только определенные теги
./run-playbook.sh setup-environment.yml 51.250.1.100 --tags "nginx,security"

# Выполнить только на одном сервере
./run-playbook.sh check-status.yml 51.250.1.100 --limit dev-vm1

# Dry-run (проверка без выполнения)
./run-playbook.sh setup-environment.yml 51.250.1.100 --check

# Подробный вывод
./run-playbook.sh setup-environment.yml 51.250.1.100 -vvv
```

## Доступные теги

- `system` - системные пакеты
- `packages` - установка пакетов
- `python` - Python пакеты
- `nodejs` - Node.js и npm
- `nginx` - установка и настройка Nginx
- `security` - настройки безопасности
- `firewall` - настройка UFW
- `fail2ban` - настройка Fail2Ban
- `ssh` - настройка SSH
- `app` - настройка приложения
- `deploy` - деплой приложения

## Логирование

Все запуски playbook логируются в директорию `logs/` с временными метками:
```
logs/ansible_setup-environment_20240315_143022.log
logs/ansible_deploy-app_20240315_144511.log
```

## Мониторинг

После настройки вы можете:

1. **Проверить статус сервисов:**
```bash
systemctl status nginx
systemctl status webapp  # или имя вашего приложения
```

2. **Просмотреть логи:**
```bash
journalctl -u nginx -f
journalctl -u webapp -f
tail -f /var/log/webapp/app.log
```

3. **Проверить файрвол:**
```bash
ufw status
fail2ban-client status
```

## Устранение неполадок

### Проблемы с SSH подключением
```bash
# Проверка SSH конфигурации
ssh -vvv bastion@<BASTION_IP>

# Проверка через bastion
ssh -vvv -J bastion@<BASTION_IP> dev_tf@172.16.1.10
```

### Проблемы с Nginx
```bash
# Проверка конфигурации
nginx -t

# Перезапуск сервиса
systemctl restart nginx
```

### Проблемы с приложением
```bash
# Проверка статуса
systemctl status webapp

# Просмотр логов
journalctl -u webapp --since "1 hour ago"
```

## Безопасность

Playbook настраивает базовую безопасность:
- Отключает root login по SSH
- Настраивает UFW firewall
- Устанавливает Fail2Ban
- Настраивает безопасные заголовки в Nginx

Для production окружения рекомендуется:
- Настроить SSL/TLS сертификаты
- Настроить более строгие правила firewall
- Настроить мониторинг и алерты
- Регулярно обновлять систему

## Кастомизация

Для адаптации под ваше приложение:

1. Обновите переменные в `group_vars/`
2. Модифицируйте шаблоны в `templates/`
3. Добавьте дополнительные задачи в playbooks
4. Создайте собственные роли в директории `roles/`