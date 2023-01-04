// リスク分類出力コントローラのテスト
@isTest
private class RiskClassiOutputCtlrTest {
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
            for (Integer i = 0; i < 1; i++) {
                ermt__M_Classification__c clsGrp = TestDataFactory.createClassification(
                    i + 1
                    , System.Label.ClassiRecordType_RiskClassiGroup
                    , null
                );
                clsGrp.ermt__Kind__c = '種別1';
                clsGrp.ermt__Label_Pick__c = 'リスク分類1';
                clsGrp.ermt__Label__c = 'リスク分類1';
                clsGrps.add(clsGrp);
            }
            insert clsGrps;
            ret.put('ermt__M_Classification__c', clsGrps);

            // 分類・評価軸設定（選択肢）
            List<ermt__M_Classification__c> clss = new List<ermt__M_Classification__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__M_Classification__c cls = TestDataFactory.createClassification(
                    i + clsGrps.size()
                    , System.Label.ClassiRecordType_Choice
                    , clsGrps[i]
                );
                cls.ermt__Kind__c = '種別1';
                cls.ermt__Label_Pick__c = '選択肢1';
                cls.ermt__Label__c = '選択肢1';
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
            for (Integer i = 0; i < 1; i++) {
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
                    , clss[i]
                );
                rskClss.add(rskCls);
            }
            insert rskClss;
            ret.put('ermt__Risk_Classification_Junc__c', rskClss);
        }
        return ret;
    }

    // 分類・評価軸のグループラベルの取得のテスト
    @isTest static void getClassiGroupLabelTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__M_Classification__c> clsGrps = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c');
        System.runAs(usrs[0]) {
            // 分類・評価軸のグループラベルの取得
            String label = RiskClassiOutputCtlr.getClassiGroupLabel(
                clsGrps[0].Id
            );

            // 検証
            System.assert(String.isNotEmpty(label));
        }
    }

    // 分類・評価軸リストの取得のテスト
    @isTest static void getClassisTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            // 分類・評価軸リストの取得
            List<ermt__M_Classification__c> classis = RiskClassiOutputCtlr.getClassis(
                new List<Id>{ clss[0].Id }
            );

            // 検証
            System.assert(!classis.isEmpty());
        }
    }
}