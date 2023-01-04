// リスク分類のトリガーのテスト
@isTest
private class RiskClassificationJuncTriggerTest {
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
            ret.put('ermt__M_Classification__c', clss);
            
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
            ret.put('ermt__Risk_Classification_Junc__c', rskClss);

            // リスクロック設定
            rskLckStt.ermt__IsLockEnabled__c = true;
            upsert rskLckStt;
        }
        return ret;
    }

    // リスク分類の削除のテスト
    @isTest static void riskClassiDeleteTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        // ユーザの取得
        List<User> usrs = (List<User>)data.get('User');
        // リスク分類の取得
        List<ermt__Risk_Classification_Junc__c> rskClss = (List<ermt__Risk_Classification_Junc__c>)data.get('ermt__Risk_Classification_Junc__c');

        System.runAs(usrs[0]) {
            Test.startTest();

            Boolean result = true;
            try {
                // リスク分類の削除
                delete rskClss[0];
            } catch (Exception ex) {
                result = false;
            }
            Test.stopTest();

            // 検証
            System.assert(!result);
        }
    }
}