@isTest
private class ProjectRisklistApprovalCtrlTest {
    static Map<String, Object> makeData_1() {
        Map<String, Object> ret = new Map<String, Object>();

        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        ret.put('User', usrs);

        System.runAs(usrs[0]) {
            List<Account> accs = new List<Account>();
            for (Integer i = 0; i < 1; i++) {
                Account acc = TestDataFactory.createAccount(i + 1);
                accs.add(acc);
            }
            insert accs;
            ret.put('Account', accs);

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

            List<ermt__Project__c> prjs = new List<ermt__Project__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Project__c prj = TestDataFactory.createProject(i + 1);
                prj.ermt__AnalyseTimingDefault__c = clss[0].id;
                prjs.add(prj);
            }
            insert prjs;
            ret.put('ermt__Project__c', prjs);

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

            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = TestDataFactory.createRisk(i + 1, accs[0]);
                rsk.ermt__Project__c = prjs[0].Id;
                rsk.ermt__ApprovalStatus__c = '未申請';
                rsks.add(rsk);
            }
            insert rsks;
            ret.put('ermt__Risk__c', rsks);

            List<ermt__RiskAssessment__c> rskAsss = new List<ermt__RiskAssessment__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__RiskAssessment__c rskAss = TestDataFactory.createRiskAssessment(rsks[0]);
                rskAsss.add(rskAss);
            }
            insert rskAsss;
            ret.put('ermt__RiskAssessment__c', rskAsss);

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

            List<ermt__Risk_Classification_Junc__c> rskCtls = new List<ermt__Risk_Classification_Junc__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk_Classification_Junc__c rskCtl = TestDataFactory.createRiskClassi(
                    rsks[0]
                    , clss[0]
                );
                rskCtls.add(rskCtl);
            }
            insert rskCtls;
            ret.put('ermt__Risk_Classification_Junc__c', rskCtls);
        }
        return ret;
    }
    @isTest static void getRiskDisplayFieldNameSelsTest_1() {
        List<Map<String, Object>> sels = ProjectRisklistApprovalCtrl.getRiskDisplayFieldNameSels();
        System.assert(!sels.isEmpty());
    }
    @isTest static void getRiskAssessmentDisplayFieldNameSelsTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<Map<String, Object>> sels = ProjectRisklistApprovalCtrl.getRiskAssessmentDisplayFieldNameSels(prjs[0].Id);
            System.assert(!sels.isEmpty());
        }
    }
    @isTest static void getControlDisplayFieldSelsTest_1() {
        List<Map<String, Object>> sels = ProjectRisklistApprovalCtrl.getControlDisplayFieldNameSels();
        System.assert(!sels.isEmpty());
    }
    @isTest static void getRisklistDisplayFieldNameTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            String fieldName = ProjectRisklistApprovalCtrl.getRisklistDisplayFieldName(prjs[0].Id);
            System.assert(String.isEmpty(fieldName));
        }
    }
    @isTest static void getRiskFieldDescByNameTest_1() {
        List<String> dispFieldNames = new List<String>{
            'Name', 'ermt__Organization__c', 'ermt__AssessmentStatus__c'
        };
        Map<String, ProjectRisklistApprovalCtrl.FieldDescribe> fieldDescMap = ProjectRisklistApprovalCtrl.getRiskFieldDescByName(
            dispFieldNames
        );
        System.assert(!fieldDescMap.isEmpty());
    }

    @isTest static void getRiskAssessmentFieldDescByNameTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<String> dispFieldNames = new List<String>{
                System.Label.ClassiRecordType_AnalyseTiming
                , System.Label.ClassiRecordType_Probability
                , System.Label.ClassiRecordType_ResultImpact
                , System.Label.ClassiRecordType_ThirdEvaluation
                , 'ermt__isActive__c'
            };
            Map<String, ProjectRisklistApprovalCtrl.FieldDescribe> fieldDescMap = ProjectRisklistApprovalCtrl.getRiskAssessmentFieldDescByName(
                prjs[0].Id    
                , dispFieldNames
            );
            System.assert(!fieldDescMap.isEmpty());
        }
    }

    @isTest static void getClassificationFieldDescByNameTest_1() {
        List<String> dispFieldNames = new List<String>{
            'ermt__Label_Pick__c'
        };
        Map<String, ProjectRisklistApprovalCtrl.FieldDescribe> fieldDescMap = ProjectRisklistApprovalCtrl.getClassificationFieldDescByName(
            dispFieldNames
        );
        System.assert(!fieldDescMap.isEmpty());
    }

    @isTest(SeeAllData=true) static void getRisksTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<String> dispFieldNames = new List<String>{
                'Name', 'ermt__Organization__c', 'ermt__AssessmentStatus__c'
            };
            Map<String, Object> result = ProjectRisklistApprovalCtrl.getRisks( prjs[0].Id, dispFieldNames, null, null);
            System.assert(!result.isEmpty());
        }
    }

    @isTest static void getRiskAssessmentsByRiskIdTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        List<ermt__M_Classification__c> clss = (List<ermt__M_Classification__c>)data.get('ermt__M_Classification__c_2');
        System.runAs(usrs[0]) {
            List<String> dispFieldNames = new List<String>{
                System.Label.ClassiRecordType_AnalyseTiming
                , System.Label.ClassiRecordType_Probability
                , System.Label.ClassiRecordType_ResultImpact
                , System.Label.ClassiRecordType_ThirdEvaluation
                , 'ermt__isActive__c'
                , 'ermt__SeverityRiskLevel__c'
                , 'CreatedById'
            };
  
            Map<String, Object> result = ProjectRisklistApprovalCtrl.getRiskAssessmentsByRiskId(prjs[0].Id, dispFieldNames, null, null);

            System.assert(!result.isEmpty());
        }
    }

    @isTest static void getClassificationsByRiskIdTest_1() {
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<String> dispFieldNames = new List<String>{};
            dispFieldNames.add('ermt__Label_Pick__c');
            String kindRecordType = '種別1: 分類・評価軸設定1';    
            Map<String, Object> result = ProjectRisklistApprovalCtrl.getClassificationsByRiskId(prjs[0].Id, dispFieldNames, kindRecordType, null, null);

            System.assert(!result.isEmpty());
        }
    }

    @isTest static void applyApprovalTest(){
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<ermt__Risk__c> risks = [SELECT id FROM ermt__Risk__c];
            ermt__Risk__c riskApplyApproval = risks[0];
            List<String> riskIdApproval = new List<String>();
            riskIdApproval.add(riskApplyApproval.Id);
            ProjectRisklistApprovalCtrl.ApprovalResult result = ProjectRisklistApprovalCtrl.applyApproval('please approval',riskIdApproval);
            System.assert(result.isSuccess == false);
        }
    }

    @isTest static void getGroupClassiSelsTest(){
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<ermt__Project__c> prjs = (List<ermt__Project__c>)data.get('ermt__Project__c');
        System.runAs(usrs[0]) {
            List<Map<String,String>> result = ProjectRisklistApprovalCtrl.getGroupClassiSels(prjs[0].Id, Label.ClassiRecordType_RiskClassiGroup);
            System.assert(result != null);
        }
    }
}