terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "pedantic-pandas"
    key    = "terraform-state"
    region = "eu-west-2"
  }
}

provider "aws" {
  #profile = "terraform"
  region  = "eu-west-2"
}
resource "aws_instance" "pedantic_instance" {
  ami           = "ami-0da7f840f6c348e2d"
  instance_type = "t2.micro"

  tags = {
    Name = "pedantic-pandas"
  }

  security_groups = [aws_security_group.pedantic_pandas_security.name]
}

data "aws_vpc" "default_vpc" {
  id = "vpc-080dbb0b7dc86503a"
}

resource "aws_security_group" "pedantic_pandas_security" {
  name        = "pedantic_pandas_security"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    # cidr_blocks      = [aws_vpc.main.cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
}
