module "vpc" {
  source = "./vpc"

  project = var.project
  region = var.region
  zone = var.zone
}

module "sql" {
  source = "./database"
  
  project = var.project
  region = var.region
  zone = var.zone

  root_password = var.db_root_password
}

module "mig" {
  source = "./mig"

  project = var.project
  region = var.region
  zone = var.zone

  vpc_name = module.vpc.vpc_name
  startupscripturl = var.startupscripturl
  db_ip = module.sql.db_address
}

module "lb" {
  source = "./lb"

  project = var.project
  region = var.region
  zone = var.zone

  instance_group = module.mig.instance_group
}




