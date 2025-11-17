<#
Automates Docker Compose deployment and a basic persistence test.

Run from project root in PowerShell:
    .\deploy-and-test.ps1

Requirements: Docker Desktop / Engine must be running and available.
#>

Write-Host "Starting deployment and test..." -ForegroundColor Cyan

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

function Wait-ForPort($host, $port, $timeoutSec = 120) {
    $start = Get-Date
    while ((Get-Date) - $start -lt ([TimeSpan]::FromSeconds($timeoutSec))) {
        $res = Test-NetConnection -ComputerName $host -Port $port -WarningAction SilentlyContinue
        if ($res.TcpTestSucceeded) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

docker-compose up --build -d
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker-compose failed. Ensure Docker Desktop / Engine is running and you have permissions."; Pop-Location; exit 1
}

Write-Host "Waiting for MySQL on localhost:3306..." -NoNewline
if (-not (Wait-ForPort 'localhost' 3306 120)) { Write-Error "MySQL did not become available in time."; Pop-Location; exit 1 }
Write-Host " OK" -ForegroundColor Green

Write-Host "Waiting for backend on localhost:8081..." -NoNewline
if (-not (Wait-ForPort 'localhost' 8081 120)) { Write-Host " (port closed). Will still attempt HTTP calls." }
Write-Host " Done" -ForegroundColor Green

Start-Sleep -Seconds 5

function Post-Json($url, $body) {
    try {
        $json = $body | ConvertTo-Json -Depth 5
        $resp = Invoke-RestMethod -Uri $url -Method Post -Body $json -ContentType 'application/json' -TimeoutSec 30
        return @{ success = $true; body = $resp }
    } catch {
        return @{ success = $false; error = $_.Exception.Message }
    }
}

$signupUrl = 'http://localhost:8081/auth/signup'
$loginUrl = 'http://localhost:8081/auth/login'

Write-Host "Posting sample signup to $signupUrl" -ForegroundColor Cyan
$signup = Post-Json $signupUrl @{ username = 'demo'; email = 'demo@example.com'; password = 'pass' }
if ($signup.success) { Write-Host "Signup response: $($signup.body)" -ForegroundColor Green } else { Write-Warning "Signup failed: $($signup.error)" }

Write-Host "Restarting containers to test persistence..." -ForegroundColor Cyan
docker restart travel-backend, travel-db | ForEach-Object { Write-Host "Restarted: $_" }

Start-Sleep -Seconds 8

Write-Host "Attempting login to verify persistence" -ForegroundColor Cyan
$login = Post-Json $loginUrl @{ username = 'demo'; password = 'pass' }
if ($login.success) { Write-Host "Login response: $($login.body)" -ForegroundColor Green } else { Write-Warning "Login failed: $($login.error)" }

Write-Host "Deployment and basic persistence test complete." -ForegroundColor Cyan
Pop-Location
