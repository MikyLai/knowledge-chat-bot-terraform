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
# read  → Reader（只讀）
# apply → Contributor（可以改資源）
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

# -----------------------------------------------------------------------------
# 把 Azure secrets 存到每個 GitHub Environment
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

output "github_actions_client_ids" {
  description = "Client ID for each GitHub environment"
  value       = { for k, v in azuread_application.github_actions : k => v.client_id }
}

output "github_environment_variables" {
  description = "GitHub environment variables set for each environment"
  value = {
    for k, v in local.github_env_secrets : k => {
      environment = v.env
      name        = v.name
      value       = v.value
    }
  }
}
