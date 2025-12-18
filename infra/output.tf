output "privat-Ips" {
  description = "ip adresses for ansible? "
  value = [for instance in google_compute_instance.vm_for_databases[*]: instance.network_interface[0].network_ip]  
  #google_compute_instance.vm_for_databases[*].network_interface[*].network_ip
}

output "key-for-artifact-registry" {
  description = "key for artifact registry access from pods"
  #value = google_service_account_key.registry-access-key.private_key
  value = "key is stored in file)))"
}
resource "local_file" "private-key-for-registry" {
  content = google_service_account_key.registry-access-key.private_key
  filename = "./private-key.json" 
}