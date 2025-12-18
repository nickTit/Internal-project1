resource "google_compute_network" "main_vpc_network" {
  name                    = "project-vpc-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "private_subnetworks" {
  for_each      = var.private_subnetwokr_names #3 
  name          = each.key
  ip_cidr_range = each.value.cidr_range
  region        = var.region
  network       = google_compute_network.main_vpc_network.id
  
  secondary_ip_range {
    range_name    = "second-range-k8s-pods-${each.key}"
    ip_cidr_range = each.value.secondary_cidr_range_pods
  }
  secondary_ip_range {
    range_name    = "second-range-k8s-services-${each.key}"
    ip_cidr_range = each.value.secondary_cidr_range_services
  }
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = var.region
  network = google_compute_network.main_vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name   = "my-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = var.access_requiring_subnets
    
    content {
      name                    = google_compute_subnetwork.private_subnetworks[subnetwork.value].self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  endpoint_types = ["ENDPOINT_TYPE_VM"]
  min_ports_per_vm = 64
}

resource "google_artifact_registry_repository" "my-repo" {
  location      = var.region
  repository_id = "project-repo"
  description   = "project docker repository"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }
  cleanup_policies {
    id     = "cleanup-policy-1-tst"
    action = "DELETE"
    condition {
      tag_state = "TAGGED"
    }
  }

}

resource "google_compute_instance" "vm_for_databases" {
  count = length(var.instances)

  name         = var.instances[count.index]
  machine_type = "e2-medium"
  zone         = "europe-central2-a"

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnetworks["subnet-vms-db"].self_link
    # access_config {
    #   nat_ip = "10.202.32.53"
    # }
  }

  tags = ["database"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2404-noble-amd64-v20251121"
      labels = {
        my_label = "value"
      }
    }
  } #10 gb

  // Local SSD disk
  # scratch_disk {
  #   interface = "NVME"
  # }

  metadata = {
    ssh-keys = "ansible-user:${file("~/.ssh/final_task.pub")}" #тока юзера указывать -  ansible-user
  }

}

resource "google_compute_firewall" "firewall-database" {
  name    = "firewall-database-ingress"
  network = google_compute_network.main_vpc_network.name

  source_tags = ["database"]
  target_tags = ["database"]

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
}
# resource "google_compute_firewall" "firewall-database-2" {
#   name    = "firewall-database-egress"
#   network = google_compute_network.main_vpc_network.name
#   #source_tags = ["database"]
#   target_tags = ["database"]

#   direction = "EGRESS"
#   allow {
#     protocol = "tcp"
#     ports    = ["5432"]
#   }
# }

resource "google_compute_firewall" "firewall-runner" {
  name    = "firewall-runner"
  network = google_compute_network.main_vpc_network.name

  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["database"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "firewall-kuber-database" {
  name    = "firewall-kuber-database"
  network = google_compute_network.main_vpc_network.name

  #source_ranges = ["${var.private_subnetwokr_names["subnet-gke-pods"].cidr_range}"] #указать это для subnet-gke-pods
  source_ranges = [google_compute_subnetwork.private_subnetworks["subnet-gke-nodes"].secondary_ip_range[0].ip_cidr_range] #указать это для subnet-gke-pods
  
  target_tags   = ["database"]

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
}

resource "google_compute_firewall" "allow-ingress-from-iap" {
  name    = "allow-ingress-from-iap"
  network = google_compute_network.main_vpc_network.name

  source_ranges = ["35.235.240.0/20"]
  
  allow {
    protocol = "tcp"
  }
}




resource "google_project_iam_member" "access-iap" {
  project = var.project_id
  role = "roles/iap.tunnelResourceAccessor"
  member = "serviceAccount:${google_service_account.iap-sa.email}"
}


resource "google_service_account" "iap-sa" {
  account_id   = "iap-account"
  display_name = "A service account for iap"
}

resource "google_service_account" "registry-sa" {
  account_id   = "artifact-registry-account"
  display_name = "A service account for artifact registry access"
}

resource "google_project_iam_member" "registry-iam" {
  project = var.project_id
  role = "roles/artifactregistry.createOnPushWriter"
  member = "serviceAccount:${google_service_account.registry-sa.email}"
}

resource "google_service_account_key" "registry-access-key" {
  service_account_id = google_service_account.registry-sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
