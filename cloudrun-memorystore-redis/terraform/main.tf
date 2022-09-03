terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.34.0"
    }
  }
}

variable "project_id" {}

provider "google" {
  project = var.project_id
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "redis" {
  service = "redis.googleapis.com"
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "servicenetworking" {
  service = "servicenetworking.googleapis.com"
}

resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
}


/******************************
Networking
******************************/

resource "google_compute_network" "myapp-vpc" {
  name                    = "myapp-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "myapp-asia-northeast1" {
  name          = "asia-northeast1"
  ip_cidr_range = "10.146.0.0/20"
  network       = google_compute_network.myapp-vpc.id
  region        = "asia-northeast1"
}

resource "google_vpc_access_connector" "myapp-connector" {
  name          = "myapp-connector"
  ip_cidr_range = "10.8.0.0/28"
  region        = "asia-northeast1"
  network       = google_compute_network.myapp-vpc.id

  depends_on = [google_project_service.vpcaccess]
}


/******************************
Networking (Private Service Access)
https://cloud.google.com/vpc/docs/private-services-access
******************************/

resource "google_compute_global_address" "google-psa-range" {
  name          = "google-psa-range"
  prefix_length = 16
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.myapp-vpc.id
}

resource "google_service_networking_connection" "servicenetworking" {
  network                 = google_compute_network.myapp-vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google-psa-range.name]

  depends_on = [google_project_service.servicenetworking]
}


/******************************
Service Account for Cloud Run service
******************************/

resource "google_service_account" "myapp-sa" {
  account_id = "myapp-sa"
}


/******************************
Service Account for Cloud Run service
******************************/

resource "google_artifact_registry_repository" "myapp-docker" {
  location      = "asia-northeast1"
  repository_id = "myapp"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}

/******************************
Plain Redis instance (No AUTH, No TLS)
******************************/

resource "google_redis_instance" "myapp-redis-plain" {
  name               = "myapp-redis-plain"
  memory_size_gb     = 1
  authorized_network = google_compute_network.myapp-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  location_id        = "asia-northeast1-a"
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  region             = "asia-northeast1"

  auth_enabled            = false
  transit_encryption_mode = "DISABLED"

  depends_on = [
    google_project_service.redis,
    google_service_networking_connection.servicenetworking,
  ]
}

resource "google_secret_manager_secret" "myapp-redis-plain-host" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-plain-host"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-plain-host" {
  secret      = google_secret_manager_secret.myapp-redis-plain-host.id
  secret_data = google_redis_instance.myapp-redis-plain.host
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-plain-host_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-plain-host.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}


/******************************
Redis instance with AUTH
******************************/

resource "google_redis_instance" "myapp-redis-auth" {
  name               = "myapp-redis-auth"
  memory_size_gb     = 1
  authorized_network = google_compute_network.myapp-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  region             = "asia-northeast1"

  auth_enabled            = true
  transit_encryption_mode = "DISABLED"

  depends_on = [
    google_project_service.redis,
    google_service_networking_connection.servicenetworking,
  ]
}

resource "google_secret_manager_secret" "myapp-redis-auth-host" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-auth-host"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-auth-host" {
  secret      = google_secret_manager_secret.myapp-redis-auth-host.id
  secret_data = google_redis_instance.myapp-redis-auth.host
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-auth-host_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-auth-host.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}

resource "google_secret_manager_secret" "myapp-redis-auth-authstring" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-auth-authstring"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-auth-authstring" {
  secret      = google_secret_manager_secret.myapp-redis-auth-authstring.id
  secret_data = google_redis_instance.myapp-redis-auth.auth_string
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-auth-authstring_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-auth-authstring.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}


/******************************
Redis instance with TLS
******************************/

resource "google_redis_instance" "myapp-redis-tls" {
  name               = "myapp-redis-tls"
  memory_size_gb     = 1
  authorized_network = google_compute_network.myapp-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  region             = "asia-northeast1"

  auth_enabled            = false
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  depends_on = [
    google_project_service.redis,
    google_service_networking_connection.servicenetworking,
  ]
}

resource "google_secret_manager_secret" "myapp-redis-tls-host" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-tls-host"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-tls-host" {
  secret      = google_secret_manager_secret.myapp-redis-tls-host.id
  secret_data = google_redis_instance.myapp-redis-tls.host
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-tls-host_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-tls-host.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}

resource "google_secret_manager_secret" "myapp-redis-tls-cert" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-tls-cert"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-tls-cert" {
  secret      = google_secret_manager_secret.myapp-redis-tls-cert.id
  secret_data = google_redis_instance.myapp-redis-tls.server_ca_certs.0.cert
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-tls-cert_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-tls-cert.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}

/******************************
Redis instance with AUTH and TLS
******************************/

resource "google_redis_instance" "myapp-redis-authtls" {
  name               = "myapp-redis-authtls"
  memory_size_gb     = 1
  authorized_network = google_compute_network.myapp-vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  region             = "asia-northeast1"

  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  depends_on = [
    google_project_service.redis,
    google_service_networking_connection.servicenetworking,
  ]
}

resource "google_secret_manager_secret" "myapp-redis-authtls-host" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-authtls-host"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-authtls-host" {
  secret      = google_secret_manager_secret.myapp-redis-authtls-host.id
  secret_data = google_redis_instance.myapp-redis-authtls.host
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-authtls-host_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-authtls-host.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}

resource "google_secret_manager_secret" "myapp-redis-authtls-authstring" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-authtls-authstring"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-authtls-authstring" {
  secret      = google_secret_manager_secret.myapp-redis-authtls-authstring.id
  secret_data = google_redis_instance.myapp-redis-authtls.auth_string
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-authtls-authstring_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-authtls-authstring.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}

resource "google_secret_manager_secret" "myapp-redis-authtls-cert" {
  replication {
    automatic = true
  }
  secret_id = "myapp-redis-authtls-cert"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "myapp-redis-authtls-cert" {
  secret      = google_secret_manager_secret.myapp-redis-authtls-cert.id
  secret_data = google_redis_instance.myapp-redis-authtls.server_ca_certs.0.cert
}

resource "google_secret_manager_secret_iam_member" "myapp-redis-authtls-cert_myapp-secretAccessor" {
  secret_id = google_secret_manager_secret.myapp-redis-authtls-cert.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.myapp-sa.email}"
}
