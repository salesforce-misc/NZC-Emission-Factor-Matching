#!/bin/bash

###############################################################################
# Fix Custom Setting Page Layout Assignment
#
# This script:
# 1. Deploys the page layout for NZC_EmissionsMatchingConfig__c
# 2. Provides instructions for assigning the layout to all profiles
#
# Usage:
#   ./scripts/fix-custom-setting-layout.sh [org-alias]
#
# Example:
#   ./scripts/fix-custom-setting-layout.sh gus
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_ALIAS="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAYOUT_FILE="$PROJECT_ROOT/force-app/main/default/layouts/NZC_EmissionsMatchingConfig__c-NZC Emissions Matching Configuration Layout.layout"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_cli() {
    if command -v sf &> /dev/null; then
        CLI_CMD="sf"
        print_success "Using Salesforce CLI: sf"
    elif command -v sfdx &> /dev/null; then
        CLI_CMD="sfdx"
        print_success "Using Salesforce CLI: sfdx"
    else
        print_error "Salesforce CLI (sf or sfdx) not found. Please install it first."
        exit 1
    fi
    
    if [ -n "$ORG_ALIAS" ]; then
        print_info "Using org alias: $ORG_ALIAS"
        ORG_FLAG="--target-org $ORG_ALIAS"
    else
        print_warning "No org alias provided. Using default org."
        ORG_FLAG=""
    fi
}

deploy_layout() {
    print_header "Step 1: Deploying Page Layout"
    
    if [ ! -f "$LAYOUT_FILE" ]; then
        print_error "Layout file not found: $LAYOUT_FILE"
        exit 1
    fi
    
    print_info "Deploying layout file..."
    
    if [ "$CLI_CMD" = "sf" ]; then
        sf project deploy start --source-dir "$PROJECT_ROOT/force-app/main/default/layouts" $ORG_FLAG
    else
        sfdx force:source:deploy --sourcepath "$PROJECT_ROOT/force-app/main/default/layouts" $ORG_FLAG
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Layout deployed successfully"
    else
        print_error "Layout deployment failed"
        exit 1
    fi
}

show_instructions() {
    print_header "Step 2: Assign Layout to Profiles (Manual Steps Required)"
    
    print_warning "Page layout assignment must be done manually via Setup UI."
    echo ""
    
    print_info "OPTION 1: Assign via Object Manager (Recommended)"
    echo "  1. Go to Setup > Object Manager > NZC Emissions Matching Configuration"
    echo "  2. Click 'Page Layouts' in the left sidebar"
    echo "  3. Click 'Page Layout Assignment' button"
    echo "  4. For each profile, select: 'NZC Emissions Matching Configuration Layout'"
    echo "  5. Click 'Save'"
    echo ""
    
    print_info "OPTION 2: Assign via Profile"
    echo "  1. Go to Setup > Users > Profiles"
    echo "  2. Click on a profile name"
    echo "  3. Scroll to 'Page Layout Assignment' section"
    echo "  4. Find 'NZC Emissions Matching Configuration'"
    echo "  5. Select: 'NZC Emissions Matching Configuration Layout'"
    echo "  6. Click 'Save'"
    echo "  7. Repeat for all profiles"
    echo ""
    
    print_info "OPTION 3: Use Metadata API (Advanced)"
    echo "  1. Retrieve profile metadata:"
    echo "     sf project retrieve start --metadata Profile:Admin"
    echo "  2. Edit profile XML to add layout assignment"
    echo "  3. Deploy back: sf project deploy start"
    echo ""
    
    print_info "QUICK TEST:"
    echo "  After assigning, verify by:"
    echo "  1. Setup > Custom Settings > NZC Emissions Matching Configuration"
    echo "  2. Click 'Manage'"
    echo "  3. Click on a record (should work without error)"
    echo ""
}

run_check_script() {
    print_header "Step 3: Checking Current State"
    
    if [ "$CLI_CMD" = "sf" ]; then
        sf apex run --file "$PROJECT_ROOT/scripts/fix-custom-setting-layout.txt" $ORG_FLAG
    else
        sfdx force:apex:execute --apexcodefile "$PROJECT_ROOT/scripts/fix-custom-setting-layout.txt" $ORG_FLAG
    fi
}

# Main execution
main() {
    print_header "Fix Custom Setting Page Layout"
    
    check_cli
    deploy_layout
    echo ""
    show_instructions
    echo ""
    run_check_script
}

# Run main function
main

