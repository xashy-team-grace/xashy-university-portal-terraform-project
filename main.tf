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
  ami                  = "ami-0521cb2d60cfbb1a6"
  instance_type        = "t3.micro"
  security_groups      = [aws_security_group.web_app_sg.id]
  subnet_id            = module.vpc.private_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.ssm.name

  tags = {
    Name = "web-app-${var.project}"
  }
}

resource "aws_iam_role" "ssm" {
  name               = "${var.project}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.example.json
}

# AWS-managed policy grants the minimum permissions for the SSM agent to register
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.project}-ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}

# Scoped to the artifact bucket only: bucket-level actions on the ARN,
# object-level actions on the /* path
data "aws_iam_policy_document" "artifact_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.artifact_bucket.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.artifact_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "artifact_access" {
  name   = "${var.project}-artifact-bucket-access"
  role   = aws_iam_role.ssm.id
  policy = data.aws_iam_policy_document.artifact_access.json
}


resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.project}-artifact"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "ENABLED"
  }
}


data "aws_iam_policy_document" "example" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "example" {
  name   = "example_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.example.json
}