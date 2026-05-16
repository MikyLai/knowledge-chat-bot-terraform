output "current_subscription_display_name" {
  value = data.azurerm_subscription.current.display_name
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