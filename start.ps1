Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [ValidateSet("Running", "Success", "Failed", "Skipped")]
        [string]$State = "Running"
    )

    $icon = switch ($State) {
        "Running" { "[RUNNING]"; break }
        "Success" { "[ OK ]"; break }
        "Failed" { "[FAIL]"; break }
        "Skipped" { "[SKIP]"; break }
    }

    $color = switch ($State) {
        "Running" { "Yellow"; break }
        "Success" { "Green"; break }
        "Failed" { "Red"; break }
        "Skipped" { "Yellow"; break }
    }

    Write-Host "$icon $Status" -ForegroundColor $color
}

function Get-ContainerState {
    param(
        [Parameter(Mandatory)]
        [string]$ContainerName
    )

    $containers = @(& wslc.exe list --all --format json)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get container status (exit code $LASTEXITCODE)."
    }

    foreach ($line in $containers) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $container = $line | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Could not read container status: $($_.Exception.Message)"
        }

        $names = [string]$container.Names -split ","
        if ($names -contains $ContainerName) {
            return [string]$container.State
        }
    }

    return $null
}

function Start-Container {
    param(
        [Parameter(Mandatory)]
        [string]$ContainerName
    )

    Write-Step "Checking status of container '$ContainerName'"
    $containerState = Get-ContainerState -ContainerName $ContainerName
    if (-not $containerState) {
        throw "Container '$ContainerName' was not found. Run setup.ps1 first to create the development containers."
    }
    if ($containerState -eq "running") {
        Write-Step "Container '$ContainerName' is already running" -State Skipped
        return $false
    }
    Write-Step "Container '$ContainerName' is '$containerState'; it will be started"

    Write-Step "Starting container '$ContainerName'"

    $null = & wslc.exe start $ContainerName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container '$ContainerName' (exit code $LASTEXITCODE)."
    }

    Write-Step "Container '$ContainerName' started" -State Success
    return $true
}

try {
    Write-Host "Initializing containers for development environment..." -ForegroundColor Cyan

    if (-not (Get-Command wslc.exe -ErrorAction SilentlyContinue)) {
        throw "wslc.exe was not found in PATH."
    }

    $databaseStarted = Start-Container -ContainerName "odoo_data"

    if ($databaseStarted) {
        Write-Step "Waiting for the database container"
        for ($elapsed = 1; $elapsed -le 3; $elapsed++) {
            Write-Progress `
                -Activity "Starting Odoo environment" `
                -Status "Waiting for database ($elapsed of 3 seconds)" `
                -PercentComplete (($elapsed / 3) * 100)
            Start-Sleep -Seconds 1
        }
        Write-Progress -Activity "Starting Odoo environment" -Completed
        Write-Step "Database startup delay complete" -State Success
    }

    $null = Start-Container -ContainerName "odoo_app"

    Write-Host "Odoo development environment is running." -ForegroundColor Green
}
catch {
    Write-Progress -Activity "Starting Odoo environment" -Completed
    Write-Step $_.Exception.Message -State Failed
    exit 1
}