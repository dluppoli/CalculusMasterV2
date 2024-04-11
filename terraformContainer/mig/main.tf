resource "google_compute_instance_template" "default" {
    name_prefix         = "appservertemplate"
    machine_type = "e2-micro"
    tags = ["web"]

    disk {
      auto_delete  = true
      boot         = true
      device_name  = "persistent-disk-0"
      mode         = "READ_WRITE"
      source_image = "cos-cloud/cos-stable"
      type         = "PERSISTENT"
    }

    scheduling {
      provisioning_model = "SPOT"
      automatic_restart = false
      preemptible = true
    }

    network_interface {
        network = var.vpc_name
        access_config {}
    }

    metadata = {
         gce-container-declaration = var.container_metadata
    }

    service_account {
        scopes = ["cloud-platform"]
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "google_compute_instance_group_manager" "default" {
  name = "appservermig"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  base_instance_name = "appserver"
}

resource "google_compute_autoscaler" "default" {
  name   = "appservermig-autoscaler"
  target = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 1
    cooldown_period = 90

    cpu_utilization {
      target = 0.60
    }
  }
}

