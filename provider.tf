terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.200.0"
    }
  }
}

provider "yandex" {
  zone      = "ru-central1-a"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}
