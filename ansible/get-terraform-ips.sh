#!/bin/bash

# Скрипт для получения IP адресов из Terraform state и обновления inventory

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Проверка существования Terraform state
TERRAFORM_DIR="../infra"
if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    log_warn "Terraform state не найден в $TERRAFORM_DIR"
    log_warn "Убедитесь, что вы выполнили 'terraform apply' в директории infra"
    exit 1
fi

log_info "Получение IP адресов из Terraform state..."

# Переход в директорию с Terraform
cd "$TERRAFORM_DIR"

# Получение IP адресов
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
DEV_VM1_IP=$(terraform output -raw dev_vm1_private_ip 2>/dev/null || echo "172.16.1.10")
DEV_VM2_IP=$(terraform output -raw dev_vm2_private_ip 2>/dev/null || echo "172.16.1.11")

# Возврат в директорию ansible
cd - > /dev/null

if [ -z "$BASTION_IP" ]; then
    log_warn "Не удалось получить IP адрес bastion host из Terraform"
    log_warn "Проверьте, что в main.tf есть output для bastion_public_ip"
    echo ""
    echo "Добавьте в main.tf следующие outputs:"
    echo ""
    echo "output \"bastion_public_ip\" {"
    echo "  value = yandex_compute_instance.bastion_host.network_interface.0.nat_ip_address"
    echo "}"
    echo ""
    echo "output \"dev_vm1_private_ip\" {"
    echo "  value = yandex_compute_instance.work_vm[0].network_interface.0.ip_address"
    echo "}"
    echo ""
    echo "output \"dev_vm2_private_ip\" {"
    echo "  value = yandex_compute_instance.work_vm[1].network_interface.0.ip_address"
    echo "}"
    exit 1
fi

log_info "Найденные IP адреса:"
log_info "  Bastion: $BASTION_IP"
log_info "  Dev-VM1: $DEV_VM1_IP"
log_info "  Dev-VM2: $DEV_VM2_IP"

# Создание временного inventory файла
TEMP_INVENTORY="inventory/hosts_generated.yml"
log_info "Создание обновленного inventory файла: $TEMP_INVENTORY"

cat > "$TEMP_INVENTORY" << EOF
---
all:
  vars:
    ansible_user: dev_tf
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_python_interpreter: /usr/bin/python3
    
bastion:
  hosts:
    bastion-host:
      ansible_host: "$BASTION_IP"
      ansible_user: bastion
      ansible_ssh_private_key_file: ~/.ssh/id_rsa

dev_servers:
  hosts:
    dev-vm1:
      ansible_host: $DEV_VM1_IP
      ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion@$BASTION_IP"'
    dev-vm2:
      ansible_host: $DEV_VM2_IP
      ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion@$BASTION_IP"'
  vars:
    # Общие переменные для dev серверов
    nginx_user: www-data
    nginx_worker_processes: auto
    nginx_worker_connections: 1024
    app_user: app
    app_group: app
    app_dir: /opt/app
    
web_servers:
  children:
    dev_servers:
EOF

log_info "Inventory файл создан: $TEMP_INVENTORY"
log_info "Теперь вы можете запустить playbook:"
log_info "  ./run-playbook.sh setup-environment.yml $BASTION_IP -i inventory/hosts_generated.yml"

# Создание удобного скрипта для запуска
cat > "run-with-terraform-ips.sh" << EOF
#!/bin/bash
# Автоматический запуск playbook с IP из Terraform

if [ \$# -lt 1 ]; then
    echo "Использование: \$0 <playbook> [дополнительные_опции]"
    echo ""
    echo "Примеры:"
    echo "  \$0 setup-environment.yml"
    echo "  \$0 deploy-app.yml --tags deploy"
    exit 1
fi

PLAYBOOK=\$1
shift
EXTRA_ARGS="\$@"

# Получение IP из Terraform
BASTION_IP="$BASTION_IP"

# Запуск playbook
./run-playbook.sh "\$PLAYBOOK" "\$BASTION_IP" -i inventory/hosts_generated.yml \$EXTRA_ARGS
EOF

chmod +x "run-with-terraform-ips.sh"

log_info "Создан удобный скрипт: run-with-terraform-ips.sh"
log_info "Использование: ./run-with-terraform-ips.sh <playbook>"