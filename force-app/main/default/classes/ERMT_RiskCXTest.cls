@isTest
private class ERMT_RiskCXTest {
	
	@testSetup  static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();
	}
	
	@isTest static void test_copyRiskData() {
		List<String> riskIds = new List<String>();
		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];
		List<ermt__Risk__c> risks = [Select Id From ermt__Risk__c];
		for(ermt__Risk__c r : risks){
			riskIds.add(r.Id);
		}
		ERMT_EnhancedCloneHelper.CloneModel result = ERMT_RiskCX.copyRiskData(riskIds, prj2.Id);
		System.assert(result.isSuccess == true);
	}
	
	@isTest static void test_getAllProject() {
		Test.startTest();
		//test contructor
		ermt__Risk__c risk  = new ermt__Risk__c(ermt__RiskContents__c = 'Risk 1' ,Name = 'risk1');
		List<ermt__Risk__c> risks = new List<ermt__Risk__c>();
		insert risk;
		risks.add(risk);
		// StandartSetController allow list record
		ApexPages.StandardSetController sc = new ApexPages.StandardSetController(risks);
		 ERMT_RiskCX myClass = new ERMT_RiskCX(sc);

		List<ermt__Project__c> projects = ERMT_RiskCX.getAllProject();
		Test.stopTest();
		System.assertEquals(2 , projects.size());
	}
}