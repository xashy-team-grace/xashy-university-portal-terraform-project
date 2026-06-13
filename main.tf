module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "xashy-university-portal"
  }
}

resource "aws_security_group" "web_app_sg" {
  name   = "${var.project}-web-app-sg"
  vpc_id = module.vpc.vpc_id

}

resource "aws_instance" "web_app" {
  ami             = "ami-06d5c141ec5b90893"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.web_app_sg.id]
  subnet_id       = module.vpc.private_subnets[0]
}