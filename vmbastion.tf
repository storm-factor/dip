
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.bastion_boot.id
  }

  network_interface {
    index      = 1
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto2.id
    ip_address = "192.168.10.100"
    nat        = true
    security_group_ids = [yandex_vpc_security_group.sgkbastion.id]
  }

#  scheduling_policy {
#    preemptible = true
#  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_disk" "bastion_boot" {
  name     = "disk-3"
  type     = "network-hdd"
  size     = 10
  zone     = "ru-central1-a"
  image_id = "fd8gqkbp69nel2ibb5pr"

  labels = {
    environment = "bastion"
  }
}