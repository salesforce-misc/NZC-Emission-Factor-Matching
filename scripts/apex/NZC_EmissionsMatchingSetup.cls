/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 * 
 * NOTE: This class is for setup purposes only and should NOT be deployed to production.
 * Use the Anonymous Apex script (setup-anon-apex.txt) instead, which includes this code inline.
 */

public with sharing class NZC_EmissionsMatchingSetup {

    private static final String PERMISSION_SET_NAME = 'EmissionsMatching';
    private static final String CUSTOM_SETTING_NAME = 'Default';

    /**
     * Creates a default Custom Setting record with recommended values from USER_GUIDE.md
     * @return NZC_EmissionsMatchingConfig__c The created or existing configuration record
     */
    public static NZC_EmissionsMatchingConfig__c createDefaultConfig() {
        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.NZC_EmissionsMatchingConfig__c.isAccessible()) {
            throw new SetupException('User does not have access to NZC_EmissionsMatchingConfig__c');
        }
        // Check if a default record already exists
        List<NZC_EmissionsMatchingConfig__c> existingConfigs = [
            SELECT Id, Name
            FROM NZC_EmissionsMatchingConfig__c
            WHERE Name = :CUSTOM_SETTING_NAME
            LIMIT 1
        ];

        if (!existingConfigs.isEmpty()) {
            System.debug('Default configuration already exists: ' + existingConfigs[0].Id);
            return existingConfigs[0];
        }

        // Create new configuration with defaults
        NZC_EmissionsMatchingConfig__c config = new NZC_EmissionsMatchingConfig__c(
            Name = CUSTOM_SETTING_NAME,
            DateMatchingField__c = 'StartDate',
            Emissions_Matching_Batch_Size__c = 200,
            Emissions_Recalc_Batch_Size__c = 50,
            doLog__c = true, // Enable logging for initial setup/debugging
            DoMatchEmissionsOnInsert__c = false,
            DoMatchEmissionsOnUpdate__c = false,
            AllowCustomTagMatching__c = false,
            AllowAdvancedMatching__c = false,
            AllowTransmissionDistribution__c = false
        );

        // Check CRUD permissions before DML operation
        if (!Schema.sObjectType.NZC_EmissionsMatchingConfig__c.isCreateable()) {
            throw new SetupException('User does not have create permission for NZC_EmissionsMatchingConfig__c');
        }

        try {
            insert config;
            System.debug('Successfully created default configuration: ' + config.Id);
            return config;
        } catch (DmlException e) {
            System.debug('Error creating configuration: ' + e.getMessage());
            throw new SetupException('Failed to create default configuration: ' + e.getMessage());
        }
    }

    /**
     * Assigns the EmissionsMatching permission set to specified users
     * Supports both username and user ID input
     * @param usernamesOrIds List of usernames or user IDs
     * @return List<PermissionSetAssignment> List of created assignments
     */
    public static List<PermissionSetAssignment> assignPermissionSetToUsers(List<String> usernamesOrIds) {
        if (usernamesOrIds == null || usernamesOrIds.isEmpty()) {
            throw new SetupException('User list cannot be empty');
        }

        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.PermissionSet.isAccessible()) {
            throw new SetupException('User does not have access to PermissionSet');
        }
        // Get the Permission Set
        List<PermissionSet> permissionSets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :PERMISSION_SET_NAME
            LIMIT 1
        ];

        if (permissionSets.isEmpty()) {
            throw new SetupException('Permission Set "' + PERMISSION_SET_NAME + '" not found. Please ensure it is deployed.');
        }

        PermissionSet ps = permissionSets[0];

        // Find users by username or ID
        Set<String> usernameSet = new Set<String>();
        Set<Id> idSet = new Set<Id>();

        for (String identifier : usernamesOrIds) {
            // Try to parse as ID first
            try {
                Id userId = (Id)identifier;
                idSet.add(userId);
            } catch (Exception e) {
                // Not a valid ID, treat as username
                usernameSet.add(identifier);
            }
        }

        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new SetupException('User does not have access to User');
        }
        List<User> users = [
            SELECT Id, Username, Name
            FROM User
            WHERE Id IN :idSet
               OR Username IN :usernameSet
        ];

        if (users.isEmpty()) {
            throw new SetupException('No users found matching the provided identifiers');
        }

        // Check for existing assignments
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            userIds.add(u.Id);
        }

        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
            throw new SetupException('User does not have access to PermissionSetAssignment');
        }
        List<PermissionSetAssignment> existingAssignments = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :ps.Id
              AND AssigneeId IN :userIds
        ];

        Set<Id> alreadyAssigned = new Set<Id>();
        for (PermissionSetAssignment psa : existingAssignments) {
            alreadyAssigned.add(psa.AssigneeId);
        }

        // Create new assignments
        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
        for (User u : users) {
            if (!alreadyAssigned.contains(u.Id)) {
                newAssignments.add(new PermissionSetAssignment(
                    AssigneeId = u.Id,
                    PermissionSetId = ps.Id
                ));
            } else {
                System.debug('User ' + u.Username + ' already has permission set assigned');
            }
        }

        if (newAssignments.isEmpty()) {
            System.debug('All specified users already have the permission set assigned');
            return new List<PermissionSetAssignment>();
        }

        // Check CRUD permissions before DML operation
        if (!Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
            throw new SetupException('User does not have create permission for PermissionSetAssignment');
        }

        try {
            insert newAssignments;
            System.debug('Successfully assigned permission set to ' + newAssignments.size() + ' user(s)');
            return newAssignments;
        } catch (DmlException e) {
            System.debug('Error assigning permission set: ' + e.getMessage());
            throw new SetupException('Failed to assign permission set: ' + e.getMessage());
        }
    }

    /**
     * Validates that the setup is complete
     * @return SetupValidationResult Result object with validation status
     */
    public static SetupValidationResult validateSetup() {
        SetupValidationResult result = new SetupValidationResult();

        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.NZC_EmissionsMatchingConfig__c.isAccessible()) {
            result.addError('User does not have access to NZC_EmissionsMatchingConfig__c');
            return result;
        }
        // Check Custom Setting
        List<NZC_EmissionsMatchingConfig__c> configs = [
            SELECT Id, Name, DateMatchingField__c, 
                   Emissions_Matching_Batch_Size__c, Emissions_Recalc_Batch_Size__c
            FROM NZC_EmissionsMatchingConfig__c
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            result.addError('Custom Setting record not found. Run createDefaultConfig() first.');
        } else {
            result.configExists = true;
            NZC_EmissionsMatchingConfig__c config = configs[0];
            
            if (String.isBlank(config.DateMatchingField__c)) {
                result.addError('DateMatchingField__c is not set');
            }
            if (config.Emissions_Matching_Batch_Size__c == null || config.Emissions_Matching_Batch_Size__c <= 0) {
                result.addError('Emissions_Matching_Batch_Size__c is not set or invalid');
            }
            if (config.Emissions_Recalc_Batch_Size__c == null || config.Emissions_Recalc_Batch_Size__c <= 0) {
                result.addError('Emissions_Recalc_Batch_Size__c is not set or invalid');
            }
        }

        // Check CRUD permissions before SOQL query
        if (!Schema.sObjectType.PermissionSet.isAccessible()) {
            result.addWarning('User does not have access to PermissionSet');
            return result;
        }
        // Check Permission Set exists
        List<PermissionSet> permissionSets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :PERMISSION_SET_NAME
            LIMIT 1
        ];

        if (permissionSets.isEmpty()) {
            result.addWarning('Permission Set "' + PERMISSION_SET_NAME + '" not found. Ensure it is deployed.');
        } else {
            result.permissionSetExists = true;
        }

        return result;
    }

    /**
     * Gets a human-readable setup status report
     * @return String Status report
     */
    public static String getSetupStatus() {
        SetupValidationResult validation = validateSetup();
        
        StringBuilder status = new StringBuilder();
        status.append('=== Emissions Matching Setup Status ===\n\n');
        
        // Custom Setting Status
        status.append('Custom Setting: ');
        if (validation.configExists) {
            // Check CRUD permissions before SOQL query
            if (!Schema.sObjectType.NZC_EmissionsMatchingConfig__c.isAccessible()) {
                status.append('✗ ACCESS DENIED\n');
            } else {
                List<NZC_EmissionsMatchingConfig__c> configs = [
                SELECT Id, Name, DateMatchingField__c, 
                       Emissions_Matching_Batch_Size__c, Emissions_Recalc_Batch_Size__c,
                       doLog__c, DoMatchEmissionsOnInsert__c, DoMatchEmissionsOnUpdate__c
                FROM NZC_EmissionsMatchingConfig__c
                LIMIT 1
            ];
            if (!configs.isEmpty()) {
                NZC_EmissionsMatchingConfig__c config = configs[0];
                status.append('✓ EXISTS\n');
                status.append('  - Name: ' + config.Name + '\n');
                status.append('  - Date Matching Field: ' + config.DateMatchingField__c + '\n');
                status.append('  - Matching Batch Size: ' + config.Emissions_Matching_Batch_Size__c + '\n');
                status.append('  - Recalc Batch Size: ' + config.Emissions_Recalc_Batch_Size__c + '\n');
                status.append('  - Logging Enabled: ' + config.doLog__c + '\n');
            }
            }
        } else {
            status.append('✗ NOT FOUND\n');
        }
        
        status.append('\n');
        
        // Permission Set Status
        status.append('Permission Set: ');
        if (validation.permissionSetExists) {
            // Check CRUD permissions before SOQL query
            if (!Schema.sObjectType.PermissionSet.isAccessible()) {
                status.append('✗ ACCESS DENIED\n');
            } else {
                List<PermissionSet> psList = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name = :PERMISSION_SET_NAME
                LIMIT 1
            ];
            if (!psList.isEmpty()) {
                status.append('✓ EXISTS\n');
                status.append('  - Name: ' + psList[0].Name + '\n');
                status.append('  - ID: ' + psList[0].Id + '\n');
                
                // Check CRUD permissions before SOQL query
                if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
                    status.append('  - Assignment count: ACCESS DENIED\n');
                } else {
                    // Count assignments
                    Integer assignmentCount = [
                    SELECT COUNT()
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId = :psList[0].Id
                    ];
                    status.append('  - Assigned to ' + assignmentCount + ' user(s)\n');
                }
            }
            }
        } else {
            status.append('✗ NOT FOUND\n');
        }
        
        status.append('\n');
        
        // Validation Errors
        if (!validation.errors.isEmpty()) {
            status.append('Errors:\n');
            for (String error : validation.errors) {
                status.append('  ✗ ' + error + '\n');
            }
            status.append('\n');
        }
        
        // Validation Warnings
        if (!validation.warnings.isEmpty()) {
            status.append('Warnings:\n');
            for (String warning : validation.warnings) {
                status.append('  ⚠ ' + warning + '\n');
            }
            status.append('\n');
        }
        
        // Overall Status
        status.append('Overall Status: ');
        if (validation.isValid()) {
            status.append('✓ SETUP COMPLETE\n');
        } else {
            status.append('✗ SETUP INCOMPLETE\n');
        }
        
        return status.toString();
    }

    /**
     * Inner class for validation results
     */
    public class SetupValidationResult {
        public Boolean configExists = false;
        public Boolean permissionSetExists = false;
        public List<String> errors = new List<String>();
        public List<String> warnings = new List<String>();

        public void addError(String error) {
            errors.add(error);
        }

        public void addWarning(String warning) {
            warnings.add(warning);
        }

        public Boolean isValid() {
            return errors.isEmpty() && configExists;
        }
    }

    /**
     * Custom exception for setup errors
     */
    public class SetupException extends Exception {}
}

