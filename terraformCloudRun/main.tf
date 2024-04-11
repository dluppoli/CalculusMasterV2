module "vpc" {
  source = "./vpc"

  project = var.project
  region = var.region
  zone = var.zone
}

module "sqlvm" {
  source = "./vm"

  project = var.project
  region = var.region
  zone = var.zone

  vm_name = "dbserver"
  vpc_name = module.vpc.vpc_name
  startupscripturl = var.startupscripturl_mysql
}

module "neg" {
  source = "./cloudrunneg"

  project = var.project
  region = var.region
  zone = var.zone

  vpc_name = module.vpc.vpc_name

  container_image = var.container_image

  APP_PORT = var.APP_PORT
  DB_HOST = module.sqlvm.private_ip_address
  DB = var.DB
  DB_PASSWORD = var.DB_PASSWORD
  DB_USER = var.DB_USER 
  SESSION_SECRET = var.SESSION_SECRET
}

module "lb" {
  source = "./cloudrunlb"

  project = var.project
  region = var.region
  zone = var.zone

  network_endpoint_group = module.neg.neg_id
}