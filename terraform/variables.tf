
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
  description = "พื้นที่ควบคุม (Region) บน AWS ที่เราจะเข้าไปสร้างระบบ"
  default     = "ap-southeast-1" 
}



# ==========================================
# RDS Variables
# ==========================================

variable "db_username" {
  type        = string
  description = "ชื่อ Admin สำหรับล็อกอินเข้าฐานข้อมูล PostgreSQL"
  default     = "postgres"
}

variable "db_password" {
  type        = string
  description = "รหัสผ่านสำหรับล็อกอินเข้าฐานข้อมูล PostgreSQL"
  sensitive   = true 
}
