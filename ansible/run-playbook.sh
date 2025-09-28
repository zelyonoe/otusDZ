#!/bin/bash

# Скрипт для запуска Ansible playbooks с логированием

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка аргументов
if [ $# -lt 2 ]; then
    echo "Использование: $0 <playbook> <bastion_ip> [дополнительные_опции]"
    echo ""
    echo "Доступные playbooks:"
    echo "  setup-environment.yml - Первоначальная настройка серверов"
    echo "  deploy-app.yml        - Деплой приложения"
    echo "  check-status.yml      - Проверка статуса серверов"
    echo ""
    echo "Пример:"
    echo "  $0 setup-environment.yml 51.250.1.100"
    echo "  $0 deploy-app.yml 51.250.1.100 --tags deploy"
    echo "  $0 check-status.yml 51.250.1.100 --limit dev-vm1"
    exit 1
fi

PLAYBOOK=$1
BASTION_IP=$2
shift 2
EXTRA_ARGS="$@"

# Проверка существования playbook
if [ ! -f "playbooks/$PLAYBOOK" ]; then
    log_error "Playbook playbooks/$PLAYBOOK не найден!"
    exit 1
fi

# Создание директории для логов
mkdir -p logs

# Генерация имени лог-файла с timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/ansible_${PLAYBOOK%.*}_${TIMESTAMP}.log"

log_info "Запуск playbook: $PLAYBOOK"
log_info "Bastion IP: $BASTION_IP"
log_info "Лог-файл: $LOG_FILE"

# Проверка доступности bastion host
log_info "Проверка доступности bastion host..."
if ! ping -c 1 -W 5 $BASTION_IP > /dev/null 2>&1; then
    log_warn "Bastion host $BASTION_IP недоступен по ping, но продолжаем..."
fi

# Запуск playbook
log_info "Выполнение playbook..."
echo "=======================================" > $LOG_FILE
echo "Ansible Playbook Execution Log" >> $LOG_FILE
echo "Playbook: $PLAYBOOK" >> $LOG_FILE
echo "Bastion IP: $BASTION_IP" >> $LOG_FILE
echo "Timestamp: $(date)" >> $LOG_FILE
echo "Extra args: $EXTRA_ARGS" >> $LOG_FILE
echo "=======================================" >> $LOG_FILE
echo "" >> $LOG_FILE

# Выполнение ansible-playbook с логированием
if ansible-playbook \
    -i inventory/hosts.yml \
    -e "bastion_public_ip=$BASTION_IP" \
    playbooks/$PLAYBOOK \
    $EXTRA_ARGS \
    2>&1 | tee -a $LOG_FILE; then
    
    log_info "Playbook выполнен успешно!"
    log_info "Полный лог сохранен в: $LOG_FILE"
else
    log_error "Ошибка выполнения playbook!"
    log_error "Проверьте лог-файл: $LOG_FILE"
    exit 1
fi

# Показать краткую сводку
echo ""
echo "======================================="
echo "СВОДКА ВЫПОЛНЕНИЯ"
echo "======================================="
echo "Playbook: $PLAYBOOK"
echo "Bastion IP: $BASTION_IP"
echo "Время выполнения: $(date)"
echo "Статус: УСПЕШНО"
echo "Лог-файл: $LOG_FILE"
echo "======================================="