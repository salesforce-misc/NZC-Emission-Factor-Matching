#!/bin/bash

###############################################################################
# Complete Setup Orchestrator (Bash)
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
#   ./complete-setup.sh [org-alias]
#
# Example:
#   ./complete-setup.sh MyOrg
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

# Main execution
main() {
    print_header "Emissions Matching - Complete Setup"
    
    echo ""
    print_info "This script will:"
    print_info "1. Deploy the setup Apex class"
    print_info "2. Create the default Custom Setting record"
    print_info "3. Assign the EmissionsMatching permission set to users"
    print_info "4. Provide guidance for page layout configuration"
    print_info "5. Validate the setup"
    echo ""
    
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled by user"
        exit 0
    fi
    
    echo ""
    
    # Step 1: Run setup script
    print_header "Running Setup Script"
    if [ -n "$ORG_ALIAS" ]; then
        "$SCRIPT_DIR/setup.sh" "$ORG_ALIAS"
    else
        "$SCRIPT_DIR/setup.sh"
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Setup script failed. Please review errors above."
        exit 1
    fi
    
    echo ""
    
    # Step 2: Page Layout Configuration
    print_header "Page Layout Configuration"
    print_warning "Page layout configuration requires manual steps or org-specific setup."
    print_info ""
    print_info "Would you like to see guidance for page layout configuration? (y/n)"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -n "$ORG_ALIAS" ]; then
            "$SCRIPT_DIR/configure-page-layouts.sh" "$ORG_ALIAS"
        else
            "$SCRIPT_DIR/configure-page-layouts.sh"
        fi
    else
        print_info "Skipping page layout configuration guidance."
        print_info "You can run it later with: ./configure-page-layouts.sh"
    fi
    
    echo ""
    
    # Step 3: Final Summary
    print_header "Setup Summary"
    print_success "Core setup completed!"
    print_info ""
    print_info "Completed:"
    print_success "  ✓ Custom Setting created"
    print_success "  ✓ Permission Set assigned (if users were specified)"
    print_info ""
    print_info "Remaining Manual Steps:"
    print_warning "  1. Configure Page Layouts (see configure-page-layouts.sh output or USER_GUIDE.md)"
    print_warning "  2. Optionally configure Custom Metadata for advanced features"
    print_warning "  3. Set up emissions set hierarchy manually (data-dependent)"
    print_info ""
    print_info "Next Steps:"
    print_info "1. Verify Custom Setting in Setup > Custom Settings > NZC Emissions Matching Configuration"
    print_info "2. Verify Permission Set assignments in Setup > Users > Permission Set Assignments"
    print_info "3. Configure page layouts as shown in USER_GUIDE.md"
    print_info "4. Test the setup by creating a test energy use record"
    print_info ""
    print_info "For detailed instructions, see:"
    print_info "  - docs/USER_GUIDE.md"
    print_info "  - docs/SETUP_AUTOMATION.md"
    print_info ""
    
    print_header "Setup Complete!"
}

# Run main function
main


