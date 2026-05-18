moved {
  from = random_string.storage_suffix
  to   = random_string.suffix
}

resource "random_string" "suffix" {
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
  resource_suffix = "${var.environment}-${random_string.suffix.result}"
}

