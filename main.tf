terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

provider "aws" {
    region = "ap-south-1"
}

locals {
  users_data = yamldecode(file("./users.yml")).users
}

output "users_data" {
  value = local.users_data[*].username
}