variable "custom_vpc" {
  description = "vpc to test alb"
  type        = string
  default     = "10.0.0.0/16"

}

variable "instance_tenancy" {
  description = "it defines the tenancy of VPC. Whether it's defsult or dedicated "
  type        = string
  default     = "default"

}

variable "ami_id" {
  description = "ami_id"
  type        = string
  default     = "ami-09208e69ff3feb1db"

}


variable "instance_type" {
  description = "size of ec2"
  type        = string
  default     = "t2.micro"

}

variable "ssh_pr_key" {
  description = "pem file of Keypair we used to login to EC2 instances"
  type        = string
  default     = "./Keypair-01.pem"
}

