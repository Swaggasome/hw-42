# 1. Создаем сеть
resource "yandex_vpc_network" "default" {
  name = "lab-network"
}

# 2. Создаем подсеть
resource "yandex_vpc_subnet" "default" {
  name           = "lab-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for web server"
  network_id  = yandex_vpc_network.default.id
  
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "All outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# 3. Используем наш модуль для создания ВМ
module "my_first_vm" {
  source     = "./modules/yandex_vm"
  vm_name    = "web-server-1"
  subnet_id  = yandex_vpc_subnet.default.id
  cores      = 2
  memory     = 2
  depends_on = [ yandex_vpc_security_group.web_sg ]
}
