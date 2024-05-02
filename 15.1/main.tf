###Разворачиваем VPC
resource "yandex_vpc_network" "my-vpc" {
  name        = "my-vpc-network"
  description = "My VPC"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_route_table" "nat-routetable" {
  network_id = yandex_vpc_network.my-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_instance_ip
  }
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.my-vpc.id
  route_table_id = yandex_vpc_route_table.nat-routetable.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

###Разворачиваем инстансы

#NAT-instance:
resource "yandex_compute_instance" "nat-instance" {
  platform_id = "standard-v1"
  name        = "nat-instance"
  zone        = var.default_zone
  description = "https://terraform-provider.yandexcloud.net/Resources/compute_image"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = var.nat_instance_img
      name     = "nat-instance"
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    nat        = true
    ip_address = var.nat_instance_ip
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }
}

#Public-instance:
resource "yandex_compute_instance" "public-instance" {
  platform_id = "standard-v1"
  name        = "public-instance"
  zone        = var.default_zone
  description = "https://terraform-provider.yandexcloud.net/Resources/compute_image"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }
  boot_disk {
    initialize_params {
      image_id = var.instance_img
      name     = "public-instance"
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }
}

#Private-instance:
resource "yandex_compute_instance" "private-instance" {
  platform_id = "standard-v1"
  name        = "private-instance"
  zone        = var.default_zone
  description = "https://terraform-provider.yandexcloud.net/Resources/compute_image"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }
  boot_disk {
    initialize_params {
      image_id = var.instance_img
      name     = "private-instance"
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${var.public_key}"
  }
}
