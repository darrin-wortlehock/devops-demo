# Configure the AWS Provider
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_key_pair" "devops" {
  key_name = "devops-key"
  public_key = "${var.aws_devops_public_key}"
}