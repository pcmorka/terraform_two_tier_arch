#create an Amazon Web Services (AWS) Virtual Private Cloud (a custom VPC )
resource "aws_vpc" "wk22Project-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "Prod"
    Terraform   = "true"
  }
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#create internet gateway to attach to VPC
resource "aws_internet_gateway" "wk22Project-igw" {
  vpc_id = aws_vpc.wk22Project-vpc.id

  tags = {
    Name = "wk22Project-igw"
  }
}

#Create the first public subnet (public subnet 1) for the WebServer-Tier in the us-east-1a Availability Zone (AZ)
resource "aws_subnet" "wk22Project-public1" {
  vpc_id                  = aws_vpc.wk22Project-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.az1a
  map_public_ip_on_launch = true

  tags = {
    Name = "wk22Project-public1"
  }
}

#Create the second public subnet (public subnet 2) for the WebServer-Tier in the us-east-1b Availability Zone (AZ)
resource "aws_subnet" "wk22Project-public2" {
  vpc_id                  = aws_vpc.wk22Project-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = var.az1b
  map_public_ip_on_launch = true

  tags = {
    Name = "wk22Project-public2"
  }
}

#create the first Elastic IP address (EIP) in an AWS VPC to assign to NAT Gateway 
resource "aws_eip" "wk22Project-eip1" {
  vpc        = true
  depends_on = [aws_vpc.wk22Project-vpc]
  tags = {
    Name = "wk22Project-eip1"
  }
}

#create the second Elastic IP address (EIP) in an AWS VPC to assign to NAT Gateway 
resource "aws_eip" "wk22Project-eip2" {
  vpc        = true
  depends_on = [aws_vpc.wk22Project-vpc]
  tags = {
    Name = "wk22Project-eip2"
  }
}

#create the first NAT Gateway in the VPC public subnet 1
resource "aws_nat_gateway" "wk22Project-nat-gw1" {
  depends_on    = [aws_eip.wk22Project-eip1]
  allocation_id = aws_eip.wk22Project-eip1.id
  subnet_id     = aws_subnet.wk22Project-public1.id
  tags = {
    Name = "wk22Project-nat-gw"
  }
}

#create the second NAT Gateway in the VPC public subnet 2
resource "aws_nat_gateway" "wk22Project-nat-gw2" {
  depends_on    = [aws_eip.wk22Project-eip2]
  allocation_id = aws_eip.wk22Project-eip2.id
  subnet_id     = aws_subnet.wk22Project-public2.id
  tags = {
    Name = "wk22Project-nat-gw"
  }
}

#Create the first private subnet (private subnet 1) for the RDS_Server-Tier in the us-east-1a Availability Zone (AZ)
resource "aws_subnet" "wk22Project-private1" {
  vpc_id            = aws_vpc.wk22Project-vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = var.az1a

  tags = {
    Name = "wk22Project-private1"
  }
}

#Create the second private subnet (private subnet 2) for the RDS_Server-Tier in the us-east-1b Availability Zone (AZ)
resource "aws_subnet" "wk22Project-private2" {
  vpc_id            = aws_vpc.wk22Project-vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = var.az1b

  tags = {
    Name = "wk22Project-private2"
  }
}

#create public route table with route for internet gateway
resource "aws_route_table" "wk22Project-public-rt" {
  vpc_id = aws_vpc.wk22Project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wk22Project-igw.id
  }

  tags = {
    Name = "wk22Project-igw"
  }
}

#public route table with public subnet associations 
resource "aws_route_table_association" "wk22publicsubnet-route1" {
  route_table_id = aws_route_table.wk22Project-public-rt.id
  subnet_id      = aws_subnet.wk22Project-public1.id
}

resource "aws_route_table_association" "wk22publicsubnet-route2" {
  route_table_id = aws_route_table.wk22Project-public-rt.id
  subnet_id      = aws_subnet.wk22Project-public2.id
}

#create private route table with route for NAT gateway in the AWS VPC
resource "aws_route_table" "wk22Project-private-rt1" {
  vpc_id = aws_vpc.wk22Project-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wk22Project-nat-gw1.id
  }

  tags = {
    Name = "wk22Project-private-rt1"
  }
}

#private route table with private subnet associations     
resource "aws_route_table_association" "wk22privatesubnet-route1" {
  route_table_id = aws_route_table.wk22Project-private-rt1.id
  subnet_id      = aws_subnet.wk22Project-private1.id
}

#create private route table with route for NAT gateway in the AWS VPC
resource "aws_route_table" "wk22Project-private-rt2" {
  vpc_id = aws_vpc.wk22Project-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wk22Project-nat-gw2.id
  }

  tags = {
    Name = "wk22Project-private-rt2"
  }
}

#private route table with private subnet associations 
resource "aws_route_table_association" "wk22privatesubnet-route2" {
  route_table_id = aws_route_table.wk22Project-private-rt2.id
  subnet_id      = aws_subnet.wk22Project-private2.id
}

#create security groups that allows inbound traffic from the internet

#Web Server Security Group
resource "aws_security_group" "wk22Project-webserver-sg" {
  name   = "wk22Project-webserver-sg"
  description = "allow traffic from Webserver Tier & SSH" 
  vpc_id = aws_vpc.wk22Project-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wk22Project-webserver-sg"
  }
}

#Database Server (MYSQL Server) Security Group
resource "aws_security_group" "wk22Project-db-sg" {
  name   = "wk22Project-db-sg"
  description = "allow traffic from Webserver Tier & SSH" 
  vpc_id = aws_vpc.wk22Project-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wk22Project-db-sg"
  }
}

#Application Load Balancer Security Group
resource "aws_security_group" "wk22Project-alb-sg" {
  name   = "wk22Project-alb-sg"
  description = "alb security group"
  vpc_id = aws_vpc.wk22Project-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wk22Project-alb-sg"
  }
}


# Create database subnet group for RDS instance

resource "aws_db_subnet_group" "wk22Project-dbsubnet-grp" {
  name       = "wk22Project-dbsubnet-grp"
  subnet_ids = [aws_subnet.wk22Project-private1.id, aws_subnet.wk22Project-private2.id]

  tags = {
    Name = "wk22Project db subnet group"
  }
}

# Create AWS Database Instance (RDS MySQL Instance)

resource "aws_db_instance" "wk22project-db-instance" {
  allocated_storage = 10
  db_name           = "wk22project-db-instance"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"

  #Set Database login credentials for the RDS Instance
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.wk22Project-db-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.wk22Project-dbsubnet-grp.name 
  skip_final_snapshot    = true
}

#create a launch template for an EC2 instance using auto scaling group

resource "aws_launch_template" "wk22Project-WebServer" {
  name                   = "wk22Project-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.wk22Project-webserver-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Apache-WebServer"
    }
  }
  user_data = filebase64("apache.sh")
}

#auto scaling group to launch minimum of 2 instances and maximum of 5 instances

resource "aws_autoscaling_group" "wk22Project-asg" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.wk22Project-private1.id, aws_subnet.wk22Project-private2.id]

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  launch_template {
    id = aws_launch_template.wk22Project-WebServer.id
  }

  tag {
    key                 = "Name"
    value               = "wk22Project-WebServer"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "wk22Project-asg-attach" {
  autoscaling_group_name = aws_autoscaling_group.wk22Project-asg.id
  lb_target_group_arn    = aws_lb_target_group.wk22Project-launch-template.arn
}

#Create Application Load Balancer
resource "aws_lb" "wk22Project-alb" {
  name               = "wk22Project-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.wk22Project-public1.id, aws_subnet.wk22Project-public2.id]

  security_groups = [
    aws_security_group.wk22Project-alb-sg.id,
  ]

  tags = {
    Name = "wk22Project-alb-sg"
  }
}

resource "aws_lb_listener" "wk22Project-http-listener" {
  load_balancer_arn = aws_lb.wk22Project-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {

    target_group_arn = aws_lb_target_group.wk22Project-launch-template.arn

    type             = "forward"
  }
}

resource "aws_lb_target_group" "wk22Project-launch-template" {

  name        = "wk22Project-launch-template"

  port        = 80

  protocol    = "HTTP"

  target_type = "instance"

  vpc_id      = aws_vpc.wk22Project-vpc.id

  health_check {
    healthy_threshold   = 4
    interval            = 45
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 5
    path                = "/"
    matcher             = "300"
  }

  depends_on = [aws_lb.wk22Project-alb]
}
