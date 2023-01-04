// リスクマトリックス（リスクアセスメント分類軸）コントローラのテスト
@isTest
private class RiskMatrixRiskAssessClassiCtlrTest {
    // データ作成
    static Map<String, Object> makeData_1() {
        Map<String, Object> ret = new Map<String, Object>();

        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        ret.put('User', usrs);

        System.runAs(usrs[0]) {
            // 組織・部門
            List<Account> accs = new List<Account>();
            for (Integer i = 0; i < 1; i++) {
                Account acc = TestDataFactory.createAccount(i + 1);
                accs.add(acc);
            }
            insert accs;
            ret.put('Account', accs);

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
            ret.put('ermt__M_Classification__c', clsGrps);

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
            ret.put('ermt__M_Classification__c_2', clss);

            // プロジェクト
            List<ermt__Project__c> prjs = new List<ermt__Project__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Project__c prj = TestDataFactory.createProject(i + 1);
                prjs.add(prj);
            }
            insert prjs;
            ret.put('ermt__Project__c', prjs);

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
            ret.put('ermt__Project_Classification_Junc__c', prjClss);

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = TestDataFactory.createRisk(i + 1, accs[0]);
                rsk.ermt__Project__c = prjs[0].Id;
                rsks.add(rsk);
            }
            insert rsks;
            ret.put('ermt__Risk__c', rsks);

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
            ret.put('ermt__Risk_Classification_Junc__c', rskClss);

            // リスクアセスメント
            List<ermt__RiskAssessment__c> rskAsss = new List<ermt__RiskAssessment__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment__c rskAss = TestDataFactory.createRiskAssessment(rsks[0]);
                rskAsss.add(rskAss);
            }
            insert rskAsss;
            ret.put('ermt__RiskAssessment__c', rskAsss);

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
            ret.put('ermt__RiskAssessment_Classification_Junc__c', rskAssClss);

            // セル色
            List<ermt__CellColor__c> cellColors = new List<ermt__CellColor__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__CellColor__c cellColor = TestDataFactory.createCellColor(
                    prjs[0]
                    , clss[2]
                    , clss[3]
                );
                cellColors.add(cellColor);
            }
            insert cellColors;
            ret.put('ermt__CellColor__c', cellColors);
        }
        return ret;
    }

    // リスクマトリックスの設定の取得のテスト
    @isTest static void getRiskMatrixSettingTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // リスクマトリックスの設定の取得
            ermt__RiskMatrixSetting__mdt setting = RiskMatrixRiskAssessClassiCtlr.getRiskMatrixSetting();

            // 検証
            System.assert(setting != null);
        }
    }

    // リスクマトリックスのセル色の取得のテスト
    @isTest static void getRiskMatrixCellColorTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // リスクマトリックスのセル色の取得
            List<ermt__CellColor__c> cellColors = RiskMatrixRiskAssessClassiCtlr.getRiskMatrixCellColor(prjs[0].Id);

            // 検証
            System.assert(!cellColors.isEmpty());
        }
    }

    // プロジェクト選択リストの取得のテスト
    @isTest static void getProjectSelsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // プロジェクト選択リストの取得
            List<Map<String, String>> sels = RiskMatrixRiskAssessClassiCtlr.getProjectSels();

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 分類・評価軸選択リストグループリストの取得のテスト
    @isTest static void getClassiSelsGroupsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 分類・評価軸選択リストグループリストの取得
            List<Map<String, Object>> groups = RiskMatrixRiskAssessClassiCtlr.getClassiSelsGroups(prjs[0].Id);

            // 検証
            System.assert(!groups.isEmpty());
        }
    }

    // 軸選択リストの取得のテスト
    // プロジェクトID有り
    @isTest static void getAxisSelsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 軸選択リストの取得
            List<Map<String, String>> sels = RiskMatrixRiskAssessClassiCtlr.getAxisSels(prjs[0].Id);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 軸選択リストの取得のテスト
    // プロジェクトID無し
    @isTest static void getAxisSelsTest_2() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // 軸選択リストの取得
            List<Map<String, String>> sels = RiskMatrixRiskAssessClassiCtlr.getAxisSels(null);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 分類・評価軸リストの取得のテスト
    @isTest static void getClassisTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<Id> prjIds = new List<Id>{ prjs[0].Id };

            // 分類・評価軸リストの取得
            List<ermt__M_Classification__c> clss = RiskMatrixRiskAssessClassiCtlr.getClassis(
                System.Label.ClassiRecordType_Probability
                , prjIds
            );

            // 検証
            System.assert(!clss.isEmpty());
        }
    }

    // // 組織・部門リストの取得のテスト
    // @isTest static void getAccountsTest_1() {
    //     // データ作成
    //     Map<String, Object> data = makeData_1();
    //     List<User> usrs = (List<User>)data.get('User');
    //     System.runAs(usrs[0]) {
    //         // 組織・部門リストの取得
    //         List<Account> accs = RiskMatrixRiskAssessClassiCtlr.getAccounts();

    //         // 検証
    //         System.assert(!accs.isEmpty());
    //     }
    // }

    // リスクリストの取得のテスト
    @isTest static void getRisksTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        List<Account> accs = (List<Account>)data.get('Account');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            List<Id> prjIds = new List<Id>{ prjs[0].Id };
            List<Id> accIds = new List<Id>{ accs[0].Id };
            List<Id> clsIds = new List<Id>{ clss[0].Id };

            // 検索条件リスト
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };

            // 検索条件ロジック
            String searchCondLogic = '(NOT 1)';

            // リスクリストの取得
            Map<String, Object> result = RiskMatrixRiskAssessClassiCtlr.getRisks(
                prjIds 
                , accIds
                , clsIds
                , searchConds
                , searchCondLogic
                , null
                , null
            );

            // 検証
            System.assert(!result.isEmpty());
        }
    }

    // リスクアセスメントリストの取得のテスト
    @isTest static void getRiskAssessmentsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {       
            List<Id> prjIds = new List<Id>{ prjs[0].Id };
            
            // 検索条件リスト
            List<Map<String, Object>> searchConds = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };

            // 検索条件ロジック
            String searchCondLogic = '(NOT 1)';
            
            // リスクアセスメントリストの取得
            Map<String, Object> result = RiskMatrixRiskAssessClassiCtlr.getRiskAssessments(
                prjIds  
                , searchConds
                , searchCondLogic
                , null
            );

            // 検証
            System.assert(!result.isEmpty());
        }
    }
}