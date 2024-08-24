# Импорт функции логирования
. "$PSScriptRoot\Logging.ps1"

function Invoke-DnsAction {
    param (
        [string]$Action,
        [hashtable]$Parameters,
        [scriptblock]$ActionScript
    )

    $ipAddress = $Request.UserHostAddress
    $user = $env:USERNAME
    $response = ""

    try {
        $response = & $ActionScript
        return $response
    } catch {
        $response = $_.Exception.Message
        throw $response
    } finally {
        Write-Log -Action $Action -IpAddress $ipAddress -User $user -Parameters $Parameters -Response $response
    }
}

function Get-DnsRecord {
    param (
        [string]$Zone,
        [string]$Name
    )

    Invoke-DnsAction -Action "Get-DnsRecord" -Parameters @{ Zone = $Zone; Name = $Name } -ActionScript {
        Import-Module DnsServer
        $dnsRecord = Get-DnsServerResourceRecord -Name $Name -ZoneName $Zone -ComputerName "localhost"
        if ($dnsRecord) {
            return $dnsRecord | Select-Object -Property Name, RecordType, RecordClass, Timestamp | ConvertTo-Json
        } else {
            return "DNS record not found."
        }
    }
}

function New-DnsRecord {
    param (
        [string]$Zone,
        [string]$Name,
        [string]$RecordType,
        [string]$Value,
        [int]$TTL
    )

    Invoke-DnsAction -Action "New-DnsRecord" -Parameters @{ Zone = $Zone; Name = $Name; RecordType = $RecordType; Value = $Value; TTL = $TTL } -ActionScript {
        Import-Module DnsServer
        Add-DnsServerResourceRecordA -Name $Name -ZoneName $Zone -IPv4Address $Value -TimeToLive $TTL -ComputerName "localhost"
        return "DNS record created successfully."
    }
}

function Set-DnsRecord {
    param (
        [string]$Zone,
        [string]$Name,
        [string]$RecordType,
        [string]$Value,
        [int]$TTL
    )

    Invoke-DnsAction -Action "Set-DnsRecord" -Parameters @{ Zone = $Zone; Name = $Name; RecordType = $RecordType; Value = $Value; TTL = $TTL } -ActionScript {
        Import-Module DnsServer
        $record = Get-DnsServerResourceRecord -Name $Name -ZoneName $Zone -ComputerName "localhost"
        if ($record) {
            Remove-DnsServerResourceRecord -Name $Name -ZoneName $Zone -RecordType $RecordType -ComputerName "localhost"
            Add-DnsServerResourceRecordA -Name $Name -ZoneName $Zone -IPv4Address $Value -TimeToLive $TTL -ComputerName "localhost"
            return "DNS record updated successfully."
        } else {
            return "DNS record not found for update."
        }
    }
}

function Remove-DnsRecord {
    param (
        [string]$Zone,
        [string]$Name
    )

    Invoke-DnsAction -Action "Remove-DnsRecord" -Parameters @{ Zone = $Zone; Name = $Name } -ActionScript {
        Import-Module DnsServer
        $record = Get-DnsServerResourceRecord -Name $Name -ZoneName $Zone -ComputerName "localhost"
        if ($record) {
            Remove-DnsServerResourceRecord -Name $Name -ZoneName $Zone -RecordType $record.RecordType -ComputerName "localhost"
            return "DNS record removed successfully."
        } else {
            return "DNS record not found for deletion."
        }
    }
}
