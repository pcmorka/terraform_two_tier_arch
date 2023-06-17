#create an Amazon Web Services VPC
resource "aws_vpc" "wk22project-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "project-env"
    Terraform   = "true"
  }

  enable_dns_hostnames = true
}

#List of AZs in the current region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#Create the public subnets for the WebServer-Tier in the us-east-1a (& 1b) Availability Zone (AZ)
resource "aws_subnet" "wk22project-pub_sub" {
  for_each                = var.wk22project-pub_sub
  vpc_id                  = aws_vpc.wk22project-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = wk22project-public-subnet
    Terraform = "true"
  }
}

#Create the  private subnets for the database-Tier in the us-east-1a (& 1b) Availability
resource "aws_subnet" "wk22project-priv_sub" {
  for_each          = var.wk22project-priv_sub
  vpc_id            = aws_vpc.wk22project-vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

  tags = {
    Name      = wk22project-private-subnet
    Terraform = "true"
  }
}

#Create public route table with route for internet gateway 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.wk22project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wk22Project-igw.id
  }

  tags = {
    Name = "wk22projec_public_rt"
  }
}
##create private route table with route for NAT gateway in the AWS VPC
resource "aws_route_table" "wk22projec_private_rt" {
  vpc_id = aws_vpc.wk22project-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wk22project-nat-gw.id
  }

  tags = {
    Name      = "wk22project-private-rt"
    Terraform = "true"
  }
}

#Create public route table associations  with public subnet 
resource "aws_route_table_association" "wk22project-public-rt-ass" {
  depends_on     = [aws_subnet.aws_subnet.wk22project-pub_sub]
  route_table_id = aws_route_table.wk22project-public-rt.id
  for_each       = aws_subnet.wk22project-pub_sub
  subnet_id      = each.value.id
}

#private route table with private subnet associations
resource "aws_route_table_association" "wk22project-private-rt-ass" {
  depends_on     = [aws_subnet.wk22project-priv_sub]
  route_table_id = aws_route_table.wk22project-private-rt.id
  for_each       = aws_subnet.wk22project-priv_sub
  subnet_id      = each.value.id
}

#Create Internet Gateway to attach to VPC
resource "aws_internet_gateway" "wk22project-igw" {
  vpc_id = aws_vpc.wk22project-vpc.id

  tags = {
    Name = "wk22project-igw"
  }
}

#create the Elastic IP address (EIP) in an AWS VPC to assign to NAT Gateway
resource "aws_eip" "wk22project-nat-gw-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.wk22project-igw]

  tags = {
    Name = "wk22project-nat-gw-eip"
  }
}

#create NAT Gateway in the VPC public subnet 1
resource "aws_nat_gateway" "wk22project-nat-gw" {
  depends_on    = [aws_subnetwk22project-pub_sub]
  allocation_id = aws_eip.wk22project-eip1.id
  subnet_id     = aws_subnet.wk22project-pub_sub["wk22project-pub_sub_11"].id

  tags = {
    Name = "wk22project-nat-gw"
  }
}
# create security groups that allows inbound traffic from the internet
resource "aws_security_group" "wk22project-webserver-sg" {
  name        = "wk22project-webserver-sg"
  description = "allow traffic from Webserver Tier & SSH (ports 80 & 22)"
  vpc_id      = aws_vpc.wk22project-vpc.id

  # allow access on port 80
  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wk22project-webserver-sg"
  }
}

# create Database Server (MYSQL Server) Security Group
resource "aws_security_group" "wk22project-db-sg" {
  name        = "wk22project-db-sg"
  description = "allow traffic from Webserver Tier & SSH (ports 80, 22, & 3306)"
  vpc_id      = aws_vpc.wk22project-vpc.id

  # allow access on port 80
  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description     = "ssh access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.wk22project-webserver-sg.id]
  }

  # allow webserver access to rds database
  ingress {
    description     = "database"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wk22project-webserver-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wk22project-db-sg"
  }
}

#cCreate AWS Database Instance (RDS MySQL Instance)
resource "aws_db_instance" "wk22project-db-instance" {
  allocated_storage      = 10
  db_name                = "wk22project-db-instance"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "db_username"
  password               = "db_password"
  vpc_security_group_ids = [aws_security_group.wk22project-db-sg.id, aws_security_group.wk22project-webserver-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.wk22project-dbsubnet-grp.name
  skip_final_snapshot    = true
  publicly_accessible    = true
}

#Create database subnet group for RDS instance
resource "aws_db_subnet_group" "wk22project-dbsubnet-grp" {
  name       = "wk22project-dbsubnet-grp"
  subnet_ids = [aws_subnet.wk22project-priv_sub["wk22project-priv_sub_1"].id, aws_subnet.wk22project-priv_sub["wk22project-priv_sub_2"].id]

  tags = {
    Name = "wk22project db subnet group"
  }
}

# create an EC2 instance 
resource "aws_instance" "wk22project-webserver" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  for_each               = aws_subnet.wk22project-pub_sub
  subnet_id              = each.value.id
  vpc_security_group_ids = [aws_security_group.wk22project-webserver-sg.id]
  key_name               = var.key_name
  user_data              = file("apache.sh")

  tags = {
    Name = "apache-webserver"
  }
}
