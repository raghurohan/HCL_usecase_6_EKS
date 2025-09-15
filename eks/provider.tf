terraform {
  required_providers {
    aws = {                     #provider name      
      source  = "hashicorp/aws" #source of provider
      version = "~>6.0"        #version of provider
    }
  }
  backend "s3" { #backend info should always be in terraform block
    bucket         = "remotestate11"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1" # region of bucket
    use_lockfile = true     #s3 by default supports locking but to be explicit
    encrypt       = true
    }
}

# here we configure AWS provider
provider "aws" {
  #configuration options
  region = "us-east-1"
}

