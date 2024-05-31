/**
 * Created by mverigin on 4/18/24.
 */

public with sharing class NZC_EmissionMatchingInsertWrapper {
    private static final String DATE_MATCH_PATTERN = '(\\d{4})';
    private static final String STRIP_REGEX = '[^a-zA-Z\\s-_]';
    private static final String STRIP_BRACKETS = '\\([^)]*\\)';

    @InvocableVariable(Required=true Label='Record to link in hierarchy' Description='Record inserting to process into emissions hierarchy structure')
    public SObject recordInserting;

    @InvocableVariable(Required=true Label='Record hierarchy lookup name' Description='Lookup field used to link this record in hierarchy structure')
    public String lookupName;

    @InvocableVariable(Required=true Label='Api field name of date field used for sorting' Description='Date field used to demark when this emissions set it relevant from')
    public String dateFieldName;

    public String name;

    public Date startDate;

    public List<NZC_EmissionMatchingInsertWrapper> relevantEmissionsSets;

    public void preProcessRecords() {
        name = (String) recordInserting.get('Name');
        relevantEmissionsSets = new List<NZC_EmissionMatchingInsertWrapper>();
        parseName();
        determineStartDate();
    }

    private void parseName() {
        name = name.replaceAll(STRIP_BRACKETS, '');
        name = name.replaceAll(STRIP_REGEX, '').trim();
    }

    private void parseDateFromName(String name) {
        Pattern regexPattern = Pattern.compile(DATE_MATCH_PATTERN);
        Matcher patternMatcher = regexPattern.matcher(name);
        if (patternMatcher.find()) {
            String yearExtracted = patternMatcher.group();
            startDate = Date.newInstance(Integer.valueOf(yearExtracted), 01, 01);
        }
    }

    private void determineStartDate() {
        // use created as default
        //TODO REMOVE startDate = Date.valueOf((Datetime) recordInserting.get('CreatedDate'));
        // use date from name next if available
        parseDateFromName((String) recordInserting.get('Name'));
        // if user defined date use that as default
        if ((Date) recordInserting.get(dateFieldName) != null) {
            startDate = (Date) recordInserting.get(dateFieldName);
        }
    }
}