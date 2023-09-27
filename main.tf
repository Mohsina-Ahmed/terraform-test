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

resource "aws_iam_role" "pedantic_pandas_role" {
  name = "pedantic-pandas-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "pedantic_pandas_ec2_instance_profile" {
  name = "pedantic-pandas-profile"  # Replace with your desired instance profile name
  role = aws_iam_role.pedantic_pandas_role.name
}

resource "aws_instance" "pedantic_instance" {
  ami           = "ami-0da7f840f6c348e2d"
  instance_type = "t2.micro"
  #key_name      = "pedantic-pandas-key"

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

resource "aws_elastic_beanstalk_application" "pedantic_pandas_app" {
  name        = "pedantic-pandas-app"
  description = "Task listing app v2"
}

resource "aws_elastic_beanstalk_environment" "pedantic_pandas_app_environment" {
  name                = "pedantic-pandas-app-environment"
  application         = aws_elastic_beanstalk_application.pedantic_pandas_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.pedantic_pandas_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "pedantic-pandas-key"
  }
}
