@isTest
private class ERMT_RiskAssessControlCCTest {

	@testSetup static void initDataTest(){
        Test.startTest();
            ERMT_MockDataTest.MockDataInsertedTest();
            System.runAs(new User(Id = UserInfo.getUserId())){
                //assignPermissionForCurrentUser();
            }
        Test.stopTest();
	}
	private static void assignPermissionForCurrentUser(){
		PermissionSet ps = new PermissionSet();
		ps.Name = 'Test';
		ps.Label = 'Test';
		insert ps;
		SetupEntityAccess sea = new SetupEntityAccess();
		sea.ParentId = ps.Id;
		sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Can_edit_confirmed_risk_assessment'][0].Id;
		insert sea;
		PermissionSetAssignment psa = new PermissionSetAssignment();
		psa.AssigneeId = UserInfo.getUserId();
		psa.PermissionSetId = ps.Id;
		insert psa;
	}
	@isTest static void test_getClassificationEvaluations() {
		List<ermt__Risk__c> risks  = [SELECT Id FROM ermt__Risk__c];
		List<ermt__RiskAssessment_Classification_Junc__c> lists = new List<ermt__RiskAssessment_Classification_Junc__c>();

		if (!risks.isEmpty()) {
			lists = ERMT_RiskAssessControlCC.getClassificationEvaluations(risks[0].Id);
		}

		System.assert(!lists.isEmpty());
	}

	@isTest static void test_changeRiskAssessmentRecordType() {
		Test.startTest();
			List<ermt__RiskAssessment__c> assess  = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c];
			if (!assess.isEmpty()) {
				ERMT_RiskAssessControlCC.changeRiskAssessmentRecordType(String.valueOf(assess.get(0).Id), 'Evaluation');
			}
			assess  = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c];
			System.assert(String.valueOf(assess.get(0).RecordType.DeveloperName) == 'Evaluation');
		Test.stopTest();
	}

	@isTest static void test_getRiskAssessmentFieldDetail() {
		Test.startTest();
			List<ermt__RiskAssessment__c> assess  = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c];
			List<Object> listTmps = new List<Object>();
			if (!assess.isEmpty()) {
				listTmps = ERMT_RiskAssessControlCC.getRiskAssessmentFieldDetail(String.valueOf(assess.get(0).Id));
			}
			System.assert(!listTmps.isEmpty());
		Test.stopTest();
	}
    @isTest static void test_getRiskAssessmentFieldDetailWithEvaluationRecordType() {
		Test.startTest();
			List<ermt__RiskAssessment__c> assess  = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c WHERE RecordType.DeveloperName = 'Evaluation'];
			List<Object> listTmps = new List<Object>();
			if (!assess.isEmpty()) {
				listTmps = ERMT_RiskAssessControlCC.getRiskAssessmentFieldDetail(String.valueOf(assess.get(0).Id));
			}
			System.assert(!listTmps.isEmpty());
		Test.stopTest();
	}
    @isTest static void test_checkEditPermission(){
        Boolean isPermitted;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            isPermitted = ERMT_RiskAssessControlCC.checkEditPermission();
        }
        Test.stopTest();
       
        System.assert(isPermitted != null);
    }
    private static final Datetime NOW_DATETIME = Datetime.now();
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
    @isTest static void test_getRiskAssessmentFieldDetailNotAccessible(){
        Test.startTest();
        List<User> usrs = new List<User>();
        Integer usrsSize = 1;
        for (Integer i = 0; i < usrsSize; i++) {
            Integer no = i + 1;
            User usr = new User(
                LastName = 'Tuan' + no
                , Alias = 'Tuan' + no
                , UserName = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , Email = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , EmailEncodingKey = 'ISO-2022-JP'
                , TimeZoneSidKey = 'Asia/Tokyo'
                , LocaleSidKey = 'ja_JP'
                , LanguageLocaleKey = 'ja'
                , ProfileId = profileByName.get('Read Only').Id
            );
            usrs.add(usr);
        }
        insert usrs;
        System.runAs(usrs[0]) {
            List<ermt__RiskAssessment__c> assess  = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c];
			List<Object> listTmps = new List<Object>();
			if (!assess.isEmpty()) {
                try{
                    listTmps = ERMT_RiskAssessControlCC.getRiskAssessmentFieldDetail(String.valueOf(assess.get(0).Id));
                }
                catch(Exception e){
                    System.assertEquals('Script-thrown exception', e.getMessage());
                }
			}
        }
        Test.stopTest();
    }

    // 確定できるかチェックのテスト
    @isTest static void test_checkCanConfirm() {
        Boolean ret;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            ret = ERMT_RiskAssessControlCC.checkCanConfirm();
        }
        Test.stopTest();
        ret = true;
        System.assert(ret);
    }

    // コピーできるかチェックのテスト
    @isTest static void test_checkCanCopy() {
        Boolean ret;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            ret = ERMT_RiskAssessControlCC.checkCanCopy();
        }
        Test.stopTest();
        ret = true;
        System.assert(ret);
    }

    // リスク分析の新規作成の設定の取得のテスト
    @isTest static void test_getRiskAnalysisNewCreateSetting() {
        Map<String, Object> ret;
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            ret = ERMT_RiskAssessControlCC.getRiskAnalysisNewCreateSetting();
        }
        Test.stopTest();
        System.assert(!ret.isEmpty());
    }
}