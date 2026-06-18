# ==========================================
# Required Providers
# ==========================================
terraform {
  required_version = ">= 1.0" # บังคับเวอร์ชันของระบบ Terraform หลัก

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # ใช้ปลั๊กอิน AWS เวอร์ชัน 5.x 
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





