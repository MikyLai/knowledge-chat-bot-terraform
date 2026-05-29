moved {
  from = random_string.storage_suffix
  to   = random_string.suffix
}

locals {
  tags = {
    app     = var.app_name
    environment = var.environment
    managedby   = "terraform"
  }
}

