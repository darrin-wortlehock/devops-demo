variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

variable "aws_devops_public_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "chef_server_admin_user_name" {
  default = "admin"
}
variable "chef_server_admin_user_full_name" {
  default = "Administrative User"
}
variable "chef_server_admin_user_email" {
  default = "admin@devops-demo.co.uk"
}
variable "chef_server_admin_user_password" {}

variable "chef_server_deploy_user_name" {
  default = "deploy"
}

variable "chef_server_deploy_user_full_name" {
  default = "Deploy User"
}

variable "chef_server_deploy_user_email" {
  default = "deploy@devops-demo.co.uk"
}

variable "chef_server_deploy_user_password" {}

variable "chef_server_org_name" {
  default = "devops-demo"
}
variable "chef_server_org_full_name" {
  default = "Devops Demo"
}

# Ubuntu Trusty 14.04 LTS (x64)
variable "aws_amis" {
  default = {
    ap-northeast-1 = "ami-b405bfb4"
    ap-southeast-1 = "ami-72353b20"
    ap-southeast-2 = "ami-3d054707"
    eu-central-1 = "ami-8ae0e797"
    eu-west-1 = "ami-92401ce5"
    sa-east-1 = "ami-d1a129cc"
    us-east-1 = "ami-2dcf7b46"
    us-west-1 = "ami-976d93d3"
    us-west-2 = "ami-97d5c0a7"
    cn-north-1 = "ami-b0d34f89"
    us-gov-west-1 = "ami-bd89ea9e"
  }
}

