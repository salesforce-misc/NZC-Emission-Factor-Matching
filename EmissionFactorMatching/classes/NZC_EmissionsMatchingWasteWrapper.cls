/**
 * Created by mverigin on 6/20/23.
 */

public with sharing class NZC_EmissionsMatchingWasteWrapper extends NZC_EmissionsMatchingWrapper {
    public NZC_EmissionsMatchingWasteWrapper(GeneratedWaste incomingEnergyUse) {
        super(incomingEnergyUse.StnryAssetEnvrSrcId, incomingEnergyUse.Id, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.DisposalType);
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
    }

    public NZC_EmissionsMatchingWasteWrapper(GeneratedWaste incomingEnergyUse, String generatedId) {
        super(incomingEnergyUse.StnryAssetEnvrSrcId, generatedId, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.DisposalType, String.valueOf(incomingEnergyUse.getSObjectType()));
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
    }
}