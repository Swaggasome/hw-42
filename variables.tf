variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key content"
  type        = string
  sensitive   = true
}

variable "ip-address" {
  description = "Static IP address"
  type        = string
  default     = "93.77.178.178"
}
