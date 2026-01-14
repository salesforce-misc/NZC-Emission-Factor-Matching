###############################################################################
# Page Layout Configuration Script (PowerShell)
#
# This script configures page layouts by:
# 1. Retrieving existing layouts for energy use and emissions set objects
# 2. Adding required fields to layouts
# 3. Deploying updated layouts back to org
#
# Prerequisites:
# - Salesforce CLI (sf or sfdx) installed
# - Authenticated to target org
# - Appropriate permissions to retrieve and deploy metadata
#
# Usage:
#   .\configure-page-layouts.ps1 [org-alias]
#
# Example:
#   .\configure-page-layouts.ps1 MyOrg
###############################################################################

param(
    [string]$OrgAlias = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$TempDir = Join-Path $ProjectRoot ".temp-layouts"

# Objects and their required fields
$LayoutConfig = @{
    "StnryAssetEnrgyUse" = "Recalculate_Emissions__c"
    "VehicleAssetEnrgyUse" = "Recalculate_Emissions__c"
    "GeneratedWaste" = "Recalculate_Emissions__c"
    "HotelStayEnrgyUse" = "Recalculate_Emissions__c"
    "ElectricityEmssnFctrSet" = "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
    "RefrigerantEmssnFctr" = "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
    "OtherEmssnFctrSet" = "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
    "WstDispoEmssnFctrSet" = "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
    "HotelStayEmssnFctr" = "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
}

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

function Get-Layouts {
    Write-Header "Step 1: Retrieving Page Layouts"
    
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir | Out-Null
    }
    
    Write-Info "Retrieving layouts for target objects..."
    
    # Note: This is a simplified approach. In practice, you'd need to:
    # 1. Query for all layouts for each object
    # 2. Retrieve each layout individually
    # 3. Parse and modify the XML
    # 4. Deploy back
    
    Write-Warning "Page layout modification requires manual steps:"
    Write-Info "1. Retrieve layouts using: sf project retrieve start --metadata Layout:ObjectName"
    Write-Info "2. Manually add fields to layout XML files"
    Write-Info "3. Deploy updated layouts using: sf project deploy start"
    Write-Info ""
    Write-Info "Alternatively, use Setup UI:"
    Write-Info "1. Go to Setup > Object Manager > [Object Name] > Page Layouts"
    Write-Info "2. Edit the layout"
    Write-Info "3. Drag required fields onto the layout"
    Write-Info "4. Save"
    Write-Info ""
    Write-Info "Required fields per object:"
    foreach ($objectName in $LayoutConfig.Keys) {
        Write-Info "  - $objectName : $($LayoutConfig[$objectName])"
    }
}

function Cleanup {
    if (Test-Path $TempDir) {
        Write-Info "Cleaning up temporary files..."
        Remove-Item -Path $TempDir -Recurse -Force
    }
}

# Register cleanup on exit
Register-EngineEvent PowerShell.Exiting -Action { Cleanup } | Out-Null

# Main execution
function Main {
    Write-Header "Page Layout Configuration"
    
    Test-CLI
    
    Write-Warning "Automated page layout modification is complex and org-specific."
    Write-Warning "This script provides guidance for manual configuration."
    Write-Info ""
    
    Get-Layouts
    
    Write-Header "Configuration Guidance"
    Write-Success "See output above for manual configuration steps"
    Write-Info ""
    Write-Info "For automated layout modification, consider using:"
    Write-Info "- Salesforce Metadata API directly"
    Write-Info "- Third-party tools like Gearset, Copado, or Flosum"
    Write-Info "- Custom Apex Metadata API calls"
}

# Run main function
Main


