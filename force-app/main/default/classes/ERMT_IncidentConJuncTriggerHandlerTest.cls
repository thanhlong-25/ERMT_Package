@isTest
public with sharing class ERMT_IncidentConJuncTriggerHandlerTest {
    private static final String INCIDENT_CONTROL_JUNC_OBJECT = 'ermt__Incident_Control_Junc__c';
    static Map<String, Object> initData(){
        Map<String, Object> ret = new Map<String, Object>();

        // Init account
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 1; i++) {
            Account acc = TestDataFactory.createAccount(i + 1);
            accs.add(acc);
        }
        insert accs;
        ret.put('Account', accs);

         // Init Control__c
        List<Control__c> controls = new List<Control__c>();
        for (Integer i = 0; i < 2; i++) {
            Control__c control = TestDataFactory.createControl(i + 1, accs[0]);
            controls.add(control);
        }
        insert controls;
        ret.put('Control__c', controls);

        // Init Incident__c
        List<Incident__c> incidents = new List<Incident__c>();
        for (Integer i = 0; i < 20; i++) {
            Incident__c incident = TestDataFactory.createIncident(i + 1, accs[0]);
            incidents.add(incident);
        }
        insert incidents;
        ret.put('Incident__c', incidents);

        // Init Incident_control_Junc__c
        List<Incident_Control_Junc__c> incidentControlJuncs = new List<Incident_Control_Junc__c>();
        for (Integer i = 0; i < 2; i++) {
            Incident_Control_Junc__c incidentControlJunc = TestDataFactory.createIncidentControl(incidents[i], controls[0]);
            incidentControlJuncs.add(incidentControlJunc);
        }
        insert incidentControlJuncs;
        ret.put('Incident_Control_Junc__c', incidentControlJuncs);

        return ret;
    }

    //test save Incident_Control_Junc__c history log when Incident linked to Control
    @isTest
    static void testSaveHistoryLog_01() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        List<History__c> histories = [SELECT Id, Type__c, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c =: INCIDENT_CONTROL_JUNC_OBJECT LIMIT 1];

        //compare
        System.assertEquals(1, histories.size());
        System.assertEquals(INCIDENT_CONTROL_JUNC_OBJECT, histories[0].ObjectLog__c);
        System.assertEquals('追加', histories[0].Type__c);
        System.assertEquals(incidents[0].Id, histories[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, histories[0].ParentRecordId2__c);
    }

    //test save Incident_Control_Junc__c history log when Incident unlinked to Control
    @isTest
    static void testSaveHistoryLog_02() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;
        
        //DML
        delete controls;

        List<History__c> histories = [SELECT Id, Type__c, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c =: INCIDENT_CONTROL_JUNC_OBJECT LIMIT 1];

        //compare
        System.assertEquals(1, histories.size());
        System.assertEquals(INCIDENT_CONTROL_JUNC_OBJECT, histories[0].ObjectLog__c);
        System.assertEquals('削除', histories[0].Type__c);
        System.assertEquals(incidents[0].Id, histories[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, histories[0].ParentRecordId2__c);
    }
}