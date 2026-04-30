resource "yandex_compute_instance" "vm" {
  name = var.vm_name
  platform_id = var.platform_id
  zone        = "ru-central1-a"

  resources {
    cores  = var.cores
    memory = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" # Ubuntu 22.04 LTS
      size     = 20
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true # Выдаем публичный IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

