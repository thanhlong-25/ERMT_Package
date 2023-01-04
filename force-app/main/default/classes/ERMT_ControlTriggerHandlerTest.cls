@isTest
public with sharing class ERMT_ControlTriggerHandlerTest {
    private static final String CONTROL_OBJECT_NAME = 'ermt__Control__c';
    
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

    // Save HistoryLog when Control update primitive type field
    @IsTest
    static void saveHistoryLog_Test_1(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__Period__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;


        // DML test
        Control__c control = controls[0];
        control.Period__c = 'test';
        update control;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: control.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c);  // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Control__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__Period__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('test', historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Control update reference field
    @IsTest
    static void saveHistoryLog_Test_2(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__AssignedOrg__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');
        List<Account> accounts = (List<Account>)data.get('Account');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;


        // DML test
        Control__c control = controls[0];
        control.AssignedOrg__c = accounts[1].Id;
        update control;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: control.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c);  // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Control__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__AssignedOrg__c', historiesAfter[0].FieldName__c);
        System.assertEquals(accounts[0].Name, historiesAfter[0].OldValue__c);
        System.assertEquals(accounts[1].Name, historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Control update picklist field
    @IsTest
    static void saveHistoryLog_Test_3(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "ermt__ExecutionFrequency__c"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;


        // DML test
        Control__c control = controls[0];
        control.ExecutionFrequency__c = '日次';
        update control;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: control.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c);  // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Control__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('ermt__ExecutionFrequency__c', historiesAfter[0].FieldName__c);
        System.assertEquals(null, historiesAfter[0].OldValue__c);
        System.assertEquals('日次', historiesAfter[0].NewValue__c);
    }

    // Save HistoryLog when Control update Name field
    @IsTest
    static void saveHistoryLog_Test_4(){
        //fake data custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ CONTROL_OBJECT_NAME + '\' AND IsActive__c = True LIMIT 50000';
        String fieldSettingString = '[{"ermt__ApiName__c" : "Name"}]';
        CustomMetadataDAOTest.setMetadata(queryFieldSetting, (List<HistoryLogConfiguration__mdt>) JSON.deserialize(fieldSettingString, List<HistoryLogConfiguration__mdt>.class));

        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;


        // DML test
        Control__c control = controls[0];
        control.Name = 'test';
        update control;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: control.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('変更', historiesAfter[0].Type__c);  // 変更 is UPDATE_TYPE
        System.assertEquals('ermt__Control__c', historiesAfter[0].ObjectLog__c);
        System.assertEquals('Name', historiesAfter[0].FieldName__c);
        System.assertEquals('対応策1', historiesAfter[0].OldValue__c);
        System.assertEquals('test', historiesAfter[0].NewValue__c);
    }

    //Save history log when no set field in custom metadata
    @IsTest
    static void saveHistoryLog_Test_5() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;


        // DML test
        Control__c control = controls[0];
        control.Name = 'test';
        update control;

        //Compare
        List<History__c> historiesAfter = [SELECT Id, Type__c, RecordId__c, ObjectLog__c, FieldName__c, OldValue__c, NewValue__c
            FROM History__c
            WHERE RecordId__c =: control.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(0, historiesAfter.size());
    }

    // Test delete junction record Incident_Control_Junc__c
    @IsTest
    static void deleteAllIncidentControlJunc_Test_1(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        // DML Test
        delete controls;

        //Compare
        List<Incident_Control_Junc__c> icjs = [SELECT ID FROM Incident_Control_Junc__c];
        System.assertEquals(0, icjs.size());
    }

    // Test delete junction record Risk_Control_Junc__c
    @IsTest
    static void deleteAllRiskControlJunc_Test_1(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        // DML Test
        delete controls;

        //Compare
        List<Risk_Control_Junc__c> rcjs = [SELECT ID FROM Risk_Control_Junc__c];
        System.assertEquals(0, rcjs.size());
    }
}