// カスタム機能設定コントローラテスト
@isTest
private class CustomFunctionSettingCtlrTest {
    // データ作成
    static Map<String, Object> makeData_1() {
        Map<String, Object> ret = new Map<String, Object>();

        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        ret.put('User', usrs);

        System.runAs(usrs[0]) {
            // プロジェクト
            List<ermt__Project__c> prjs = new List<ermt__Project__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Project__c prj = TestDataFactory.createProject(i + 1);
                prjs.add(prj);
            }
            insert prjs;
            ret.put('ermt__Project__c', prjs);
        }
        return ret;
    }

    // カスタム機能設定の取得・セットテスト
    // 機能種別：リスクマトリックス（リスクアセスメント分類）
    // 設定種別：検索条件
    @isTest static void getSetCustomFunctionSettingValueTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            String functionType = System.Label.FunctionType_RiskMatrixRiskAssessClassi;
            String settingType = System.Label.SettingType_SearchCond;
            Id projectId = prjs[0].Id;
            Object settingValue;

            Test.startTest();

            // カスタム機能設定のセット（追加）
            settingValue = 'test';
            CustomFunctionSettingCtlr.setCustomFunctionSettingValue(
                functionType, settingType, projectId, settingValue
            );

            // カスタム機能設定の取得
            settingValue = CustomFunctionSettingCtlr.getCustomFunctionSettingValue(
                functionType, settingType, projectId
            );

            System.assertEquals('test', settingValue);

            // カスタム機能設定のセット（更新）
            settingValue = 'test2';
            CustomFunctionSettingCtlr.setCustomFunctionSettingValue(
                functionType, settingType, projectId, settingValue
            );

            // カスタム機能設定の取得
            settingValue = CustomFunctionSettingCtlr.getCustomFunctionSettingValue(
                functionType, settingType, projectId
            );

            System.assertEquals('test2', settingValue);

            Test.stopTest();
        }
    }
}