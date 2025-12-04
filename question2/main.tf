terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# ---------------------
# Key Pair
# ---------------------
resource "aws_key_pair" "divyansh_saxena_key" {
  key_name   = "divyansh_saxena_Key"
  public_key = file("${path.module}/ec2key.pub")
}

# ---------------------
# Security Group
# ---------------------
resource "aws_security_group" "divyansh_saxena_sg" {
  name        = "divyansh_saxena_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = "vpc-03859bafc99711919"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
}

# ---------------------
# EC2 Instance
# ---------------------
resource "aws_instance" "divyansh_saxena_ec2" {
  ami                         = "ami-0d176f79571d18a8f"
  instance_type               = "t3.micro"
  subnet_id                   = "subnet-018deda5f044b6779"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.divyansh_saxena_key.key_name
  vpc_security_group_ids      = [aws_security_group.divyansh_saxena_sg.id]

  user_data = file("${path.module}/userdata.sh")

  tags = {
    Name = "divyansh_saxena_EC2"
  }

  # Upload resume PDF
  provisioner "file" {
    source      = "${path.module}/divyansh_saxena_resume.pdf"
    destination = "/home/ec2-user/divyansh_saxena_resume.pdf"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("${path.module}/divyansh_saxena_.pem")
    }
  }

  # ---------------------
  # Restart nginx
  # ---------------------
    provisioner "remote-exec" {
  inline = [
    "echo 'Detecting OS and user home...'",
    "USER_HOME=$(ls -d /home/* | head -n1 || echo /root)",
    "echo 'user home:' $USER_HOME",
    "SRC=\"$USER_HOME/divyansh_saxena_resume.pdf\"",
    "if [ -f \"$SRC\" ]; then",
    "  echo 'Found resume at' $SRC '; moving to webroot'",
    "  sudo mv -f \"$SRC\" /usr/share/nginx/html/divyansh_saxena_resume.pdf",
    "  sudo chmod 644 /usr/share/nginx/html/divyansh_saxena_resume.pdf",
    "  # set owner depending on distro",
    "  if id nginx >/dev/null 2>&1; then sudo chown nginx:nginx /usr/share/nginx/html/divyansh_saxena_resume.pdf; elif id www-data >/dev/null 2>&1; then sudo chown www-data:www-data /usr/share/nginx/html/divyansh_saxena_resume.pdf; else sudo chown root:root /usr/share/nginx/html/divyansh_saxena_resume.pdf; fi",
    "  # fix SELinux context if present",
    "  if command -v restorecon >/dev/null 2>&1; then sudo restorecon -v /usr/share/nginx/html/divyansh_saxena_resume.pdf || true; fi",
    "else",
    "  echo 'Resume not found at' $SRC '; listing /home:'; ls -la /home || true",
    "fi",
    "echo 'Checking nginx root and status'",
    "sudo nginx -T | sed -n '1,120p' || true",
    "sudo systemctl restart nginx || true",
    "sudo systemctl status nginx --no-pager || true",
    "exit 0"
  ]

  connection {
    type        = "ssh"
    user        = "ec2-user"    # change to ubuntu/fedora if your AMI uses that user
    host        = self.public_ip
    private_key = file("${path.module}/divyansh_saxena_.pem")
  }
}



}

# ---------------------
# Output
# ---------------------
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.divyansh_saxena_ec2.public_ip
}