###############################################################################
# Emissions Matching Setup Script (PowerShell)
#
# This script automates the post-deployment setup:
# 1. Deploys the setup Apex class
# 2. Creates Custom Setting record
# 3. Assigns Permission Set to users
#
# Prerequisites:
# - Salesforce CLI (sf or sfdx) installed
# - Authenticated to target org
# - Appropriate permissions to deploy and execute Apex
#
# Usage:
#   .\setup.ps1 [org-alias]
#
# Example:
#   .\setup.ps1 MyOrg
###############################################################################

param(
    [string]$OrgAlias = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$AnonApexFile = Join-Path $ScriptDir "setup-anon-apex.txt"

# Functions
function Write-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Test-CLI {
    if (Get-Command sf -ErrorAction SilentlyContinue) {
        $script:CLICmd = "sf"
        Write-Success "Using Salesforce CLI: sf"
    }
    elseif (Get-Command sfdx -ErrorAction SilentlyContinue) {
        $script:CLICmd = "sfdx"
        Write-Success "Using Salesforce CLI: sfdx"
    }
    else {
        Write-Error "Salesforce CLI (sf or sfdx) not found. Please install it first."
        exit 1
    }
}

function Test-Org {
    if ([string]::IsNullOrEmpty($OrgAlias)) {
        Write-Warning "No org alias provided. Using default org."
    }
    else {
        Write-Info "Using org alias: $OrgAlias"
    }
}

function Invoke-SetupScript {
    Write-Header "Step 1: Executing Setup Script"
    
    if (-not (Test-Path $AnonApexFile)) {
        Write-Error "Anonymous Apex script not found at: $AnonApexFile"
        exit 1
    }
    
    Write-Info "Executing Anonymous Apex setup script..."
    Write-Warning "Note: The script includes the setup class inline, so no deployment is required."
    Write-Info ""
    Write-Info "Before executing, make sure to:"
    Write-Info "1. Edit $AnonApexFile"
    Write-Info "2. Add usernames/user IDs to the USERNAMES_OR_IDS list"
    Write-Info ""
    $response = Read-Host "Have you updated the USERNAMES_OR_IDS list? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Warning "Please update the script and run again, or press Enter to continue anyway..."
        Read-Host
    }
    
    # Read the file content and execute it
    $apexContent = Get-Content -Path $AnonApexFile -Raw
    
    if (-not [string]::IsNullOrEmpty($OrgAlias)) {
        if ($CLICmd -eq "sf") {
            $apexContent | & $CLICmd apex run --target-org $OrgAlias
        }
        else {
            $apexContent | & $CLICmd force:apex:execute -u $OrgAlias
        }
    }
    else {
        if ($CLICmd -eq "sf") {
            $apexContent | & $CLICmd apex run
        }
        else {
            $apexContent | & $CLICmd force:apex:execute
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Setup script executed successfully"
    }
    else {
        Write-Error "Failed to execute setup script"
        Write-Info "You can also run the script manually:"
        Write-Info "  - Copy contents of $AnonApexFile"
        Write-Info "  - Paste into Developer Console > Execute Anonymous Window"
        exit 1
    }
}

# Permission Set assignment and validation are handled in the Anonymous Apex script

# Main execution
function Main {
    Write-Header "Emissions Matching Setup"
    
    Test-CLI
    Test-Org
    Invoke-SetupScript
    
    Write-Header "Setup Complete"
    Write-Success "Next steps:"
    Write-Info "1. Verify Custom Setting in Setup > Custom Settings"
    Write-Info "2. Verify Permission Set assignments in Setup > Users"
    Write-Info "3. Configure Page Layouts (run configure-page-layouts.ps1)"
    Write-Info "4. Optionally configure Custom Metadata for advanced features"
    Write-Info ""
    Write-Info "Note: The setup class code was executed inline and is not deployed to your org."
    Write-Info "You can run the script again anytime by executing the Anonymous Apex file."
}

# Run main function
Main

