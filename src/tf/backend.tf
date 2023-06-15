terraform {
  backend "s3" {
    region  = "eu-west-2"
    bucket  = "annem-terraform-state"
    key     = "annem/terraform.tfstate"
    encrypt = true
  }
}