variable "vm_name" {
  description = "Название виртуальной машины"
  type        = string
}

variable "platform_id" {
  description = "Платформа ВМ (standard-v1, standard-v2)"
  type        = string
  default     = "standard-v1"
}

variable "cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объем RAM в ГБ"
  type        = number
  default     = 2
}

variable "subnet_id" {
  description = "ID подсети, в которой будет создана ВМ"
  type        = string
}

variable "public_key_path" {
  description = "Путь к публичному SSH ключу"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

