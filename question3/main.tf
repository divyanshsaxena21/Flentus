terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

########################
# Variables
########################

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_a_cidr" { default = "10.0.1.0/24" }
variable "public_b_cidr" { default = "10.0.2.0/24" }
variable "private_a_cidr" { default = "10.0.11.0/24" }
variable "private_b_cidr" { default = "10.0.12.0/24" }

variable "key_name" {
  type        = string
  description = "Existing EC2 Key Pair name for SSH access"
}

variable "my_ip" {
  type        = string
  description = "Your IPv4 in CIDR (for SSH access) e.g. 1.2.3.4/32"
}

variable "desired_capacity" { default = 2 }
variable "max_size" { default = 4 }
variable "min_size" { default = 2 }

########################
# Data
########################

data "aws_availability_zones" "azs" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

########################
# VPC + Subnets
########################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "divyansh_saxena_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "divyansh_saxena_igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_a_cidr
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "divyansh_saxena_public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_b_cidr
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "divyansh_saxena_public_b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_a_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]

  tags = {
    Name = "divyansh_saxena_private_a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_b_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]

  tags = {
    Name = "divyansh_saxena_private_b"
  }
}

########################
# Route tables
########################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "divyansh_saxena_public_rt"
  }
}

resource "aws_route_table_association" "pub_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

########################
# NAT Gateway
########################

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "divyansh_saxena_nat_eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "divyansh_saxena_nat_gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "divyansh_saxena_private_rt"
  }
}

resource "aws_route_table_association" "priv_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "priv_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

########################
# Security Groups
########################

resource "aws_security_group" "alb_sg" {
  name        = "divyansh-saxena-alb-sg"
  description = "Allow HTTP from Internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "divyansh_saxena_alb_sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "divyansh-saxena-ec2-sg"
  description = "Allow traffic from ALB and SSH from admin IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "divyansh_saxena_ec2_sg"
  }
}

########################
# ALB + Target Group + Listener
########################

resource "aws_lb" "alb" {
  name               = "divyansh-saxena-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "divyansh_saxena_alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "divyansh-saxena-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "divyansh_saxena_tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

########################
# Launch Template
########################

resource "aws_launch_template" "lt" {
  name_prefix   = "divyansh-saxena-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y nginx1
              systemctl enable nginx
              mkdir -p /var/www/html
              cat > /var/www/html/index.html <<'HTML'
              <!doctype html>
              <html>
              <head><meta charset="utf-8"><title>Resume</title></head>
              <body><h1>Divyansh Saxena - Resume (Sample)</h1><p>Hosted on EC2 behind ALB</p></body>
              </html>
              HTML
              systemctl start nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "divyansh_saxena_ec2"
    }
  }
}

########################
# Auto Scaling Group
########################

resource "aws_autoscaling_group" "asg" {
  name             = "divyansh-saxena-asg"
  max_size         = var.max_size
  min_size         = var.min_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "divyansh_saxena_asg_instance"
    propagate_at_launch = true
  }
}

########################
# Outputs
########################

output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}