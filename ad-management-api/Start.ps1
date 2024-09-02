# Импортируйте модули и настройки
Import-Module -Name ./src/DNSManagement.ps1
Import-Module -Name ./src/CertificateManagement.ps1
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
        Write-UDLog -Message "Authentication failed for user $username. Error: $_" 
        return $false
    }
}

# Функция обработки запросов
function Complete-Request {
    param (
        [Microsoft.AspNetCore.Http.Internal.DefaultHttpRequest]$Request,
        $Body
    )

    try {
        # $username = $Request.Headers["Username"]
        $username = 'testU'
        # $password = $Request.Headers["Password"] | ConvertTo-SecureString -AsPlainText -Force
        $password = 'testP'

        # Write-UDLog -Message "User: $username, pass = $password"
        # # Проверка аутентификации
        # if (-not (Test-ADUserAuthentication -username $username -password $password)) {
        #     Write-UDLog -Message "Unauthorized access attempt by user $username" 
        #     return "" | ConvertTo-Json
        # }

        Write-UDLog -Message "RAW Body: $Body"
        $body = $Body | ConvertFrom-Json

        # Логирование начала обработки запроса
        Write-UDLog -Message "Processing request: URL=$($Request.Path), Method=$($Request.Method), Headers=$($Request.Headers), Body=$($body | Format-List | Out-String)" 

        $action = $Request.Path -replace '^/api/+', ''
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
                Write-UDLog -Message "Retrieved DNS record: $result" 
                $result = @{
                    Body = $result
                    StatusCode = 200
                }
            }
            "dns/new" {
                New-DNSRecord -Name $params['Name'] -Type $params['Type'] -Value $params['Value'] -ZoneName $params['ZoneName']
                Write-UDLog -Message "Created DNS record: Name=$($params['Name']), Type=$($params['Type']), Value=$($params['Value'])" 
                $result = @{
                    Body = "DNS record created successfully"
                    StatusCode = 201
                }
            }
            "dns/update" {
                Update-DNSRecord -Name $params['Name'] -Type $params['Type'] -Value $params['Value'] -ZoneName $params['ZoneName']
                Write-UDLog -Message "Updated DNS record: Name=$($params['Name']), Type=$($params['Type']), Value=$($params['Value'])" 
                $result = @{
                    Body = "DNS record updated successfully"
                    StatusCode = 200
                }
            }
            "dns/remove" {
                Remove-DNSRecord -Name $params['Name'] -ZoneName $params['ZoneName']
                Write-UDLog -Message "Removed DNS record: Name=$($params['Name'])" 
                $result = @{
                    Body = "DNS record deleted successfully"
                    StatusCode = 200
                }
            }
            "certificates/get" {
                $result = Get-Certificate -SubjectName $params['SubjectName']
                Write-UDLog -Message "Retrieved certificate: $result" 
                $result = @{
                    Body = $result
                    StatusCode = 200
                }
            }
            "certificates/new" {
                New-Certificate -TemplateName $params['TemplateName'] -SubjectName $params['SubjectName']
                Write-UDLog -Message "Created certificate: TemplateName=$($params['TemplateName']), SubjectName=$($params['SubjectName'])" 
                $result = @{
                    Body = "Certificate created successfully"
                    StatusCode = 201
                }
            }
            "certificates/update" {
                Update-Certificate -TemplateName $params['TemplateName'] -SubjectName $params['SubjectName']
                Write-UDLog -Message "Updated certificate: TemplateName=$($params['TemplateName']), SubjectName=$($params['SubjectName'])" 
                $result = @{
                    Body = "Certificate updated successfully"
                    StatusCode = 200
                }
            }
            "certificates/remove" {
                Remove-Certificate -SubjectName $params['SubjectName']
                Write-UDLog -Message "Removed certificate: SubjectName=$($params['SubjectName'])" 
                $result = @{
                    Body = "Certificate deleted successfully"
                    StatusCode = 200
                }
            }
            default {
                Write-UDLog -Message "Unknown action: $action" 
                $result = @{
                    Body = "Unknown action: $action"
                    StatusCode = 400
                }
            }
        }
    } catch {
        Write-UDLog -Message "Error processing request: $_" 
        $result = @{
            Body = "Internal Server Error"
            StatusCode = 500
        }
    }
    return $result | ConvertTo-Json
}

# Настройка и запуск API с помощью UniversalDashboard
$EP_DNS_GET     = New-UDEndpoint -Url "/dns/get"    -Method POST     -Endpoint  { Complete-Request -Request $Request -Body $Body }
$EP_DNS_NEW     = New-UDEndpoint -Url "/dns/new"    -Method POST    -Endpoint   { Complete-Request -Request $Request -Body $Body }
$EP_DNS_UPDATE  = New-UDEndpoint -Url "/dns/update" -Method PUT     -Endpoint   { Complete-Request -Request $Request -Body $Body }
$EP_DNS_REMOVE  = New-UDEndpoint -Url "/dns/remove" -Method DELETE  -Endpoint   { Complete-Request -Request $Request -Body $Body }


    # New-UDEndpoint -Url "/certificates/get" -Method GET -Endpoint {
    #     Handle-Request -Request $Request
    # },

    # New-UDEndpoint -Url "/certificates/new" -Method POST -Endpoint {
    #     Handle-Request -Request $Request
    # },

    # New-UDEndpoint -Url "/certificates/update" -Method PUT -Endpoint {
    #     Handle-Request -Request $Request
    # },

    # New-UDEndpoint -Url "/certificates/remove" -Method DELETE -Endpoint {
    #     Handle-Request -Request $Request
    # },

    # # Статический эндпоинт для Swagger UI
    # New-UDEndpoint -Url "/swagger-ui" -Method GET -Endpoint {
    #     $swaggerPath = Join-Path $PSScriptRoot "swagger/swagger-ui.html"
    #     $response = [System.IO.File]::ReadAllText($swaggerPath)
    #     return @{
    #         Body = $response
    #         StatusCode = 200
    #         Headers = @{ "Content-Type" = "text/html" }
    #     }
    # },

    # # Статический эндпоинт для Swagger YAML
    # New-UDEndpoint -Url "/swagger.yaml" -Method GET -Endpoint {
    #     $swaggerYamlPath = Join-Path $PSScriptRoot "swagger/swagger.yaml"
    #     $response = [System.IO.File]::ReadAllText($swaggerYamlPath)
    #     return @{
    #         Body = $response
    #         StatusCode = 200
    #         Headers = @{ "Content-Type" = "application/x-yaml" }
    #     }
    # },

    # test
$EP_TEST = New-UDEndpoint -Url "/test" -Method GET -Endpoint {
        $result = Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; ID=$_.ID} }
        $ret = @{
            Body = $result
            StatusCode = 200
        }
        return $ret | ConvertTo-Json
    }



# $ne2 = New-UDEndpoint -Url "/test" -Method GET -Endpoint {
#     return @{
#         Body = "test"
#         StatusCode = 200
#     }
# }

$Endpoints = @($EP_DNS_GET, $EP_DNS_NEW, $EP_DNS_UPDATE, $EP_DNS_REMOVE, $EP_TEST)
Enable-UDLogging
Start-UDRestApi -Name 'AD-Management-API' -Port $port -Endpoint $Endpoints -Debug -Verbose
