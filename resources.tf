
resource "yandex_vpc_network" "vpc_net_neto" {
  name = "vpc_net_neto"
}

resource "yandex_vpc_subnet" "vpc_subnet_neto2" {
  name           = "subnet_neto2"
  description    = "subnet for private bastion-webvm"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_net_neto.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "vpc_subnet_neto" {
  name           = "subnet_neto"
  description    = "subnet for private webvm"
  v4_cidr_blocks = ["192.168.0.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_net_neto.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "route-table"
  network_id = yandex_vpc_network.vpc_net_neto.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_alb_target_group" "btg" {
  name = "backend-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto.id
    ip_address = yandex_compute_instance.vm1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.vpc_subnet_neto.id
    ip_address = yandex_compute_instance.vm2.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "test_backend_group" {
  name = "my-backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.btg.id}"]

    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout  = "1s"
      interval = "1s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_virtual_host" "virtual-hosts" {
  name      = "my-virtual-host"
  http_router_id = yandex_alb_http_router.tf_router.id
  route {
    name = "my-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.test_backend_group.id
        timeout = "3s"
      }
    }
  }
}


resource "yandex_alb_http_router" "tf_router" {
  name = "myhttp-router"

  labels = {
    tf-label    = "tf-label-value"
    empty-label = "my_label_for_http_router"
  }
}

resource "yandex_alb_load_balancer" "ya_load_balancer" {
  name = "load-balancer"

  network_id = yandex_vpc_network.vpc_net_neto.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.vpc_subnet_neto.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.tf_router.id
      }
    }
  }


  log_options {
    discard_rule {
      http_code_intervals = ["HTTP_2XX"]
      discard_percent     = 75
    }
  }
}

resource "yandex_compute_snapshot_schedule" "snapshot_disks" {
  name = "snapshot-every-day-ttl7"
  schedule_policy {
    expression = "0 0 * * *"
  }

  retention_period = "168h"

  snapshot_spec {
      description = "retention-snapshot"
  }

  disk_ids = [
    "yandex_compute_disk.kibana_boot.id",
    "yandex_compute_disk.boot_for_elastic.id",
    "yandex_compute_disk.bastion_boot.id",
    "yandex_compute_disk.zabbix_boot.id",
    "yandex_compute_disk.boot_for_vm1.id",
    "yandex_compute_disk.boot_for_vm2.id"
  ]
}

resource "yandex_vpc_security_group" "sg1" {
  name        = "security_group"
  description = "sec group for private and bastion"
  network_id  = yandex_vpc_network.vpc_net_neto.id

  labels = {
    my-label = "sg1"
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 80"
    v4_cidr_blocks = ["192.168.0.0/24"]
    port           = 80
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 22"
    v4_cidr_blocks = ["192.168.10.100/32"]
    port           = 22
  }
  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "sgkib" {
  name        = "security_kib"
  description = "sec group sub2"
  network_id  = yandex_vpc_network.vpc_net_neto.id

  labels = {
    my-label = "kib"
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 5601"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 22"
    v4_cidr_blocks = ["192.168.10.100/32"]
    port           = 22
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 10050"
    v4_cidr_blocks = ["192.168.10.200/32"]
    port           = 10050
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "sgkbastion" {
  name        = "security_bastion"
  description = "sec group bast"
  network_id  = yandex_vpc_network.vpc_net_neto.id

  labels = {
    my-label = "bastion"
  }


  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 22"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 10050"
    v4_cidr_blocks = ["192.168.10.200/32"]
    port           = 10050
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "sgzabbix" {
  name        = "security_zabbix"
  description = "sec group zabbix"
  network_id  = yandex_vpc_network.vpc_net_neto.id

  labels = {
    my-label = "zabbix"
  }


  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 22"
    v4_cidr_blocks = ["192.168.10.100/32"]
    port           = 22
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 10050"
    v4_cidr_blocks = ["192.168.10.200/32"]
    port           = 10050
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 10051"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 10051
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow access on port 80"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
