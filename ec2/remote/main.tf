
terraform {

  backend "s3" {
    bucket         = "remote-tf-state"
    key            = "remote/backend/tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

resource "aws_security_group" "web-terraform-sg" {
  name = "web-terraform-sg"
  description = "web-terraform-sg-description"
  # vpc_id = ""

  // ssh access
  # ingress {
  #   from_port = 22
  #   protocol = "tcp"
  #   to_port = 22
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web-terraform-instance" {
  ami           = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  instance_type = "t2.micro"
  count         = 1
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.web-terraform-sg.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "<h1>Hello, World from $(hostname -f)<h1>" > index.html
    python3 -m http.server 80 &
    EOF

  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
  }

  tags = {
    Name ="web-terraform-instance"
    Environment = "SANDBOX"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.web-terraform-sg ]
}

output "ec2instance-public-ip" {
  value = aws_instance.web-terraform-instance[0].public_ip
}
