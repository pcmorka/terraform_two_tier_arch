variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "wk22project_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "wk22project-pub_sub" {
  default = {
    "wk22project-pub_sub_1" = 1
    "wk22project-pub_sub_2" = 2
  }
}


variable "wk22project-priv_sub" {
  default = {
    "wk22project-priv_sub_1" = 1
    "wk22project-priv_sub_2" = 2
  }
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  description = "ami id for Amazon Linux 2 Kernel"
  type        = string
  default     = "ami-09988af04120b3591"
}

variable "db_username" {
  description = "Database username for the RDS Instance"
  type        = string
  default     = "dbusername"
  sensitive   = true
}

variable "db_password" {
  description = "Database password for the RDS Instance"
  type        = string
  default     = "dbpassword"
  sensitive   = true
}

variable "key_name" {
  type    = string
  default = "key_name"
}
