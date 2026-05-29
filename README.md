## Required tools

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux)
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7.0
- [jq](https://jqlang.org/download/)

## create terraform remote backend storage

* create storage to keep remove-state
> az login <------use  Admin permission 
> az account show <------ check login user
> cd remote-state >　change `resource_group_name` in `remove-state/dev.tfvars`; `app_name` in variables.tf
> terraform init 
> terraform plan -var-file dev.tfvars 
> terraform apply -var-file dev.tfvars

## Bootstrapping Managed Identity for Github CICD
> cd bootstrap/  >　
Replace the resource_group_name and storage_account_name values in backend block with the actual output from remote-state.
Replace `tfstate_storage_account_name`,`github_repository_name`, `tfstate_resource_group_name` in `bootstrap/variables.tf`

> terraform init 
> terraform plan -var-file dev.tfvars 
> terraform apply  -var-file dev.tfvars


