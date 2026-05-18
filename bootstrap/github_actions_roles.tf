locals {
  github_org  = "MikyLai"
  github_repo = var.github_repository_name

  # 展開成 {env}-read 和 {env}-apply 兩種 environment
  github_env_roles = merge(
    { for env in var.github_environments : "${env.name}-read"  => { env = env.name, role = "read"  } },
    { for env in var.github_environments : "${env.name}-apply" => { env = env.name, role = "apply" } }
  )
}

# -----------------------------------------------------------------------------
# GitHub Environments (dev-read, dev-apply, prod-read, prod-apply)
# -----------------------------------------------------------------------------
resource "github_repository_environment" "envs" {
  for_each    = local.github_env_roles
  repository  = local.github_repo
  environment = each.key
}

# -----------------------------------------------------------------------------
# Azure AD App Registration + Service Principal (每個 GitHub environment 一個)
# -----------------------------------------------------------------------------
resource "azuread_application" "github_actions" {
  for_each     = local.github_env_roles
  display_name = "gh-${local.github_repo}-${each.key}"
}

resource "azuread_service_principal" "github_actions" {
  for_each  = local.github_env_roles
  client_id = azuread_application.github_actions[each.key].client_id
}

# -----------------------------------------------------------------------------
# Federated Identity Credential (OIDC 信任 GitHub Actions)
# subject = repo:<org>/<repo>:environment:<env>-read / <env>-apply
# -----------------------------------------------------------------------------
resource "azuread_application_federated_identity_credential" "github_actions" {
  for_each       = local.github_env_roles
  application_id = azuread_application.github_actions[each.key].id
  display_name   = "github-${each.key}"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_org}/${local.github_repo}:environment:${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
}

# -----------------------------------------------------------------------------
# Role Assignment
# read  → Reader
# apply → Contributor
# -----------------------------------------------------------------------------
data "azurerm_resource_group" "app" {
  name = var.app_resource_group_name
}

resource "azurerm_role_assignment" "github_actions" {
  for_each             = local.github_env_roles
  scope                = data.azurerm_resource_group.app.id
  role_definition_name = each.value.role == "read" ? "Reader" : "Contributor"
  principal_id         = azuread_service_principal.github_actions[each.key].object_id
}

# tfstate storage: data plane 權限讓 SP 能讀寫 tfstate blob（ARM_USE_AZUREAD 模式下不需要 listKeys）
data "azurerm_resource_group" "tfstate" {
  name = var.tfstate_resource_group_name
}

data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

# management plane: 讓 SP 能 read tfstate RG（terraform refresh state 時需要）
resource "azurerm_role_assignment" "github_actions_tfstate_rg" {
  for_each             = local.github_env_roles
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions[each.key].object_id
}

resource "azurerm_role_assignment" "github_actions_tfstate" {
  for_each             = local.github_env_roles
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions[each.key].object_id
}

# read role 缺少 Microsoft.Web/sites/config/list/action，terraform plan 會 403
# 用自訂 role 補上這個 action 給所有 SP（read + apply 都需要 refresh state）
resource "azurerm_role_definition" "web_config_reader" {
  name        = "WebConfigReader-${var.app_resource_group_name}"
  scope       = data.azurerm_resource_group.app.id
  description = "Allow reading App Service config/list actions for Terraform plan"

  permissions {
    actions = [
      "Microsoft.Web/sites/config/list/action",
    ]
  }

  assignable_scopes = [data.azurerm_resource_group.app.id]
}

resource "azurerm_role_assignment" "github_actions_web_config" {
  for_each           = { for k, v in local.github_env_roles : k => v if v.role == "read" }
  scope              = data.azurerm_resource_group.app.id
  role_definition_id = azurerm_role_definition.web_config_reader.role_definition_resource_id
  principal_id       = azuread_service_principal.github_actions[each.key].object_id
}

output github_env_roles {
  value = local.github_env_roles
}
# -----------------------------------------------------------------------------
# Create Azure variable in each GitHub Environment
# -----------------------------------------------------------------------------
locals {
  github_env_secrets = {
    for pair in flatten([
      for env_key, env_val in local.github_env_roles : [
        { env = env_key, name = "AZURE_CLIENT_ID",       value = azuread_application.github_actions[env_key].client_id },
        { env = env_key, name = "AZURE_TENANT_ID",       value = var.tenant_id },
        { env = env_key, name = "AZURE_SUBSCRIPTION_ID", value = var.subscription_id },
      ]
    ]) : "${pair.env}__${pair.name}" => pair
  }
}

resource "github_actions_environment_variable" "azure" {
  for_each      = local.github_env_secrets
  repository    = local.github_repo
  environment   = each.value.env
  variable_name = each.value.name
  value         = each.value.value

  depends_on = [github_repository_environment.envs]
}


