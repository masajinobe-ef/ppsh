[CmdletBinding()]
param (
    [int]$Count = 2,
    [string[]]$SetDnsServers,
    [switch]$SetFastestDns
)

# Функция для получения информации о стране и городе по IP-адресу
function Get-IPInfo {
    param (
        [string]$IPAddress
    )

    $url = "http://ip-api.com/json/$IPAddress"

    try {
        $response = Invoke-RestMethod -Uri $url
    } catch [System.Net.HttpStatusCode] {
        if ($_.Exception.Response.StatusCode -eq '429') {
            Write-Host "Error: DNS-server location was not found in the IP API database."
        } else {
            Write-Host "An HTTP error has occurred: $($_.Exception.Message)"
        }
    } catch {
        Write-Host "An error has occurred: $($_.Exception.Message)"
    }

    $country = $response.country
    $city = $response.city

    return $country, $city
}

# Чтение IP-адресов из файла JSON
$ipAddresses = Get-Content -Raw -Path "IP.json" | ConvertFrom-Json

# Массив для хранения результатов скорости соединения
$connectionSpeeds = @()

# Создаем объект Ping для отправки ICMP-запросов
$ping = New-Object System.Net.NetworkInformation.Ping

# Проход по каждому IP-адресу
foreach ($ip in $ipAddresses) {
    # Массив для хранения времени ответа на каждый запрос пинга
    $pingTimes = @()

    # Получение информации о стране и городе по IP-адресу
    $country, $city = Get-IPInfo -IPAddress $ip

    # Попытка отправки запросов к IP-адресу и обработка ошибок
    try {
        for ($i = 1; $i -le $Count; $i++) {
            $pingReply = $ping.Send($ip)
            if ($pingReply.Status -eq "Success") {
                $pingTimes += $pingReply.RoundtripTime
            }
            # Пауза между запросами пинга
            Start-Sleep -Seconds 0.2
        }
    } catch {
        Write-Host ""Ошибка при отправке запросов к IP-адресу " + $ip + ":" + $_"
        continue
    }

    # Рассчет среднего времени ответа на запрос пинга
    $averagePing = $pingTimes | Measure-Object -Average | Select-Object -ExpandProperty Average

    # Добавление результатов в массив
    $connectionSpeeds += [PSCustomObject]@{
        IPAddress = $ip
        Country = $country
        City = $city
        AveragePing = $averagePing
        RequestsSent = $pingTimes.Count
    }

    # Вывод комментария после каждого проверенного IP
    Write-Host "IP address of $ip has been checked."
}

# Установка DNS-серверов, если они были указаны
if ($SetDnsServers) {
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $SetDnsServers

    Write-Host "DNS-servers are setup: $($SetDnsServers -join '; ')"
}

# Установка DNS-серверов, если параметр SetFastestDns указан
if ($SetFastestDns) {
    try {
        $fastestDnsServers = $connectionSpeeds | Sort-Object -Property AveragePing | Select-Object -First 2 | ForEach-Object { $_.IPAddress }

        $formattedDnsServers = "(`"$($fastestDnsServers -join '","')`")"

        Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $fastestDnsServers

        Write-Host "The fastest DNS-servers are setup: $formattedDnsServers"
    } catch {
        Write-Host "Error setup DNS-servers: $($_.Exception.Message)"
    }
}

# Сортировка массива по среднему времени ответа пинга
$sortedConnectionSpeeds = $connectionSpeeds | Sort-Object -Property AveragePing

# Вывод результатов в виде таблицы
$sortedConnectionSpeeds | Format-Table -Property IPAddress, Country, City, AveragePing, RequestsSent -AutoSize

# Вывод информации о завершени
Write-Host "Success!`nTotal IP checked: $($sortedConnectionSpeeds.Count)"