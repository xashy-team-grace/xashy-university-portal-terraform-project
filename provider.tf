terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.10.0"

  backend "s3" {
    bucket = "cactus-tfstate"
    key    = "dev/xashy-university-portal.tfstate"
    use_lockfile = true
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}
