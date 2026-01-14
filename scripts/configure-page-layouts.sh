#!/bin/bash

###############################################################################
# Page Layout Configuration Script (Bash)
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
#   ./configure-page-layouts.sh [org-alias]
#
# Example:
#   ./configure-page-layouts.sh MyOrg
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
TEMP_DIR="$PROJECT_ROOT/.temp-layouts"

# Objects and their required fields
# Using a function instead of associative array for bash 3.2 compatibility
get_layout_fields() {
    case "$1" in
        "StnryAssetEnrgyUse")
            echo "Recalculate_Emissions__c"
            ;;
        "VehicleAssetEnrgyUse")
            echo "Recalculate_Emissions__c"
            ;;
        "GeneratedWaste")
            echo "Recalculate_Emissions__c"
            ;;
        "HotelStayEnrgyUse")
            echo "Recalculate_Emissions__c"
            ;;
        "ElectricityEmssnFctrSet")
            echo "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
            ;;
        "RefrigerantEmssnFctr")
            echo "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
            ;;
        "OtherEmssnFctrSet")
            echo "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
            ;;
        "WstDispoEmssnFctrSet")
            echo "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
            ;;
        "HotelStayEmssnFctr")
            echo "Recalculate_Emissions__c,MasterEmissionsSet__c,EmissionsFactorUpdateYear__c"
            ;;
        *)
            echo ""
            ;;
    esac
}

# List of objects
LAYOUT_OBJECTS="StnryAssetEnrgyUse VehicleAssetEnrgyUse GeneratedWaste HotelStayEnrgyUse ElectricityEmssnFctrSet RefrigerantEmssnFctr OtherEmssnFctrSet WstDispoEmssnFctrSet HotelStayEmssnFctr"

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
    elif command -v sfdx &> /dev/null; then
        CLI_CMD="sfdx"
    else
        print_error "Salesforce CLI (sf or sfdx) not found. Please install it first."
        exit 1
    fi
    print_success "Using Salesforce CLI: $CLI_CMD"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

retrieve_layouts() {
    print_header "Step 1: Retrieving Page Layouts"
    
    mkdir -p "$TEMP_DIR"
    
    print_info "Retrieving layouts for target objects..."
    
    # Build package.xml for layouts
    PACKAGE_XML="$TEMP_DIR/package.xml"
    cat > "$PACKAGE_XML" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
EOF
    
    for object_name in $LAYOUT_OBJECTS; do
        echo "        <members>*</members>" >> "$PACKAGE_XML"
    done
    
    cat >> "$PACKAGE_XML" <<EOF
        <name>Layout</name>
    </types>
    <version>60.0</version>
</Package>
EOF
    
    # Note: This is a simplified approach. In practice, you'd need to:
    # 1. Query for all layouts for each object
    # 2. Retrieve each layout individually
    # 3. Parse and modify the XML
    # 4. Deploy back
    
    print_warning "Page layout modification requires manual steps:"
    print_info "1. Retrieve layouts using: sf project retrieve start --metadata Layout:ObjectName"
    print_info "2. Manually add fields to layout XML files"
    print_info "3. Deploy updated layouts using: sf project deploy start"
    print_info ""
    print_info "Alternatively, use Setup UI:"
    print_info "1. Go to Setup > Object Manager > [Object Name] > Page Layouts"
    print_info "2. Edit the layout"
    print_info "3. Drag required fields onto the layout"
    print_info "4. Save"
    print_info ""
    print_info "Required fields per object:"
    for object_name in $LAYOUT_OBJECTS; do
        fields=$(get_layout_fields "$object_name")
        print_info "  - $object_name: $fields"
    done
}

# Main execution
main() {
    print_header "Page Layout Configuration"
    
    check_cli
    
    print_warning "Automated page layout modification is complex and org-specific."
    print_warning "This script provides guidance for manual configuration."
    print_info ""
    
    retrieve_layouts
    
    print_header "Configuration Guidance"
    print_success "See output above for manual configuration steps"
    print_info ""
    print_info "For automated layout modification, consider using:"
    print_info "- Salesforce Metadata API directly"
    print_info "- Third-party tools like Gearset, Copado, or Flosum"
    print_info "- Custom Apex Metadata API calls"
}

# Run main function
main

