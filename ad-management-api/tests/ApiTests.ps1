Describe 'API Tests' {
    It 'should return status 200 for GET /dns/get' {
        $response = Invoke-RestMethod -Uri 'http://localhost:8080/dns/get' -Method Get
        $response.StatusCode | Should -Be 200
    }

    It 'should return status 201 for POST /dns/new' {
        $body = @{
            Name = 'example.com'
            Type = 'A'
            Value = '192.168.1.1'
            ZoneName = 'example-zone'
        }
        $response = Invoke-RestMethod -Uri 'http://localhost:8080/dns/new' -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        $response.StatusCode | Should -Be 201
    }

    # Добавьте больше тестов по аналогии
}
