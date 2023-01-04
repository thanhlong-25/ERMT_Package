// リスク対応策の登録コントローラテスト
@isTest
private class RiskControlEntryCtlrTest {
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
                );
                rsks.add(rsk);
            }
            insert rsks;

            // 対応策
            List<ermt__Control__c> ctls = new List<ermt__Control__c>();
            for (Integer i = 0; i < 2; i++) {
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
        }
    }

    // ラベルマップの取得テスト
    @isTest static void getLabelMapTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // ラベルマップ取得
            Map<String, String> labelMap = RiskControlEntryCtlr.getLabelMap();

            // 検証
            System.assert(!labelMap.isEmpty());
        }
    }

    // 登録種別選択リストの取得テスト
    @isTest static void getRegisterTypeSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当元オブジェクト名選択リスト取得
            List<Map<String, Object>> sels = RiskControlEntryCtlr.getRegisterTypeSels();

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 対応策情報の取得テスト
    @isTest static void getControlInfoTest_1() {
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

        System.runAs(usr) {
            // 割当先情報の取得
            RiskControlEntryCtlr.ControlInfo info;
            info = RiskControlEntryCtlr.getControlInfo(
                rsk.Id
                , System.Label.RiskControlEntry_Unregistered
                , null
                , null
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assert(!info.records.isEmpty());
        }
    }

    // 対応策情報の取得テスト
    // 検索条件が有り
    @isTest static void getControlInfoTest_2() {
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

        // 検索条件
        List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'no' => 1
                , 'fieldName' => 'Id'
                , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                , 'value' => ''
                , 'errMsg' => ''
            }
        };
        String searchConditionLogic = '(NOT 1)';

        System.runAs(usr) {
            // 割当先情報の取得
            RiskControlEntryCtlr.ControlInfo info;
            info = RiskControlEntryCtlr.getControlInfo(
                rsk.Id
                , System.Label.RiskControlEntry_Registered
                , searchConditions
                , searchConditionLogic
                , '対応策'
                , null
                , 0
                , 1
            );

            // 検証
            System.assert(!info.records.isEmpty());
        }
    }

    // 対応策情報の取得テスト
    // ソート項目：対応策名
    @isTest static void getControlInfoTest_3() {
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

        System.runAs(usr) {
            // 割当先情報の取得
            RiskControlEntryCtlr.ControlInfo info;
            info = RiskControlEntryCtlr.getControlInfo(
                rsk.Id
                , System.Label.RiskControlEntry_All
                , null
                , null
                , null
                , 'nameLink'
                , 1
                , 1
            );

            // 検証
            System.assert(!info.records.isEmpty());
        }
    }

    // 対応策情報の取得テスト
    // ソート項目：担当組織・部門
    @isTest static void getControlInfoTest_4() {
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

        System.runAs(usr) {
            // 割当先情報の取得
            RiskControlEntryCtlr.ControlInfo info;
            info = RiskControlEntryCtlr.getControlInfo(
                rsk.Id
                , System.Label.RiskControlEntry_All
                , null
                , null
                , null
                , 'assignedOrgName'
                , 1
                , 1
            );

            // 検証
            System.assert(!info.records.isEmpty());
        }
    }

    // リスク対応策の登録テスト
    @isTest static void registerRiskControlTest_1() {
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

        // 対応策の取得
        ermt__Control__c ctl = [
            SELECT Id FROM ermt__Control__c
            WHERE Name = '対応策2' LIMIT 1
        ];
        List<Id> ctlIds = new List<Id>{ ctl.Id };

        System.runAs(usr) {
            // リスク対応策の登録
            RiskControlEntryCtlr.registerRiskControl(
                rsk.Id
                , ctlIds
            );

            // 検証
            List<ermt__Risk_Control_Junc__c> rskCtls = [
                SELECT Id FROM ermt__Risk_Control_Junc__c
                WHERE ermt__Risk__c = :rsk.Id
                AND ermt__Control__c IN :ctlIds
                LIMIT 1
            ];
            System.assert(!rskCtls.isEmpty());
        }
    }

    // リスク対応策の削除テスト
    @isTest static void deleteRiskControlTest_1() {
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

        // 対応策の取得
        ermt__Control__c ctl = [
            SELECT Id FROM ermt__Control__c
            WHERE Name = '対応策1' LIMIT 1
        ];
        List<Id> ctlIds = new List<Id>{ ctl.Id };

        System.runAs(usr) {
            // リスク対応策の削除
            RiskControlEntryCtlr.deleteRiskControl(
                rsk.Id
                , ctlIds
            );

            // 検証
            List<ermt__Risk_Control_Junc__c> rskCtls = [
                SELECT Id FROM ermt__Risk_Control_Junc__c
                WHERE ermt__Risk__c = :rsk.Id
                AND ermt__Control__c IN :ctlIds
                LIMIT 1
            ];
            System.assert(rskCtls.isEmpty());
        }
    }
}