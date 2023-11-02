# Environment, for example "prod" or "test"
variable "environment" {
    type = string
}

# The name of your new service, for example "cfpartners"
variable "service_name" { 
    type = string
}

# Change this to match whatever suits you best
variable "location" {
    type = string
    default = "uksouth"
}

# Whatever domain you want your service to answer to. To get up and running, just let this be the *.azurewebsites.net.
variable "custom_domain" {
    type = string
    default = "yourdomain.azurewebsites.net"
}

# GitHub Repo name
variable "github_repo_name" {
  type = string
  description = "GitHub Repo Name used to store secrets of generated resources"
}

# Personal Access Token to access GitHub
variable "github_token" {
  type      = string
  sensitive = true
}