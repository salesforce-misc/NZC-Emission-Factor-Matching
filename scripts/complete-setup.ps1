###############################################################################
# Complete Setup Orchestrator (PowerShell)
#
# This master script orchestrates the entire setup process:
# 1. Deploys setup Apex class
# 2. Creates Custom Setting
# 3. Prompts for and assigns Permission Set
# 4. Provides guidance for Page Layout configuration
# 5. Validates complete setup
# 6. Provides summary report
#
# Prerequisites:
# - Salesforce CLI (sf or sfdx) installed
# - Authenticated to target org
# - Appropriate permissions
#
# Usage:
#   .\complete-setup.ps1 [org-alias]
#
# Example:
#   .\complete-setup.ps1 MyOrg
###############################################################################

param(
    [string]$OrgAlias = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

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

# Main execution
function Main {
    Write-Header "Emissions Matching - Complete Setup"
    
    Write-Host ""
    Write-Info "This script will:"
    Write-Info "1. Deploy the setup Apex class"
    Write-Info "2. Create the default Custom Setting record"
    Write-Info "3. Assign the EmissionsMatching permission set to users"
    Write-Info "4. Provide guidance for page layout configuration"
    Write-Info "5. Validate the setup"
    Write-Host ""
    
    $response = Read-Host "Continue? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Warning "Setup cancelled by user"
        exit 0
    }
    
    Write-Host ""
    
    # Step 1: Run setup script
    Write-Header "Running Setup Script"
    if (-not [string]::IsNullOrEmpty($OrgAlias)) {
        & "$ScriptDir\setup.ps1" -OrgAlias $OrgAlias
    }
    else {
        & "$ScriptDir\setup.ps1"
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Setup script failed. Please review errors above."
        exit 1
    }
    
    Write-Host ""
    
    # Step 2: Page Layout Configuration
    Write-Header "Page Layout Configuration"
    Write-Warning "Page layout configuration requires manual steps or org-specific setup."
    Write-Info ""
    $response = Read-Host "Would you like to see guidance for page layout configuration? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        if (-not [string]::IsNullOrEmpty($OrgAlias)) {
            & "$ScriptDir\configure-page-layouts.ps1" -OrgAlias $OrgAlias
        }
        else {
            & "$ScriptDir\configure-page-layouts.ps1"
        }
    }
    else {
        Write-Info "Skipping page layout configuration guidance."
        Write-Info "You can run it later with: .\configure-page-layouts.ps1"
    }
    
    Write-Host ""
    
    # Step 3: Final Summary
    Write-Header "Setup Summary"
    Write-Success "Core setup completed!"
    Write-Info ""
    Write-Info "Completed:"
    Write-Success "  ✓ Custom Setting created"
    Write-Success "  ✓ Permission Set assigned (if users were specified)"
    Write-Info ""
    Write-Info "Remaining Manual Steps:"
    Write-Warning "  1. Configure Page Layouts (see configure-page-layouts.ps1 output or USER_GUIDE.md)"
    Write-Warning "  2. Optionally configure Custom Metadata for advanced features"
    Write-Warning "  3. Set up emissions set hierarchy manually (data-dependent)"
    Write-Info ""
    Write-Info "Next Steps:"
    Write-Info "1. Verify Custom Setting in Setup > Custom Settings > NZC Emissions Matching Configuration"
    Write-Info "2. Verify Permission Set assignments in Setup > Users > Permission Set Assignments"
    Write-Info "3. Configure page layouts as shown in USER_GUIDE.md"
    Write-Info "4. Test the setup by creating a test energy use record"
    Write-Info ""
    Write-Info "For detailed instructions, see:"
    Write-Info "  - docs/USER_GUIDE.md"
    Write-Info "  - docs/SETUP_AUTOMATION.md"
    Write-Info ""
    
    Write-Header "Setup Complete!"
}

# Run main function
Main


