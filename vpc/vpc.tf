module "vpc" {
source         = "git::https://github.com/raghurohan/terraform-vpc-child-module.git?ref=main"  
  vpc_name       = var.vpc_name
  vpc_cidr       = var.vpc_cidr
  project        = var.project
  environment    = var.environment
  public_cidr   = var.public_cidr
  private_cidr  = var.private_cidr
  is_peering_required = var.is_peering_required
}
