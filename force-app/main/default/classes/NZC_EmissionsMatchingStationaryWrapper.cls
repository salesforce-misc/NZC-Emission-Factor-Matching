/**
 * Created by mverigin on 6/19/23.
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