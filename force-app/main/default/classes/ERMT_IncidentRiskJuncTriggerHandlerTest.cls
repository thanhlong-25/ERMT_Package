@isTest
public with sharing class ERMT_IncidentRiskJuncTriggerHandlerTest {

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
        for (Integer i = 0; i < 2; i++) {
            Incident_Risk_Junc__c incidentRiskJunc = TestDataFactory.createIncidentRisk(incidents[i], risks[0]);
            incidentRiskJuncs.add(incidentRiskJunc);
        }
        insert incidentRiskJuncs;
        ret.put('Incident_Risk_Junc__c', incidentRiskJuncs);

        return ret;
    }

    @isTest
    static void updateIncidentLinkValue_Test_1(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML data test
        List<Incident_Risk_Junc__c> irjs = new List<Incident_Risk_Junc__c>();
        irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[0].id, Incident__c = incidents[0].id));
        irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[0].id, Incident__c = incidents[1].id));
        insert irjs;

        // Compare
        String incidentLinkValue = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(false, incidentLinkValue.endsWith('...'));
    }

    @isTest
    static void updateIncidentLinkValue_Test_2(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML data test
        List<Incident_Risk_Junc__c> irjs = new List<Incident_Risk_Junc__c>();
        irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[0].id, Incident__c = incidents[0].id));
        irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[0].id, Incident__c = incidents[1].id));
        irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[1].id, Incident__c = incidents[0].id));
        insert irjs;

        // Compare
        String incidentLinkValue_1 = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        String incidentLinkValue_2 = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[1].id LIMIT 1]?.Incident_Links__c;

        System.assertEquals(false, incidentLinkValue_1.endsWith('...'));
        System.assertEquals(false, incidentLinkValue_2.endsWith('...'));
        System.assertEquals('<p><a href="/' + incidents[0].id + '" target="_blank">' + incidents[0].Title__c + '</a></p>', incidentLinkValue_2);
    }

    @isTest
    static void updateIncidentLinkValue_Test_3(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident__c> incidents = (List<Incident__c>)data.get('Incident__c');

        // DML data test
        List<Incident_Risk_Junc__c> irjs = new List<Incident_Risk_Junc__c>();
        for (Integer i = 0; i < 20; i++) {
            irjs.add(new Incident_Risk_Junc__c(Risk__c = risks[0].id, Incident__c = incidents[i].id));
        }
        insert irjs;

        // Compare
        String incidentLinkValue = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(true, incidentLinkValue.endsWith('...'));
    }

    @isTest
    static void updateIncidentLinkValue_Test_4(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident_Risk_Junc__c> incidentRiskJuncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        String incidentLinkValueBeforeTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;

        // DML data test
        delete incidentRiskJuncs;

        // Compare
        String incidentLinkValueAfterTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(true, String.isBlank(incidentLinkValueAfterTest));
        System.assertEquals(true, incidentLinkValueBeforeTest != incidentLinkValueAfterTest);
    }

    @isTest
    static void updateIncidentLinkValue_Test_5(){
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Incident_Risk_Junc__c> incidentRiskJuncs = (List<Incident_Risk_Junc__c>)data.get('Incident_Risk_Junc__c');
        String incidentLinkValueBeforeTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;

        // DML data test
        delete incidentRiskJuncs[0];

        // Compare
        String incidentLinkValueAfterTest = [SELECT ID, Incident_Links__c FROM Risk__c WHERE ID =:risks[0].id LIMIT 1]?.Incident_Links__c;
        System.assertEquals(false, String.isBlank(incidentLinkValueAfterTest));
        System.assertEquals(true, incidentLinkValueBeforeTest != incidentLinkValueAfterTest);
    }

    @isTest
    static void formatIncidentLinkValue_Test_1(){
        String currentIncidentLinkValue = '';
        // Create String with 980 length
        for(Integer i = 0; i < 20; i++){
            currentIncidentLinkValue += '1111111111222222222233333333334444444444555555555'; // 49 character
        }
        // Call method
        ERMT_IncidentRiskJuncTriggerHandler.ResultWrapper ret = ERMT_IncidentRiskJuncTriggerHandler.formatIncidentLinkValue(currentIncidentLinkValue, 'id', '', false); // value after format have 41 length ( 980 + 41 = 1022 => specical length case)
        // Compare
        System.assertEquals(true, ret.isBreak);
        System.assertEquals('...', ret.value);
    }

    @isTest
    static void formatIncidentLinkValue_Test_2(){
        String currentIncidentLinkValue = '';
        // Create String with 980 length
        for(Integer i = 0; i < 20; i++){
            currentIncidentLinkValue += '1111111111222222222233333333334444444444555555555'; // 49 character
        }
        // Call method
        ERMT_IncidentRiskJuncTriggerHandler.ResultWrapper ret = ERMT_IncidentRiskJuncTriggerHandler.formatIncidentLinkValue(currentIncidentLinkValue, 'id', '', true); // value after format have 41 length ( 980 + 41 = 1022 => specical length case)
        // Compare
        System.assertEquals(true, ret.isBreak);
        System.assertEquals('<p><a href="/id" target="_blank"></a></p>', ret.value);
    }
}