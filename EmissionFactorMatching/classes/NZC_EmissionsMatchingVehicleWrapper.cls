/**
 * Created by mverigin on 6/20/23.
 */

public with sharing class NZC_EmissionsMatchingVehicleWrapper extends NZC_EmissionsMatchingWrapper {
    public NZC_EmissionsMatchingVehicleWrapper(VehicleAssetEnrgyUse incomingEnergyUse) {
        super(incomingEnergyUse.VehicleAssetEmssnSrcId, incomingEnergyUse.Id, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.FuelType);
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }

    public NZC_EmissionsMatchingVehicleWrapper(VehicleAssetEnrgyUse incomingEnergyUse, String generatedId) {
        super(incomingEnergyUse.VehicleAssetEmssnSrcId, generatedId, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), incomingEnergyUse.FuelType, String.valueOf(incomingEnergyUse.getSObjectType()));
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }
}