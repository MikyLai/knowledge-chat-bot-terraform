##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Override default naming convention"
}

variable "resource_position_prefix" {
  type        = string
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "vnet", "ddospp") in the resource name.

- If true, the keyword is prepended: "vnet-core-dev".
- If false, the keyword is appended: "core-dev-vnet".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = null
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "location" {
  type        = string
  default     = null
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "label_order" {
  type        = list(string)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azure-vnet"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

##-----------------------------------------------------------------------------
## Vnet
##-----------------------------------------------------------------------------
variable "enable" {
  type        = bool
  default     = true
  description = "Flag to control the module creation"
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group in which to create the virtual network. Changing this forces a new resource to be created."
}

variable "address_spaces" {
  type        = list(string)
  default     = []
  description = "The list of the address spaces that is used by the virtual network."
}

variable "flow_timeout_in_minutes" {
  type        = number
  default     = null
  description = "The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes."
}

# If no values specified, this defaults to Azure DNS
variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "The DNS servers to be used with vNet."
}

variable "bgp_community" {
  type        = number
  default     = null
  description = "The BGP community attribute in format <as-number>:<community-value>."
}
variable "edge_zone" {
  type        = string
  default     = null
  description = " (Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created."
}

variable "enable_encryption_settings" {
  type        = string
  default     = null
  description = "Specifies if the encrypted Virtual Network allows VM that does not support encryption. Possible values are DropUnencrypted and AllowUnencrypted."
}

##-----------------------------------------------------------------------------
## DDOS Protection Plan
##-----------------------------------------------------------------------------
variable "enable_ddos_pp" {
  type        = bool
  default     = false
  description = "Flag to control the resource creation"
}

variable "existing_ddos_pp" {
  type        = string
  default     = null
  description = "ID of an existing DDOS protection plan defined in the same subscription."

  validation {
    condition     = !(var.enable_ddos_pp && var.existing_ddos_pp != null)
    error_message = "You cannot set both 'enable_ddos_pp = true' and 'existing_ddos_pp' at the same time. Provide only one."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to be applied to all resources in this module."
}


##-----------------------------------------------------------------------------
## Network Watcher
##-----------------------------------------------------------------------------
variable "enable_network_watcher" {
  type        = bool
  default     = false
  description = "Flag to control creation of network watcher."
}

##-----------------------------------------------------------------------------
## Subnet
##-----------------------------------------------------------------------------
variable "app_service_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR for App Service VNet integration subnet (e.g. 10.0.1.0/24). Must be at least /27."
}

variable "db_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR for PostgreSQL Flexible Server subnet (e.g. 10.0.2.0/24). Must be at least /28."
}

variable "app_service_id" {
  type        = string
  description = "Resource ID of the App Service (azurerm_linux_web_app) to integrate with VNet."
}