# ==========================================
# 1. สร้างตึกเครือข่ายหลัก (VPC)
# ==========================================
resource "aws_vpc" "databricks_vpc" {
  cidr_block           = "10.0.0.0/16" # ขนาดพื้นที่เครือข่าย (สร้าง IP ได้ 65,536 เครื่อง)
  enable_dns_hostnames = true          # กฎเหล็ก Databricks: ต้องเปิด DNS
  enable_dns_support   = true          # กฎเหล็ก Databricks: ต้องเปิด DNS

  tags = {
    Name = "fema-databricks-vpc"
  }
}


# ==========================================
# 2. สร้างประตูทางเข้า-ออก อินเทอร์เน็ต (Internet Gateway)
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.databricks_vpc.id

  tags = {
    Name = "fema-databricks-igw"
  }
}


# ==========================================
# 3. สร้างชั้นทำงาน (Subnets) - Databricks บังคับว่าต้องมีอย่างน้อย 2 ห้อง!
# ==========================================
data "aws_availability_zones" "available" {} # คำสั่งดึงข้อมูลว่าสิงคโปร์มีตึกย่อย (AZ) กี่ตึก

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.databricks_vpc.id
  cidr_block              = "10.0.1.0/24" # ห้องที่ 1
  availability_zone       = data.aws_availability_zones.available.names[0] # วางไว้ตึกย่อยที่ 1
  map_public_ip_on_launch = true # เปิดให้เครื่องในห้องนี้รับ Public IP ได้

  tags = {
    Name = "fema-databricks-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.databricks_vpc.id
  cidr_block              = "10.0.2.0/24" # ห้องที่ 2
  availability_zone       = data.aws_availability_zones.available.names[1] # วางไว้ตึกย่อยที่ 2
  map_public_ip_on_launch = true

  tags = {
    Name = "fema-databricks-public-subnet-2"
  }
}


# ==========================================
# 4. สร้างป้ายบอกทาง (Route Table) ให้วิ่งออกเน็ตได้
# ==========================================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.databricks_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # ถ้าจะออกเน็ต...
    gateway_id = aws_internet_gateway.igw.id # ...ให้วิ่งไปที่ประตู IGW นะ
  }

  tags = {
    Name = "fema-databricks-public-rt"
  }
}

# ผูกป้ายบอกทางเข้ากับห้อง Subnet ทั้ง 2 ห้อง
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}


# ==========================================
# 5. สร้างกำแพงไฟ (Security Group) สำหรับ Databricks Cluster
# ==========================================
resource "aws_security_group" "databricks_sg" {
  name        = "fema-databricks-cluster-sg"
  description = "Security Group for Databricks Clusters"
  vpc_id      = aws_vpc.databricks_vpc.id

  # กฎเหล็ก Databricks: เครื่อง Cluster ต้องคุยกันเองได้ทุกพอร์ต (Internal Communication)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # อนุญาตให้เครื่องวิ่งออกไปโหลดข้อมูลข้างนอกได้
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fema-databricks-cluster-sg"
  }
}