/**
 * インシデントリスク登録コントローラテスト
 */
@isTest
private class IncidentRiskEntryCtlrTest {
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
            List<ermt__Incident_Control_Junc__c> incCtls = new List<ermt__Incident_Control_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Incident_Control_Junc__c incRsk = TestDataFactory.createIncidentControl(incs[0], ctls[0]);
                incCtls.add(incRsk);
            }
            insert incCtls;
            data.put('ermt__Incident_Control_Junc__c', incCtls);
        }
        return data;
    }

    // インシデントリスク登録設定の取得テスト
    @isTest static void getIncidentRiskEntrySettingTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // インシデントリスク登録設定の取得
            ermt__IncidentRiskEntrySetting__mdt setting;
            setting = IncidentRiskEntryCtlr.getIncidentRiskEntrySetting();

            // 検証
            System.assert(setting != null);
        }
    }

    // インシデントの取得テスト
    @isTest static void getIncidentTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        System.runAs(usrs[0]) {
            // インシデントの取得
            ermt__Incident__c inc;
            inc = IncidentRiskEntryCtlr.getIncident(incs[0].Id);

            // 検証
            System.assert(inc != null);
        }
    }

    // リスク項目定義リストの取得テスト
    @isTest static void getRiskFieldDefinesTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'Name' };

            // リスク項目定義リストの取得
            List<IncidentRiskEntryCtlr.FieldDefine> fieldDefs;
            fieldDefs = IncidentRiskEntryCtlr.getRiskFieldDefines(displayFieldNames);

            // 検証
            System.assert(fieldDefs != null);

            // 項目定義クラスのコンストラクタのテスト
            IncidentRiskEntryCtlr.FieldDefine fieldDef = new IncidentRiskEntryCtlr.FieldDefine();
        }
    }

    // リスクリストの取得テスト
    @isTest static void getRisksTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        System.runAs(usrs[0]) {
            // リスク項目定義リストの取得
            List<String> displayFieldNames = new List<String>{ 'Name', 'ermt__Organization__c' };
            List<IncidentRiskEntryCtlr.FieldDefine> fieldDefs;
            fieldDefs = IncidentRiskEntryCtlr.getRiskFieldDefines(displayFieldNames);

            // 検索条件の作成
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchCondLogic = '(NOT 1)';

            // リスクリストの取得
            List<ermt__Risk__c> risks = IncidentRiskEntryCtlr.getRisks(
                incs[0].Id,
                fieldDefs,
                System.Label.Label_Registered,
                searchConds,
                searchCondLogic,
                2000
            );

            // 検証
            System.assert(!risks.isEmpty());
        }
    }

    // インシデントリスクの登録テスト
    @isTest static void registerIncidentRiskTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<Id> riskIds = new List<Id>{ rsks[0].Id, rsks[1].Id };

            Test.startTest();

            // インシデントリスクの登録
            Boolean result = IncidentRiskEntryCtlr.registerIncidentRisk(
                incs[0].Id,
                riskIds
            );

            Test.stopTest();

            // 検証
            System.assert(result);
        }
    }

    // インシデントリスクの削除テスト
    @isTest static void deleteIncidentRiskTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            List<Id> riskIds = new List<Id>{ rsks[0].Id, rsks[1].Id };

            Test.startTest();

            // インシデントリスクの削除
            Boolean result = IncidentRiskEntryCtlr.deleteIncidentRisk(
                incs[0].Id,
                riskIds
            );

            Test.stopTest();

            // 検証
            System.assert(result);
        }
    }

    // リスク対応策の登録テスト
    @isTest static void registerRiskControlTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        System.runAs(usrs[0]) {
            Test.startTest();

            // リスク対応策の登録
            Map<String, Object> result = IncidentRiskEntryCtlr.registerRiskControl(
                incs[0].Id,
                rsks[0].Id
            );

            Test.stopTest();

            // 検証
            Integer registerCount = (Integer)result.get('registerCount');
            System.assert(registerCount > 0);
        }
    }
}