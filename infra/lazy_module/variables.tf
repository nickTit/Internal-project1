variable "region" {
  type = string
  default = "europe-central2"
}
variable "project_id" {
  type = string
}

variable "access_requiring_subnets" {
  type = list(string)
  default = ["subnet-gke-nodes", "subnet-vms-db"] #бавь сюда потом все сабнеты
}

variable "private_subnetwokr_names" {
  type = map(object(
    {
      cidr_range           = string,
      secondary_cidr_range_pods = string,
      secondary_cidr_range_services = string,

    }
  ))
  default = {
    subnet-gke-nodes = {
      cidr_range           = "10.1.0.0/16",
      secondary_cidr_range_pods = "10.10.0.0/20"
      secondary_cidr_range_services = "10.20.0.0/20"
    },
    #subnet-gke-pods = {
    #  cidr_range           = "10.2.0.0/16",
    #  secondary_cidr_range = "192.168.20.0/24" #пока ставлю один адрес, будет больше подов-буду думать
    #},
    #subnet-gke-services = {
    #  cidr_range           = "10.3.0.0/16",
    #  secondary_cidr_range = "192.168.30.0/24" #пока ставлю один адрес, будет больше подов-буду думать
    #},
    subnet-vms-db = {
      cidr_range           = "10.4.0.0/16",
      secondary_cidr_range_pods = "10.40.0.0/20" #пока ставлю один адрес, будет больше подов-буду думать
      secondary_cidr_range_services = "10.50.0.0/20"
    },

  }
}


variable "instances" {
  type = list(string)
  default = ["pg-primary", "pg-standby"]
}

variable "roles-for-gke" {
  type = list(string)
  description = "two roles for access from gitlab ci to GKE cluster"
  default = ["roles/container.developer", "roles/storage.objectAdmin" ]
}