locals {
  # list of dedicated service accounts used by the tenant nodepools
  list_tenant_nodepool_sa = [
    for sa in google_service_account.tenant_nodepool_sa: sa.email
  ]
}

// deny all egress from the FL node pool
resource "google_compute_firewall" "tenantpool-deny-egress" {
  name          = "tenantpool-deny-egress"
  description   = "Default deny egress from tenant nodepool" 
  project       = var.project_id
  network       = google_compute_network.vpc.name
  direction     = "EGRESS"
  target_service_accounts = local.list_tenant_nodepool_sa
  deny {
    protocol = "all"
  }
  priority = 65535
}

resource "google_compute_firewall" "tenantpool-allow-egress-nodes-pods-services" {
  name          = "tenantpool-allow-egress-nodes-pods-services"
  description   = "Allow egress from tenant nodepool to cluster nodes, pods and services" 
  project       = var.project_id
  network       = google_compute_network.vpc.name
  direction     = "EGRESS"
  target_service_accounts = local.list_tenant_nodepool_sa
  destination_ranges = [google_compute_subnetwork.subnet.ip_cidr_range, "10.20.0.0/14", "10.24.0.0/20"]
  allow {
    protocol = "all"
  }
  priority = 1000
}

resource "google_compute_firewall" "tenantpool-allow-egress-api-server" {
  name          = "tenantpool-allow-egress-api-server"
  description   = "Allow egress from node pool to the Kubernetes API server" 
  project       = var.project_id
  network       = google_compute_network.vpc.name
  direction     = "EGRESS"
  target_service_accounts = local.list_tenant_nodepool_sa
  destination_ranges = [var.master_ipv4_cidr_block]
  allow {
    protocol = "tcp"
    ports = [443, 10250]
  }
  priority = 1000
}

resource "google_compute_firewall" "tenantpool-allow-egress-google-apis" {
  name          = "tenantpool-allow-egress-google-apis"
  description   = "Allow egress from tenant nodepool to Google APIs (private Google access)" 
  project       = var.project_id
  network       = google_compute_network.vpc.name
  direction     = "EGRESS"
  target_service_accounts = local.list_tenant_nodepool_sa
  destination_ranges = ["199.36.153.8/30"]
  allow {
    protocol = "tcp"
  }
  priority = 1000
}

// Dev / Testing
// Allow ssh tunnel-through-iap to all cluster nodes
resource "google_compute_firewall" "allow-ssh-tunnel-iap" {
  name          = "allow-ssh-tunnel-iap"
  project       = var.project_id
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["gke-${var.cluster_name}"]
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  priority = 1000
}
