provider "aws" {
  region            = "${var.region}"
  profile           = "default"
  
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "EC2_Public_key"
  public_key = "${file("files/ec2_public.pub")}"
}

module "vpc_basic" {
  source        = "./vpc"
  name          = "web"
  cidr          = "10.0.0.0/16"
  public_subnet = "10.0.1.0/24"

}

resource "aws_security_group" "web_host_sg" {
  name        = "web_host"
  description = "Allow SSH & HTTP to web hosts"
  vpc_id      = module.vpc_basic.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc_basic.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "web_inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = module.vpc_basic.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web" {
  ami               = var.ami[var.region]
  instance_type     = var.instance_type
  key_name          = "${aws_key_pair.ec2_key.key_name}"
  subnet_id         = module.vpc_basic.public_subnet_id
  private_ip        = var.instance_ips[count.index]
  availability_zone = "${var.azs}"
  #   user_data                   = file("files/web_bootstrap.sh")
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.web_host_sg.id,
  ]

  tags = {
    Name = "web-${format("%03d", count.index + 1)}"
  }

  count = length(var.instance_ips)
}

