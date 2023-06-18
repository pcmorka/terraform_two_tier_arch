terraform {
  cloud {
    organization = "Terraform-Deployment"

    workspaces {
      name = "terraform_two_tier_arch"
    }
  }
}