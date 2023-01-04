// リスク組織・部門のトリガーのテスト
@isTest
private class RiskAccountJuncTriggerTest {
    private static final Datetime NOW_DATETIME = Datetime.now(); // 現在日時

    // プロファイルマップ
    // キー:プロファイル名
    // 値:プロファイルのレコード
    private static Map<String, Profile> profileByName {
        get {
            if (profileByName == null) {
                profileByName = new Map<String, Profile>();
                for (Profile p : [
                    SELECT Name FROM Profile
                    WHERE Name IN (:System.Label.Profile_System_Admin)
                    ORDER BY Name
                ]) {
                    profileByName.put(p.Name, p);
                }
            }
            return profileByName;
        }
        set;
    }

    // レコードタイプマップ
    // キー:Sオブジェクトタイプ,レコードタイプ名
    // 値:レコードタイプのレコード
    private static Map<String, RecordType> recordTypeByKey {
        get {
            if (recordTypeByKey == null) {
                recordTypeByKey = new Map<String, RecordType>();
                for (RecordType rt : [
                    SELECT SobjectType, DeveloperName
                    FROM RecordType
                    WHERE IsActive = true
                    AND SobjectType IN ('Account'
                    , 'ermt__Risk__c'
                    , 'ermt__RiskAssessment__c')
                    ORDER BY SobjectType, DeveloperName
                ]) {
                    String key = rt.SobjectType + ',' + rt.DeveloperName;
                    recordTypeByKey.put(key, rt);
                }
            }
            return recordTypeByKey;
        }
        set;
    }

    // テストータ作成
    @testSetup static void makeTestData() {
        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
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
            // 組織・部門
            List<Account> accs = new List<Account>();
            RecordType accRecType = recordTypeByKey.get('Account,OrganizationRecordType');
            for (Integer i = 0; i < 3; i++) {
                Account acc = new Account(
                    Name = '組織' + (i + 1)
                    , RecordTypeId = accRecType.Id
                );
                accs.add(acc);
            }
            insert accs;

            // グループ
            List<Group> grps = new List<Group>();
            for (Group g : [
                SELECT Id FROM Group
                WHERE DeveloperName = :RiskShareHandler.ACCOUNT_GROUP_NAME_PREFIX + accs[1].Id
                AND Type = 'Regular'
                LIMIT 1
            ]) {
                grps.add(g);
            }
            if (grps.isEmpty()) {
                grps.add(new Group(
                    Name = accs[1].Name
                    , DeveloperName = RiskShareHandler.ACCOUNT_GROUP_NAME_PREFIX + accs[1].Id
                ));
                insert grps;
            }

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            RecordType rskRecType = recordTypeByKey.get('ermt__Risk__c,Master');
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = new ermt__Risk__c(
                    Name = 'リスク' + (i + 1)
                    , RecordTypeId = rskRecType.Id
                    , ermt__Organization__c = accs[0].Id
                );
                rsks.add(rsk);
            }
            insert rsks;

            // リスク共有
            List<ermt__Risk__Share> rskShrs = new List<ermt__Risk__Share>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__Share rskShr = new ermt__Risk__Share(
                    ParentId = rsks[0].Id
                    , UserOrGroupId = grps[0].Id
                    , AccessLevel = RiskShareHandler.RISK_SHARE_ACCESS_LEVEL
                    , RowCause = RiskShareHandler.RISK_SHARE_REASON
                );
                rskShrs.add(rskShr);
            }
            insert rskShrs;

            // リスク組織・部門
            List<ermt__Risk_Account_Junc__c> rskAccs = new List<ermt__Risk_Account_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Account_Junc__c rskAcc = new ermt__Risk_Account_Junc__c(
                    ermt__Risk__c = rsks[0].Id
                    , ermt__Department__c = accs[2].Id
                );
                rskAccs.add(rskAcc);
            }
            insert rskAccs;

            // リスクアセスメント
            List<ermt__RiskAssessment__c> rskAsss = new List<ermt__RiskAssessment__c>();
            RecordType rskAssRecType = recordTypeByKey.get('ermt__RiskAssessment__c,Analysis');
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment__c rskAss = new ermt__RiskAssessment__c(
                    RecordTypeId = rskAssRecType.Id
                    , ermt__Risk__c = rsks[0].Id
                );
                rskAsss.add(rskAss);
            }
            insert rskAsss;

            // リスクアセスメント共有
            List<ermt__RiskAssessment__Share> rskAssShrs = new List<ermt__RiskAssessment__Share>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment__Share rskAssShr = new ermt__RiskAssessment__Share(
                    ParentId = rskAsss[0].Id
                    , UserOrGroupId = grps[0].Id
                    , AccessLevel = RiskAssessShareHandler.RISK_ASSESS_SHARE_ACCESS_LEVEL
                    , RowCause = RiskAssessShareHandler.RISK_ASSESS_SHARE_REASON
                );
                rskAssShrs.add(rskAssShr);
            }
            insert rskAssShrs;
        }
    }

    // リスク組織・部門の削除のテスト
    @isTest static void riskAssessDeleteTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // リスクの取得
        ermt__Risk__c rsk = [
            SELECT Id FROM ermt__Risk__c
            WHERE Name = 'リスク1' LIMIT 1
        ];

        // リスク組織・部門の取得
        ermt__Risk_Account_Junc__c rskAcc = [
            SELECT ermt__Risk__c FROM ermt__Risk_Account_Junc__c
            WHERE ermt__Risk__c = :rsk.Id LIMIT 1
        ];

        System.runAs(usr) {
            Test.startTest();

            // リスク組織・部門の削除
            delete rskAcc;
            
            Test.stopTest();

            // 処理結果のチェック
            Boolean isExist = false;
            for (ermt__Risk_Account_Junc__c raj : [
                SELECT Id FROM ermt__Risk_Account_Junc__c
                WHERE Id = :rskAcc.Id LIMIT 1
            ]) {
                isExist = true;
            }
            System.assertEquals(false, isExist);
        }
    }
}