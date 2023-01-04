@isTest
public with sharing class ERMT_RiskControlJuncTriggerHandlerTest {
    private static final String RISK_CONTROL_JUNC_OBJECT = 'ermt__Risk_Control_Junc__c';
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

        // Init Risk__c
        List<Risk__c> risks = new List<Risk__c>();
        for (Integer i = 0; i < 20; i++) {
            Risk__c risk = TestDataFactory.createRisk(i + 1, accs[0]);
            risks.add(risk);
        }
        insert risks;
        ret.put('Risk__c', risks);

        // Init Risk_control_Junc__c
        List<Risk_Control_Junc__c> riskControlJuncs = new List<Risk_Control_Junc__c>();
        for (Integer i = 0; i < 2; i++) {
            Risk_Control_Junc__c riskControlJunc = TestDataFactory.createRiskControl(risks[i], controls[0]);
            riskControlJuncs.add(riskControlJunc);
        }
        insert riskControlJuncs;
        ret.put('Risk_Control_Junc__c', riskControlJuncs);

        return ret;
    }

    //test save Risk_Control_Junc__c history log when Risk linked to Control
    @isTest
    static void testSaveHistoryLog_01() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        List<History__c> histories = [SELECT Id, Type__c, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c =: RISK_CONTROL_JUNC_OBJECT LIMIT 1];

        //compare
        System.assertEquals(1, histories.size());
        System.assertEquals(RISK_CONTROL_JUNC_OBJECT, histories[0].ObjectLog__c);
        System.assertEquals('追加', histories[0].Type__c);
        System.assertEquals(risks[0].Id, histories[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, histories[0].ParentRecordId2__c);
    }

    //test save Risk_Control_Junc__c history log when Risk unlinked to Control
    @isTest
    static void testSaveHistoryLog_02() {
        // Retrieve initData
        Map<String, Object> data = initData();
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        List<Control__c> controls = (List<Control__c>)data.get('Control__c');

        //delete histories before 
        List<History__c> historiesBefore = [SELECT Id FROM History__c LIMIT 50000];
        delete historiesBefore;
        
        //DML
        delete controls;

        List<History__c> histories = [SELECT Id, Type__c, ObjectLog__c, ParentRecordId1__c, ParentRecordId2__c FROM History__c WHERE ObjectLog__c =: RISK_CONTROL_JUNC_OBJECT LIMIT 1];


        //compare
        System.assertEquals(1, histories.size());
        System.assertEquals(RISK_CONTROL_JUNC_OBJECT, histories[0].ObjectLog__c);
        System.assertEquals('削除', histories[0].Type__c);
        System.assertEquals(risks[0].Id, histories[0].ParentRecordId1__c);
        System.assertEquals(controls[0].Id, histories[0].ParentRecordId2__c);
    }
}