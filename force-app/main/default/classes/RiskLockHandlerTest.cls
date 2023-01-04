// リスクロックハンドラのテスト
@isTest
private class RiskLockHandlerTest {
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
                    , 'ermt__M_Classification__c'
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
            // リスクロック設定
            ermt__RiskLockSetting__c rskLckStt = ermt__RiskLockSetting__c.getInstance();
            rskLckStt.ermt__IsLockEnabled__c = false;
            upsert rskLckStt;

            // 組織・部門
            List<Account> accs = new List<Account>();
            RecordType accRecType = recordTypeByKey.get('Account,OrganizationRecordType');
            for (Integer i = 0; i < 1; i++) {
                Account acc = new Account(
                    Name = '組織' + (i + 1)
                    , RecordTypeId = accRecType.Id
                );
                accs.add(acc);
            }
            insert accs;

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

            // 分類・評価軸設定（選択肢）
            List<ermt__M_Classification__c> clss = new List<ermt__M_Classification__c>();
            RecordType clsRecType = recordTypeByKey.get('ermt__M_Classification__c,ChoiceItem');
            for (Integer i = 0; i < 1; i++) {
                ermt__M_Classification__c cls = new ermt__M_Classification__c(
                    Name = '選択肢' + (i + 1)
                    , RecordTypeId = clsRecType.Id
                    , ermt__invalid__c = false

                );
                clss.add(cls);
            }
            insert clss;

            // リスク分類
            List<ermt__Risk_Classification_Junc__c> rskClss = new List<ermt__Risk_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Classification_Junc__c rskCls = new ermt__Risk_Classification_Junc__c(
                    ermt__Risk__c = rsks[0].Id
                    , ermt__M_Classification__c = clss[0].Id
                );
                rskClss.add(rskCls);
            }
            insert rskClss;

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

            // リスクアセスメント分類
            List<ermt__RiskAssessment_Classification_Junc__c> rskAssClss = new List<ermt__RiskAssessment_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment_Classification_Junc__c rskAssCls = new ermt__RiskAssessment_Classification_Junc__c(
                    ermt__RiskAssessment__c = rskAsss[0].Id
                    , ermt__M_Classification__c = clss[0].Id
                );
                rskAssClss.add(rskAssCls);
            }
            insert rskAssClss;

            // 対応策
            List<ermt__Control__c> ctls = new List<ermt__Control__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Control__c ctl = new ermt__Control__c(
                    Name = '対応策' + (i + 1)
                    , ermt__AssignedOrg__c = accs[0].Id
                );
                ctls.add(ctl);
            }
            insert ctls;

            // リスク対応策
            List<ermt__Risk_Control_Junc__c> rskCtls = new List<ermt__Risk_Control_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Control_Junc__c rskCtl = new ermt__Risk_Control_Junc__c(
                    ermt__Risk__c = rsks[0].Id
                    , ermt__Control__c = ctls[0].Id
                );
                rskCtls.add(rskCtl);
            }
            insert rskCtls;

            // リスクロック設定
            rskLckStt.ermt__IsLockEnabled__c = true;
            upsert rskLckStt;
        }
    }

    // リスクロックチェックのテスト
    @isTest static void checkRiskLockTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // リスクの取得
        List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
        for (ermt__Risk__c r : [
            SELECT Id FROM ermt__Risk__c
            WHERE Name = 'リスク1' LIMIT 1
        ]) {
            rsks.add(r);
        }

        System.runAs(usr) {
            Test.startTest();

            // リスクロックチェック
            Boolean ret = RiskLockHandler.checkRiskLock(rsks);

            Test.stopTest();

            // 処理結果のチェック
            System.assert(!ret);
        }
    }

    // リスク分類のリスクロックチェックのテスト
    @isTest static void checkRiskLockByRiskClassiTest_1() {
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

        // リスク分類の取得
        List<ermt__Risk_Classification_Junc__c> rskClss = new List<ermt__Risk_Classification_Junc__c>();
        for (ermt__Risk_Classification_Junc__c rcj : [
            SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c
            WHERE ermt__Risk__c = :rsk.Id LIMIT 1
        ]) {
            rskClss.add(rcj);
        }

        System.runAs(usr) {
            Test.startTest();

            // リスク分類のリスクロックチェック
            Boolean ret = RiskLockHandler.checkRiskLockByRiskClassi(rskClss);

            Test.stopTest();

            // 処理結果のチェック
            System.assert(!ret);
        }
    }

    // リスクアセスメントのリスクロックチェックのテスト
    @isTest static void checkRiskLockByRiskAssessTest_1() {
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

        // リスクアセスメントの取得
        List<ermt__RiskAssessment__c> rskAsss = new List<ermt__RiskAssessment__c>();
        for (ermt__RiskAssessment__c ra : [
            SELECT ermt__Risk__c FROM ermt__RiskAssessment__c
            WHERE ermt__Risk__c = :rsk.Id LIMIT 1
        ]) {
            rskAsss.add(ra);
        }

        System.runAs(usr) {
            Test.startTest();

            // リスクアセスメントのリスクロックチェック
            Boolean ret = RiskLockHandler.checkRiskLockByRiskAssess(rskAsss);

            Test.stopTest();

            // 処理結果のチェック
            System.assert(!ret);
        }
    }

    // リスクアセスメント分類のリスクロックチェックのテスト
    @isTest static void checkRiskLockByRiskAssessClassiTest_1() {
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

        // リスクアセスメントの取得
        ermt__RiskAssessment__c rskAss = [
            SELECT Id FROM ermt__RiskAssessment__c
            WHERE ermt__Risk__c = :rsk.Id LIMIT 1
        ];

        // リスクアセスメント分類の取得
        List<ermt__RiskAssessment_Classification_Junc__c> rskAssClss = new List<ermt__RiskAssessment_Classification_Junc__c>();
        for (ermt__RiskAssessment_Classification_Junc__c racj : [
            SELECT ermt__RiskAssessment__c FROM ermt__RiskAssessment_Classification_Junc__c
            WHERE ermt__RiskAssessment__c = :rskAss.Id LIMIT 1
        ]) {
            rskAssClss.add(racj);
        }

        System.runAs(usr) {
            Test.startTest();

            // リスクアセスメント分類のリスクロックチェック
            Boolean ret = RiskLockHandler.checkRiskLockByRiskAssessClassi(rskAssClss);

            Test.stopTest();

            // 処理結果のチェック
            System.assert(!ret);
        }
    }

    // リスク対応策のリスクロックチェックのテスト
    @isTest static void checkRiskLockByRiskControlTest_1() {
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

        // リスク対応策の取得
        List<ermt__Risk_Control_Junc__c> rskCtls = new List<ermt__Risk_Control_Junc__c>();
        for (ermt__Risk_Control_Junc__c rcj : [
            SELECT ermt__Risk__c FROM ermt__Risk_Control_Junc__c
            WHERE ermt__Risk__c = :rsk.Id LIMIT 1
        ]) {
            rskCtls.add(rcj);
        }

        System.runAs(usr) {
            Test.startTest();

            // リスク対応策のリスクロックチェック
            Boolean ret = RiskLockHandler.checkRiskLockByRiskControl(rskCtls);

            Test.stopTest();

            // 処理結果のチェック
            System.assert(!ret);
        }
    }
}