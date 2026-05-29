resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  tags = {
    app     = var.app_name
    environment = var.environment
    managedby   = "terraform"
  }
}

