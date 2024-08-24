# Active Directory Management API

## Overview

This PowerShell-based API provides management functionality for DNS records and certificates within an Active Directory environment. It includes endpoints for CRUD operations on DNS records and certificates using AD PKI.

## Prerequisites

- Windows Server with Active Directory and DNS installed.
- PowerShell with appropriate permissions to manage DNS and certificates.
- [Universal Dashboard](https://docs.ironmansoftware.com/) or another method for hosting PowerShell APIs.

## Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/ad-management-api.git
   cd ad-management-api
    ```
2. **Install Required Modules**

Ensure that the necessary PowerShell modules are installed:
```PowerShell
Install.ps1
```

3. **Configure Logging**

Update Logging.ps1 with your desired log file path and other settings.

4. **Start the API**
```PowerShell
Start-UniversalDashboard -Port 8080 -Endpoint @(
    @{
        Url = "/dns"
        Endpoint = "src/DNSManagement.ps1"
    },
    @{
        Url = "/certificates"
        Endpoint = "src/CertificateManagement.ps1"
    }
)
```
The API will be available at http://localhost:8080.

## API Endpoints
**DNS Management**
GET /dns/{zone}/{name}: Retrieve DNS record.
POST /dns/{zone}/{name}: Create DNS record.
PUT /dns/{zone}/{name}: Update DNS record.
DELETE /dns/{zone}/{name}: Remove DNS record.

**Certificate Management**
GET /certificates/{template_name}/{subject_name}: Retrieve certificate.
POST /certificates/{template_name}/{subject_name}: Create certificate.
PUT /certificates/{template_name}/{subject_name}: Update certificate.
DELETE /certificates/{template_name}/{subject_name}: Remove certificate.
**Logging**
The API logs the following information for each request:

- Date and time of the action
- IP address of the requester
- User executing the request
- Parameters of the request
- Response from the API
- Logs are stored in the file specified in Logging.ps1.

## Running Tests
1. **Install Required Modules**
Ensure that the necessary PowerShell modules are installed:

```PowerShell
Install-Module -Name PSSwagger
```
2. **Start the API** 
Ensure that your AD Management API is running and accessible.

3. **Invoke tests**
```PowerShell
Invoke-Pester -Path .\tests\
```
