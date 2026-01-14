###############################################################################
# Fix Custom Setting Page Layout Assignment (PowerShell)
#
# This script:
# 1. Deploys the page layout for NZC_EmissionsMatchingConfig__c
# 2. Provides instructions for assigning the layout to all profiles
#
# Usage:
#   .\scripts\fix-custom-setting-layout.ps1 [org-alias]
#
# Example:
#   .\scripts\fix-custom-setting-layout.ps1 gus
###############################################################################

param(
    [string]$OrgAlias = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$LayoutFile = Join-Path $ProjectRoot "force-app\main\default\layouts\NZC_EmissionsMatchingConfig__c-NZC Emissions Matching Configuration Layout.layout"

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
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Check-CLI {
    if (Get-Command sf -ErrorAction SilentlyContinue) {
        $script:CLI_CMD = "sf"
        Write-Success "Using Salesforce CLI: sf"
    } elseif (Get-Command sfdx -ErrorAction SilentlyContinue) {
        $script:CLI_CMD = "sfdx"
        Write-Success "Using Salesforce CLI: sfdx"
    } else {
        Write-Error "Salesforce CLI (sf or sfdx) not found. Please install it first."
        exit 1
    }
    
    if ($OrgAlias) {
        Write-Info "Using org alias: $OrgAlias"
        $script:ORG_FLAG = "--target-org $OrgAlias"
    } else {
        Write-Warning "No org alias provided. Using default org."
        $script:ORG_FLAG = ""
    }
}

function Deploy-Layout {
    Write-Header "Step 1: Deploying Page Layout"
    
    if (-not (Test-Path $LayoutFile)) {
        Write-Error "Layout file not found: $LayoutFile"
        exit 1
    }
    
    Write-Info "Deploying layout file..."
    
    $LayoutsDir = Join-Path $ProjectRoot "force-app\main\default\layouts"
    
    if ($CLI_CMD -eq "sf") {
        sf project deploy start --source-dir $LayoutsDir $ORG_FLAG
    } else {
        sfdx force:source:deploy --sourcepath $LayoutsDir $ORG_FLAG
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Layout deployed successfully"
    } else {
        Write-Error "Layout deployment failed"
        exit 1
    }
}

function Show-Instructions {
    Write-Header "Step 2: Assign Layout to Profiles (Manual Steps Required)"
    
    Write-Warning "Page layout assignment must be done manually via Setup UI."
    Write-Host ""
    
    Write-Info "OPTION 1: Assign via Object Manager (Recommended)"
    Write-Host "  1. Go to Setup > Object Manager > NZC Emissions Matching Configuration"
    Write-Host "  2. Click 'Page Layouts' in the left sidebar"
    Write-Host "  3. Click 'Page Layout Assignment' button"
    Write-Host "  4. For each profile, select: 'NZC Emissions Matching Configuration Layout'"
    Write-Host "  5. Click 'Save'"
    Write-Host ""
    
    Write-Info "OPTION 2: Assign via Profile"
    Write-Host "  1. Go to Setup > Users > Profiles"
    Write-Host "  2. Click on a profile name"
    Write-Host "  3. Scroll to 'Page Layout Assignment' section"
    Write-Host "  4. Find 'NZC Emissions Matching Configuration'"
    Write-Host "  5. Select: 'NZC Emissions Matching Configuration Layout'"
    Write-Host "  6. Click 'Save'"
    Write-Host "  7. Repeat for all profiles"
    Write-Host ""
    
    Write-Info "OPTION 3: Use Metadata API (Advanced)"
    Write-Host "  1. Retrieve profile metadata:"
    Write-Host "     sf project retrieve start --metadata Profile:Admin"
    Write-Host "  2. Edit profile XML to add layout assignment"
    Write-Host "  3. Deploy back: sf project deploy start"
    Write-Host ""
    
    Write-Info "QUICK TEST:"
    Write-Host "  After assigning, verify by:"
    Write-Host "  1. Setup > Custom Settings > NZC Emissions Matching Configuration"
    Write-Host "  2. Click 'Manage'"
    Write-Host "  3. Click on a record (should work without error)"
    Write-Host ""
}

function Run-CheckScript {
    Write-Header "Step 3: Checking Current State"
    
    $CheckScript = Join-Path $ProjectRoot "scripts\fix-custom-setting-layout.txt"
    
    if ($CLI_CMD -eq "sf") {
        sf apex run --file $CheckScript $ORG_FLAG
    } else {
        sfdx force:apex:execute --apexcodefile $CheckScript $ORG_FLAG
    }
}

# Main execution
Write-Header "Fix Custom Setting Page Layout"

Check-CLI
Deploy-Layout
Write-Host ""
Show-Instructions
Write-Host ""
Run-CheckScript

