terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
   assume_role {
   role_arn = "arn:aws:iam::520715763275:role/provider.tfrole"
  }
}