# CFP Security Operations Task

## Test solution locally

Use docker compose to orchestrate 3 containers

* a Postgres database
* a docker container running the Flask web app
* an nginx that works as a reverse proxy to expose the Flask web app


```{bash}
docker-compose up -d
```

to tear down and remove containers, remove images and volumes created run
```{bash}
docker-compose down --rmi all --volumes
```

## Setting up required Azure Infrastructure

The folders **setup_azure_for_terraform** and **setup-azure-container-registry** create several resources needed to interact with Azure. The main resources created are

* A security group to hold other resources
* A AD application to support creating security principals
* A security principal to provide permissions to access other resources
* A storage account intended to hold terraform state

These terraform modules also store important secrets in GitHub, to allow access to Azure resources from within GitHub and when implementing CI/CD.
In order to be able to login and create secrets in GitHub, you'd have first to create a personal access token.
This token will then be passed on to terraform as a variable (as seen below) or can be entered interactively if you'd prefer.

These modules should be executed in the order and using vars provided in **cfpartnersdev.tfvars **

```{bash}
cd setup-azure-container-registry
terraform init
terraform fmt
terraform plan -var-file=../cfpartnersdev.tfvars -var='github_token=<YOUR_GITHUB_TOKEN>'
terraform apply -var-file=../cfpartnersdev.tfvars -var='github_token=<YOUR_GITHUB_TOKEN>'
```

Note that you'd have to manually update value of **cfpartners_service_principal_id** in **terraform.tfvars** using output value returned in previous script and before executing next script.

```{bash}
cd setup-azure-container-registry
terraform init
terraform fmt
terraform plan -var-file=../cfpartnersdev.tfvars -var='github_token=<YOUR_GITHUB_TOKEN>'
terraform apply -var-file=../cfpartnersdev.tfvars -var='github_token=<YOUR_GITHUB_TOKEN>'
```

# Security Considerations

Terraform State should be moved to a secure location, such as for example, Azure Storage Container

In order to deploy the dockerised applications to Azure, we need to be able to authenticate with Azure.
This can be done in multiple ways, but one of the recommended approaches is to use a Service Principal (see [Azure Provider: Authenticating using a Service Principal with a Client Certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_certificate)).


# Tools used

* Terraform as IaC
* docker for containarising applications 
* docker-compose to orchestrate docker instances and test locally
* az to login interactivelly to Azure

# TODO:

* Move secreats to Azure Key Vault
* Move Terraform state to Azure Storage Container
* Associate client certificate to service principal used
* Remove public access from Azure storage account
* Automatically save value of **cfpartners_service_principal_id** to remove need to manually update terraform.tfvars