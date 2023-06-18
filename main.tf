
#create a custom VPC
resource "aws_vpc" "wk22project-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "project_env"
    Terraform   = "true"
  }

  enable_dns_hostnames = true
}

#create internet gateway to attach to custom VPC
resource "aws_internet_gateway" "wk22project-igw" {
  vpc_id = aws_vpc.wk22project-vpc.id

  tags = {
    Name = "wk22project-igw"
  }
}

#A public subnet launched in the us-east-1a AZ (Web-Tier)
resource "aws_subnet" "wk22project-public1" {
  vpc_id                  = aws_vpc.wk22project-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.az1a
  map_public_ip_on_launch = true

  tags = {
    Name = "wk22project-public1"
  }
}

#A public subnet launched in the us-east-1b AZ (Web-Tier)
resource "aws_subnet" "wk22project-public2" {
  vpc_id                  = aws_vpc.wk22project-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = var.az1b
  map_public_ip_on_launch = true

  tags = {
    Name = "wk22project-public2"
  }
}

#create an elastic IP to assign to NAT Gateway
resource "aws_eip" "wk22project-eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.wk22project-igw]
  tags = {
    Name = "wk22project-eip1"
  }
}

#create an elastic IP to assign to NAT Gateway
resource "aws_eip" "wk22project-eip2" {
  vpc        = true
  depends_on = [aws_vpc.wk22project-vpc]
  tags = {
    Name = "wk22project-eip2"
  }
}

#create NAT Gateway
resource "aws_nat_gateway" "wk22project-nat-gw1" {
  depends_on    = [aws_eip.wk22project-eip1]
  allocation_id = aws_eip.wk22project-eip1.id
  subnet_id     = aws_subnet.wk22project-public1.id
  tags = {
    Name = "wk22project-nat-gw"
  }
}

#create NAT Gateway
resource "aws_nat_gateway" "wk22project-nat-gw2" {
  depends_on    = [aws_eip.wk22project-eip2]
  allocation_id = aws_eip.wk22project-eip2.id
  subnet_id     = aws_subnet.wk22project-public2.id
  tags = {
    Name = "wk22project-nat-gw"
  }
}

#create a  private subnet launched in the AZ us-east-1a (RDS-Tier)
resource "aws_subnet" "wk22project-private1" {
  vpc_id            = aws_vpc.wk22project-vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = var.az1a

  tags = {
    Name = "wk22project-private1"
  }
}

#create a private subnet launched in the AZ us-east-1b  (RDS-Tier)
resource "aws_subnet" "wk22project-private2" {
  vpc_id            = aws_vpc.wk22project-vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = var.az1b

  tags = {
    Name = "wk22project-private2"
  }
}

#create public route table with route for internet gateway 
resource "aws_route_table" "wk22project-public-rt" {
  vpc_id = aws_vpc.wk22project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wk22project-igw.id
  }

  tags = {
    Name = "wk22project-igw-pub-rt"
  }
}

#public route table with public subnet associations
resource "aws_route_table_association" "publicsubnet-route1-ass" {
  route_table_id = aws_route_table.wk22project-public-rt.id
  subnet_id      = aws_subnet.wk22project-public1.id
}

resource "aws_route_table_association" "publicsubnet-route2-ass" {
  route_table_id = aws_route_table.wk22project-public-rt.id
  subnet_id      = aws_subnet.wk22project-public2.id
}

#create a private route table with route for NAT gateway
resource "aws_route_table" "wk22project-private-rt1" {
  vpc_id = aws_vpc.wk22project-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wk22project-nat-gw1.id
  }

  tags = {
    Name = "wk22project-private-rt1"
  }
}

#create a private route table with private subnet associations
resource "aws_route_table_association" "privatesubnet-route1-ass" {
  route_table_id = aws_route_table.wk22project-private-rt1.id
  subnet_id      = aws_subnet.wk22project-private1.id
}

#create private route table with route for NAT gateway
resource "aws_route_table" "wk22project-private-rt2" {
  vpc_id = aws_vpc.wk22project-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wk22project-nat-gw2.id
  }

  tags = {
    Name = "wk22project-private-rt2"
  }
}

#private route table with private subnet associations
resource "aws_route_table_association" "privatesubnet-route2-ass" {
  route_table_id = aws_route_table.wk22project-private-rt2.id
  subnet_id      = aws_subnet.wk22project-private2.id
}


#security groups allowing inbound traffic from internet
resource "aws_security_group" "wk22project-webserver-sg" {
  name   = "wk22project-webserver-sg"
  vpc_id = aws_vpc.wk22project-vpc.id

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
    Name = "wk22project-webserver-sg"
  }
}

resource "aws_security_group" "wk22project-db-sg" {
  name   = "wk22project-db-sg"
  vpc_id = aws_vpc.wk22project-vpc.id

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
    Name = "wk22project-db-sg"
  }
}

resource "aws_security_group" "wk22project-alb-sg" {
  name   = "wk22project-alb-sg"
  vpc_id = aws_vpc.wk22project-vpc.id

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
    Name = "wk22project-alb-sg"
  }
}


#create an application load balancer
resource "aws_lb" "wk22project-alb" {
  name               = "wk22project-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.wk22project-public1.id, aws_subnet.wk22project-public2.id]

  security_groups = [
    aws_security_group.wk22project-alb-sg.id,
  ]

  tags = {
    Name = "wk22project-alb-sg"
  }
}

resource "aws_lb_listener" "wk22project-webserver-listener" {
  load_balancer_arn = aws_lb.wk22project-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.wk22project-launch-template.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "wk22project-launch-template" {
  name        = "wk22project-launch-template"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.wk22project-vpc.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 5
    path                = "/"
    matcher             = "200"
  }

  depends_on = [aws_lb.wk22project-alb]
}

#create EC2 instance launch template for auto scaling group
resource "aws_launch_template" "wk22project-webserver" {
  name                   = "wk22project-lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.wk22project-webserver-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Apache-Websever"
    }
  }
  user_data = filebase64("apache.sh")
}

#auto scaling group to launch minimum of 2 instances and maximum of 3 instances
resource "aws_autoscaling_group" "wk22project-asg" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.wk22project-private1.id, aws_subnet.wk22project-private2.id]

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  launch_template {
    id = aws_launch_template.wk22project-webserver.id
  }

  tag {
    key                 = "Name"
    value               = "wk22project-webserver"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "wk22project-asg-attach" {
  autoscaling_group_name = aws_autoscaling_group.wk22project-asg.id
  lb_target_group_arn    = aws_lb_target_group.wk22project-launch-template.arn
}

# Create subnet group for RDS instance
resource "aws_db_subnet_group" "wk22project-db_sub_grp" {
  name       = "wk22project-db_sub_grp"
  subnet_ids = [aws_subnet.wk22project-private1.id, aws_subnet.wk22project-private2.id]

  tags = {
    Name = "wk22project-db_sub_grp"
  }
}

# Create RDS MySQL Instance
resource "aws_db_instance" "wk22project-db-server" {
  allocated_storage      = 10
  db_name                = "wk22project-db-server"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.wk22project-db_sub_grp.name
  vpc_security_group_ids = [aws_security_group.wk22project-db-sg.id, aws_security_group.wk22project-webserver-sg.id]
  skip_final_snapshot    = true
}

