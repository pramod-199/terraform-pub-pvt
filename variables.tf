variable "aws_vpc_cidr_block" {
  description = "value for the cidr block"
  type        = string
}

variable "aws_subnet1_cidr_block" {
  description = " value for the subnet1 cidr block"
  type        = string

}

variable "aws_subnet2_cidr_block" {
  description = " value for the subnet1 cidr block"
  type        = string

}

variable "allowed_ports" {
  description = "value for the ingress security group"
  type        = list(number)

}

variable "aws_instance_ami" {
  description = " value for the ami "
  type        = string

}

variable "aws_instance_type" {
  description = " value for the instance type"
  type        = string

}