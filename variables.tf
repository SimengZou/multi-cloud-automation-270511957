variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "microservices-architecture"
}

variable "container_port" {
  description = "Port the application runs on"
  type        = number
  default     = 3000
}

variable "github_repo" {
  description = "The GitHub repository for the CI/CD source"
  type        = string
}

variable "github_owner" {
  description = "GitHub username/org"
  type        = string
}


variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}