resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  tags = {
    project     = var.project
    environment = var.environment
    managedby   = "terraform"
  }
  resource_suffix = "${var.environment}-${random_string.storage_suffix.result}"
}

