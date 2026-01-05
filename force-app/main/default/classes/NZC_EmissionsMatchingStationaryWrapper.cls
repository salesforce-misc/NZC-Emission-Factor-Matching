/**
 * Copyright (c) 2025, Salesforce, Inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/Apache-2.0
 */


public with sharing class NZC_EmissionsMatchingStationaryWrapper extends NZC_EmissionsMatchingWrapper {
    public NZC_EmissionsMatchingStationaryWrapper(StnryAssetEnrgyUse incomingEnergyUse) {
        super(incomingEnergyUse.StnryAssetEnvrSrcId, incomingEnergyUse.Id, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.FuelType);
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }

    public NZC_EmissionsMatchingStationaryWrapper(StnryAssetEnrgyUse incomingEnergyUse, String generatedId) {
        super(incomingEnergyUse.StnryAssetEnvrSrcId, generatedId, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.FuelType, String.valueOf(incomingEnergyUse.getSObjectType()));
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }
}