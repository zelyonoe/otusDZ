variable "service_account_key_file" {
  type    = string
  default = "/Users/evgeniy/yandex-cloud/key.json"
  sensitive = true
}

variable "cloud_id" {
  type    = string
  default = "b1geqf8co8nfauq18ib2"
  sensitive = true
}

variable "folder_id" {
  type    = string
  default = "b1gg91lkltpf5g47086f"
  sensitive = true
}

variable "zone" {
  type    = string
  default = "ru-central1-b"
}

# Путь к публичному ключу SSH
variable "public_key_path" {
  type = string
  description = "Путь к файлу с публичным SSH-ключом"
  default = "/Users/evgeniy/.ssh/id_rsa.pub"
}

# Параметры bastion host
variable "bastion_username" {
  type = string
  description = "Имя пользователя для bastion host"
  default = "bastion"
}

variable "bastion_cores" {
  type = number
  description = "Количество ядер для bastion host"
  default = 2
}

variable "bastion_memory" {
  type = number
  description = "Объем памяти для bastion host"
  default = "2"
}

# Параметры рабочих ВМ
variable "dev_vm_username" {
  type = string
  description = "Имя пользователя для рабочих ВМ"
  default = "dev_tf"
}

variable "dev_vm_cores" {
  type = number
  description = "Количество ядер для рабочих ВМ"
  default = 2
}

variable "dev_vm_memory" {
  type = number
  description = "Объем памяти для рабочих ВМ"
  default = "2"
}
