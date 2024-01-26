# PPShell (PPSH)

PPShell (PPSH) - это инструмент для управления DNS-серверами и проверки их состояния с использованием PowerShell.

## Установка

1. Клонируйте репозиторий: `git clone https://github.com/masajinobe-ef/ppsh`
2. Перейдите в каталог проекта: `cd ppsh`
3. Запустите PPShell: `./ppsh.ps1`

## Использование

```bash
./ppsh.ps1 # Count = 2
./ppsh.ps1 -Count 10
./ppsh.ps1 -SetFastestDns
./ppsh.ps1 -SetDnsServers ("8.8.8.8","8.8.4.4")
