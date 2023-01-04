// リスク分析の新規作成コントローラのテスト
@isTest
private class RiskAnalysisNewCreateCtlrTest {
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

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            RecordType rskRecType = recordTypeByKey.get('ermt__Risk__c,Master');
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = new ermt__Risk__c(
                    Name = 'リスク' + (i + 1)
                    , RecordTypeId = rskRecType.Id
                    , ermt__Project__c = prjs[0].Id
                );
                rsks.add(rsk);
            }
            insert rsks;

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

            // リスクアセスメント分類・評価軸設定の紐づけ
            List<ermt__RiskAssessment_Classification_Junc__c> rskAssClss = new List<ermt__RiskAssessment_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment_Classification_Junc__c rskAssCls = new ermt__RiskAssessment_Classification_Junc__c(
                    ermt__RiskAssessment__c = rskAsss[0].Id
                    , ermt__M_Classification__c = clss[0].Id
                );
                rskAssClss.add(rskAssCls);
            }
            insert rskAssClss;

            // リスク分析の新規作成の設定の追加
            ermt__RiskAnalysisNewCreateSetting__c setting = new ermt__RiskAnalysisNewCreateSetting__c(
                ermt__AnalyseTimingDispOrder__c = 1
                , ermt__ProbabilityDispOrder__c = 3
                , ermt__ResultImpactDispOrder__c = 2
                , ermt__ThirdEvaluationDispOrder__c = 3
            );
            insert setting;
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
            Map<String, String> labelMap = RiskAnalysisNewCreateCtlr.getLabelMap();

            // 検証
            System.assertEquals(false, labelMap.isEmpty());
        }
    }

    // 設定の取得のテスト
    @isTest static void getSettingTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 設定の取得
            Map<String, Object> setting = RiskAnalysisNewCreateCtlr.getSetting();

            //System.debug('setting=' + setting);

            // 検証
            System.assertEquals(false, setting.isEmpty());
        }
    }

    // リスクアセスメントのレコードタイプIDの取得のテスト
    @isTest static void getRiskAssessRecTypeIdTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // リスクアセスメントのレコードタイプIDの取得
            Id rskAssRecTypeId = RiskAnalysisNewCreateCtlr.getRiskAssessRecTypeId(
                'Analysis'
            );

            // 検証
            System.assertNotEquals(null, rskAssRecTypeId);
        }
    }

    // リスクアセスメントの取得のテスト
    @isTest static void getRiskAssessTest_1() {
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

        System.runAs(usr) {
            // リスクアセスメントの取得
            ermt__RiskAssessment__c ret = RiskAnalysisNewCreateCtlr.getRiskAssess(
                rskAss.Id
            );

            // 検証
            System.assert(ret.Id != null);
        }
    }

    // 分類・評価軸IDの取得のテスト
    @isTest static void getClassiIdTest_1() {
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

        // 分類・評価軸設定（分類・評価軸グループ）の取得
        ermt__M_Classification__c clsGroup = [
            SELECT Id FROM ermt__M_Classification__c
            WHERE Name = '分析タイミング1' LIMIT 1
        ];

        System.runAs(usr) {
            // 分類・評価軸IDの取得
            Id ret = RiskAnalysisNewCreateCtlr.getClassiId(
                rskAss.Id
                , clsGroup.Id
            );

            // 検証
            System.assert(ret != null);
        }
    }

    // リスクアセスメント分類・評価軸連携の更新のテスト
    @isTest static void updateRiskAssessClassiTest_1() {
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

        // 分類・評価軸設定（分類・評価軸グループ）の取得
        ermt__M_Classification__c clsGroup = [
            SELECT Id FROM ermt__M_Classification__c
            WHERE Name = '分析タイミング1' LIMIT 1
        ];

        // 分類・評価軸設定（選択肢）の取得
        ermt__M_Classification__c cls = [
            SELECT Id FROM ermt__M_Classification__c
            WHERE Name = '選択肢1' LIMIT 1
        ];

        System.runAs(usr) {
            Test.startTest();

            // リスクアセスメント分類・評価軸連携の更新
            Boolean ret = RiskAnalysisNewCreateCtlr.updateRiskAssessClassi(
                rskAss.Id
                , cls.Id
                , clsGroup.Id
            );

            Test.stopTest();

            // 検証
            System.assert(ret);
        }
    }

    // リスクアセスメントの削除のテスト
    @isTest static void deleteRiskAssessTest_1() {
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

        System.runAs(usr) {
            // リスクアセスメントの削除
            Boolean ret = RiskAnalysisNewCreateCtlr.deleteRiskAssess(
                rskAss.Id
            );

            // 検証
            System.assert(ret);
        }
    }
}