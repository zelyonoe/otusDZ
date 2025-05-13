terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.141.0"
    }
  }
  required_version = ">= 1.0"
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Создаем сеть по умолчанию
resource "yandex_vpc_network" "default" {
  name = "default-network"
}

# Создаем публичный IP-адрес для bastion
resource "yandex_vpc_address" "bastion_public_ip" {
  name = "bastion-public-ip"
  external_ipv4_address {
    zone_id = var.zone
  }
}

# Создаем внешнюю подсеть
resource "yandex_vpc_subnet" "external_subnet" {
  name           = "bastion-external-segment"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["172.16.0.0/24"]
}

# Создаем внутреннюю подсеть
resource "yandex_vpc_subnet" "internal_subnet" {
  name           = "bastion-internal-segment"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["172.16.1.0/24"]
}

# Создаем группу безопасности для внешнего интерфейса
resource "yandex_vpc_security_group" "external_sg" {
  name        = "secure-bastion-sg"
  network_id  = yandex_vpc_network.default.id

  ingress {
    description    = "SSH access"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создаем группу безопасности для внутреннего интерфейса
resource "yandex_vpc_security_group" "internal_sg" {
  name        = "internal-bastion-sg"
  network_id  = yandex_vpc_network.default.id

  ingress {
    description    = "SSH from internal network"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["172.16.1.0/24"]
  }
}

data "yandex_compute_image" "nat_ubuntu_2204" {
  family = "nat-instance-ubuntu-2204"
}
# Получаем ID образа Ubuntu 22.04
data "yandex_compute_image" "ubuntu-2204" {
  family = "ubuntu-2204-lts"
}

# Создаем виртуальную машину bastion
resource "yandex_compute_instance" "bastion_host" {
  name        = "bastion-host"
  hostname    = "bastion-host"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.bastion_cores
    memory = var.bastion_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_ubuntu_2204.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.external_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.external_sg.id]
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal_subnet.id
    ip_address         = "172.16.1.254"
    security_group_ids = [yandex_vpc_security_group.internal_sg.id]
  }

  metadata = {
    ssh-keys = "${var.bastion_username}:${file(var.public_key_path)}"
  }
}

# Создаем рабочие ВМ
resource "yandex_compute_instance" "work_vm" {
  count       = 2
  name        = "dev-vm${count.index + 1}"
  hostname    = "dev-vm${count.index + 1}"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.dev_vm_cores
    memory = var.dev_vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-2204.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal_subnet.id
    security_group_ids = [yandex_vpc_security_group.internal_sg.id]
  }

  metadata = {
    ssh-keys = "${var.dev_vm_username}:${file(var.public_key_path)}"
  }
}

# Создаем группу безопасности для рабочих ВМ
resource "yandex_vpc_security_group" "work_vm_sg" {
  name        = "work-vm-sg"
  network_id  = yandex_vpc_network.default.id

  ingress {
    description    = "SSH from internal network"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["172.16.1.0/24"]
  }

  egress {
    description    = "Outbound traffic"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


