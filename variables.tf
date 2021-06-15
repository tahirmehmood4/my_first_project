# //////////////////////////////
# VARIABLES
# //////////////////////////////

variable "bucket_name" {
  default = "tahir-tfbckstateee"
}

data "aws_iam_user" "admin" {
  user_name = "admin"
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "main_vpc_cidr" {
    description = "CIDR of the VPC"
    default = "10.0.0.0/16"
}

variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "us-east-1"
}

variable "mgmt_jump_private_ips" {
  default = {
    "0" = "10.0.10.101"
    "1" = "10.0.20.102"
  }
}

variable "subnet_cidrs_public" {
  description = "Subnet CIDRs for public subnets (length must match configured availability_zones)"
  default = ["10.0.10.0/24", "10.0.20.0/24"]
  type = list(string)
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["us-east-1a", "us-east-1b"]
  type = list(string)
}

/*variable "amis" {
  default = {
    # AMIs for Ubuntu 14.04
    eu-west-1 = "ami-47a23a30"
    eu-west-2 = "ami-accff2b1"
  }
}*/

/*
variable "availability_zone1" {
    description = "Avaialbility Zones"
    default = "us-east-1a"
}

variable "availability_zone2" {
    description = "Avaialbility Zones"
    default = "us-east-1b"
}
*/
