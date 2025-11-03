variable "project_prefix" {
  description = "Prefix for names/tags"
  type        = string
  default     = "kowshal-opl"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project = "OshawaLibrary"
    Owner   = "Kowshal"
    Env     = "dev"
  }
}
