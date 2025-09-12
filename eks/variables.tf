variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "usecase6"
        Terraform = "true"
        Environment = "dev"
    }
}