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
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  # Гарантированное выполнение после создания ВМ
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "echo 'Your second terraform setup...' | sudo tee /var/www/html/index.html"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.network_interface[0].nat_ip_address
    }
  }
}

