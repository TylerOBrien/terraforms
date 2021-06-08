/*
|--------------------------------------------------------------------------
| AMIs
|--------------------------------------------------------------------------
*/

variable "aws_amis" {
  type = map(string)
  default = {
    "ubuntu-20.04-x86"   = "ami-00399ec92321828f5",
    "debian-10-x86"      = "ami-089fe97bc00bff7cc",
    "amazon-linux-2-x86" = "ami-077e31c4939f6a2f3",
    "rhel-8-x86"         = "ami-0ba62214afa52bec7"
  }
}

/*
|--------------------------------------------------------------------------
| Settings
|--------------------------------------------------------------------------
*/

variable "name_prefix" {
  type    = string
  default = "dev"
}

/*
|--------------------------------------------------------------------------
| VPC
|--------------------------------------------------------------------------
*/

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "map_public_ip_on_launch" {
  type    = bool
  default = true
}

/*
|--------------------------------------------------------------------------
| EC2
|--------------------------------------------------------------------------
*/

variable "api_arch" {
  type    = string
  default = "x86"
}

variable "api_system" {
  type    = string
  default = "ubuntu-20.04"
}

variable "bastion_arch" {
  type    = string
  default = "x86"
}

variable "bastion_system" {
  type    = string
  default = "ubuntu-20.04"
}

/*
|--------------------------------------------------------------------------
| RDS
|--------------------------------------------------------------------------
*/

variable "db_name" {
  type        = string
  description = "The name of the initial database to be created on RDS."
}

variable "db_username" {
  type        = string
  description = "Username for the RDS database instance."
}

variable "db_password" {
  type        = string
  description = "Password for the RDS database instance."
}
