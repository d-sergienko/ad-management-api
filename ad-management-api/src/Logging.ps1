function Write-Log {
    param (
        [string]$Action,
        [string]$IpAddress,
        [string]$User,
        [hashtable]$Parameters,
        [string]$Response
    )

    $logFilePath = "C:\Logs\ADManagementAPI.log"

    # Создание директории, если не существует
    if (-not (Test-Path (Split-Path $logFilePath))) {
        New-Item -ItemType Directory -Path (Split-Path $logFilePath) | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $paramString = $Parameters.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" } | Out-String
    $logEntry = "$timestamp - Action: $Action - IP: $IpAddress - User: $User - Parameters: $paramString - Response: $Response"
    Add-Content -Path $logFilePath -Value $logEntry
}
