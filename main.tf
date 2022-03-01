terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  cloud {
    organization = "metaforager"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "random" {}

data "aws_ami" "us-west-1" {
  owners = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm/ubuntu-precise-12.04-amd64-server-20170502"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "us-west-2" {
  owners = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm/ubuntu-precise-12.04-amd64-server-20170502"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_pet" "sg" {}

resource "aws_instance" "web-us-west-1" {
  provider = aws

  ami                    = data.aws_ami.us-west-1.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg-us-west-1.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_instance" "web-us-west-2" {
  provider = aws.us-west-2

  ami                    = data.aws_ami.us-west-2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg-us-west-2.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_security_group" "web-sg-us-west-1" {
  provider = aws
  name     = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web-sg-us-west-2" {
  provider = aws.us-west-2
  name     = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web-address-us-west-1" {
  value = "${aws_instance.web-us-west-1.public_dns}:8080"
}

output "web-address-us-west-2" {
  value = "${aws_instance.web-us-west-2.public_dns}:8080"
}
