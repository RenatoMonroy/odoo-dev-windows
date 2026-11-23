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

try {
    Write-Host "Stopping the Odoo development environment..." -ForegroundColor Cyan

    if (-not (Get-Command wslc.exe -ErrorAction SilentlyContinue)) {
        throw "wslc.exe was not found in PATH."
    }

    $existingContainers = @()
    foreach ($containerName in @("odoo_app", "odoo_data")) {
        Write-Step "Checking status of container '$containerName'"
        $containerState = Get-ContainerState -ContainerName $containerName
        if (-not $containerState) {
            Write-Step "Container '$containerName' does not exist; skipping" -State Skipped
        }
        elseif ($containerState -eq "running") {
            $existingContainers += $containerName
        }
        else {
            Write-Step "Container '$containerName' is already '$containerState'; skipping" -State Skipped
        }
    }

    foreach ($containerName in $existingContainers) {
        Write-Step "Stopping container '$containerName'"
        & wslc.exe stop $containerName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stop container '$containerName' (exit code $LASTEXITCODE)."
        }
        Write-Step "Container '$containerName' stopped" -State Success
    }

    Write-Host "Odoo development environment is stopped." -ForegroundColor Green
}
catch {
    Write-Step $_.Exception.Message -State Failed
    exit 1
}
