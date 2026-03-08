terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.35.1"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-270511957-simeng"
    key            = "ecs-project/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-lock-270511957-simeng"
    encrypt        = true
  }
}