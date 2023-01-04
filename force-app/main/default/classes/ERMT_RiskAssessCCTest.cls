@isTest
private class ERMT_RiskAssessCCTest {
	@testSetup static void initDataTest(){
        Test.startTest();
		ERMT_MockDataTest.MockDataInsertedTest();
        System.runAs(new User(Id = Userinfo.getUserId())) {
			assignPermissionForCurrentUser();
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
	@isTest static void test_getListSelectAndChild() {
		List<ermt__Project__c> projectList = [Select Id, Name From ermt__Project__c];
		List<ermt__M_Classification__c> mClassList = ERMT_RiskAssessCC.getListSelectAndChild(projectList[0].Id , 'LikelihoodGroup');
		System.assertEquals('MTest' ,mClassList[0].Name);
	
	}

	@isTest static void test_getSelectedClassification(){
		List<ermt__RiskAssessment__c> rAssesstList = [Select Id, Name From ermt__RiskAssessment__c];
		List<ermt__RiskAssessment_Classification_Junc__c> raJuncList =  ERMT_RiskAssessCC.getSelectedClassification(rAssesstList[1].Id,'LikelihoodGroup');
		System.assertEquals(1, raJuncList.size());
	}

	@isTest static void test_upsertSelectedClassification(){
		List<ermt__M_Classification__c> mClassList = [Select Id, Name , ermt__ParentMClassification_del__c From ermt__M_Classification__c Where RecordType.DeveloperName='ChoiceItem' And ermt__ParentMClassification_del__r.RecordType.DeveloperName='LikelihoodGroup'];
		List<ermt__RiskAssessment__c> rAssesstList = [Select Id, Name From ermt__RiskAssessment__c];
		ERMT_RiskAssessCC.upsertSelectedClassification(rAssesstList[0].Id, mClassList[0].Id , mClassList[0].ermt__ParentMClassification_del__c);
		List<ermt__RiskAssessment_Classification_Junc__c> raJuncList = [Select Id , Name , ermt__RiskAssessment__c, ermt__M_Classification__c  From ermt__RiskAssessment_Classification_Junc__c Where ermt__M_Classification__r.RecordType.DeveloperName='ChoiceItem' And ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName='LikelihoodGroup' And ermt__RiskAssessment__c=:rAssesstList[0].id];
		System.assertEquals( mClassList[0].Id , raJuncList[0].ermt__M_Classification__c);

	}
    @isTest static void test_checkEditPermission(){
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            Boolean isPermitted = ERMT_RiskAssessCC.checkEditPermission();
            System.assert(isPermitted == true);
        }
        Test.stopTest();
    }
	
}