// プロジェクトの分類・評価軸の初期値登録コントローラのテスト
@isTest
private class ProjectClassiDefaultEntryCtlrTest {
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
                    AND SobjectType IN ('ermt__Project__c', 'ermt__M_Classification__c')
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

            // 分類・評価軸設定（分類・評価軸グループ）
            List<ermt__M_Classification__c> clsGroups = new List<ermt__M_Classification__c>();
            RecordType clsGroupRecType = recordTypeByKey.get('ermt__M_Classification__c,EvaluationPeriodGroup');
            for (Integer i = 0; i < 1; i++) {
                ermt__M_Classification__c clsGroup = new ermt__M_Classification__c(
                    Name = '分析タイミング' + (i + 1)
                    , RecordTypeId = clsGroupRecType.Id
                    , ermt__invalid__c = false
                );
                clsGroups.add(clsGroup);
            }
            insert clsGroups;

            // 分類・評価軸設定（選択肢）
            List<ermt__M_Classification__c> clss = new List<ermt__M_Classification__c>();
            RecordType clsRecType = recordTypeByKey.get('ermt__M_Classification__c,ChoiceItem');
            for (Integer i = 0; i < 1; i++) {
                ermt__M_Classification__c cls = new ermt__M_Classification__c(
                    Name = '選択肢' + (i + 1)
                    , RecordTypeId = clsRecType.Id
                    , ermt__ParentMClassification_del__c = clsGroups[0].Id
                    , ermt__invalid__c = false

                );
                clss.add(cls);
            }
            insert clss;

            // プロジェクトと分類・評価軸設定の紐づけ
            List<ermt__Project_Classification_Junc__c> prjClss = new List<ermt__Project_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Project_Classification_Junc__c prjCls = new ermt__Project_Classification_Junc__c(
                    ermt__Project__c = prjs[0].Id
                    , ermt__M_Classification__c = clsGroups[0].Id
                );
                prjClss.add(prjCls);
            }
            insert prjClss;
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
            Map<String, String> labelMap = ProjectClassiDefaultEntryCtlr.getLabelMap();

            // 検証
            System.assertEquals(false, labelMap.isEmpty());
        }
    }

    // 分類・評価軸の選択リスト情報の取得のテスト
    @isTest static void getClassiSelsInfoTest_1() {
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
            // 分類・評価軸の選択リスト情報の取得
            List<Map<String, Object>> info = ProjectClassiDefaultEntryCtlr.getClassiSelsInfo(
                prj.Id
                , 'EvaluationPeriodGroup'
                , true
            );

            // 検証
            System.assertEquals(false, info.isEmpty());
        }
    }
}