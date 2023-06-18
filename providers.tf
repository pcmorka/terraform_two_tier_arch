#In this project, we will be using AWS as the provider, and this will tell Terraform the cloud provider we are going to create our resources in.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}