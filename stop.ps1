$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

docker compose down

Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -match "uvicorn app.main:app" -or
    $_.CommandLine -match "http.server 5173"
} |
ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host "LoreGraph arrêté." -ForegroundColor Green
