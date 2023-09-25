/**
 * Created by mverigin on 9/19/23.
 */

public with sharing class NZC_EmissionsMatchingHotelWrapper extends NZC_EmissionsMatchingWrapper {
    public NZC_EmissionsMatchingHotelWrapper(HotelStayEnrgyUse incomingEnergyUse) {
        super(incomingEnergyUse.Scope3EmssnSrcId, incomingEnergyUse.Id, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), null);
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }

    public NZC_EmissionsMatchingHotelWrapper(HotelStayEnrgyUse incomingEnergyUse, String generatedId) {
        super(incomingEnergyUse.Scope3EmssnSrcId, generatedId, NZC_EmissionsMatchingUtil.getDateForWrapper(incomingEnergyUse), null, String.valueOf(incomingEnergyUse.getSObjectType()));
        String masterId = (String) incomingEnergyUse.get(getEnergyUseLookupFieldName());
        attachMasterEmissionSetId(masterId);
        attachCustomMatchingField(incomingEnergyUse);
    }
}