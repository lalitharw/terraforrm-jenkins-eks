module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  subnets              = var.subnets
  sg_id                = module.sg.vpc_security_group_ids
  enable_dns_hostnames = var.enable_dns_hostnames
}

module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}