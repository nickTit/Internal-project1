output "privat-Ips" {
  description = "ip adresses for ansible? "
  value = [for instance in google_compute_instance.vm_for_databases[*]: instance.network_interface[0].network_ip]  
  #google_compute_instance.vm_for_databases[*].network_interface[*].network_ip
}