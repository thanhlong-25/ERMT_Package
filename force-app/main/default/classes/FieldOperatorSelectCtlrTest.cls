// 項目演算子選択コントローラテスト
@isTest
private class FieldOperatorSelectCtlrTest {
    private static final Datetime NOW_DATETIME = Datetime.now(); // 現在日時

    // プロファイルマップ取得
    // キー:プロファイル名
    // 値:プロファイルレコード
    private static Map<String, Profile> profileByName {
        get {
            if (profileByName == null) {
                profileByName = new Map<String, Profile>();
                for (Profile p : [
                    SELECT Name FROM Profile
                    ORDER BY Name
                ]) {
                    profileByName.put(p.Name, p);
                }
            }
            return profileByName;
        }
        private set;
    }

    // テストータ作成
    @testSetup static void makeTestData() {
        // ユーザ
        List<User> usrs = new List<User>();
        Integer usrsSize = 1;
        for (Integer i = 0; i < usrsSize; i++) {
            Integer no = i + 1;
            User usr = new User(
                LastName = 'ユーザ' + no
                , Alias = 'ユーザ' + no
                , UserName = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , Email = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , EmailEncodingKey = 'ISO-2022-JP'
                , TimeZoneSidKey = 'Asia/Tokyo'
                , LocaleSidKey = 'ja_JP'
                , LanguageLocaleKey = 'ja'
                , ProfileId = profileByName.get(System.Label.Profile_System_Admin).Id
            );
            usrs.add(usr);
        }
        insert usrs;

        System.runAs(usrs[0]) {
            
        }
    }

    // 演算子選択リストの取得のテスト
    @isTest static void getOperatorSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 演算子選択リストの取得
            List<Map<String, Object>> sels =FieldOperatorSelectCtlr.getOperatorSels('Account', 'Owner.Name');

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 選択リストの作成のテスト
    // データ型：BOOLEAN
    @isTest static void createOperatorSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldOperatorSelectCtlr.createOperatorSels(Schema.DisplayType.BOOLEAN);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 選択リストの作成のテスト
    // データ型：DATE
    @isTest static void createOperatorSelsTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldOperatorSelectCtlr.createOperatorSels(Schema.DisplayType.DATE);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 選択リストの作成のテスト
    // データ型：PICKLIST
    @isTest static void createOperatorSelsTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldOperatorSelectCtlr.createOperatorSels(Schema.DisplayType.PICKLIST);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 選択リストの作成のテスト
    // データ型：MULTIPICKLIST
    @isTest static void createOperatorSelsTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldOperatorSelectCtlr.createOperatorSels(Schema.DisplayType.MULTIPICKLIST);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 選択リストの作成のテスト
    // データ型：STRING
    @isTest static void createOperatorSelsTest_5() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldOperatorSelectCtlr.createOperatorSels(Schema.DisplayType.STRING);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }
}