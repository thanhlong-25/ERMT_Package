@isTest
private class ERMT_ChecklistCCTest {
	
	@testSetup static void initDataTest(){
		Test.startTest();
		ERMT_MockChecklistTest.MockDataInsertedChecklistTest();
		ERMT_MockChecklistTest.MockDataChecklistTest();
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
		sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'Can_answer_checklist'][0].Id;
		insert sea;
		PermissionSetAssignment psa = new PermissionSetAssignment();
		psa.AssigneeId = UserInfo.getUserId();
		psa.PermissionSetId = ps.Id;
		insert psa;
	}

	@isTest static void test_SubmitChecklistSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		ERMT_MockChecklistTest.MockDataInsertChecklistAnswersTest();

        ERMT_ChecklistCC.submitChecklist(cl.Id);

		Test.stopTest();

		List<ermt__Checklist_User__c> listChecklistUsers = [SELECT Id, ermt__Is_Submit__c FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id AND ermt__User__c =: UserInfo.getUserId()];

		System.assert(listChecklistUsers[0].ermt__Is_Submit__c == true);
	}


	@isTest static void test_CheckSubmitableChecklistMissAnswerSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;

		ERMT_MockChecklistTest.MockDataInsertChecklistMissingAnswersTest();

        ERMT_ChecklistCC.CheckSubmit a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);

		Test.stopTest();
		System.assert(a.submitable == false);
	}

	@isTest static void test_CheckSubmitableChecklistFullAnswerSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;
		
		ERMT_MockChecklistTest.MockDataInsertChecklistAnswersTest();

        ERMT_ChecklistCC.CheckSubmit a;
        System.runAs(new User(Id = UserInfo.getUserId())){
            a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);
        }
		Test.stopTest();

		System.assert(a.submitable == true);
	}

	@isTest static void test_CheckSubmitableChecklistSubmittedSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;

		ERMT_MockChecklistTest.MockDataInsertChecklistAnswersTest();

		List<ermt__Checklist_User__c> listChecklistUsers = [SELECT Id, ermt__Is_Submit__c FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id AND ermt__User__c =: UserInfo.getUserId()];
		listChecklistUsers[0].ermt__Is_Submit__c = true;
		
		update listChecklistUsers[0];

        ERMT_ChecklistCC.CheckSubmit a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);

		Test.stopTest();

		System.assert(a.submitable == false);
	}

	@isTest static void test_CheckSubmitableChecklistWithoutChecklistUserSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;
		
		ERMT_MockChecklistTest.MockDataInsertChecklistAnswersTest();

		ERMT_MockChecklistTest.MockDataDeleteChecklistUserTest();

        ERMT_ChecklistCC.CheckSubmit a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);

		System.assert(a.submitable == false);
	}

	@isTest static void test_CheckSubmitableChecklistWithoutPermissionSuccess() {
		
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		
		ERMT_MockChecklistTest.MockDataInsertChecklistAnswersTest();

		Profile p = [SELECT Id FROM Profile WHERE UserType ='Standard' And Name != 'ERMT' Limit 1];
      	User u2 = new User(Alias = 'userTest', Email='newuserTest@testorg.com',
		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
		LocaleSidKey='en_US', ProfileId = p.Id,
		TimeZoneSidKey='America/Los_Angeles', UserName='newuserTest@testorg.Test.com');
		insert u2;
		ERMT_ChecklistCC.CheckSubmit a = null;
		Test.startTest();
		System.runAs(u2) {
			a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);
		}
		Test.stopTest();
		
		System.assert(a.submitable == false);
	}

	@isTest static void test_CheckSubmitableChecklistInvalidSuccess() {
		
		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

        ERMT_ChecklistCC.CheckSubmit a = ERMT_ChecklistCC.checkChecklistSubmitable(cl.Id);

		Test.stopTest();

		System.assert(a.submitable == false);
	}
	
}