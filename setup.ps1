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
        "Failed"  { "[FAIL]"; break }
        "Skipped" { "[SKIP]"; break }
    }

    $color = switch ($State) {
        "Running" { "Yellow"; break }
        "Success" { "Green"; break }
        "Failed"  { "Red"; break }
        "Skipped" { "Yellow"; break }
    }

    Write-Host "$icon $Status" -ForegroundColor $color
}

function Invoke-Wslc {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    Write-Step $Status
    & wslc.exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to $($Status.ToLower()) (exit code $LASTEXITCODE)."
    }
    Write-Step "$Status complete" -State Success
}

function Ensure-WslcObject {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string[]]$CreateArguments
    )

    Write-Step "Checking $Description"
    & wslc.exe inspect $Name *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "$Description already exists; skipping creation" -State Skipped
        return
    }

    Write-Step "$Description does not exist; creating it"
    Invoke-Wslc -Status "Creating $Description" -Arguments $CreateArguments
}

try {
    Write-Host "Setting up the Odoo development environment..." -ForegroundColor Cyan

    if (-not (Get-Command wslc.exe -ErrorAction SilentlyContinue)) {
        throw "wslc.exe was not found in PATH."
    }

    Ensure-WslcObject `
        -Name "odoo_network" `
        -Description "network 'odoo_network'" `
        -CreateArguments @("network", "create", "odoo_network")

    Ensure-WslcObject `
        -Name "odoo_data" `
        -Description "database container 'odoo_data'" `
        -CreateArguments @(
            "run", "-d",
            "--name", "odoo_data",
            "--network", "odoo_network",
            "-e", "POSTGRES_USER=odoo",
            "-e", "POSTGRES_PASSWORD=odoo",
            "-e", "POSTGRES_DB=postgres",
            "-e", "PGDATA=/var/lib/postgresql/data/pgdata",
            "postgres:18"
        )

    Ensure-WslcObject `
        -Name "odoo_app" `
        -Description "application container 'odoo_app'" `
        -CreateArguments @(
            "run", "-d",
            "--name", "odoo_app",
            "--network", "odoo_network",
            "-p", "8069:8069",
            "-v", "${PWD}/config:/etc/odoo",
            "-v", "${PWD}/addons:/mnt/extra-addons",
            "odoo:20.0"
        )

    Write-Host "Odoo development environment setup complete." -ForegroundColor Green
}
catch {
    Write-Progress -Activity "Setting up Odoo environment" -Completed
    Write-Step $_.Exception.Message -State Failed
    exit 1
}