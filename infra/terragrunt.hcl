terraform {
    source = "./lazy_module"
}

locals  {
    region = "europe-central2"
    project_id = get_env("TF_VAR_project_id")
}

inputs = {
    region = local.region
}

remote_state {
    backend = "gcs"
    generate = {
        path = "_backend.tf"
        if_exists = "overwrite"
    }

    config = {
        bucket = "backend-random-bucket"
        prefix = "${path_relative_to_include()}/terraform.tfstate"
        project = local.project_id
        location = local.region
    }
}

generate "myconfig" {
    path = "_conf.tf"
    if_exists = "overwrite"

    contents = <<EOF
    provider "google" {
  project = var.project_id
  region  = var.region
}
EOF
}