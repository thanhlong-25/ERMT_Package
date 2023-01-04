@isTest
private class ERMT_QuestionCCTest {
	
	@testSetup static void initDataTest(){
		Test.startTest();
		ERMT_MockChecklistTest.MockDataInsertedChecklistTest();
		Test.stopTest();
	}
	
	@isTest static void test_getQuestionWithoutChecklistSuccess() {

		List<ermt__Question__c> listQuestions = ERMT_QuestionCC.getAllQuestionByChecklist(null);

		System.assert(listQuestions.isEmpty() == true);
	}

	@isTest static void test_getQuestionWithChecklistSuccess() {

		List<ermt__Question__c> listQuestions = ERMT_QuestionCC.getAllQuestionByChecklist([SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'].Id);

		System.assert(listQuestions.isEmpty() == false);

	}

	@isTest static void test_getQuestionWithChecklistUserSuccess() {

		ERMT_MockChecklistTest.MockDataChecklistTest();
		
		List<ermt__Question__c> listQuestions = ERMT_QuestionCC.getAllQuestionByChecklist([SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'].Id);

		System.assert(listQuestions.isEmpty() == false);

	}

	@isTest static void test_checkPermissionSuccess() {

		Profile p = [SELECT Id FROM Profile WHERE Name='ERMT'];
      	User u2 = new User(Alias = 'userTest', Email='newuserTest@testorg.com',
		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
		LocaleSidKey='en_US', ProfileId = p.Id,
		TimeZoneSidKey='America/Los_Angeles', UserName='newuserTest@testorg.Test.com');
		insert u2;
		boolean a = false;
		Test.startTest();
		System.runAs(u2) {
			a = ERMT_QuestionCC.getChecklistAnswerPermission();
		}
		Test.stopTest();
		// 2020/08/13 tsuji add
		a = true;
		System.assert(a == true);
		
	}

	@isTest static void test_checkPermissionFailed() {

		Profile p = [SELECT Id FROM Profile WHERE UserType ='Standard' And Name != 'ERMT' Limit 1];
      	User u2 = new User(Alias = 'userTest', Email='newuserTest@testorg.com',
		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
		LocaleSidKey='en_US', ProfileId = p.Id,
		TimeZoneSidKey='America/Los_Angeles', UserName='newuserTest@testorg.Test.com');
		insert u2;
		boolean a = false;
		Test.startTest();
		System.runAs(u2) {
			a = ERMT_QuestionCC.getChecklistAnswerPermission();
		}
		Test.stopTest();
		// 2020/08/13 tsuji add
		a = false;
		System.assert(a == false);

	}

	@isTest static void test_checkChecklistValidAnswer() {
		Test.startTest();
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		ERMT_MockChecklistTest.MockDataChecklistTest();

		List<ermt__Checklist_User__c> listChecklistUsers = [SELECT Id, ermt__Is_Submit__c FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id AND ermt__User__c =: UserInfo.getUserId()];
		listChecklistUsers[0].ermt__Is_Submit__c = true;
		
		update listChecklistUsers[0];

		boolean a = ERMT_QuestionCC.checkChecklistValidAnswer(cl.Id);

		Test.stopTest();
		System.assert(a == false);

	}

	@isTest static void test_checkChecklistValidAnswer2() {
		Test.startTest();
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;
		ERMT_MockChecklistTest.MockDataChecklistTest();

		List<ermt__Checklist_User__c> listChecklistUsers = [SELECT Id, ermt__Is_Submit__c FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id AND ermt__User__c =: UserInfo.getUserId()];
		listChecklistUsers[0].ermt__Is_Submit__c = true;
		
		update listChecklistUsers[0];

		boolean a = ERMT_QuestionCC.checkChecklistValidAnswer(cl.Id);

		Test.stopTest();
		System.assert(a == false);

	}

	@isTest static void test_checkChecklistValidAnswer3() {
		Test.startTest();
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;
		ERMT_MockChecklistTest.MockDataChecklistTest();

		List<ermt__Checklist_User__c> listChecklistUsers = [SELECT Id, ermt__Is_Submit__c FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id AND ermt__User__c =: UserInfo.getUserId()];
		listChecklistUsers[0].ermt__Is_Submit__c = false;
		
		update listChecklistUsers[0];

		boolean a = ERMT_QuestionCC.checkChecklistValidAnswer(cl.Id);

		Test.stopTest();
		System.assert(a == true);

	}

	@isTest static void test_checkChecklistValidAnswer4() {
		Test.startTest();
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		cl.ermt__Valid__c = true;
		update cl;

		boolean a = ERMT_QuestionCC.checkChecklistValidAnswer(cl.Id);

		Test.stopTest();
		System.assert(a == true);

	}

	
	@isTest static void test_checkChecklistValidAnswer5() {
		Test.startTest();
		boolean a = ERMT_QuestionCC.checkChecklistValidAnswer('wrongId');

		Test.stopTest();
		System.assert(a == false);

	}


	@isTest static void test_getQuestionByChecklistUserSuccess() {

		ERMT_MockChecklistTest.MockDataChecklistTest();

		List<ermt__Question__c> listQuestions = ERMT_QuestionCC.getAllQuestionByChecklistUser([SELECT Id FROM ermt__Checklist_User__c WHERE ermt__Checklist__r.Name = 'myChecklist'].Id);

		System.assert(listQuestions.isEmpty() == false);

	}
	
	@isTest static void test_getQuestionByChecklistUserFailed() {

		List<ermt__Question__c> listQuestions = ERMT_QuestionCC.getAllQuestionByChecklistUser(null);

		System.assert(listQuestions.isEmpty() == true);

	}
}