app_resource_group_name = "rg-qr-generator-dev"
environment = "dev"
subscription_id = "b1fa58f6-9220-4ea8-8567-e7ab1158bfb0"
github_environments = [
  {
    name = "dev"
    requires_review_for_release = false
  },
  {
    name = "prod"
  }
]
