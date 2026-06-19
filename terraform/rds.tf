# ==========================================
# Security Group for RDS
# ==========================================
resource "aws_security_group" "rds_sg" {
  name        = "fema_rds_security_group"
  description = "Allow inbound traffic for PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

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
  identifier             = "fema-flood-db"           
  engine                 = "postgres"                 
  engine_version         = "15"                    
  instance_class         = "db.t3.micro"              
  allocated_storage      = 20                         
  
  db_name                = "fema_flood_db"            
  username               = var.db_username            
  password               = var.db_password            
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id] 
  
  publicly_accessible    = true                      
  skip_final_snapshot    = true                      
}

# ==========================================
# RDS Endpoint
# ==========================================
output "rds_endpoint" {
  value       = aws_db_instance.fema_postgres_db.endpoint
  description = "RDS Endpoint URL "
}