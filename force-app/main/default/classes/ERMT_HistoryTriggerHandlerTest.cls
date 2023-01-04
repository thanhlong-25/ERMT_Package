@isTest
public with sharing class ERMT_HistoryTriggerHandlerTest {
    private static final String RISK_OBJECT = 'ermt__Risk__c';

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

        return ret;
    }

    @isTest
    public static void updateNewValueTest_1(){
        Map<String, Object> data = initData();
        List<Account> acts = (List<Account>)data.get('Account');
        List<Risk__c> risks = (List<Risk__c>)data.get('Risk__c');
        risks[0].ermt__Organization__c = acts[1].Id;
        update risks;

        List<History__c> histories = [SELECT ID, OldValue__c, NewValue__c FROM History__c WHERE RecordId__c =: risks[0].Id AND FieldName__c = 'ermt__Organization__c'];
        System.assertEquals(1, histories.size());
        System.assertEquals(acts[1].Name, histories[0].NewValue__c);
        System.assertEquals(acts[0].Name, histories[0].OldValue__c);
    }
}