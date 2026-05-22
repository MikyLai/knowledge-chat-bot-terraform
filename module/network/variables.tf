##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to be applied to all resources in this module."
}

##-----------------------------------------------------------------------------
## Vnet
##-----------------------------------------------------------------------------
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
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created."
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

