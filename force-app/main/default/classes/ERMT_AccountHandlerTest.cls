@isTest
private class ERMT_AccountHandlerTest {
	
	@testSetup static void initDataTest(){
		Test.startTest();
		ERMT_MockChecklistTest.MockDataInsertedAccountHandleTest();
		Test.stopTest();
	}
	
	@isTest static void test_PublicGroup_created() {
		List<Group> listGrps = [select Id,DeveloperName,Name from Group Where DeveloperName Like 'Account_%'];
		System.assert(listGrps.isEmpty() == false);
	}	

	@isTest static void test_deletePublicGroupSuccess() {

		Test.startTest();

		List<Account> listAccounts = [select Id, RecordTypeId from Account];
		String id = 'Account_' + listAccounts[0].Id;
		delete listAccounts;

		Test.stopTest();

		List<Group> listGrps = [select Id, Name from Group WHERE DeveloperName like :id];

		System.assert(listGrps.isEmpty() == true);
	}


	@isTest static void test_deletePublicGroupNullInputData() {
		Test.startTest();

		ERMT_AccountHandler.deletePublicGroupRelated(null);

		Test.stopTest();

		List<Group> listGrps = [select Id from Group];
		System.assert(listGrps.isEmpty() == false);
	}
}