// リスク分類チャート（リスクアセスメント分類軸）コントローラのテスト
@isTest
private class RiskClassChartRiskAssessClassCtlrTest {
    // データ作成
    static Map<String, List<SObject>> makeData_1() {
        Map<String, List<SObject>> data = new Map<String, List<SObject>>();

        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        data.put('User', usrs);

        System.runAs(usrs[0]) {
            // 組織・部門
            List<Account> accs = new List<Account>();
            for (Integer i = 0; i < 2; i++) {
                Account acc = TestDataFactory.createAccount(i + 1);
                accs.add(acc);
            }
            insert accs;
            data.put('Account', accs);

            // 分類・評価軸設定（グループ）
            List<ermt__M_Classification__c> clsGrps = new List<ermt__M_Classification__c>();
            for (Integer i = 0; i < 5; i++) {
                String recordTypeDevName;
                if (i == 0) {
                    recordTypeDevName = System.Label.ClassiRecordType_RiskClassiGroup;
                } else if (i == 1) {
                    recordTypeDevName = System.Label.ClassiRecordType_AnalyseTiming;
                } else if (i == 2) {
                    recordTypeDevName = System.Label.ClassiRecordType_Probability;
                } else if (i == 3) {
                    recordTypeDevName = System.Label.ClassiRecordType_ResultImpact;
                } else if (i == 4) {
                    recordTypeDevName = System.Label.ClassiRecordType_ThirdEvaluation;
                }
                ermt__M_Classification__c clsGrp = TestDataFactory.createClassification(
                    i + 1
                    , recordTypeDevName
                    , null
                );
                clsGrps.add(clsGrp);
            }
            insert clsGrps;
            data.put('ermt__M_Classification__c', clsGrps);

            // 分類・評価軸設定（選択肢）
            List<ermt__M_Classification__c> clss = new List<ermt__M_Classification__c>();
            for (Integer i = 0; i < 5; i++) {
                ermt__M_Classification__c cls = TestDataFactory.createClassification(
                    i + clsGrps.size()
                    , System.Label.ClassiRecordType_Choice
                    , clsGrps[i]
                );
                clss.add(cls);
            }
            insert clss;
            data.put('ermt__M_Classification__c_2', clss);

            // プロジェクト
            List<ermt__Project__c> prjs = new List<ermt__Project__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Project__c prj = TestDataFactory.createProject(i + 1);
                prjs.add(prj);
            }
            insert prjs;
            data.put('ermt__Project__c', prjs);

            // プロジェクト分類
            List<ermt__Project_Classification_Junc__c> prjClss = new List<ermt__Project_Classification_Junc__c>();
            for (Integer i = 0; i < 5; i++) {
                ermt__Project_Classification_Junc__c prjCls = TestDataFactory.createProjectClassi(
                    prjs[0]
                    , clsGrps[i]
                );
                prjClss.add(prjCls);
            }
            insert prjClss;
            data.put('ermt__Project_Classification_Junc__c', prjClss);

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = TestDataFactory.createRisk(i + 1, accs[0]);
                rsk.ermt__Project__c = prjs[0].Id;
                rsks.add(rsk);
            }
            insert rsks;
            data.put('ermt__Risk__c', rsks);

            // リスク組織・部門
            List<ermt__Risk_Account_Junc__c> rskAccs = new List<ermt__Risk_Account_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Account_Junc__c rskAcc = new ermt__Risk_Account_Junc__c(
                    ermt__Risk__c = rsks[0].Id
                    , ermt__Department__c = accs[1].Id
                );
                rskAccs.add(rskAcc);
            }
            insert rskAccs;
            data.put('ermt__Risk_Account_Junc__c', rskAccs);

            // リスク分類
            List<ermt__Risk_Classification_Junc__c> rskClss = new List<ermt__Risk_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Classification_Junc__c rskCls = TestDataFactory.createRiskClassi(
                    rsks[0]
                    , clss[0]
                );
                rskClss.add(rskCls);
            }
            insert rskClss;
            data.put('ermt__Risk_Classification_Junc__c', rskClss);

            // リスクアセスメント
            List<ermt__RiskAssessment__c> rskAsss = new List<ermt__RiskAssessment__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment__c rskAss = TestDataFactory.createRiskAssessment(rsks[0]);
                rskAsss.add(rskAss);
            }
            insert rskAsss;
            data.put('ermt__RiskAssessment__c', rskAsss);

            // リスクアセスメント分類
            List<ermt__RiskAssessment_Classification_Junc__c> rskAssClss = new List<ermt__RiskAssessment_Classification_Junc__c>();
            for (Integer i = 1; i < 5; i++) {
                ermt__RiskAssessment_Classification_Junc__c rskAssCls = TestDataFactory.createRiskAssessmentClassi(
                    rskAsss[0]
                    , clss[i]
                );
                rskAssClss.add(rskAssCls);
            }
            insert rskAssClss;
            data.put('ermt__RiskAssessment_Classification_Junc__c', rskAssClss);
        }
        return data;
    }

    // リスク分類チャートの設定の取得テスト
    @isTest static void getRiskClassChartSettingTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // リスク分類チャートの設定の取得
            SObject setting =
                RiskClassChartRiskAssessClassCtlr.getRiskClassChartSetting();

            // 検証
            System.assert(setting != null);
        }
    }

    // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の取得テスト
    @isTest static void getRiskClassChartRacBackColorInfoTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の取得
            String info =
                RiskClassChartRiskAssessClassCtlr.getRiskClassChartRacBackColorInfo(prjs[0].Id);

            // 検証
            System.assert(String.isEmpty(info));
        }
    }

    // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の保存テスト
    @isTest static void saveRiskClassChartRacBackColorInfoTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の保存
            Boolean result =
                RiskClassChartRiskAssessClassCtlr.saveRiskClassChartRacBackColorInfo(
                    prjs[0].Id,
                    null
                );

            // 検証
            System.assert(result);
        }
    }

    // 分類グループリストの取得テスト
    @isTest static void getClassGroupsTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 分類グループリストの取得
            List<SObject> clsGrps =
                RiskClassChartRiskAssessClassCtlr.getClassGroups(prjs[0].Id);

            // 検証
            System.assert(!clsGrps.isEmpty());
        }
    }

    // 分類リストの取得
    @isTest static void getClassesTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__M_Classification__c> clsGrps =
            (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c');
        System.runAs(usrs[0]) {
            // 分類リストの取得
            List<SObject> clss =
                RiskClassChartRiskAssessClassCtlr.getClasses(clsGrps[2].Id);

            // 検証
            System.assert(!clss.isEmpty());
        }
    }

    // リスクリストの取得テスト
    @isTest static void getRisksTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        List<Account> accs = (List<Account>)data.get('Account');
        System.runAs(usrs[0]) {
            List<Id> accIds = new List<Id>{ accs[0].Id };

            // 検索条件リスト
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1,
                    'fieldName' => 'Id',
                    'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL,
                    'value' => '',
                    'errMsg' => ''
                }
            };

            // 検索条件ロジック
            String searchCondLogic = '(NOT 1)';

            // リスクリストの取得
            List<SObject> rsks = RiskClassChartRiskAssessClassCtlr.getRisks(
                prjs[0].Id,
                accIds,
                searchConds,
                searchCondLogic,
                null,
                1000
            );

            // 検証
            System.assert(!rsks.isEmpty());
        }
    }

    // リスク分類リストの取得テスト
    @isTest static void getRiskClassesTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<ermt__M_Classification__c> clsGrps = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            List<Id> rskIds = new List<Id>{ rsks[0].Id };
            List<Id> clsIds = new List<Id>{ clss[0].Id };
            List<Id> clsGrpIds = new List<Id>{ clsGrps[0].Id };

            // リスク分類リストの取得
            List<SObject> rskClss = RiskClassChartRiskAssessClassCtlr.getRiskClasses(
                rskIds, 
                clsIds, 
                clsGrpIds, 
                null, 
                1000
            );

            // 検証
            System.assert(!rskClss.isEmpty());
        }
    }

    // リスク組織・部門リストの取得テスト
    @isTest static void getRiskAccountsTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<Account> accs = (List<Account>)data.get('Account');
        System.runAs(usrs[0]) {
            List<Id> rskIds = new List<Id>{ rsks[0].Id };
            List<Id> accIds = new List<Id>{ accs[1].Id };

            // リスク組織・部門リストの取得
            List<SObject> rskaccs = RiskClassChartRiskAssessClassCtlr.getRiskAccounts(
                rskIds,
                accIds,
                null,
                1000
            );

            // 検証
            System.assert(!rskaccs.isEmpty());
        }
    }

    // リスクアセスメントリストの取得のテスト
    @isTest static void getRiskAssessmentsTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<ermt__RiskAssessment__c> rskAsss = (List<ermt__RiskAssessment__c>)data.get('ermt__RiskAssessment__c');
        System.runAs(usrs[0]) {       
            List<Id> rskAssIds = new List<Id>{ rskAsss[0].Id };
            List<Id> rskIds = new List<Id>{ rsks[0].Id };

            // 検索条件リスト
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1,
                    'fieldName' => 'Id',
                    'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL,
                    'value' => '',
                    'errMsg' => ''
                }
            };

            // 検索条件ロジック
            String searchCondLogic = '(NOT 1)';
            
            // リスクアセスメントリストの取得
            rskAsss = RiskClassChartRiskAssessClassCtlr.getRiskAssessments(
                rskAssIds,
                rskIds,
                searchConds,
                searchCondLogic,
                null,
                1000
            );

            // 検証
            System.assert(!rskAsss.isEmpty());
        }
    }

    // リスクアセスメント分類リストの取得テスト
    @isTest static void getRiskAssessmentClassesTest_1() {
        // データ作成
        Map<String, List<SObject>> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<ermt__RiskAssessment__c> rskAsss = (List<ermt__RiskAssessment__c>)data.get('ermt__RiskAssessment__c');
        List<ermt__M_Classification__c> clsGrps = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            List<Id> rskAssIds = new List<Id>{ rskAsss[0].Id };
            List<Id> rskIds = new List<Id>{ rsks[0].Id };
            List<Id> clsIds = new List<Id>{ clss[2].Id };
            List<Id> clsGrpIds = new List<Id>{ clsGrps[2].Id };

            // リスクアセスメント分類リストの取得
            List<SObject> rskAssClss = RiskClassChartRiskAssessClassCtlr.getRiskAssessmentClasses(
                rskAssIds,
                rskIds, 
                clsIds, 
                clsGrpIds, 
                null, 
                1000
            );

            // 検証
            System.assert(!rskAssClss.isEmpty());
        }
    }
}