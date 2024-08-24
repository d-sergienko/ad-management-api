# Terraform Provider for AD Management

## Overview

This Terraform provider allows management of DNS records and certificates within an Active Directory environment via the AD Management API.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- Access to the AD Management API hosted in your environment.

## Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/terraform-provider-ad.git
   cd terraform-provider-ad
```

2. **Build the Provider**
```bash
go mod tidy
go build -o terraform-provider-ad
```

3. **Install the Provider**
Copy the built binary to your Terraform plugins directory or use it directly in your Terraform configuration.

4. **Configure the Provider**
In your Terraform configuration file (main.tf), add the provider block:

```hcl
terraform {
  required_providers {
    ad = {
      source = "yourusername/ad"
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
```

## Resources

`ad_dns_record`
- create: Create a DNS record.
- read: Read a DNS record.
- update: Update a DNS record.
- delete: Delete a DNS record.

Example:
```hcl
resource "ad_dns_record" "example" {
  zone        = "example.com"
  name        = "test"
  record_type  = "A"
  value       = "192.168.1.1"
  ttl         = 3600
}
```

`ad_certificate`
- create: Create a certificate.
- read: Read a certificate.
- update: Update a certificate.
- delete: Delete a certificate.

```hcl
resource "ad_certificate" "example" {
  template_name = "WebServerTemplate"
  subject_name  = "CN=example.com"
}
```

## Running Tests
To run tests for the provider, ensure you have Go installed and run:

```bash
go test -v ./...
```
