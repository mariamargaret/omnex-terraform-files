variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "Subnet_CIDR1" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.1.4.0/24"
}

#variable "Subnet_CIDR2" {
#  description = "The CIDR block for the private subnet"
#  type        = string
#  default     = "10.1.1.0/24"
#}

variable "Subnet_CIDR3" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.1.3.0/24"
}


variable "Subnet_CIDR4" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.1.2.0/24"
}


variable "Subnet_CIDR5" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.1.5.0/24"
}


variable "Subnet_CIDR6" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.1.6.0/24"
}



variable "Subnet_CIDR7" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.1.7.0/24"
}

#variable "region" {
#  description = "The AWS region to deploy to"
#  type        = string
#  default     = "us-east-2"
#}


# Variable for AMI ID
variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Replace with your AMI ID
}

# Variable for key pair name
variable "key_name" {
  description = "The name of the key pair to use for SSH access to the instance"
  type        = string
  default     = "omnex-test" # Replace with your key pair name
}
