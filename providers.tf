
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  #  service_account_key_file = "./key.json"
  zone      = "ru-central1-a"
  token     = var.yandex_cloud_id_token
  folder_id = var.yandex_cloud_folder_token
}



