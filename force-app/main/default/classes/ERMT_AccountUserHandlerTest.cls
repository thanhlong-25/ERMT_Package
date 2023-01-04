@isTest
private class ERMT_AccountUserHandlerTest {
	
	@testSetup static void initDataTest(){
		Test.startTest();
		ERMT_MockChecklistTest.MockDataInsertedAccountUserHandleTest();
		ERMT_MockChecklistTest.insertGroupMemberTest();
		Test.stopTest();
	}
	
	@isTest static void test_deleteGroupMemberSuccess() {

		Test.startTest();

		List<ermt__Account_User__c> listAccountUsers = [select Id from ermt__Account_User__c];
		String id = 'Account_' + listAccountUsers[0].Id;
		delete listAccountUsers;

		Test.stopTest();

		List<GroupMember> listGrps = [select Id from GroupMember WHERE Group.DeveloperName like :id];

		System.assert(listGrps.isEmpty() == true);
	}


	@isTest static void test_deleteGroupMemberNullInputData() {
		Test.startTest();

		ERMT_AccountUserHandler.deleteGroupMemberRelated(null);

		Test.stopTest();

		List<GroupMember> listGrps = [select Id from GroupMember];
		System.assert(listGrps.isEmpty() == false);
	}

	@isTest static void test_deleteGroupMemberRunAsUserWithoutPermission() {

		Test.startTest();

		User u = [SELECT Id From User WHERE profile.Name = 'ERMT' AND IsActive = true limit 1] ;

		List<ermt__Account_User__c> listAccountUsers = [select Id from ermt__Account_User__c];
		String id = 'Account_' + listAccountUsers[0].Id;

		delete listAccountUsers;

		System.runAs(u){
			System.debug(Schema.sObjectType.ermt__Checklist__c.isAccessible());
			System.debug(Schema.sObjectType.ermt__Checklist__c.isQueryable());
			System.debug(Schema.sObjectType.ermt__Checklist__c.isUpdateable());
		}

		System.debug([select Id from ermt__Checklist__c]);

		Test.stopTest();

		List<GroupMember> listGrps = [select Id from GroupMember WHERE Group.DeveloperName like :id];

		System.assert(listGrps.isEmpty() == true);
	}
}