variable "ami" {
  type    = "map"
  default = {}

}

variable "instance_type" {
  default = "t2.micro"

}

variable "region" {
  description = " AWS region."
}

variable "instance_ips" {
  type        = "list"
  description = "The IPs to use for our instances"
  default     = ["10.0.1.20", "10.0.1.21"]

}

variable "azs" {
  default = "us-east-1a"
}

