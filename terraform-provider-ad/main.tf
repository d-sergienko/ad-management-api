terraform {
  required_providers {
    ad = {
      source = "github.com/yourusername/terraform-provider-ad"
      version = "~> 1.0"
    }
  }
}

provider "ad" {
  base_url = "http://ad-management-api"
}

resource "ad_dns_record" "example" {
  zone        = "example.com"
  name        = "test"
  record_type  = "A"
  value       = "192.168.1.1"
  ttl         = 3600
}

resource "ad_certificate" "example" {
  template_name = "WebServerTemplate"
  subject_name  = "CN=example.com"
}
