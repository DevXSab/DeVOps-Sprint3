# -----------------------
# NETWORK
# -----------------------
resource "yandex_vpc_network" "network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "k8s-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# -----------------------
# SECURITY GROUP (только SSH)
# -----------------------
resource "yandex_vpc_security_group" "servers_sg" {
  name       = "servers-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
   # ✅ ICMP для ping внутри сети
  ingress {
    protocol       = "ICMP"
    description    = "Internal ping"
    v4_cidr_blocks = ["10.0.0.0/24"]
  }

  # Разрешить всю внутреннюю сеть
  ingress {
    protocol       = "TCP"
    description    = "Internal TCP"
    v4_cidr_blocks = ["10.0.0.0/24"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    protocol       = "UDP"
    description    = "Internal UDP"
    v4_cidr_blocks = ["10.0.0.0/24"]
    from_port      = 1
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------
# MASTER SERVER PROD1
# -----------------------
resource "yandex_compute_instance" "master" {
  name = "k8s-master"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u" 
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.servers_sg.id]
  }

  metadata = {
    ssh-keys = "belyakovs:${var.ssh_public_key}"
    user-data   = <<-EOF
            #cloud-config
            hostname: prod1
            fqdn: prod1.local
            EOF
  }
}

# -----------------------
# APP WORKER PROD2
# -----------------------
resource "yandex_compute_instance" "app" {
  name = "k8s-app"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u"
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.servers_sg.id]
  }

  metadata = {
    ssh-keys = "belyakovs:${var.ssh_public_key}"
    user-data   = <<-EOF
            #cloud-config
            hostname: prod2
            fqdn: prod2.local
            EOF
  }
}

# -----------------------
# SRV WORKER PROD3
# -----------------------
resource "yandex_compute_instance" "srv" {
  name = "k8s-srv"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u"
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.servers_sg.id]
  }

  metadata = {
    ssh-keys = "belyakovs:${var.ssh_public_key}"
    user-data   = <<-EOF
            #cloud-config
            hostname: prod3
            fqdn: prod3.local
            EOF
  }
}

# -----------------------
# OUTPUTS
# -----------------------
output "external_ips" {
  value = {
    master-p1 = yandex_compute_instance.master.network_interface[0].nat_ip_address
    app-p2    = yandex_compute_instance.app.network_interface[0].nat_ip_address
    srv-p3    = yandex_compute_instance.srv.network_interface[0].nat_ip_address
  }
}

output "internal_ips" {
  value = {
    master-p1 = yandex_compute_instance.master.network_interface[0].ip_address
    app-p2    = yandex_compute_instance.app.network_interface[0].ip_address
    srv-p3    = yandex_compute_instance.srv.network_interface[0].ip_address
  }
}
