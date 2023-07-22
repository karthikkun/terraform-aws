terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}

resource "aws_instance" "web-terraform-instance-1" {
  ami           = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  security_groups = [aws_security_group.web-terraform-sg.name]
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
    Name = var.instance_tag
    Environment = "SANDBOX"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.web-terraform-sg ]
}

resource "aws_instance" "web-terraform-instance-2" {
  ami           = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  security_groups = [aws_security_group.web-terraform-sg.name]
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
    Name = var.instance_tag
    Environment = "SANDBOX"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.web-terraform-sg ]
}

data "aws_vpc" "default-vpc" {
    default = true
}

data "aws_subnets" "default-subnet" {
    filter {
      name = "vpc-id" 
        values = [data.aws_vpc.default-vpc.id]
    }
}

resource "aws_security_group" "web-terraform-sg" {
  name = "web-terraform-sg"
  description = "web-terraform-sg-description"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = [aws_security_group.web-terraform-lb-sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ aws_security_group.web-terraform-lb-sg ]
}

resource "aws_lb_listener" "http-traffic" {
    load_balancer_arn = aws_lb.web-terraform-lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = 404
      }
    }
}

resource "aws_lb_target_group" "instances" {
  name = "instances-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default-vpc.id
  health_check {
    path                    = "/"
    protocol                = "HTTP"
    matcher                 = "200"
    interval                = 15
    timeout                 = 3
    healthy_threshold       = 2 
    unhealthy_threshold     = 2 
  }
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.web-terraform-instance-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.web-terraform-instance-2.id
  port             = 80
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn      = aws_lb_listener.http-traffic.arn
  priority          = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

resource "aws_security_group" "web-terraform-lb-sg" {
  name = "web-terraform-lb-sg"
  description = "web-terraform-lb-sg-description"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "web-terraform-lb" {
  name                  = "web-terraform-lb"
  load_balancer_type    = "application"
  subnets               = data.aws_subnets.default-subnet.ids
  security_groups       = [aws_security_group.web-terraform-lb-sg.id] 
}
