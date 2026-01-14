#!/bin/bash

###############################################################################
# Emissions Matching Setup Script (Bash)
#
# This script automates the post-deployment setup:
# 1. Executes Anonymous Apex script (includes setup class inline)
# 2. Creates Custom Setting record
# 3. Assigns Permission Set to users
#
# Prerequisites:
# - Salesforce CLI (sf or sfdx) installed
# - Authenticated to target org
# - Appropriate permissions to execute Anonymous Apex
#
# Usage:
#   ./setup.sh [org-alias]
#
# Example:
#   ./setup.sh MyOrg
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
ANON_APEX_FILE="$SCRIPT_DIR/setup-anon-apex.txt"

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

check_org() {
    if [ -z "$ORG_ALIAS" ]; then
        print_warning "No org alias provided. Using default org."
        ORG_ALIAS=""
    else
        print_info "Using org alias: $ORG_ALIAS"
    fi
}

# Note: Setup class is included inline in the Anonymous Apex script, so no deployment needed

execute_setup_script() {
    print_header "Step 1: Executing Setup Script"
    
    if [ ! -f "$ANON_APEX_FILE" ]; then
        print_error "Anonymous Apex script not found at: $ANON_APEX_FILE"
        exit 1
    fi
    
    print_info "Executing Anonymous Apex setup script..."
    print_warning "Note: The script includes the setup class inline, so no deployment is required."
    print_info ""
    print_info "Before executing, make sure to:"
    print_info "1. Edit $ANON_APEX_FILE"
    print_info "2. Add usernames/user IDs to the USERNAMES_OR_IDS list"
    print_info ""
    read -p "Have you updated the USERNAMES_OR_IDS list? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please update the script and run again, or press Enter to continue anyway..."
        read
    fi
    
    # Read the file content and execute it
    APEX_CONTENT=$(cat "$ANON_APEX_FILE")
    
    if [ -n "$ORG_ALIAS" ]; then
        if [ "$CLI_CMD" = "sf" ]; then
            echo "$APEX_CONTENT" | $CLI_CMD apex run --target-org "$ORG_ALIAS"
        else
            echo "$APEX_CONTENT" | $CLI_CMD force:apex:execute -u "$ORG_ALIAS"
        fi
    else
        if [ "$CLI_CMD" = "sf" ]; then
            echo "$APEX_CONTENT" | $CLI_CMD apex run
        else
            echo "$APEX_CONTENT" | $CLI_CMD force:apex:execute
        fi
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Setup script executed successfully"
    else
        print_error "Failed to execute setup script"
        print_info "You can also run the script manually:"
        print_info "  - Copy contents of $ANON_APEX_FILE"
        print_info "  - Paste into Developer Console > Execute Anonymous Window"
        exit 1
    fi
}

# Permission Set assignment and validation are handled in the Anonymous Apex script

# Main execution
main() {
    print_header "Emissions Matching Setup"
    
    check_cli
    check_org
    execute_setup_script
    
    print_header "Setup Complete"
    print_success "Next steps:"
    print_info "1. Verify Custom Setting in Setup > Custom Settings"
    print_info "2. Verify Permission Set assignments in Setup > Users"
    print_info "3. Configure Page Layouts (run configure-page-layouts.sh)"
    print_info "4. Optionally configure Custom Metadata for advanced features"
    print_info ""
    print_info "Note: The setup class code was executed inline and is not deployed to your org."
    print_info "You can run the script again anytime by executing the Anonymous Apex file."
}

# Run main function
main

