
resource "aws_s3_bucket" "fema_data_lake" {
  bucket = "fema-flood-claims-bucket-2026"

  # คำสั่งไม้ตาย: อนุญาตให้ลบถังนี้ทิ้งได้ทันทีแม้ว่าจะมีไฟล์ค้างอยู่ข้างใน (เหมาะสำหรับโปรเจกต์ทดสอบ)
  force_destroy = true 

  tags = {
    Name        = "FEMA Data Lake"
    Environment = "Dev"
    Project     = "Data Engineering Portfolio"
  }
}


resource "aws_s3_bucket_public_access_block" "fema_data_lake_security" {
  bucket = aws_s3_bucket.fema_data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

