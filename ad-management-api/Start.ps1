# Импортируйте модули и настройки
Import-Module -Name ./src/DNSManagement.ps1
Import-Module -Name ./src/CertificateManagement.ps1
Import-Module -Name ./src/Logging.ps1
Import-Module -Name UniversalDashboard.Community

# Загрузите конфигурацию
. .\config.ps1

# Функция для аутентификации пользователя через AD
function Test-ADUserAuthentication {
    param (
        [string]$username,
        [System.Security.SecureString]$password
    )

    try {
        # Создаем объект PSCredential
        $credential = New-Object System.Management.Automation.PSCredential($username, $password)

        # Аутентификация пользователя через AD
        $user = Get-ADUser -Filter {SamAccountName -eq $username} -Properties PasswordLastSet
        if ($user -and $user.PasswordLastSet) {
            # Проверяем учетные данные
            $auth = Test-ADCredential -Credential $credential
            return $auth
        }
    } catch {
        Write-Log -Message "Authentication failed for user $username. Error: $_" -LogFilePath $logFilePath
        return $false
    }
}

# Функция обработки запросов
function Handle-Request {
    param (
        [System.Net.HttpListenerRequest]$Request
    )

    try {
        $username = $Request.Headers["Username"]
        $password = $Request.Headers["Password"] | ConvertTo-SecureString -AsPlainText -Force

        # Проверка аутентификации
        if (-not (Test-ADUserAuthentication -username $username -password $password)) {
            Write-Log -Message "Unauthorized access attempt by user $username" -LogFilePath $logFilePath
            return @{
                Body = "Unauthorized"
                StatusCode = 401
            }
        }

        # Логирование начала обработки запроса
        Write-Log -Message "Processing request: URL=$($Request.Url.AbsolutePath), Method=$($Request.HttpMethod), Headers=$($Request.Headers), Body=$($Request.InputStream.ReadToEnd())" -LogFilePath $logFilePath

        $body = $Request.InputStream.ReadToEnd() | ConvertFrom-Json
        $action = $Request.Url.AbsolutePath -replace '^/+', ''
        $params = @{
            'Name' = $body.Name
            'Type' = $body.Type
            'Value' = $body.Value
            'ZoneName' = $body.ZoneName
            'SubjectName' = $body.SubjectName
            'TemplateName' = $body.TemplateName
        }

        switch ($action) {
            "dns/get" {
                $result = Get-DNSRecord -Name $params['Name'] -ZoneName $params['ZoneName']
                Write-Log -Message "Retrieved DNS record: $result" -LogFilePath $logFilePath
                return @{
                    Body = $result | ConvertTo-Json
                    StatusCode = 200
                }
            }
            "dns/new" {
                New-DNSRecord -Name $params['Name'] -Type $params['Type'] -Value $params['Value'] -ZoneName $params['ZoneName']
                Write-Log -Message "Created DNS record: Name=$($params['Name']), Type=$($params['Type']), Value=$($params['Value'])" -LogFilePath $logFilePath
                return @{
                    Body = "DNS record created successfully"
                    StatusCode = 201
                }
            }
            "dns/update" {
                Update-DNSRecord -Name $params['Name'] -Type $params['Type'] -Value $params['Value'] -ZoneName $params['ZoneName']
                Write-Log -Message "Updated DNS record: Name=$($params['Name']), Type=$($params['Type']), Value=$($params['Value'])" -LogFilePath $logFilePath
                return @{
                    Body = "DNS record updated successfully"
                    StatusCode = 200
                }
            }
            "dns/remove" {
                Remove-DNSRecord -Name $params['Name'] -ZoneName $params['ZoneName']
                Write-Log -Message "Removed DNS record: Name=$($params['Name'])" -LogFilePath $logFilePath
                return @{
                    Body = "DNS record deleted successfully"
                    StatusCode = 200
                }
            }
            "certificates/get" {
                $result = Get-Certificate -SubjectName $params['SubjectName']
                Write-Log -Message "Retrieved certificate: $result" -LogFilePath $logFilePath
                return @{
                    Body = $result | ConvertTo-Json
                    StatusCode = 200
                }
            }
            "certificates/new" {
                New-Certificate -TemplateName $params['TemplateName'] -SubjectName $params['SubjectName']
                Write-Log -Message "Created certificate: TemplateName=$($params['TemplateName']), SubjectName=$($params['SubjectName'])" -LogFilePath $logFilePath
                return @{
                    Body = "Certificate created successfully"
                    StatusCode = 201
                }
            }
            "certificates/update" {
                Update-Certificate -TemplateName $params['TemplateName'] -SubjectName $params['SubjectName']
                Write-Log -Message "Updated certificate: TemplateName=$($params['TemplateName']), SubjectName=$($params['SubjectName'])" -LogFilePath $logFilePath
                return @{
                    Body = "Certificate updated successfully"
                    StatusCode = 200
                }
            }
            "certificates/remove" {
                Remove-Certificate -SubjectName $params['SubjectName']
                Write-Log -Message "Removed certificate: SubjectName=$($params['SubjectName'])" -LogFilePath $logFilePath
                return @{
                    Body = "Certificate deleted successfully"
                    StatusCode = 200
                }
            }
            default {
                Write-Log -Message "Unknown action: $action" -LogFilePath $logFilePath
                return @{
                    Body = "Unknown action: $action"
                    StatusCode = 400
                }
            }
        }
    } catch {
        Write-Log -Message "Error processing request: $_" -LogFilePath $logFilePath
        return @{
            Body = "Internal Server Error"
            StatusCode = 500
        }
    }
}

# Настройка и запуск API с помощью UniversalDashboard
Start-UDDashboard -Port $port -Endpoint {
    New-UDEndpoint -Url "/dns/get" -Method GET -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/dns/new" -Method POST -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/dns/update" -Method PUT -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/dns/remove" -Method DELETE -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/certificates/get" -Method GET -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/certificates/new" -Method POST -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/certificates/update" -Method PUT -Endpoint {
        Handle-Request -Request $Request
    }

    New-UDEndpoint -Url "/certificates/remove" -Method DELETE -Endpoint {
        Handle-Request -Request $Request
    }

    # Статический эндпоинт для Swagger UI
    New-UDEndpoint -Url "/swagger-ui" -Method GET -Endpoint {
        $swaggerPath = Join-Path $PSScriptRoot "swagger/swagger-ui.html"
        $response = [System.IO.File]::ReadAllText($swaggerPath)
        return @{
            Body = $response
            StatusCode = 200
            Headers = @{ "Content-Type" = "text/html" }
        }
    }

    # Статический эндпоинт для Swagger YAML
    New-UDEndpoint -Url "/swagger.yaml" -Method GET -Endpoint {
        $swaggerYamlPath = Join-Path $PSScriptRoot "swagger/swagger.yaml"
        $response = [System.IO.File]::ReadAllText($swaggerYamlPath)
        return @{
            Body = $response
            StatusCode = 200
            Headers = @{ "Content-Type" = "application/x-yaml" }
        }
    }
}
