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

module "mig" {
  source = "./mig"

  project = var.project
  region = var.region
  zone = var.zone

  vpc_name = module.vpc.vpc_name
  container_metadata = module.container.metadata
}

module "lb" {
  source = "./lb"

  project = var.project
  region = var.region
  zone = var.zone

  instance_group = module.mig.instance_group
}

module "container" {
  source = "./container"
  container_image = var.container_image

  env = [
      {
        name  = "PORT"
        value = var.APP_PORT
      },
      {
        name  = "DB_HOST"
        value = module.sqlvm.private_ip_address
      },
      {
        name  = "DB_USER"
        value = var.DB_USER
      },
      {
        name  = "DB_PASSWORD"
        value = var.DB_PASSWORD
      },
      {
        name  = "DB"
        value = var.DB
      },
      {
        name = "SESSION_SECRET"
        value = var.SESSION_SECRET
      }
    ]
}