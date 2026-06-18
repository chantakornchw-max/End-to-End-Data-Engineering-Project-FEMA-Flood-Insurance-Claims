
# ==========================================
# Security Group for RDS
# ==========================================
resource "aws_security_group" "rds_sg" {
  name        = "fema_rds_security_group"
  description = "Allow inbound traffic for PostgreSQL"

  # กฎขาเข้า (Ingress): อนุญาตให้วิ่งเข้ามาที่พอร์ต 5432 (พอร์ตมาตรฐานของ PostgreSQL)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # เปิดให้เข้าได้จากทุก IP ทั่วโลก (เพื่อความสะดวกในการต่อ Databricks และ Power BI ของเรา)
  }

  # กฎขาออก (Egress): อนุญาตให้ RDS ส่งข้อมูลออกไปได้ทุกที่
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# PostgreSQL Configurations
# ==========================================
resource "aws_db_instance" "fema_postgres_db" {
  identifier             = "fema-flood-db"            # ชื่อเซิร์ฟเวอร์ที่โชว์บนหน้าเว็บ AWS
  engine                 = "postgres"                 # เลือกใช้ PostgreSQL
  engine_version         = "15.4"                     # เวอร์ชันของฐานข้อมูล
  instance_class         = "db.t3.micro"              # สเปกเครื่องจิ๋ว (อยู่ในโควตา Free Tier)
  allocated_storage      = 20                         # พื้นที่เก็บข้อมูล 20 GB (โควตา Free Tier)
  
  db_name                = "fema_flood_db"            # ชื่อ Database ก้อนแรกที่จะถูกสร้างขึ้นมาอัตโนมัติ
  username               = var.db_username            # ดึง Username มาจากไฟล์ตัวแปร
  password               = var.db_password            # ดึง Password มาจากไฟล์ตัวแปร
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # เอากำแพงไฟข้อ 1. มาครอบเครื่องนี้ไว้
  
  publicly_accessible    = true                       # สำคัญมาก! ต้องเปิด True เพื่อให้ Databricks และคอมพิวเตอร์ของเรา (ผ่าน DBeaver/VS Code) ยิงเข้าหาได้
  skip_final_snapshot    = true                       # ท่าไม้ตาย! สั่งให้ตอนลบทิ้ง ไม่ต้องเสียเวลาทำ Backup (กันบิลไหล)
}

# ==========================================
# RDS Endpoint
# ==========================================
output "rds_endpoint" {
  value       = aws_db_instance.fema_postgres_db.endpoint
  description = "ที่อยู่ URL สำหรับเอาไปใส่ใน DBeaver หรือโค้ด Python เพื่อเชื่อมต่อฐานข้อมูล"
}

