/*
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */

/**
 * Logs the outcome of a matching rule metadata deployment started by the rule wizard.
 * The wizard itself confirms success by reading the rule back, see NZC_EmissionsMatchingRuleController.
 */
public with sharing class NZC_EmissionsMatchingRuleDeployCallback implements Metadata.DeployCallback {

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            NZC_EmissionsMatchingLog.log('matching rule deployed', result.id);
            return;
        }
        List<String> problems = new List<String>();
        for (Metadata.DeployMessage message : result.details.componentFailures) {
            problems.add(message.fullName + ': ' + message.problem);
        }
        NZC_EmissionsMatchingLog.log('matching rule deployment failed', problems);
    }
}
