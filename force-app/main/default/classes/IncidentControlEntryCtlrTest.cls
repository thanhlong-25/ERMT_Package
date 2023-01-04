/**
 * インシデント対応策登録コントローラテスト
 */
@isTest
private class IncidentControlEntryCtlrTest {
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

            // 対応策
            List<ermt__Control__c> ctls = new List<ermt__Control__c>();
            for (Integer i = 0; i < 2; i++) {
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

    // インシデント対応策登録設定の取得テスト
    @isTest static void getIncidentControlEntrySettingTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // インシデント対応策登録設定の取得
            ermt__IncidentControlEntrySetting__mdt setting;
            setting = IncidentControlEntryCtlr.getIncidentControlEntrySetting();

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
            inc = IncidentControlEntryCtlr.getIncident(incs[0].Id);

            // 検証
            System.assert(inc != null);
        }
    }

    // 対応策項目定義リストの取得テスト
    @isTest static void getControlFieldDefinesTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            List<String> displayFieldNames = new List<String>{ 'Name' };

            // 対応策項目定義リストの取得
            List<IncidentControlEntryCtlr.FieldDefine> fieldDefs;
            fieldDefs = IncidentControlEntryCtlr.getControlFieldDefines(displayFieldNames);

            // 検証
            System.assert(fieldDefs != null);

            // 項目定義クラスのコンストラクタのテスト
            IncidentControlEntryCtlr.FieldDefine fieldDef = new IncidentControlEntryCtlr.FieldDefine();
        }
    }

    // 対応策リストの取得テスト
    @isTest static void getControlsTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        System.runAs(usrs[0]) {
            // 対応策項目定義リストの取得
            List<String> displayFieldNames = new List<String>{ 'Name', 'ermt__AssignedOrg__c' };
            List<IncidentControlEntryCtlr.FieldDefine> fieldDefs;
            fieldDefs = IncidentControlEntryCtlr.getControlFieldDefines(displayFieldNames);

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

            // 対応策リストの取得
            List<ermt__Control__c> risks = IncidentControlEntryCtlr.getControls(
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

    // インシデント対応策の登録テスト
    @isTest static void registerIncidentControlTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Control__c> ctls = (List<ermt__Control__c>)data.get('ermt__Control__c');
        System.runAs(usrs[0]) {
            List<Id> riskIds = new List<Id>{ ctls[0].Id, ctls[1].Id };

            Test.startTest();

            // インシデント対応策の登録
            Boolean result = IncidentControlEntryCtlr.registerIncidentControl(
                incs[0].Id,
                riskIds
            );

            Test.stopTest();

            // 検証
            System.assert(result);
        }
    }

    // インシデント対応策の削除テスト
    @isTest static void deleteIncidentControlTest_1() {
        // テストデータの作成
        Map<String, List<SObject>> data = makeTestData();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Incident__c> incs = (List<ermt__Incident__c>)data.get('ermt__Incident__c');
        List<ermt__Control__c> ctls = (List<ermt__Control__c>)data.get('ermt__Control__c');
        System.runAs(usrs[0]) {
            List<Id> riskIds = new List<Id>{ ctls[0].Id, ctls[1].Id };

            Test.startTest();

            // インシデント対応策の削除
            Boolean result = IncidentControlEntryCtlr.deleteIncidentControl(
                incs[0].Id,
                riskIds
            );

            Test.stopTest();

            // 検証
            System.assert(result);
        }
    }
}