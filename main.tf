# ==================== NETWORK ====================
resource "yandex_vpc_network" "my_network" {
  name = "my-network"
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.vpc_user
  ]
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["10.2.0.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["10.3.0.0/24"]
}

# ==================== SECURITY GROUP ====================
resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web instances"
  network_id  = yandex_vpc_network.my_network.id

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

  ingress {
    protocol       = "TCP"
    description    = "Health check from ALB"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"] # Диапазоны Yandex ALB
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Any outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# ==================== SERVICE ACCOUNT ====================
resource "yandex_iam_service_account" "ig_sa" {
  name        = "ig-service-account"
  description = "Service account for instance group"
  lifecycle {
    create_before_destroy = true
  }
}

resource "yandex_resourcemanager_folder_iam_binding" "compute_editor" {
  folder_id = var.folder_id
  role      = "compute.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}

resource "yandex_resourcemanager_folder_iam_binding" "vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"

  members = [
    "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}

resource "yandex_resourcemanager_folder_iam_binding" "alb_admin" {
  folder_id = var.folder_id
  role      = "alb.admin"

  members = [
    "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}

# ==================== INSTANCE GROUP ====================
resource "yandex_compute_instance_group" "app_group" {
  name                = "app-instance-group"
  description         = "Auto-scaling instance group for web application"
  folder_id           = var.folder_id
  service_account_id  = yandex_iam_service_account.ig_sa.id
  deletion_protection = false
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.compute_editor,
    yandex_resourcemanager_folder_iam_binding.alb_admin,
    yandex_resourcemanager_folder_iam_binding.vpc_user
  ]

  instance_template {
    platform_id = "standard-v2"
    resources {
      cores         = 2
      memory        = 2
      core_fraction = 50
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit" # Ubuntu 22.04 LTS
        size     = 20
      }
    }

    network_interface {
      network_id = yandex_vpc_network.my_network.id
      subnet_ids = [
        yandex_vpc_subnet.public_a.id,
        yandex_vpc_subnet.public_b.id,
        yandex_vpc_subnet.public_d.id
      ]
      security_group_ids = [yandex_vpc_security_group.web_sg.id]
      nat                = false
    }

    metadata = {
      ssh-keys  = "ubuntu:${var.ssh_public_key}"
      user-data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y nginx
        systemctl start nginx
        systemctl enable nginx
        cat > /var/www/html/index.html << EOF_HTML
        <!DOCTYPE html>
        <html>
        <head><title>Yandex Cloud Auto-Scaling Group</title></head>
        <body>
        <h1>Hello from Yandex Cloud Instance Group</h1>
        <p>Instance ID: $(hostname)</p>
        <p>Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
        </body>
        </html>
        EOF_HTML
      EOF
    }
  }

  # Политика масштабирования - автомасштабирование [citation:4]
  scale_policy {
    auto_scale {
      min_zone_size          = 1          # Минимум ВМ на зону
      max_size               = 5          # Максимум ВМ во всех зонах
      measurement_duration   = 60         # Длительность измерения метрик (сек)
      warmup_duration        = 0          # Время на прогрев новой ВМ
      stabilization_duration = 300        # Время стабилизации перед снижением числа ВМ (сек)
      initial_size           = 4          # Начальное количество ВМ
      auto_scale_type        = "REGIONAL" # Масштабирование по всем зонам

      # Кастомные правила масштабирования на основе CPU
      custom_rule {
        rule_type   = "WORKLOAD"
        metric_type = "GAUGE"
        metric_name = "cpu_utilization"
        target      = 30 # Целевое значение метрики 70%
        folder_id   = var.folder_id
        service     = "compute"
      }
    }
  }

  # Политика развертывания [citation:4]
  deploy_policy {
    max_unavailable  = 1  # Сколько ВМ может быть недоступно при обновлении
    max_expansion    = 1  # Сколько ВМ может быть создано сверх нормы
    startup_duration = 30 # Время на запуск приложения
    strategy         = "opportunistic"
  }

  # Политика распределения по зонам
  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
  }

  # Интеграция с Application Load Balancer [citation:10]
  application_load_balancer {
    target_group_name            = "alb-target-group-from-ig"
    target_group_description     = "Target group automatically managed by instance group"
    max_opening_traffic_duration = 60    # Максимальное время ожидания Health Check (сек)
    ignore_health_checks         = false # Учитывать проверки здоровья
  }

  health_check {
    interval = 30
    timeout  = 10

    http_options {
      port = 80
      path = "/"
    }
  }
}

# ==================== LOAD BALANCER ====================

resource "yandex_alb_load_balancer" "my_alb2" {
  name               = "my-alb"
  network_id         = yandex_vpc_network.my_network.id
  security_group_ids = [yandex_vpc_security_group.web_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public_b.id
    }
    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.public_d.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = var.ip-address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.main_router.id
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==================== HTTP ROUTER ====================
resource "yandex_alb_http_router" "main_router" {
  name = "main-http-router"
}

resource "yandex_alb_virtual_host" "main_vhost" {
  name           = "main-virtual-host"
  http_router_id = yandex_alb_http_router.main_router.id

  route {
    name = "default-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.main_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

# ==================== BACKEND GROUP ====================
resource "yandex_alb_backend_group" "main_backend_group" {
  name = "main-backend-group"

  http_backend {
    name             = "http-backend"
    port             = 80
    weight           = 1
    target_group_ids = [yandex_compute_instance_group.app_group.application_load_balancer.0.target_group_id]

    load_balancing_config {
      panic_threshold = 30
    }

    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"
      }
    }
  }
  depends_on = [yandex_compute_instance_group.app_group]
}

