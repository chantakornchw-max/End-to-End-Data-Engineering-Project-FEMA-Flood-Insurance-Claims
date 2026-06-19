# ==========================================
# AWS Variables
# ==========================================
variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
  sensitive   = true 
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
  sensitive   = true 
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-southeast-1" 
}


# ==========================================
# RDS Variables
# ==========================================
variable "db_username" {
  type        = string
  description = "DB Username"
  default     = "postgres"
}

variable "db_password" {
  type        = string
  description = "DB Password"
  sensitive   = true 
}