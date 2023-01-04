@isTest
private class RiskIncidentEntryCtlrTest {
    // テストータ作成
    private static Map<String, List<SObject>> makeTestData() {
        Map<String, List<SObject>> data = new Map<String, List<SObject>>();

        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        data.put('User', usrs);

        System.runAs(usrs[0]) {
            // 組織・部門
            List<Account> accs = new List<Account>();
            for (Integer i = 0; i < 1; i++) {
                Account acc = TestDataFactory.createAccount(i + 1);
                accs.add(acc);
            }
            insert accs;
            data.put('Account', accs);

            // インシデント
            List<ermt__Incident__c> incs = new List<ermt__Incident__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Incident__c inc = TestDataFactory.createIncident(i + 1, accs[0]);
                inc.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 23, 00, 00, 00);
                incs.add(inc);
            }
            insert incs;
            data.put('ermt__Incident__c', incs);

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < 2; i++) {
                ermt__Risk__c rsk = TestDataFactory.createRisk(i + 1, accs[0]);
                rsks.add(rsk);
            }
            insert rsks;
            data.put('ermt__Risk__c', rsks);

            // インシデントリスク
            List<ermt__Incident_Risk_Junc__c> incRsks = new List<ermt__Incident_Risk_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Incident_Risk_Junc__c incRsk = TestDataFactory.createIncidentRisk(incs[0], rsks[0]);
                incRsks.add(incRsk);
            }
            insert incRsks;
            data.put('ermt__Incident_Risk_Junc__c', incRsks);

            // 対応策
            List<ermt__Control__c> ctls = new List<ermt__Control__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Control__c ctl = TestDataFactory.createControl(i + 1, accs[0]);
                ctls.add(ctl);
            }
            insert ctls;
            data.put('ermt__Control__c', ctls);

            // インシデント対応策
            List<ermt__Risk_Control_Junc__c> incCtls = new List<ermt__Risk_Control_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Control_Junc__c incRsk = TestDataFactory.createRiskControl(rsks[0], ctls[0]);
                incCtls.add(incRsk);
            }
            insert incCtls;
            data.put('ermt__Risk_Control_Junc__c', incCtls);
        }
        return data;
    }

    //test get risk control setting
    @isTest static void getRiskIncidentEntrySettingTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // インシデント対応策登録設定の取得
            ermt__RiskIncidentEntrySetting__mdt setting;
            setting = RiskIncidentEntryCtlr.getRiskIncidentEntrySetting();

            // 検証
            System.assert(setting != null);
        }
    }

    // test get risk
    @isTest static void getRiskTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            ermt__Risk__c risk = RiskIncidentEntryCtlr.getRisk(risks[0].Id);
            System.assertNotEquals(null, risk);
        }
    }

    //test get risk null
    @isTest static void getRiskTest_2() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            ermt__Risk__c risk = RiskIncidentEntryCtlr.getRisk(null);
            System.assertEquals(null, risk);
        }
    }

    //test get Incident field difine success
    @isTest static void getIncidentFieldDefinesTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'Name', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            System.assertEquals(2, fieldDefs.size());
            System.assertEquals('ermt__Organization__r.Name', fieldDefs[1].parentNameFieldName);
        }
    }

    //test get Incident field difine null
    @isTest static void getIncidentFieldDefinesTest_2() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'ermt__Test__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            System.assertEquals(0, fieldDefs.size());

            RiskIncidentEntryCtlr.FieldDefine fieldDef = new RiskIncidentEntryCtlr.FieldDefine();
        }
    }

    //test get Incidents no with condtion
    @isTest static void getIncidentsTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'ermt__Title__c', 'ermt__OccurrenceDatetime__c', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>();
            List<ermt__Incident__c>  incs = RiskIncidentEntryCtlr.getIncidents(risks[0].Id, fieldDefs, '', searchConds, '', 30);
            System.assertEquals(1, incs.size());
            System.assertEquals('インシデントタイトル1', incs[0].ermt__Title__c);
            System.assertEquals(Datetime.newInstance(2022, 09, 23, 00, 00, 00), incs[0].ermt__OccurrenceDatetime__c);
        }
    }

    //test get Incident with type rigistered
    @isTest static void getIncidentsTest_2() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'ermt__Title__c', 'ermt__OccurrenceDatetime__c', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>();
            List<ermt__Incident__c>  incs = RiskIncidentEntryCtlr.getIncidents(risks[0].Id, fieldDefs, System.Label.Label_Registered, searchConds, '', 30);
            System.assertEquals(1, incs.size());
            System.assertEquals('インシデントタイトル1', incs[0].ermt__Title__c);
            System.assertEquals(Datetime.newInstance(2022, 09, 23, 00, 00, 00), incs[0].ermt__OccurrenceDatetime__c);
        }
    }

    //test get Incident with type unregister
    @isTest static void getIncidentsTest_3() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            inc.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 23, 00, 00, 00);
            insert inc;
            List<String> displayFieldNames = new List<String>{ 'ermt__Title__c', 'ermt__OccurrenceDatetime__c', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>();
            List<ermt__Incident__c>  incs = RiskIncidentEntryCtlr.getIncidents(risks[0].Id, fieldDefs, System.Label.Label_Unregistered, searchConds, '', 30);
            System.assertEquals(1, incs.size());
            System.assertEquals('インシデントタイトル123', incs[0].ermt__Title__c);
            System.assertEquals(Datetime.newInstance(2022, 09, 23, 00, 00, 00), incs[0].ermt__OccurrenceDatetime__c);
        }
    }

    //test get Incident with and Condition
    @isTest static void getIncidentsTest_4() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<ermt__Incident__c> listInc = new List<ermt__Incident__c>();
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            inc.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 24, 00, 00, 00);
            listInc.add(inc);
            ermt__Incident__c inc1 = TestDataFactory.createIncident(456, accs[0]);
            inc1.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 24, 00, 00, 00);
            listInc.add(inc1);
            insert listInc;

            List<String> displayFieldNames = new List<String>{ 'ermt__Title__c', 'ermt__OccurrenceDatetime__c', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'ermt__Title__c'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_PARTIAL_MATCH
                    , 'value' => '1'
                    , 'errMsg' => ''
                }
            };
            List<ermt__Incident__c>  incs = RiskIncidentEntryCtlr.getIncidents(risks[0].Id, fieldDefs, '', searchConds, '', 30);
            System.assertEquals(2, incs.size());
            System.assertEquals('インシデントタイトル1', incs[0].ermt__Title__c);
            System.assertEquals('インシデントタイトル123', incs[1].ermt__Title__c);
        }
    }

    //test get Incident with or condition
    @isTest static void getIncidentsTest_5() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<ermt__Incident__c> listInc = new List<ermt__Incident__c>();
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            inc.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 24, 00, 00, 00);
            listInc.add(inc);
            ermt__Incident__c inc1 = TestDataFactory.createIncident(456, accs[0]);
            inc1.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 25, 00, 00, 00);
            listInc.add(inc1);
            insert listInc;

            List<String> displayFieldNames = new List<String>{ 'ermt__Title__c', 'ermt__OccurrenceDatetime__c', 'ermt__Organization__c' };
            List<RiskIncidentEntryCtlr.FieldDefine> fieldDefs = RiskIncidentEntryCtlr.getIncidentFieldDefines(displayFieldNames);
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'ermt__Title__c'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => 'インシデントタイトル456'
                    , 'errMsg' => ''
                }, 
                new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'ermt__OccurrenceDatetime__c'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_LESS_THAN_EQUAL
                    , 'value' => Datetime.newInstance(2022, 09, 24, 00, 00, 00)
                    , 'errMsg' => ''
                }
            };
            List<ermt__Incident__c>  incs = RiskIncidentEntryCtlr.getIncidents(risks[0].Id, fieldDefs, '', searchConds, '(1 OR 2)', 30);
            System.debug(incs);
            System.assertEquals(2, incs.size());
            System.assertEquals('インシデントタイトル1', incs[0].ermt__Title__c);
            System.assertEquals('インシデントタイトル456', incs[1].ermt__Title__c);
        }

    }
    
    //test register incident with risk
    @isTest static void registerRiskIncidentTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<ermt__Incident__c> listInc = new List<ermt__Incident__c>();
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            inc.ermt__OccurrenceDatetime__c = Datetime.newInstance(2022, 09, 24, 00, 00, 00);
            listInc.add(inc);
            insert listInc;

            Boolean result = RiskIncidentEntryCtlr.registerRiskIncident(risks[0].Id, new List<Id>{listInc[0].Id});
            System.assertEquals(true, result);
            List<ermt__Incident_Risk_Junc__c> juncs = [SELECT Id FROM ermt__Incident_Risk_Junc__c WHERE ermt__Incident__c = :listInc[0].Id AND ermt__Risk__c = :risks[0].Id LIMIT 50000];
            System.assertEquals(1, juncs.size());
        }
    }

    //test register list incident with risk, one item of list incident registed with risk
    @isTest static void registerRiskIncidentTest_2() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Incident__c> incidents = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<ermt__Incident__c> listInc = new List<ermt__Incident__c>();
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            listInc.add(inc);
            insert listInc;

            Boolean result = RiskIncidentEntryCtlr.registerRiskIncident(risks[0].Id, new List<Id>{listInc[0].Id, incidents[0].Id});
            System.assertEquals(true, result);
            List<ermt__Incident_Risk_Junc__c> juncs = [SELECT Id FROM ermt__Incident_Risk_Junc__c WHERE ermt__Incident__c = :listInc[0].Id AND ermt__Risk__c = :risks[0].Id LIMIT 50000];
            System.assertEquals(1, juncs.size());
        }
    }

    //test delete register incident and risk
    @isTest static void deleteRiskIncidentTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Incident__c> incidents = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            Boolean result = RiskIncidentEntryCtlr.deleteRiskIncident(risks[0].Id, new List<Id>{incidents[0].Id});
            System.assertEquals(true, result);
            List<ermt__Incident_Risk_Junc__c> juncs = [SELECT Id FROM ermt__Incident_Risk_Junc__c WHERE ermt__Incident__c = :incidents[0].Id AND ermt__Risk__c = :risks[0].Id LIMIT 50000];
            System.assertEquals(0, juncs.size());
        }
    }

    //test register incident with control
    @isTest static void registerIncidentControlTest_1() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incidents = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            Map<String, Object> resultMap = RiskIncidentEntryCtlr.registerIncidentControl(risks[0].Id, incidents[0].Id);
            System.assertEquals(1, resultMap.get('registerCount'));
            List<ermt__Incident_Control_Junc__c> juncs = [SELECT Id FROM ermt__Incident_Control_Junc__c WHERE ermt__Incident__c = :incidents[0].Id LIMIT 50000];
            System.assertEquals(1, juncs.size());
        }
    }

    //test regiter incident with control while this incident registered with control
    @isTest static void registerIncidentControlTest_2() {
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__Risk__c> risks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<ermt__Control__c> cons = (List<ermt__Control__c>)data.get('ermt__Control__c');
        System.runAs(usrs[0]) {
            List<ermt__Incident__c> listInc = new List<ermt__Incident__c>();
            ermt__Incident__c inc = TestDataFactory.createIncident(123, accs[0]);
            listInc.add(inc);
            insert listInc;
            List<ermt__Incident_Control_Junc__c> listIncControl = new List<ermt__Incident_Control_Junc__c>();
            ermt__Incident_Control_Junc__c incControl = TestDataFactory.createIncidentControl(listInc[0], cons[0]);
            listIncControl.add(incControl);
            insert listIncControl;

            Map<String, Object> resultMap = RiskIncidentEntryCtlr.registerIncidentControl(risks[0].Id, listInc[0].Id);
            System.assertEquals(0, resultMap.get('registerCount'));
        }
    }
}