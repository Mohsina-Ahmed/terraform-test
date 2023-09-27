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

# Attach the AWSElasticBeanstalkWebTier policy
resource "aws_iam_role_policy_attachment" "web_tier_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.pedantic_pandas_role.name
}

# Attach the AWSElasticBeanstalkMulticontainerDocker policy
resource "aws_iam_role_policy_attachment" "multicontainer_docker_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.pedantic_pandas_role.name
}

# Attach the AWSElasticBeanstalkWorkerTier policy
resource "aws_iam_role_policy_attachment" "worker_tier_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.pedantic_pandas_role.name
}

# resource "aws_instance" "pedantic_instance" {
#   ami           = "ami-0da7f840f6c348e2d"
#   instance_type = "t2.micro"
#   #key_name      = "pedantic-pandas-key"

#   tags = {
#     Name = "pedantic-pandas"
#   }

#   security_groups = [aws_security_group.pedantic_pandas_security.name]
# }

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

resource "aws_iam_role_policy_attachment" "pedantic_pandas_policy_attachment" {
  role       = aws_iam_role.pedantic_pandas_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Define an S3 bucket resource for holding Dockerrun.aws.json
resource "aws_s3_bucket" "dockerrun_bucket" {
  bucket = "pedantic-pandas-for-docker"  # Replace with your desired bucket name
  acl    = "private"  # Adjust the access control settings as needed
}
# Upload the Dockerrun.aws.json file to the S3 bucket
resource "aws_s3_bucket_object" "dockerrun_object" {
  bucket = aws_s3_bucket.dockerrun_bucket.id
  key    = "Dockerrun.aws.json"  # The object key (file name)
  source = "Dockerrun.aws.json"  # Path to your local Dockerrun.aws.json file
  acl    = "private"  # Adjust the access control settings as needed
}
resource "aws_db_instance" "rds_app" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "13.3"
  instance_class       = "db.m6g.large"
  identifier           = "pedantic-pandas-app-prod"
  name                 = "pedantic-pandas-app-database"
  username             = "root"
  password             = "password"
  skip_final_snapshot  = true
  publicly_accessible = true
}