@isTest
private class ERMT_ProjectClassifiJuncTriggerTest {

	@testSetup static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();
	}
	
	@isTest static void test_deleteRiskClassiJuncChild() {
		List<ermt__Project_Classification_Junc__c> pJuncList = [Select ermt__Project__c,ermt__M_Classification__r.RecordType.DeveloperName  from ermt__Project_Classification_Junc__c];
		Test.startTest();
			delete pJuncList;
		Test.stopTest();
		List<ermt__Risk_Classification_Junc__c> rJuncListResult = [Select Id , Risk__r.Project__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName from ermt__Risk_Classification_Junc__c];
		
		List<ermt__RiskAssessment_Classification_Junc__c> raJuncListResult = [Select Id , Name from ermt__RiskAssessment_Classification_Junc__c];
		System.assertEquals(0, rJuncListResult.size());
		System.assertEquals(0, raJuncListResult.size());

	}
	
	
}