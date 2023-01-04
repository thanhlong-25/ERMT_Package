// リスクアセスメント分類のコンボボックスコントローラのテスト
@isTest
private class RiskAssessmentClassiComboboxCtlrTest {
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
        }
        return ret;
    }

    // 分類・評価軸の選択リスト情報の取得のテスト
    // プロジェクトID有り
    @isTest static void getClassiSelsInfoTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            // 分類・評価軸の選択リスト情報の取得
            RiskAssessmentClassiComboboxCtlr.ClassiSelsInfo info;
            info = RiskAssessmentClassiComboboxCtlr.getClassiSelsInfo(
                System.Label.ClassiRecordType_AnalyseTiming
                , prjs[0].Id
                , true
            );

            // 検証
            System.assert(info != null);
        }
    }

    // 分類・評価軸の選択リスト情報の取得のテスト
    // プロジェクトID無し
    @isTest static void getClassiSelsInfoTest_2() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // 分類・評価軸の選択リスト情報の取得
            RiskAssessmentClassiComboboxCtlr.ClassiSelsInfo info;
            info = RiskAssessmentClassiComboboxCtlr.getClassiSelsInfo(
                System.Label.ClassiRecordType_AnalyseTiming
                , null
                , true
            );

            // 検証
            System.assert(info != null);
        }
    }
}