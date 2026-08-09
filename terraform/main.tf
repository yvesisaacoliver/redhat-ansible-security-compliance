terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project = "ansible-compliance-demo"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${local.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.project}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${local.project}-rt" }
}

resource "aws_subnet" "controller" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "${local.project}-controller-subnet" }
}

resource "aws_route_table_association" "controller" {
  subnet_id      = aws_subnet.controller.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "env" {
  for_each                = var.environments
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name        = "${local.project}-${each.key}-subnet"
    Environment = each.key
  }
}

resource "aws_route_table_association" "env" {
  for_each       = var.environments
  subnet_id      = aws_subnet.env[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "controller" {
  name        = "${local.project}-controller-sg"
  description = "Ansible Control Node - SSH + Web UI + EDA webhook"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    description = "AAP Web UI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    description = "EDA webhook listener"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    description = "Receptor mesh"
    from_port   = 27199
    to_port     = 27199
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.project}-controller-sg" }
}

resource "aws_security_group" "env" {
  for_each    = var.environments
  name        = "${local.project}-${each.key}-sg"
  description = "Target servers - ${each.key}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.controller.id]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  dynamic "ingress" {
    for_each = each.key == "dev" ? [1] : []
    content {
      description = "HTTP for dev"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    }
  }

  dynamic "ingress" {
    for_each = each.key != "dev" ? [1] : []
    content {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project}-${each.key}-sg"
    Environment = each.key
  }
}

resource "aws_instance" "controller" {
  ami                    = var.rhel9_ami
  instance_type          = var.controller_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.controller.id
  vpc_security_group_ids = [aws_security_group.controller.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${local.project}-controller"
    Role        = "controller"
    Project     = local.project
  }
}

resource "aws_instance" "targets" {
  for_each = {
    for pair in flatten([
      for env_name, env in var.environments : [
        for i in range(env.host_count) : {
          key  = "${env_name}-${i + 1}"
          env  = env_name
          idx  = i + 1
          cidr = env.subnet_cidr
          cis  = env.cis_level
        }
      ]
    ]) : pair.key => pair
  }

  ami                    = var.rhel9_ami
  instance_type          = var.target_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.env[each.value.env].id
  vpc_security_group_ids = [aws_security_group.env[each.value.env].id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${local.project}-${each.key}"
    Role        = "target"
    Environment = each.value.env
    CISLevel    = each.value.cis
    Project     = local.project
  }
}