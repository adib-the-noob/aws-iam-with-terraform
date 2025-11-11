terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

locals {
  users_data = yamldecode(file("./users.yml")).users
  user_role_pair = flatten([for user in local.users_data : [for role in user.roles : {
    username = user.username,
    role     = role
  }]])
}

output "users_data" {
  value = local.user_role_pair
}

resource "aws_iam_user" "users" {
  for_each = toset(local.users_data[*].username)
  name     = each.key
}

# # password creation
resource "aws_iam_user_login_profile" "profile" {
  for_each        = aws_iam_user.users
  user            = each.value.name
  password_length = 12

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
      pgp_key,
    ]
  }
}

# attaching policies
resource "aws_iam_user_policy_attachment" "main" {
  for_each = {
    for pair in local.user_role_pair : "${pair.username}-${pair.role}" => pair
  }
  user       = aws_iam_user.users[each.value.username].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.role}"
}

# Get AWS Account ID for console login
data "aws_caller_identity" "current" {}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID for console login"
}

output "user_passwords" {
  value = {
    for username, profile in aws_iam_user_login_profile.profile :
    username => profile.password
  }
  sensitive   = true
  description = "Generated passwords for users (sensitive)"
}
