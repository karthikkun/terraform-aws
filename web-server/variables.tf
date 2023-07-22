
variable "region" {
  description = "Default region for provider"
  type        = string
  default     = "us-east-1"
}

variable "instance_tag" {
    description = "Tag Name of an ec2 instance"
    type = string
    default = "web-sandbox"
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
}