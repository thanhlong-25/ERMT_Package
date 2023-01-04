@isTest
public with sharing class IncidentShareCreateBatchTest {
    // Private member variable
    private static final String ACCESS_LEVEL_READ = 'Read';
    private static final String ACCESS_LEVEL_EDIT = 'Edit';
    private static final String ACCESS_LEVEL_OFF = 'Off';

    private static Integer recordNumber = 5;

    private static Integer batchSizeNumber = 200;

    private static final Incident_Configration__mdt configMdt = Incident_Configration__mdt.getInstance('Default');

    @TestSetup
    static void makeData() {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < recordNumber; i++) {
            accs.add(
                new Account(
                    Name = 'Test' + i,
                    BillingPostalCode = '123-4567',
                    BillingState = 'Test' + i,
                    BillingCity = 'Test' + i,
                    BillingStreet = 'Test' + i
                )
            );
        }
        insert accs;
        List<ermt__Incident__c> incidents = new List<ermt__Incident__c>();
        for (Account acc : accs) {
            incidents.add(new ermt__Incident__c(ermt__Organization__c = acc.Id, ermt__Detail__c = 'Test' + acc.Id));
        }
        insert incidents;
    }

    @isTest
    static void testExecuteBatch() {
        List<ermt__Incident__c> listIncident = getListIncident();
        List<String> filterGroup = getListOrganizationGroup(listIncident);
        Map<String, String> mapGroupField = convertMapGroup(
            new List<Group>([SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :filterGroup])
        );
        Test.startTest();
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        IncidentShareCreateBatch.configMdt = setConfigCustomMeta(ACCESS_LEVEL_READ);
        String rowCauseConfig = getRowCauseByConfigMdt(ACCESS_LEVEL_READ);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();
        List<ermt__Incident__Share> listShareExecute = getListShare();
        List<ermt__Incident__Share> listIncidentShareWithOrganization = new List<ermt__Incident__Share>();

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            String groupId = mapGroupField.get(recordIncident.ermt__Organization__c);

            for (ermt__Incident__Share recordShare : recordIncident.Shares) {
                System.assertEquals(
                    rowCauseConfig,
                    recordShare.RowCause,
                    'testExecuteBatch ermt__Incident__Share rowCause equals in AccountPublicGroupSharingReason_Read__c or AccountPublicGroupSharingReason_Edit__c'
                );

                System.assertEquals(
                    groupId,
                    (String) recordShare.UserOrGroupId,
                    'testExecuteBatch ermt__Incident__Share UserOrGroupId equals ermt__Organization__c'
                );
            }
        }

        System.assertEquals(
            recordNumber,
            listShareExecute.size(),
            'testEditRowCauseSharing ermt__Incident__Share records should be returned equals after execute batch'
        );

        System.assertEquals(
            listIncidentExecute.size(),
            listIncident.size(),
            'testExecuteBatch ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    @isTest
    static void testEditRowCauseSharing() {
        List<ermt__Incident__Share> listShareCurrent = getListShare();
        List<ermt__Incident__c> listIncident = getListIncident();
        List<String> filterGroup = getListOrganizationGroup(listIncident);

        Map<String, String> mapGroupField = convertMapGroup(
            new List<Group>([SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :filterGroup])
        );

        Test.startTest();
        String accessLevel = 'Edit';
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        IncidentShareCreateBatch.configMdt = setConfigCustomMeta(ACCESS_LEVEL_EDIT);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();
        String rowCauseConfig = getRowCauseByConfigMdt(ACCESS_LEVEL_EDIT);
        List<ermt__Incident__Share> listShareExecute = getListShare();

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            String groupId = mapGroupField.get(recordIncident.ermt__Organization__c);

            for (ermt__Incident__Share recordShare : recordIncident.Shares) {
                System.assertEquals(
                    rowCauseConfig,
                    recordShare.RowCause,
                    'testExecuteBatch ermt__Incident__Share rowCause equals in AccountPublicGroupSharingReason_Edit__c'
                );
                System.assertEquals(
                    groupId,
                    (String) recordShare.UserOrGroupId,
                    'testEditRowCauseSharing ermt__Incident__Share UserOrGroupId equals ermt__Organization__c'
                );
            }
        }
        System.assertEquals(
            recordNumber,
            listShareExecute.size(),
            'testEditRowCauseSharing ermt__Incident__Share records should be returned equals after execute batch'
        );

        System.assertEquals(
            listIncidentExecute.size(),
            listIncident.size(),
            'testEditRowCauseSharing ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    @isTest
    static void testReadRowCauseSharing() {
        List<ermt__Incident__c> listIncident = getListIncident();
        List<String> filterGroup = getListOrganizationGroup(listIncident);

        Map<String, String> mapGroupField = convertMapGroup(
            new List<Group>([SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :filterGroup])
        );

        Test.startTest();
        String accessLevel = 'Read';
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        IncidentShareCreateBatch.configMdt = setConfigCustomMeta(accessLevel);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__Share> listShareExecute = getListShare();
        List<ermt__Incident__c> listIncidentExecute = getListIncident();
        String rowCauseConfig = getRowCauseByConfigMdt(accessLevel);

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            String groupId = mapGroupField.get(recordIncident.ermt__Organization__c);

            for (ermt__Incident__Share recordShare : recordIncident.Shares) {
                System.assertEquals(
                    rowCauseConfig,
                    recordShare.RowCause,
                    'testReadRowCauseSharing ermt__Incident__Share rowCause equals in AccountPublicGroupSharingReason_Edit__c'
                );
                System.assertEquals(
                    groupId,
                    (String) recordShare.UserOrGroupId,
                    'testReadRowCauseSharing ermt__Incident__Share UserOrGroupId equals ermt__Organization__c'
                );
            }
        }
        System.assertEquals(
            recordNumber,
            listShareExecute.size(),
            'testReadRowCauseSharing ermt__Incident__Share records should be returned equals after execute batch'
        );

        System.assertEquals(
            listIncidentExecute.size(),
            listIncident.size(),
            'testReadRowCauseSharing ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    @isTest
    static void testOffRowCauseSharing() {
        Test.startTest();
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        IncidentShareCreateBatch.configMdt = setConfigCustomMeta(ACCESS_LEVEL_OFF);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            System.assertEquals(
                0,
                recordIncident.Shares.size(),
                'testOffRowCauseSharing equals 0 records should be returned after execute batch'
            );
        }

        System.assertEquals(
            recordNumber,
            listIncidentExecute.size(),
            'testOffRowCauseSharing ermt__Incident__c equals records should be returned  after execute batch'
        );
    }

    @isTest
    static void testExptValueRowCauseSharing() {
        Test.startTest();
        String accessLevel = 'test';
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        IncidentShareCreateBatch.configMdt = setConfigCustomMeta(accessLevel);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            System.assertEquals(
                0,
                recordIncident.Shares.size(),
                'testExptValueRowCauseSharing equals 0 records should be returned after execute batch'
            );
        }

        System.assertEquals(
            recordNumber,
            listIncidentExecute.size(),
            'testExptValueRowCauseSharing ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    @isTest
    static void testEmptyValueCustomMeta() {
        Test.startTest();
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        // IncidentShareCreateBatch.configMdt = (Incident_Configration__mdt) JSON.deserialize('{}', Incident_Configration__mdt.class);
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();

        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            System.assertEquals(
                1,
                recordIncident.Shares.size(),
                'testEmptyValueCustomMeta equals 1 records should be returned after execute batch'
            );
        }

        System.assertEquals(
            recordNumber,
            listIncidentExecute.size(),
            'testEmptyValueCustomMeta ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    @isTest
    static void testEmptyFieldOrganizationIncident() {
        Test.startTest();
        List<ermt__Incident__c> listIncident = getListIncident();
        for (ermt__Incident__c recordIncident : listIncident) {
            recordIncident.ermt__Organization__c = null;
        }
        upsert listIncident;
        IncidentShareCreateBatch batchClass = new IncidentShareCreateBatch();
        Id batchJobId = Database.executeBatch(batchClass, batchSizeNumber);
        Test.stopTest();
        //after the testing stops
        List<ermt__Incident__c> listIncidentExecute = getListIncident();
        for (ermt__Incident__c recordIncident : listIncidentExecute) {
            System.assertEquals(
                0,
                recordIncident.Shares.size(),
                'testEmptyFieldOrganizationIncident equals 0 records should be returned after execute batch'
            );
        }
        System.assertEquals(
            recordNumber,
            listIncidentExecute.size(),
            'testEmptyFieldOrganizationIncident ermt__Incident__c records should be returned equals after execute batch'
        );
    }

    private static List<ermt__Incident__Share> getListShare() {
        return [
            SELECT Id, RowCause, ParentId, UserOrGroupId
            FROM ermt__Incident__Share
            WHERE RowCause = 'ermt__AccountPublicGroupSharingReason_Read__c' OR RowCause = 'ermt__AccountPublicGroupSharingReason_Edit__c'
        ];
    }

    private static List<ermt__Incident__c> getListIncident() {
        return [
            SELECT
                Id,
                ermt__Organization__c,
                (
                    SELECT Id, RowCause, ParentId, UserOrGroupId
                    FROM Shares
                    WHERE
                        RowCause = 'ermt__AccountPublicGroupSharingReason_Read__c'
                        OR RowCause = 'ermt__AccountPublicGroupSharingReason_Edit__c'
                )
            FROM ermt__Incident__c
        ];
    }

    private static ermt__Incident_Configration__mdt setConfigCustomMeta(String value) {
        return (ermt__Incident_Configration__mdt) JSON.deserialize(
            '{"ermt__Sharing_Incidents_With_Public_Groups__c": \"' +
            value +
            '\"}',
            ermt__Incident_Configration__mdt.class
        );
    }

    private static String getRowCauseByConfigMdt(String value) {
        return 'ermt__AccountPublicGroupSharingReason_' + value + '__c';
    }

    private static Map<String, String> convertMapGroup(List<Group> listGroup) {
        Map<String, String> mapGroup = new Map<String, String>();

        for (Group record : listGroup) {
            String parts = record.DeveloperName.substringAfter('_');
            if (String.isNotBlank(parts)) {
                mapGroup.put(parts, record.Id);
            }
        }

        return mapGroup;
    }

    private static List<String> getListOrganizationGroup(List<ermt__Incident__c> listIncident) {
        List<String> filterGroup = new List<String>();
        for (ermt__Incident__c record : listIncident) {
            String organization = record.ermt__Organization__c;
            if (String.isNotBlank(organization)) {
                filterGroup.add('Account_' + organization);
            }
        }
        return filterGroup;
    }
}