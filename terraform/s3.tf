# ==========================================
# S3 Configurations
# ==========================================
resource "aws_s3_bucket" "fema_data_lake" {
  bucket = "fema-flood-claims-bucket-2026"

  force_destroy = true 

  tags = {
    Name        = "FEMA Data Lake"
    Environment = "Dev"
    Project     = "Data Engineering Portfolio"
  }
}

# ==========================================
# Blocking public access
# ==========================================
resource "aws_s3_bucket_public_access_block" "fema_data_lake_security" {
  bucket = aws_s3_bucket.fema_data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}