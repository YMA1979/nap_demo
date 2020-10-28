#Configure the AWS provider
provider "aws" {
  version = "~> 2.0"  
  region  = "eu-west-2"
}

#Configure the VPC and Public Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${var.prefix}-f5-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "ob2-vpc-teraform"
  }
}

#Configure the security Group
resource "aws_security_group" "f5" {
  name   = "${var.prefix}-f5"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["94.7.231.241/32"]
  }

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["94.7.231.241/32"]
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["94.7.231.241/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ob1-SecurityGroup1"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/userdata.tmpl")}"

}

resource "aws_instance" "OB1-JuiceShop" {
  ami = "ami-0765d48d7e15beb93"
  instance_type = "t2.micro"
  subnet_id   = module.vpc.public_subnets[0]
  private_ip = "10.0.1.10"
  key_name   = "${var.ssh_key_name}"
  user_data = "${data.template_file.user_data.rendered}"
  security_groups = [ aws_security_group.f5.id ]
}