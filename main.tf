#The below syntax is for cloud provider 

provider "google" {
  credentials = file("test-project-409715-4b55e5b6712c.json>")
  project     = "test-project-409715"
  region      = "us-east4" 
}

#The below syntax is for the creation of the VPC with 2 private subnets 

resource "google_compute_network" "my_vpc" {
  name        = "my-custom-test-vpc"
  description = "The created VPC is for testing"
  project = "test-project-409715"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet_1" {
  name          = "test-private-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east4"
  network       = google_compute_network.my_vpc.self_link

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.7
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private_subnet_2" {
  name          = "test-private-subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east4"
  network       = google_compute_network.my_vpc.self_link

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.7
    metadata             = "INCLUDE_ALL_METADATA"
  }
}


# The below syntax is for the creation of the route and NAT
resource "google_compute_router" "my_router" {
  name    = "my-test-router"
  network = google_compute_network.my_vpc.self_link
}

resource "google_compute_router_nat" "my_nat" {
  name   = "my-nat-config"
  router = google_compute_router.my_router.name

  source_subnetwork_ip_ranges_to_nat = [
    google_compute_subnetwork.private_subnet_1.ip_cidr_range,
    google_compute_subnetwork.private_subnet_2.ip_cidr_range,
  ]
  nat_ip_allocate_option = "AUTO_ONLY"
}


resource "google_compute_route" "nat_route" {
  name              = "nat-route"
  network           = google_compute_network.my_vpc.self_link
  dest_range        = "0.0.0.0/0"
  next_hop_gateway  = google_compute_router.my_router.self_link
}

# The below syntax is for the creation of the firewall rules 

resource "google_compute_firewall" "example_firewall" {
  name    = "my-test-firewall"
  network = "my-custom-test-vpc"  

  allow {
    protocol = "tcp"
    ports    = ["8080", "7687", "5006", "8787", "5433", "7474"]
  }

  source_ranges = ["0.0.0.0/0"]  # Considering Allow traffic from any source,
}



