## Required tools

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux)
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7.0
- [jq](https://jqlang.org/download/)

## create terraform remote backend storage

* create storage to keep remove state

> cd remote-state
> terraform init 
> terraform plan -var-file dev.tfvars 
> terraform apply -var-file dev.tfvars

## Bootstrapping Managed Identity for Github CICD
> cd bootstrap/


> az login <------use  Admin permission 
> az account show <------ check login user
> terraform init 
> terraform plan -var-file dev.tfvars 
> terraformye apply  -var-file dev.tfvars


