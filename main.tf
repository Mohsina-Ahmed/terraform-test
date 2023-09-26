terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}
resource "aws_instance" "pedantic_instance" {
  ami           = "ami-0da7f840f6c348e2d"
  instance_type = "t2.micro"

  tags = {
    Name = "pedantic-pandas"
  }
}