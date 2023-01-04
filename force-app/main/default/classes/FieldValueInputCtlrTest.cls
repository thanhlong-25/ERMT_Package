// 項目値入力コントローラテスト
@isTest
private class FieldValueInputCtlrTest {
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

    // 入力情報の取得のテスト
    // データ型：BOOLEAN
    @isTest static void getInputInfoTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Account', 'IsDeleted');

            // 検証
            System.assert(!info.isEmpty());
        }
    }

    // 入力情報の取得のテスト
    // データ型：DATE
    @isTest static void getInputInfoTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Opportunity', 'CloseDate');

            // 検証
            System.assert(!info.isEmpty());
        }
    }

    // 入力情報の取得のテスト
    // データ型：DATETIME
    @isTest static void getInputInfoTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Account', 'CreatedDate');

            // 検証
            System.assert(!info.isEmpty());
        }
    }

    // 入力情報の取得のテスト
    // データ型：PICKLIST
    @isTest static void getInputInfoTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Account', 'Industry');

            // 検証
            System.assert(!info.isEmpty());
        }
    }

    // 入力情報の取得のテスト
    // データ型：STRING
    @isTest static void getInputInfoTest_5() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Account', 'Owner.Name');

            // 検証
            System.assert(!info.isEmpty());
        }
    }

    // 入力情報の取得のテスト
    // データ型：REFERENCE
    @isTest static void getInputInfoTest_6() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 入力情報の取得
            Map<String, Object> info = FieldValueInputCtlr.getInputInfo('Account', 'OwnerId');

            // 検証
            System.assert(!info.isEmpty());
        }
    }
}