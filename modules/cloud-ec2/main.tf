terraform {
  required_version = "~> 0.11"
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 2.7"
}
