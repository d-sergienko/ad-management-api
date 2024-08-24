# Импорт функции логирования
. "$PSScriptRoot\Logging.ps1"

function Invoke-CertAction {
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

function Get-Certificate {
    param (
        [string]$TemplateName,
        [string]$SubjectName
    )

    Invoke-CertAction -Action "Get-Certificate" -Parameters @{ TemplateName = $TemplateName; SubjectName = $SubjectName } -ActionScript {
        Import-Module ActiveDirectory
        $certificates = Get-ADCertificate -Filter "CertificateTemplateName -eq '$TemplateName' -and Subject -eq '$SubjectName'"
        if ($certificates) {
            return $certificates | Select-Object -Property Subject, CertificateTemplate, NotBefore, NotAfter | ConvertTo-Json
        } else {
            return "Certificate not found."
        }
    }
}

function New-Certificate {
    param (
        [string]$TemplateName,
        [string]$SubjectName
    )

    Invoke-CertAction -Action "New-Certificate" -Parameters @{ TemplateName = $TemplateName; SubjectName = $SubjectName } -ActionScript {
        Import-Module ActiveDirectory
        $certRequest = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
        $certRequest.InitializeFromTemplateName(0, $TemplateName)
        $certRequest.Subject = $SubjectName
        $certRequest.Encode()
        $certRequest.CreateRequest()
        return "Certificate created successfully."
    }
}

function Set-Certificate {
    param (
        [string]$TemplateName,
        [string]$SubjectName
    )

    Invoke-CertAction -Action "Set-Certificate" -Parameters @{ TemplateName = $TemplateName; SubjectName = $SubjectName } -ActionScript {
        Import-Module ActiveDirectory
        $certificates = Get-ADCertificate -Filter "CertificateTemplateName -eq '$TemplateName' -and Subject -eq '$SubjectName'"
        if ($certificates) {
            $certRequest = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
            $certRequest.InitializeFromTemplateName(0, $TemplateName)
            $certRequest.Subject = $SubjectName
            $certRequest.Encode()
            $certRequest.CreateRequest()
            return "Certificate updated successfully."
        } else {
            return "Certificate not found for update."
        }
    }
}

function Remove-Certificate {
    param (
        [string]$TemplateName,
        [string]$SubjectName
    )

    Invoke-CertAction -Action "Remove-Certificate" -Parameters @{ TemplateName = $TemplateName; SubjectName = $SubjectName } -ActionScript {
        Import-Module ActiveDirectory
        $certificates = Get-ADCertificate -Filter "CertificateTemplateName -eq '$TemplateName' -and Subject -eq '$SubjectName'"
        if ($certificates) {
            Remove-ADCertificate -Filter "CertificateTemplateName -eq '$TemplateName' -and Subject -eq '$SubjectName'"
            return "Certificate removed successfully."
        } else {
            return "Certificate not found for deletion."
        }
    }
}
