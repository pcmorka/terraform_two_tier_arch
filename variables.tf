#The variables file defines the input variables for our infrastructure.
variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "wk22project_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "az1a" {
  description = "First public and private subnets Availability Zone(AZ)"
  type        = string
  default     = "us-east-1a"
}

variable "az1b" {
  description = "Second public and private subnets Availability Zone(AZ)"
  type        = string
  default     = "us-east-1b"
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