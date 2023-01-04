// プロジェクトのリスク一覧（編集用）コントローラのテスト
@isTest
private class ProjectRisklistEditCtlrTest {
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
                    , clss[i]
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
            for (Integer i = 0; i < 4; i++) {
                ermt__RiskAssessment_Classification_Junc__c rskAssCls = TestDataFactory.createRiskAssessmentClassi(
                    rskAsss[0]
                    , clss[i + 1]
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

    // リスク関連の更新のテスト
    @isTest static void updateRiskRelationTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__M_Classification__c> clsGrps = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c');
        List<ermt__Risk__c> rsks = (List<ermt__Risk__c>)data.get('ermt__Risk__c');
        List<ermt__Risk_Classification_Junc__c> rskClss = (List<ermt__Risk_Classification_Junc__c>)data.get('ermt__Risk_Classification_Junc__c');
        List<ermt__RiskAssessment__c> rskAsss = (List<ermt__RiskAssessment__c>)data.get('ermt__RiskAssessment__c');
        List<ermt__RiskAssessment_Classification_Junc__c> rskAssClss =
            (List<ermt__RiskAssessment_Classification_Junc__c>)data.get('ermt__RiskAssessment_Classification_Junc__c');
        List<ermt__Risk_Control_Junc__c> rskCtls = (List<ermt__Risk_Control_Junc__c>)data.get('ermt__Risk_Control_Junc__c');
        System.runAs(usrs[0]) {
            List<Map<String, Object>> risks = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rsks[0].Id
                        , 'no' => 1
                    }
                    , 'Name' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.STRING)
                        , 'value' => rsks[0].Name
                        , 'no' => 1
                    }
                }
            };
            List<Map<String, Object>> riskAssessments = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rskAsss[0].Id
                        , 'no' => 1
                    }
                    , 'ermt__isActive__c' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.BOOLEAN)
                        , 'value' => FieldValueInputCtlr.VALUE_TRUE
                        , 'no' => 1
                    }
                }
            };
            List<Map<String, Object>> riskAssessmentClassis = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rskAssClss[0].Id
                        , 'no' => 1
                    }
                    , 'ClassiRecordType' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.STRING)
                        , 'value' => System.Label.ClassiRecordType_AnalyseTiming
                        , 'no' => 1
                    }
                    , 'riskAssessmentId' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rskAssClss[0].ermt__RiskAssessment__c
                    }
                    , 'classiId' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rskAssClss[0].ermt__M_Classification__c
                        , 'no' => 1
                    }
                }
            };
            List<Map<String, Object>> riskControls = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.ID)
                        , 'value' => rskCtls[0].Id
                        , 'no' => 1
                    }
                    , 'ermt__Risk__c' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.REFERENCE)
                        , 'value' => rskCtls[0].ermt__Risk__c
                        , 'no' => 1
                    }
                    , 'ermt__Control__c' => new Map<Object, Object>{
                        'type' => String.valueOf(Schema.DisplayType.REFERENCE)
                        , 'value' => rskCtls[0].ermt__Control__c
                        , 'no' => 1
                    }
                }
            };

            // リスク関連の更新
            Boolean result = ProjectRisklistEditCtlr.updateRiskRelation(
                risks
                , riskAssessments
                , riskAssessmentClassis
                , riskControls
            );

            // 検証
            System.assert(result);
        }
    }

    // 値の変換のテスト
    @isTest static void convertValueTest_1() {
        // 値の変換
        Object value = ProjectRisklistEditCtlr.convertValue(
            FieldValueInputCtlr.VALUE_TRUE
            , String.valueOf(Schema.DisplayType.BOOLEAN)
        );
        // 検証
        System.assertEquals(true, value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            '50'
            , String.valueOf(Schema.DisplayType.PERCENT)
        );
        // 検証
        System.assertEquals(50, value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            String.valueOf(TestDataFactory.NOW_DATETIME.date())
            , String.valueOf(Schema.DisplayType.DATE)
        );
        // 検証
        System.assertEquals(TestDataFactory.NOW_DATETIME.date(), value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            '09:00:00'
            , String.valueOf(Schema.DisplayType.TIME)
        );
        // 検証
        System.assertEquals(Time.newInstance(9, 0, 0, 0), value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            TestDataFactory.NOW_DATETIME.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.000Z')
            , String.valueOf(Schema.DisplayType.DATETIME)
        );
        // 検証
        System.assertEquals(TestDataFactory.NOW_DATETIME, value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            new List<String>{'選択肢1', '選択肢2'}
            , String.valueOf(Schema.DisplayType.MULTIPICKLIST)
        );
        // 検証
        System.assertEquals('選択肢1;選択肢2', value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            UserInfo.getUserId()
            , String.valueOf(Schema.DisplayType.ID)
        );
        // 検証
        System.assertEquals(UserInfo.getUserId(), value);
        // 値の変換
        value = ProjectRisklistEditCtlr.convertValue(
            '値1'
            , String.valueOf(Schema.DisplayType.STRING)
        );
        // 検証
        System.assertEquals('値1', value);
    }
}