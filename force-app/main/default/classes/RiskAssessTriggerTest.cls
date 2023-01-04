// リスクアセスメントのトリガーのテスト
@isTest
private class RiskAssessTriggerTest {
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

    // データ作成
    static Map<String, Object> makeData_1() {
        Map<String, Object> ret = new Map<String, Object>();

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
        ret.put('User', usrs);

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
            ret.put('Account', accs);

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
            ret.put('Group', grps);

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
            ret.put('ermt__Risk__c', rsks);

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
            ret.put('ermt__Risk__Share', rskShrs);

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
            ret.put('ermt__Risk_Account_Junc__c', rskAccs);

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
            ret.put('ermt__RiskAssessment__c', rskAsss);

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
            ret.put('ermt__RiskAssessment__Share', rskAssShrs);
        }
        return ret;
    }

    // データ作成
    static Map<String, Object> makeData_2() {
        Map<String, Object> ret = new Map<String, Object>();

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
        ret.put('User', usrs);

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
            ret.put('Account', accs);

            // リスクロック設定
            ermt__RiskLockSetting__c rskLckStt = ermt__RiskLockSetting__c.getInstance();
            rskLckStt.ermt__IsLockEnabled__c = false;
            upsert rskLckStt;

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            RecordType rskRecType = recordTypeByKey.get('ermt__Risk__c,Master');
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = new ermt__Risk__c(
                    Name = 'リスク' + (i + 1)
                    , RecordTypeId = rskRecType.Id
                    , ermt__Organization__c = accs[0].Id
                    , ermt__ApprovalStatus__c = System.Label.Risk_ApprovalStatus_Applying
                );
                rsks.add(rsk);
            }
            insert rsks;
            ret.put('ermt__Risk__c', rsks);

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
            ret.put('ermt__RiskAssessment__c', rskAsss);

            // リスクロック設定
            rskLckStt.ermt__IsLockEnabled__c = true;
            upsert rskLckStt;
        }
        return ret;
    }

    // リスクアセスメントの更新のテスト
    @isTest static void riskAssessUpdateTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        // ユーザの取得
        List<User> usrs = (List<User>)data.get('User');
        // リスクアセスメントの取得
        List<ermt__RiskAssessment__c> rskAsss = (List<ermt__RiskAssessment__c>)data.get('ermt__RiskAssessment__c');

        System.runAs(usrs[0]) {
            Test.startTest();

            // リスクアセスメントの更新
            ermt__RiskAssessment__c rskAss = new ermt__RiskAssessment__c(
                Id = rskAsss[0].Id
                , ermt__Risk__c = null
            );
            update rskAss;

            Test.stopTest();

            // 処理結果のチェック
            rskAss = [
                SELECT ermt__Risk__c FROM ermt__RiskAssessment__c
                WHERE Id = :rskAss.Id LIMIT 1
            ];
            System.assertEquals(null, rskAss.ermt__Risk__c);
        }
    }

    // リスクアセスメントの削除のテスト
    @isTest static void riskAssessDeleteTest_1() {
        // データ作成
        Map<String, Object> data = makeData_2();
        // ユーザの取得
        List<User> usrs = (List<User>)data.get('User');
        // リスクアセスメントの取得
        List<ermt__RiskAssessment__c> rskAsss = (List<ermt__RiskAssessment__c>)data.get('ermt__RiskAssessment__c');

        System.runAs(usrs[0]) {
            Test.startTest();

            Boolean result = true;
            try {
                // リスクアセスメントの削除
                delete rskAsss[0];
            } catch (Exception ex) {
                result = false;
            }
            Test.stopTest();

            // 検証
            System.assert(!result);
        }
    }
}