terraform {
  backend "gcs" {
    bucket      = "playground-276313-tf-state"
    credentials = "service-account.json"
    prefix      = "terraform/state"
  }
}

provider "google" {
  credentials = file("service-account.json")
  project     = var.project
  region      = var.region
  version     = "~> 3.8"
}

resource "google_container_cluster" "cluster-0" {
  name     = "cluster-0"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  monitoring_service = none
}

resource "google_container_node_pool" "cluster-0_preemptible_nodes" {
  name       = "primary"
  location   = var.region
  cluster    = google_container_cluster.cluster-0.name
  node_count = var.node_pool.node_count

  node_config {
    preemptible  = var.node_pool.node_config.preemptible
    machine_type = var.node_pool.node_config.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
