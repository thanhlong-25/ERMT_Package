@isTest
public with sharing class CustomMetadataDAOTest {
    @isTest
    static void testGetMetadata() {
        List<SObject> customMetadataRecords;
        Test.startTest();
        customMetadataRecords = new CustomMetadataDAO().getCustomMetadataRecords('SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND IsActive__c = true LIMIT 50000');
        Test.stopTest();
        System.assertEquals([SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND IsActive__c = true LIMIT 50000].size(), customMetadataRecords.size());
    }

    public static void setMetadata(String query, List<SObject> records) {
        CustomMetadataDAO.customMetadataRecordsMap.put(query, records);
    }
}