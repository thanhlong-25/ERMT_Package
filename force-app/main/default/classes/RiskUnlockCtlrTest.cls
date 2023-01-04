// リスクのロック解除コントローラのテスト
@isTest
private class RiskUnlockCtlrTest {
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
                    AND SobjectType IN ('ermt__Project__c'
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
        Integer usrsSize = 2;
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
            // プロジェクト
            List<ermt__Project__c> prjs = new List<ermt__Project__c>();
            RecordType prjRecType = recordTypeByKey.get('ermt__Project__c,GoUnderway');
            for (Integer i = 0; i < 1; i++) {
                ermt__Project__c prj = new ermt__Project__c(
                    Name = 'プロジェクト' + (i + 1)
                    , RecordTypeId = prjRecType.Id
                );
                prjs.add(prj);
            }
            insert prjs;

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
                    , ermt__Project__c = prjs[0].Id
                    , ermt__ApprovalStatus__c = System.Label.Risk_ApprovalStatus_Approved
                );
                rsks.add(rsk);
            }
            insert rsks;

            // リスクのレコードロック
            Approval.lock(rsks, true);

            // リスクロック設定
            rskLckStt.ermt__IsLockEnabled__c = true;
            upsert rskLckStt;
        }
    }

    // ラベルマップの取得のテスト
    @isTest static void getLabelMapTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // ラベルマップ取得
            Map<String, String> labelMap = RiskUnlockCtlr.getLabelMap();

            // 検証
            System.assert(!labelMap.isEmpty());
        }
    }

    // リスクの更新のテスト
    @isTest static void updateRiskTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // プロジェクトの取得
        ermt__Project__c prj = [
            SELECT Id FROM ermt__Project__c
            WHERE Name = 'プロジェクト1' LIMIT 1
        ];

        System.runAs(usr) {
            Test.startTest();

            Boolean isSuccess = true;
            try {
                // リスクの更新
                Map<String, Object> result = RiskUnlockCtlr.updateRisk(
                    prj.Id, null
                );
            } catch (Exception ex) {
                isSuccess = false;
                System.debug(ex.getMessage());
            }
            
            Test.stopTest();

            // 検証
            System.assert(isSuccess);
        }
    }
}