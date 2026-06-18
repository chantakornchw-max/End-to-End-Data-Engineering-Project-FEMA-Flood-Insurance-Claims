# ==========================================
# Required Providers
# ==========================================
terraform {
  required_version = ">= 1.0" 

  backend "s3" {
    bucket = "fema-terraform-state-2026"   
    key    = "prod/terraform.tfstate"      
    region = "ap-southeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

# ==========================================
# AWS Provider Configuration
# ==========================================
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region 
}





