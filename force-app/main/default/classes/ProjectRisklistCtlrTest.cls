// プロジェクトのリスク一覧コントローラのテスト
@isTest
private class ProjectRisklistCtlrTest {
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
            for (Integer i = 0; i < 4; i++) {
                String recordTypeDevName;
                if (i == 0) {
                    recordTypeDevName = System.Label.ClassiRecordType_AnalyseTiming;
                } else if (i == 1) {
                    recordTypeDevName = System.Label.ClassiRecordType_Probability;
                } else if (i == 2) {
                    recordTypeDevName = System.Label.ClassiRecordType_ResultImpact;
                } else if (i == 3) {
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
            for (Integer i = 0; i < 4; i++) {
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
            for (Integer i = 0; i < 4; i++) {
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
            for (Integer i = 0; i < 4; i++) {
                ermt__RiskAssessment_Classification_Junc__c rskAssCls = TestDataFactory.createRiskAssessmentClassi(
                    rskAsss[0]
                    , clss[i]
                );
                rskAssClss.add(rskAssCls);
            }
            insert rskAssClss;
            ret.put('ermt__RiskAssessment_Classification_Junc__c', rskAssClss);

            // 対応策
            List<ermt__Control__c> ctls = new List<ermt__Control__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Control__c ctl = TestDataFactory.createControl(i + 1, accs[0]);
                ctls.add(ctl);
            }
            insert ctls;
            ret.put('ermt__Control__c', ctls);

            // リスク対応策
            List<ermt__Risk_Control_Junc__c> rskCtls = new List<ermt__Risk_Control_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Control_Junc__c rskCtl = TestDataFactory.createRiskControl(
                    rsks[0]
                    , ctls[0]
                );
                rskCtls.add(rskCtl);
            }
            insert rskCtls;
            ret.put('ermt__Risk_Control_Junc__c', rskCtls);
        }
        return ret;
    }

    // リスク表示項目名選択リストの取得のテスト
    @isTest static void getRiskDisplayFieldNameSelsTest_1() {
        // リスク表示項目名選択リストの取得
        List<Map<String, Object>> sels = ProjectRisklistCtlr.getRiskDisplayFieldNameSels();

        // 検証
        System.assert(!sels.isEmpty());
    }

    // リスクアセスメント表示項目名選択リストの取得のテスト
    @isTest static void getRiskAssessmentDisplayFieldNameSelsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // リスクアセスメント表示項目名選択リストの取得
            List<Map<String, Object>> sels = ProjectRisklistCtlr.getRiskAssessmentDisplayFieldNameSels(prjs[0].Id);

            // 検証
            System.assert(!sels.isEmpty());
        }
    }

    // 対応策表示項目名選択リストの取得のテスト
    @isTest static void getControlDisplayFieldSelsTest_1() {
        // 対応策表示項目名選択リストの取得
        List<Map<String, Object>> sels = ProjectRisklistCtlr.getControlDisplayFieldNameSels();

        // 検証
        System.assert(!sels.isEmpty());
    }

    // リスク一覧表示項目名の取得のテスト
    @isTest static void getRisklistDisplayFieldNameTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // リスク一覧表示項目名の取得
            String fieldName = ProjectRisklistCtlr.getRisklistDisplayFieldName(prjs[0].Id);

            // 検証
            System.assert(String.isEmpty(fieldName));
        }
    }

    // リスク一覧表示項目名の保存のテスト
    @isTest static void saveRisklistDisplayFieldNameTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            String fieldName = null;

            // リスク一覧表示項目名の保存
            Boolean result = ProjectRisklistCtlr.saveRisklistDisplayFieldName(prjs[0].Id, fieldName);

            // 検証
            System.assert(result);
        }
    }

    // リスク項目説明マップの取得のテスト
    @isTest static void getRiskFieldDescByNameTest_1() {
        // 表示項目リスト
        List<String> dispFieldNames = new List<String>{
            'Name', 'ermt__Organization__c', 'ermt__AssessmentStatus__c'
        };

        // リスク項目説明マップの取得
        Map<String, ProjectRisklistCtlr.FieldDescribe> fieldDescMap = ProjectRisklistCtlr.getRiskFieldDescByName(
            dispFieldNames
        );

        // 検証
        System.assert(!fieldDescMap.isEmpty());
    }

    // リスクアセスメント項目説明マップの取得のテスト
    @isTest static void getRiskAssessmentFieldDescByNameTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 表示項目リスト
            List<String> dispFieldNames = new List<String>{
                System.Label.ClassiRecordType_AnalyseTiming
                , System.Label.ClassiRecordType_Probability
                , System.Label.ClassiRecordType_ResultImpact
                , System.Label.ClassiRecordType_ThirdEvaluation
                , 'ermt__isActive__c'
            };

            // リスクアセスメント項目説明マップの取得
            Map<String, ProjectRisklistCtlr.FieldDescribe> fieldDescMap = ProjectRisklistCtlr.getRiskAssessmentFieldDescByName(
                prjs[0].Id    
                , dispFieldNames
            );

            // 検証
            System.assert(!fieldDescMap.isEmpty());
        }
    }

    // 対応策項目説明マップの取得のテスト
    @isTest static void getControlFieldDescByNameTest_1() {
        // 表示項目リスト
        List<String> dispFieldNames = new List<String>{
            'Name', 'ermt__DescriptionContents__c'
        };

        // 対応策項目説明マップの取得
        Map<String, ProjectRisklistCtlr.FieldDescribe> fieldDescMap = ProjectRisklistCtlr.getControlFieldDescByName(
            dispFieldNames
        );

        // 検証
        System.assert(!fieldDescMap.isEmpty());
    }

    // リスクリストの取得のテスト
    @isTest static void getRisksTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 表示項目リスト
            List<String> dispFieldNames = new List<String>{
                'Name', 'ermt__Organization__c', 'ermt__AssessmentStatus__c'
            };
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
            Map<String, Object> result = ProjectRisklistCtlr.getRisks(
                prjs[0].Id    
                , dispFieldNames
                , searchConds
                , searchCondLogic
                , null
                , null
            );

            // 検証
            System.assert(!result.isEmpty());
        }
    }

    // リスクアセスメントリストマップの取得のテスト
    @isTest static void getRiskAssessmentsByRiskIdTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            // 表示項目リスト
            List<String> dispFieldNames = new List<String>{
                System.Label.ClassiRecordType_AnalyseTiming
                , System.Label.ClassiRecordType_Probability
                , System.Label.ClassiRecordType_ResultImpact
                , System.Label.ClassiRecordType_ThirdEvaluation
                , 'ermt__isActive__c'
                , 'ermt__SeverityRiskLevel__c'
                , 'CreatedById'
            };
            
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

            // 分析タイミングリスト
            List<String> analyseTimings = new List<String>{
                clss[0].Id
            };

            // 発生可能性リスト
            List<String> probabilitys = new List<String>{
                clss[1].Id
            };

            // 結果影響度リスト
            List<String> resultImpacts = new List<String>{
                clss[2].Id
            };

            // 第三評価リスト
            List<String> thirdEvaluations = new List<String>{
                clss[3].Id
            };
            
            // リスクアセスメントリストマップの取得
            Map<String, Object> result = ProjectRisklistCtlr.getRiskAssessmentsByRiskId(
                prjs[0].Id    
                , dispFieldNames
                , searchConds
                , searchCondLogic
                , analyseTimings
                , probabilitys
                , resultImpacts
                , thirdEvaluations
                , null
                , null
            );

            // 検証
            System.assert(!result.isEmpty());
        }
    }

    // 対応策リストマップの取得のテスト
    @isTest static void getControlsByRiskIdTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 表示項目リスト
            List<String> dispFieldNames = new List<String>{
                'Name', 'ermt__DescriptionContents__c'
                , 'ermt__ExecutionFrequency__c'
                , 'CreatedById'
            };

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

            // 対応策リストマップの取得
            Map<String, Object> result = ProjectRisklistCtlr.getControlsByRiskId(
                prjs[0].Id    
                , dispFieldNames
                , searchConds
                , searchCondLogic
                , null
                , null
            );

            // 検証
            System.assert(!result.isEmpty());
        }
    }
}