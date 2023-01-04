@isTest
private class ERMT_UtilsTest {

	@testSetup static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();

	}
	
	@isTest static void test_isId() {
		ermt__Project__c  project = [Select Id, Name From ermt__Project__c Limit 1];
		Boolean test = ERMT_Utils.isId(project.Id);
		System.assertEquals(true , test);
	}
	@isTest static void test_isValid_sObjectId() {
		ermt__Project__c  project = [Select Id, Name From ermt__Project__c Limit 1];
		Boolean test = ERMT_Utils.isValid(project.Id , ermt__Project__c.sObjectType);
		System.assertEquals(true , test);
	}
	@isTest static void test_isValid_stringId() {
		ermt__Project__c  project = [Select Id, Name From ermt__Project__c Limit 1];
		Boolean test = ERMT_Utils.isValid((String)project.Id , ermt__Project__c.sObjectType);
		System.assertEquals(true , test);
	}

}