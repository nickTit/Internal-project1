#
#
#resource "google_container_cluster" "GKE" {
#  name = "main-k8s-cluster"
#  location = "${var.region}-a"
#  remove_default_node_pool = true
#  initial_node_count = 1
#  network = google_compute_network.main_vpc_network.self_link
#  subnetwork = google_compute_subnetwork.private_subnetworks[var.access_requiring_subnets[0]].name
#
#  networking_mode = "VPC_NATIVE"
#  deletion_protection = false
#
#  ip_allocation_policy {
#    #cluster_ipv4_cidr_block = google_compute_subnetwork.private_subnetworks["subnet-gke-pods"].ip_cidr_range
#    cluster_secondary_range_name = google_compute_subnetwork.private_subnetworks["subnet-gke-nodes"].secondary_ip_range[0].range_name
#    services_secondary_range_name = google_compute_subnetwork.private_subnetworks["subnet-gke-nodes"].secondary_ip_range[1].range_name  
#    #services_ipv4_cidr_block = google_compute_subnetwork.private_subnetworks["subnet-gke-services"].ip_cidr_range  
#  }
#
#  release_channel {
#    channel = "REGULAR"#зачем это?
#  }
#  workload_identity_config {
#    workload_pool = "${var.project_id}.svc.id.goog"#зачем это?
#  }
#
#  private_cluster_config {
#    enable_private_endpoint = false
#    enable_private_nodes = true
#    master_ipv4_cidr_block = "192.168.0.0/28"
#  } 
#
#  
#}
#
## resource "google_service_account" "account-k8s" {
##   account_id = "prod-GKE"
## }
#
## resource "google_project_iam_member" "gke_metrics" {
##   member = "serviceAccount:${google.service_account.account-k8s.email}"
##   role = "roles/monitoring.metricsWriter"
##   project = var.project_id
## }# нужно ли это вообще
#
#resource "google_container_node_pool" "main-nodepool" {
#    name = "main-nodepoooool"
#    cluster = google_container_cluster.GKE.id
#  
#
#    autoscaling {
#      total_max_node_count = 1
#      total_min_node_count = 1
#    }
#
#    node_config {
#    machine_type = "e2-medium"
#      labels = {
#        pod = "gke-pod"
#      }
#    oauth_scopes = [
#      "https://www.googleapis.com/auth/cloud-platform"
#    ]
#    }
#
#    
#}
#