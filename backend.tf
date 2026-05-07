terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "tf-state-bucket-sf-diploma" # Имя вашего бакета
    region = "ru-central1-a"              # Регион
    key    = "lab/terrafor-42.tfstate"    # Путь к файлу в бакете

    # Настройки для совместимости с Yandex Cloud
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
