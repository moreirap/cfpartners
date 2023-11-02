# Your environment, for example "test" or "prod"
variable "environment" {
  type = string
}

# Name of your service, for example "ContainerRegistry" or "cicd" or whatever suits your organization
variable "service_name" {
  type = string
}

# Add your own default here as you see fit
variable "location" {
  type    = string
  default = "uksouth"
}

/* # The ID in the output "cfpartners_service_principal_id" in the section above
variable "cfpartners_app_service_principal_id" {
    type = string
} */

# The ID in the output "cfpartners_service_principal_object_id" in the section above
variable "cfpartners_service_principal_id" {
  type = string
}

# GitHub Repo name
variable "github_repo_name" {
  type        = string
  description = "GitHub Repo Name used to store secrets of generated resources"
}

# Personal Access Token to access GitHub
variable "github_token" {
  type      = string
  sensitive = true
}