variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Nome do key pair na AWS"
  type        = string
}

variable "private_key_path" {
  description = "Caminho local da chave privada SSH"
  type        = string
  default     = "~/.ssh/ansible-demo.pem"
}

variable "my_ip" {
  description = "Seu IP publico (curl ifconfig.me). Formato: X.X.X.X/32"
  type        = string
}

variable "rhel9_ami" {
  description = "RHEL 9 AMI ID - muda por regiao"
  type        = string
  default     = "ami-0583d8c7a9c35822c"
}

variable "controller_type" {
  description = "Instance type do Ansible Control Node"
  type        = string
  default     = "t3.micro"
}

variable "target_type" {
  description = "Instance type dos servidores alvo"
  type        = string
  default     = "t3.micro"
}

variable "environments" {
  description = "Ambientes e quantidade de hosts"
  type = map(object({
    subnet_cidr = string
    host_count  = number
    cis_level   = string
  }))
  default = {
    dev = {
      subnet_cidr = "10.0.10.0/24"
      host_count  = 1
      cis_level   = "level1"
    }
    staging = {
      subnet_cidr = "10.0.20.0/24"
      host_count  = 1
      cis_level   = "level2"
    }
    prod = {
      subnet_cidr = "10.0.30.0/24"
      host_count  = 1
      cis_level   = "level2_stig"
    }
  }
}