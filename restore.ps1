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

try {
    Write-Host "Restoring the Odoo development environment..." -ForegroundColor Cyan

    if (-not (Get-Command wslc.exe -ErrorAction SilentlyContinue)) {
        throw "wslc.exe was not found in PATH."
    }

    $existingContainers = @()
    foreach ($containerName in @("odoo_data", "odoo_app")) {
        Write-Step "Checking container '$containerName'"
        & wslc.exe inspect $containerName *> $null
        if ($LASTEXITCODE -eq 0) {
            $existingContainers += $containerName
        }
        else {
            Write-Step "Container '$containerName' does not exist; skipping" -State Skipped
        }
    }

    foreach ($containerName in $existingContainers) {
        Invoke-Wslc `
            -Status "Stopping container '$containerName'" `
            -Arguments @("stop", $containerName)

        Invoke-Wslc `
            -Status "Removing container '$containerName'" `
            -Arguments @("rm", $containerName)
    }

    Write-Step "Checking network 'odoo_network'"
    & wslc.exe inspect odoo_network *> $null
    if ($LASTEXITCODE -eq 0) {
        Invoke-Wslc `
            -Status "Removing network 'odoo_network'" `
            -Arguments @("network", "rm", "odoo_network")
    }
    else {
        Write-Step "Network 'odoo_network' does not exist; skipping" -State Skipped
    }

    Write-Host "Odoo development environment restored." -ForegroundColor Green
}
catch {
    Write-Progress -Activity "Restoring Odoo environment" -Completed
    Write-Step $_.Exception.Message -State Failed
    exit 1
}