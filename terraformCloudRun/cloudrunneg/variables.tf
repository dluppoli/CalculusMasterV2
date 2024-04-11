variable "project" { }

variable "region" {
  default = "us-central1"
}

variable "zone" {
    default = "us-central1-a"
}

variable "vpc_name" { }

variable "APP_PORT" { }

variable "DB_HOST" { }
variable "DB_USER" { }
variable "DB_PASSWORD" { }
variable "DB" { }

variable "SESSION_SECRET" { }

variable "container_image" { }