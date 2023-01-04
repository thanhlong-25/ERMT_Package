@isTest
private class ERMT_CategoryCCTest {
	
	@testSetup static void initDataTest(){
		Test.startTest();
		ERMT_MockChecklistTest.MockDataInsertedChecklistTest();
		Test.stopTest();
	}
	
    @isTest static void test_answersWithoutChecklistUserSuccess() {

		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		List<ermt__Answer__c> answers = ERMT_MockChecklistTest.MockDataChecklistAnswersTest();
        ERMT_CategoryCC.upsertAnswers(cl.Id, answers);

		Test.stopTest();

		List<ermt__Answer__c> listAnswers = [select Id from ermt__Answer__c WHERE ermt__Question__r.ermt__Title__c like 'Q %'];

		System.assert(listAnswers.isEmpty() == false);
	}

    @isTest static void test_answersWithChecklistUserSuccess() {

		Test.startTest();

		ERMT_MockChecklistTest.MockDataChecklistTest();

        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		List<ermt__Answer__c> answers = ERMT_MockChecklistTest.MockDataChecklistAnswersTest();
        ERMT_CategoryCC.upsertAnswers(cl.Id, answers);

		Test.stopTest();

		List<ermt__Answer__c> listAnswers = [select Id from ermt__Answer__c WHERE ermt__Question__r.ermt__Title__c like 'Q %'];

		System.assert(listAnswers.isEmpty() == false);
	}

    @isTest static void test_answersWithoutAnswerSuccess() {

		Test.startTest();
        ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

        ERMT_CategoryCC.upsertAnswers(cl.Id, null);

		Test.stopTest();

		List<ermt__Answer__c> listAnswers = [select Id from ermt__Answer__c WHERE ermt__Question__r.ermt__Title__c like 'Q %'];

		System.assert(listAnswers.isEmpty() == true);
	}
}