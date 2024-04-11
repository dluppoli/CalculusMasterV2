resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = "appserverneg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.default.name
  }
}

resource "google_cloud_run_v2_service" "default" {
  name     = "appservercloudrun-service"
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA"
  
  template {
    containers {
      image = var.container_image

      ports {
        container_port = var.APP_PORT
      }
      env {
        name = "DB"
        value = var.DB
      }
      env {
        name = "DB_HOST"
        value = var.DB_HOST
      }
      env {
        name = "DB_USER"
        value = var.DB_USER
      }
      env {
        name = "DB_PASSWORD"
        value = var.DB_PASSWORD
      }
      env {
        name = "SESSION_SECRET"
        value = var.SESSION_SECRET
      }
    }

    vpc_access{
      network_interfaces {
        network = var.vpc_name
      }
      egress = "ALL_TRAFFIC"
    }
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = google_cloud_run_v2_service.default.location
  service  = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}