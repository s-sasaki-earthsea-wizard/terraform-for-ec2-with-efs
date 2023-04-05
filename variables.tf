variable "aws_access_key" {
  description = "The AWS access key to use for creating resources"
}

variable "aws_secret_key" {
  description = "The AWS secret key to use for creating resources"
}

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in."
  default     = "ap-northeast-1"
}

variable "az_list" {
  description = "The list of availability zone suffixes."
  default     = ["a", "c", "d"]
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_subnet_cidr_block" {
  description = "The CIDR block for the bastion subnet"
  type        = string
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to create resources in"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "instance_count" {
  type        = number
  description = "The number of EC2 instances to create"
}

variable "ami_id" {
  type        = string
  description = "The ID of the Amazon Machine Image (AMI) to use for the EC2 instances"
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instances to create"
}

variable "key_name" {
  type        = string
  description = "The name of the key pair to use for SSH access"
}
