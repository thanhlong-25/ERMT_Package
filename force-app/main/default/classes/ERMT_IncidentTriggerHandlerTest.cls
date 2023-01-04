@isTest
public with sharing class ERMT_IncidentTriggerHandlerTest {
    private static final String INCIDENT_OBJECT_NAME = 'ermt__Incident__c';

    //init data
    static Map<String, Object> initData(){
        Map<String, Object> ret = new Map<String, Object>();

        // Init account
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = TestDataFactory.createAccount(i + 1);
            accs.add(acc);
        }
        insert accs;
        ret.put('Account', accs);

         // Init Risk__c
        List<Risk__c> risks = new List<Risk__c>();
        for (Integer i = 0; i < 2; i++) {
            Risk__c risk = TestDataFactory.createRisk(i + 1, accs[0]);
            risks.add(risk);
        }
        insert risks;
        ret.put('Risk__c', risks);

        // Init Incident__c
        List<Incident__c> incidents = new List<Incident__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident__c incident = TestDataFactory.createIncident(i + 1, accs[0]);
            incidents.add(incident);
        }
        insert incidents;
        ret.put('Incident__c', incidents);

        // Init Incident_Risk_Junc__c
        List<Incident_Risk_Junc__c> incidentRiskJuncs = new List<Incident_Risk_Junc__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident_Risk_Junc__c incidentRiskJunc = TestDataFactory.createIncidentRisk(incidents[i], risks[0]);
            incidentRiskJuncs.add(incidentRiskJunc);
        }
        insert incidentRiskJuncs;
        ret.put('Incident_Risk_Junc__c', incidentRiskJuncs);

        return ret;
    }

    // Update Incident with Title__c change
    @isTest
    static void updateIncidentLinkValue_Test_1(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Incident_Risk_Junc__c> incidentRiskJuncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        String incidentLinkValueBeforeTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;

        // DML data test
        incidents[0].Title__c = 'Title updated';
        update incidents;

        // Compare
        String incidentLinkValueAfterTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(true, incidentLinkValueBeforeTest != incidentLinkValueAfterTest);
        System.assertEquals(false, incidentLinkValueBeforeTest.contains('Title updated'));
        System.assertEquals(true, incidentLinkValueAfterTest.contains('Title updated') );
    }

    // Update Incident but not Title change
    @isTest
    static void updateIncidentLinkValue_Test_2(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Incident_Risk_Junc__c> incidentRiskJuncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        String incidentLinkValueBeforeTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;

        // DML data test
        update incidents;

        // Compare
        String incidentLinkValueAfterTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(true, incidentLinkValueBeforeTest == incidentLinkValueAfterTest);
        System.assertEquals(false, incidentLinkValueBeforeTest.contains('Title updated'));
        System.assertEquals(false, incidentLinkValueAfterTest.contains('Title updated') );
    }

    // Save HistoryLog when Incident update primitive type field
    @IsTest
    static void saveHistoryLog_Test_1(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = true LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__Detail__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML test
        Incident__c inc = incidents[0];
        inc.Detail__c = 'detail updated';
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c);  // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__Detail__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('detail updated', historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Incident update Reference field
    @IsTest
    static void saveHistoryLog_Test_2(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__Organization__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Account> accounts = (List<Account>)data.get('Account');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.Organization__c = accounts[1].Id;
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c); // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__Organization__c', historiesAfter[0].FieldName__c);
        System.assertEquals(accounts[0].Name, historiesAfter[0].OldValue__c);
        System.assertEquals(accounts[1].Name, historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Incident update Datetime Field
    @IsTest
    static void saveHistoryLog_Test_3(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__OccurrenceDatetime__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.OccurrenceDatetime__c = Datetime.valueOfGMT('2000-05-02 00:00:00');
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c); // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__OccurrenceDatetime__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('2000-05-02 00:00:00', historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Incident update Date Field
    @IsTest
    static void saveHistoryLog_Test_4(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__ReportDeadlineDate__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.ReportDeadlineDate__c = Date.valueOf('2000-05-02 00:00:00');
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c); // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__ReportDeadlineDate__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('2000-05-02 00:00:00', historiesAfter[0].NewValue__c);
    }

    //Save HistoryLog when Incident update Picklist Field
    @IsTest
    static void saveHistoryLog_Test_5(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__IncidentLevel__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.IncidentLevel__c = 'グループ全体';
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c); // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__IncidentLevel__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('グループ全体', historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Incident update Multipicklist Field
    @IsTest
    static void saveHistoryLog_Test_6(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__LossCategory__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.LossCategory__c = '金額;資産';
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c); // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Incident__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__LossCategory__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('金額;資産', historiesAfter[0].NewValue__c);
    }

    //test save history log when no setting field in custom metadata
    @IsTest
    static void saveHistoryLog_Test_7() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        Incident__c inc = incidents[0];
        inc.LossCategory__c = '金額;資産';
        update inc;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: inc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(0, historiesAfter.size());
    }

    // Save HistoryLog when Incident update Multipicklist Field
    @IsTest
    static void deleteAllIncidentRiskJunc_Test_1(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML Test
        delete incidents;

        //Compare
        List<Incident_Risk_Junc__c> irjs = [SELECT ID FROM Incident_Risk_Junc__c];
        System.assertEquals(0, irjs.size());
    }
}