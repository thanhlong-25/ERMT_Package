// 項目検索コントローラテスト
@isTest
private class FieldLookupCtlrTest {
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

    // 項目ラベルの取得のテスト
    @isTest static void getFieldLabelTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            String label = FieldLookupCtlr.getFieldLabel('Account', 'Owner.Name');

            //System.debug('label=' + label);

            // 検証
            System.assert(String.isNotEmpty(label));
        }
    }

    // 項目選択リストの取得のテスト
    // 項目階層の指定
    @isTest static void getFieldSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldLookupCtlr.getFieldSels('Account', null, 2, true);

            // for (Map<String, Object> sel : sels) {
            //     System.debug('sel=' + sel);
            // }

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 項目選択リストの取得のテスト
    // 項目名リストの指定
    @isTest static void getFieldSelsTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            List<String> fieldNames = new List<String>();
            fieldNames.add('Name');
            fieldNames.add('RecordType.DeveloperName');

            // 項目選択リストの取得
            List<Map<String, Object>> sels = FieldLookupCtlr.getFieldSels('Account', fieldNames, 0, false);

            // for (Map<String, Object> sel : sels) {
            //     System.debug('sel=' + sel);
            // }

            // 検証
            System.assert(!sels.isEmpty());
        }
    }
}