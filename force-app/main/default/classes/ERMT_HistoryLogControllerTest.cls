@isTest
public with sharing class ERMT_HistoryLogControllerTest {
    private static final String RISK_OBJECT = 'ermt__Risk__c';
    private static final String INCIDENT_OBJECT = 'ermt__Incident__c';
    private static final String CONTROL_OBJECT = 'ermt__Control__c';
    private static final String RISK_CONTROL_JUNC_OBJECT = 'ermt__Risk_Control_Junc__c';
    private static final String INCIDENT_CONTROL_JUNC_OBJECT = 'ermt__Incident_Control_Junc__c';
    private static final String INCIDENT_RISK_JUNC_OBJECT = 'ermt__Incident_Risk_Junc__c';

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
        for (Integer i = 0; i < 20; i++) {
            Risk__c risk = TestDataFactory.createRisk(i + 1, accs[0]);
            risks.add(risk);
        }
        insert risks;
        ret.put('Risk__c', risks);

        // Init Incident__c
        List<Incident__c> incidents = new List<Incident__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident__c incident = TestDataFactory.createIncident(i + 1, accs[0]);
            incident.LossCategory__c = '金額;人命';
            incidents.add(incident);
        }
        insert incidents;
        ret.put('Incident__c', incidents);

        // Init Control__c
        List<Control__c> controls = new List<Control__c>();
        for (Integer i = 0; i < 20; i++) {
            Control__c control = TestDataFactory.createControl(i + 1, accs[0]);
            controls.add(control);
        }
        insert controls;
        ret.put('Control__c', controls);

        // Init Incident_Risk_Junc__c
        List<Incident_Risk_Junc__c> incidentRiskJuncs = new List<Incident_Risk_Junc__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident_Risk_Junc__c incidentRiskJunc = TestDataFactory.createIncidentRisk(incidents[i], risks[0]);
            incidentRiskJuncs.add(incidentRiskJunc);
        }
        insert incidentRiskJuncs;
        ret.put('Incident_Risk_Junc__c', incidentRiskJuncs);

        // Init Risk_Control_Junc__c
        List<Risk_Control_Junc__c> riskControlJuncs = new List<Risk_Control_Junc__c>();
        for (Integer i = 0; i < 20; i++) {
            Risk_Control_Junc__c riskControlJunc = TestDataFactory.createRiskControl(risks[i], controls[0]);
            riskControlJuncs.add(riskControlJunc);
        }
        insert riskControlJuncs;
        ret.put('Risk_Control_Junc__c', riskControlJuncs);

        // Init Incident_Control_Junc__c
        List<Incident_Control_Junc__c> incidentControlJuncs = new List<Incident_Control_Junc__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident_Control_Junc__c incidentControlJunc = TestDataFactory.createIncidentControl(incidents[i], controls[0]);
            incidentControlJuncs.add(incidentControlJunc);
        }
        insert incidentControlJuncs;
        ret.put('Incident_Control_Junc__c', incidentControlJuncs);

        return ret;
    }

    // test fet column label of History__c
    @isTest
    static void testGetColumnLabel_01() {
        Map<String, String> result = ERMT_HistoryLogController.getColumnLabel();

        //compare
        System.assertEquals(6, result.size());
        System.assertEquals(getLabelOfField('ermt__Type__c'), result.get('ermt__Type__c'));
        System.assertEquals(getLabelOfField('ermt__OldValue__c'), result.get('ermt__OldValue__c'));
        System.assertEquals(getLabelOfField('ermt__NewValue__c'), result.get('ermt__NewValue__c'));
        System.assertEquals(getLabelOfField('ermt__FieldName__c'), result.get('ermt__FieldName__c'));
        System.assertEquals(getLabelOfField('OwnerId'), result.get('OwnerId'));
        System.assertEquals(getLabelOfField('CreatedDate'), result.get('CreatedDate'));
    }

    //test get object label + label history log
    @isTest
    static void testGetObjectLabel_01() {
        User u = createUserTest();
        System.runAs(u) {
            // The following code runs as user 'u' 
            String objectLabel = ERMT_HistoryLogController.getObjectLabel(RISK_OBJECT);
    
            //compare
            System.assertEquals('Risk', objectLabel);
        }
    }

    //test get Incident__c history log
    @isTest
    static void testGetNormalObjectHistoryLog_01() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__OccurrenceDatetime__c"}, {"ermt__ApiName__c" : "ermt__ReportDeadlineDate__c"}, {"ermt__ApiName__c" : "ermt__IncidentLevel__c"}, {"ermt__ApiName__c" : "ermt__LossCategory__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "ermt__OccurrenceDatetime__c"}, {"ermt__ApiName__c" : "ermt__ReportDeadlineDate__c"}, {"ermt__ApiName__c" : "ermt__IncidentLevel__c"}, {"ermt__ApiName__c" : "ermt__LossCategory__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        //DML
        Incident__c inc = incidents[0];
        inc.OccurrenceDatetime__c = Datetime.valueOfGMT('2002-05-02 00:00:00');
        inc.ReportDeadlineDate__c = Date.valueOf('2000-05-02 00:00:00');
        inc.IncidentLevel__c = 'グループ全体';
        inc.LossCategory__c = '金額;資産';
        update inc;

        List<History__c> histories = ERMT_HistoryLogController.getNormalObjectHistoryLog(INCIDENT_OBJECT, inc.Id);

        //compare
        System.assertEquals(4, histories.size());
    }

    //test get Incident_Risk_Junc__c history logs in incident record page
    @isTest
    static void testGetJunctionObjectHistoryLog_01() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ RISK_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "Name"}, {"ermt__ApiName__c" : "ermt__Detail__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ RISK_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata display of records are displayed
        String queryRecordDisplayedSetting = 'SELECT Listview__c FROM HistoryJunctionDisplayedConfiguration__mdt WHERE Listview__c != null AND HistoryLog__c = \''+ INCIDENT_RISK_JUNC_OBJECT +'\' AND IsActive__c = True AND RecordPage__c = \''+ INCIDENT_OBJECT +'\' LIMIT 50000';
        String recordSettingDisplayedString = '[{"ermt__Listview__c" : "「追加・削除のみ」"}]';
        CustomMetadataDAOTest.setMetadata(queryRecordDisplayedSetting, (List<HistoryJunctionDisplayedConfiguration__mdt>) JSON.deserialize(recordSettingDisplayedString, List<HistoryJunctionDisplayedConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident_Risk_Junc__c> juncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        Incident_Risk_Junc__c juncTest = new Incident_Risk_Junc__c(
            Incident__c = incidents[0].Id,
            Risk__c = risks[0].Id
        );

        //update data
        delete juncs[0];

        risks[0].Name = 'test Risk';
        risks[0].Detail__c = 'test detail';
        update risks;

        insert juncTest;

        risks[0].Name = 'test Risk ver 1.0';
        update risks;

        List<History__c> histories = ERMT_HistoryLogController.getJunctionObjectHistoryLog(incidents[0].Id, INCIDENT_OBJECT, INCIDENT_RISK_JUNC_OBJECT, RISK_OBJECT, 1);
        List<History__c> historyResult = [SELECT Id, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c = :INCIDENT_RISK_JUNC_OBJECT LIMIT 1];
        //Compare
        System.assertEquals(3, histories.size());
        System.assertEquals(INCIDENT_RISK_JUNC_OBJECT, historyResult[0].ObjectLog__c);
        System.assertEquals(incidents[0].Id, historyResult[0].ParentRecordId1__c);
        System.assertEquals(risks[0].Id, historyResult[0].ParentRecordId2__c);
    }

    //test get Incident_Risk_Junc__c history logs in risk record page
    @isTest
    static void testGetJunctionObjectHistoryLog_02() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__Title__c"}, {"ermt__ApiName__c" : "ermt__Detail__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ INCIDENT_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "ermt__Title__c"}, {"ermt__ApiName__c" : "ermt__Detail__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata display of records are displayed
        String queryRecordDisplayedSetting = 'SELECT Listview__c FROM HistoryJunctionDisplayedConfiguration__mdt WHERE Listview__c != null AND HistoryLog__c = \''+ INCIDENT_RISK_JUNC_OBJECT +'\' AND IsActive__c = True AND RecordPage__c = \''+ RISK_OBJECT +'\' LIMIT 50000';
        String recordSettingDisplayedString = '[{"ermt__Listview__c" : "「追加・削除のみ」"}]';
        CustomMetadataDAOTest.setMetadata(queryRecordDisplayedSetting, (List<HistoryJunctionDisplayedConfiguration__mdt>) JSON.deserialize(recordSettingDisplayedString, List<HistoryJunctionDisplayedConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident_Risk_Junc__c> juncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        Incident_Risk_Junc__c juncTest = new Incident_Risk_Junc__c(
            Incident__c = incidents[0].Id,
            Risk__c = risks[0].Id
        );

        //update data
        delete juncs[0];

        incidents[0].Title__c = 'test Incident';
        update incidents;

        insert juncTest;

        incidents[0].Title__c = 'test Incident ver 1.0';
        incidents[0].Detail__c = 'test detail';
        update incidents;


        List<History__c> histories = ERMT_HistoryLogController.getJunctionObjectHistoryLog(risks[0].Id, RISK_OBJECT, INCIDENT_RISK_JUNC_OBJECT, INCIDENT_OBJECT, 2);
        List<History__c> historyResult = [SELECT Id, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c = :INCIDENT_RISK_JUNC_OBJECT LIMIT 1];
        //Compare
        System.assertEquals(22, histories.size());
        System.assertEquals(INCIDENT_RISK_JUNC_OBJECT, historyResult[0].ObjectLog__c);
        System.assertEquals(incidents[0].Id, historyResult[0].ParentRecordId1__c);
        System.assertEquals(risks[0].Id, historyResult[0].ParentRecordId2__c);
    }

    //test get Incident_Control_Junc__c history logs in incident record page
    @isTest
    static void testGetJunctionObjectHistoryLog_03() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata display of records are displayed
        String queryRecordDisplayedSetting = 'SELECT Listview__c FROM HistoryJunctionDisplayedConfiguration__mdt WHERE Listview__c != null AND HistoryLog__c = \''+ INCIDENT_CONTROL_JUNC_OBJECT +'\' AND IsActive__c = True AND RecordPage__c = \''+ INCIDENT_OBJECT +'\' LIMIT 50000';
        String recordSettingDisplayedString = '[{"ermt__Listview__c" : "「追加・削除のみ」"}, {"ermt__Listview__c" : "「追加・削除・変更」"}]';
        CustomMetadataDAOTest.setMetadata(queryRecordDisplayedSetting, (List<HistoryJunctionDisplayedConfiguration__mdt>) JSON.deserialize(recordSettingDisplayedString, List<HistoryJunctionDisplayedConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //update data
        controls[0].Name = 'test Control';
        update controls;
   
        List<History__c> histories = ERMT_HistoryLogController.getJunctionObjectHistoryLog(incidents[0].Id, INCIDENT_OBJECT, INCIDENT_CONTROL_JUNC_OBJECT, CONTROL_OBJECT, 1);

        List<History__c> historyResult = [SELECT Id, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c = :INCIDENT_CONTROL_JUNC_OBJECT LIMIT 1];
        
        //Compare
        System.assertEquals(2, histories.size());
        System.assertEquals(INCIDENT_CONTROL_JUNC_OBJECT, historyResult[0].ObjectLog__c);
        System.assertEquals(incidents[0].Id, historyResult[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, historyResult[0].ParentRecordId2__c);
    }

    //test get Risk_Control_Junc__c history logs in risk record page
    @isTest
    static void testGetJunctionObjectHistoryLog_04() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata display of records are displayed
        String queryRecordDisplayedSetting = 'SELECT Listview__c FROM HistoryJunctionDisplayedConfiguration__mdt WHERE Listview__c != null AND HistoryLog__c = \''+ RISK_CONTROL_JUNC_OBJECT +'\' AND IsActive__c = True AND RecordPage__c = \''+ RISK_OBJECT +'\' LIMIT 50000';
        String recordSettingDisplayedString = '[{"ermt__Listview__c" : "「追加・削除のみ」"}, {"ermt__Listview__c" : "「追加・削除・変更」"}]';
        CustomMetadataDAOTest.setMetadata(queryRecordDisplayedSetting, (List<HistoryJunctionDisplayedConfiguration__mdt>) JSON.deserialize(recordSettingDisplayedString, List<HistoryJunctionDisplayedConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');
        List<Risk_Control_Junc__c> juncs = (List<Risk_Control_Junc__c>)data.get('Risk_Control_Junc__c');
        Risk_Control_Junc__c juncTest = new Risk_Control_Junc__c(
            Control__c = controls[0].Id,
            Risk__c = risks[0].Id
        );


        //update data
        delete juncs;

        controls[0].Name = 'test Control';
        update controls;

        insert juncTest;
   
        List<History__c> histories = ERMT_HistoryLogController.getJunctionObjectHistoryLog(risks[0].Id, RISK_OBJECT, RISK_CONTROL_JUNC_OBJECT, CONTROL_OBJECT, 1);
        
        //Compare
        System.assertEquals(3, histories.size());
        System.assertEquals(RISK_CONTROL_JUNC_OBJECT, histories[0].ObjectLog__c);
        System.assertEquals(risks[0].Id, histories[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, histories[0].ParentRecordId2__c);
    }

    //test get Risk_Control_Junc__c history logs in control record page
    @isTest
    static void testGetJunctionObjectHistoryLog_05() {
        //fake data custom metadata fields are logged
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ RISK_OBJECT + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        //fake data custom metadata fields are displayed
        String queryFieldDisplayedSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ RISK_OBJECT + '\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        String fieldSettingDisplayedString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldDisplayedSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingDisplayedString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //update data
        risks[0].Name = 'test Risk';
        update risks;
   
        List<History__c> histories = ERMT_HistoryLogController.getJunctionObjectHistoryLog(controls[0].Id, CONTROL_OBJECT, RISK_CONTROL_JUNC_OBJECT, RISK_OBJECT, 2);
        List<History__c> historyResult = [SELECT Id, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c = :RISK_CONTROL_JUNC_OBJECT LIMIT 1];
        
        //Compare
        System.assertEquals(21, histories.size());
        System.assertEquals(RISK_CONTROL_JUNC_OBJECT, historyResult[0].ObjectLog__c);
        System.assertEquals(risks[0].Id, historyResult[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, historyResult[0].ParentRecordId2__c);
    }

    //test get history type map
    @isTest
    static void testGetHistoryTypeMap_01() {
        User u = createUserTest();
        System.runAs(u) {
            // The following code runs as user 'u' 
            Map<String, String> result = ERMT_HistoryLogController.getHistoryTypeMap();
            
            //compare
            System.assertEquals('Deleted', result.get('削除'));
            System.assertEquals('Changed', result.get('変更'));
            System.assertEquals('Added', result.get('追加'));
        }
    }

    private static String getLabelOfField(String fieldString) {
        return Schema.getGlobalDescribe().get('ermt__History__c').getDescribe().fields.getMap().get(fieldString).getDescribe().getLabel(); 
    }

    private static User createUserTest() {
        List<User> uesrsAdmin = [SELECT Id, Profile.Id FROM User WHERE Profile.PermissionsModifyAllData = TRUE AND profile.PermissionsCustomizeApplication= TRUE AND isActive=TRUE LIMIT 1];
        return new User(Alias = 'standt', Email='standarduserdhgvjkdfh@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = uesrsAdmin[0].Profile.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdhgvjkdfh@testorg.com'); 
    }
}