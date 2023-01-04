public with sharing class CustomMetadataDAO {
    @testVisible static private Map<String, List<SObject>> customMetadataRecordsMap = new Map<String, List<SObject>>();

    public List<SObject> getCustomMetadataRecords(String query) {
        if (!customMetadataRecordsMap.containsKey(query)) {
            customMetadataRecordsMap.put(query, Database.query(query));
        }
        return customMetadataRecordsMap.get(query);
    }
}