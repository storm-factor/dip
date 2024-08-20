
resource "yandex_compute_instance" "vm2" {
  name        = "vm2"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_for_vm2.id
  }

  network_interface {
    index      = 1
    nat        = false
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto.id
    ip_address = "192.168.0.22"
    security_group_ids = [yandex_vpc_security_group.sg1.id]
  }
  network_interface {
    index      = 2
    nat        = false
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto2.id
    ip_address = "192.168.10.22"
    security_group_ids = [yandex_vpc_security_group.sg1.id]
  }

#  scheduling_policy {
#    preemptible = true
#  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_disk" "boot_for_vm2" {
  name     = "disk-2"
  type     = "network-hdd"
  size     = 10
  zone     = "ru-central1-a"
  image_id = "fd8gqkbp69nel2ibb5pr"

  labels = {
    environment = "web"
  }
}