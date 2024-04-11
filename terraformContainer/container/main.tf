module "gce-advanced-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 3.0"

  container = {
    image = var.container_image
    env = var.env
  }

  restart_policy = "OnFailure"
}