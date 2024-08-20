
resource "yandex_compute_instance" "vm_elastic" {
  name        = "vm-elastic"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_for_elastic.id
  }

  network_interface {
    index      = 1
    nat        = false
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto2.id
    ip_address = "192.168.10.44"
  }

#  scheduling_policy {
#    preemptible = true
#  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_disk" "boot_for_elastic" {
  name     = "disk-elastic"
  type     = "network-hdd"
  size     = 10
  zone     = "ru-central1-a"
  image_id = "fd8gqkbp69nel2ibb5pr"

  labels = {
    environment = "elastic"
  }
}