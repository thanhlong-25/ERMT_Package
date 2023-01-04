@isTest
private class ERMT_FLSCheckTest {
	@testSetup static void setup() {
  		ERMT_MockDataTest.MockDataInsertedTest(); 
    }
    @isTest static void test_getPrefix(){
        String prefix = ERMT_FLSCheck.getPrefix();
        System.assert(prefix != null);
    }
    @isTest static void test_checkUpdate_ObjectNull(){
        ermt__RiskAssessment__c paramObject = new ermt__RiskAssessment__c();
        paramObject = null;
        Boolean result = ERMT_FLSCheck.checkUpdate(paramObject, new List<String>());
        System.assert(result == false);
    }
    @isTest static void test_checkUpdate_ListObjectEmpty(){
        Boolean result = ERMT_FLSCheck.checkUpdate(new List<ermt__RiskAssessment__c>(), new List<String>());
        System.assert(result == false);
    }
    @isTest static void test_checkUpdate_ListObjectWithFirstItemNull(){
        List<ermt__RiskAssessment__c> rAssessment = [Select Id , Name , ermt__Likelihood__c , ermt__NumberLikelihood__c From ermt__RiskAssessment__c];
        rAssessment[0] = null;
        Boolean result = ERMT_FLSCheck.checkUpdate(rAssessment, new List<String>());
        System.assert(result == false);
    }
	@isTest static void test_checkUpdate_One() {
		List<ermt__RiskAssessment__c> rAssessment = [Select Id , Name , ermt__Likelihood__c , ermt__NumberLikelihood__c From ermt__RiskAssessment__c];
		List<String> fields = new List<String>();
		fields.add('ermt__Likelihood__c');
		fields.add('ermt__NumberLikelihood__c');
		rAssessment[0].ermt__Likelihood__c = null;
		rAssessment[0].ermt__NumberLikelihood__c = 0;
		Boolean result = ERMT_FLSCheck.checkUpdate(rAssessment[0],  fields);
		System.assert(result == true);
		
	}	
	@isTest static void test_checkUpdate_Multi() {

		List<ermt__RiskAssessment__c> rAssessment = [Select Id , Name , ermt__Likelihood__c , ermt__NumberLikelihood__c From ermt__RiskAssessment__c];
		List<String> fields = new List<String>();
		fields.add('ermt__Likelihood__c');
		fields.add('ermt__NumberLikelihood__c');
		rAssessment[0].ermt__Likelihood__c = null;
		rAssessment[0].ermt__NumberLikelihood__c = 0;
		rAssessment[1].ermt__Consequence__c = null;
		rAssessment[1].ermt__NumberConsequence__c = 0;
		rAssessment[1].ermt__SeverityRiskLevel__c = null;
		rAssessment[1].ermt__NumberSeverityRiskLevel__c = 0;
		Boolean result = ERMT_FLSCheck.checkUpdate(rAssessment,  fields);
		System.assert(result == true);
		
	}
	@isTest static void test_checkUpdate_NotField() {

		List<ermt__RiskAssessment__c> rAssessment = [Select Id , Name , ermt__Likelihood__c , ermt__NumberLikelihood__c From ermt__RiskAssessment__c];
		List<String> fields = new List<String>();
		rAssessment[0].ermt__Likelihood__c = null;
		rAssessment[0].ermt__NumberLikelihood__c = 0;
		Boolean result = ERMT_FLSCheck.checkUpdate(rAssessment,  fields);
		System.assert(result == true);
		
	}
    @isTest static void test_checkFLSWithInvalidFields(){
        Boolean checkFlag = ERMT_FLSCheck.checkFLS(new String[]{'Invalid'},ERMT_FLSCheck.FLSType.FLS_CREATE, Account.class.getName());
        System.assert(checkFlag == false);
    }
    @isTest static void test_checkFLSWithFieldIsNotCreateable(){
        Boolean checkFlag = ERMT_FLSCheck.checkFLS(new String[]{'Id'},ERMT_FLSCheck.FLSType.FLS_CREATE, Account.class.getName());
        System.assert(checkFlag == false);
    }
    @isTest static void test_checkFLSWithFieldIsNotUpdateable(){
        Boolean checkFlag = ERMT_FLSCheck.checkFLS(new String[]{'Id'},ERMT_FLSCheck.FLSType.FLS_UPDATE, Account.class.getName());
        System.assert(checkFlag == false);
    }
    @isTest static void test_checkFLSWithFieldIsCreateable(){
        Boolean checkFlag = ERMT_FLSCheck.checkFLS(new List<String>(),ERMT_FLSCheck.FLSType.FLS_CREATE, Account.class.getName());
        System.assert(checkFlag == true);
    }
    @isTest static void test_checkFLSWithFieldIsDeleteable(){
        Boolean checkFlag = ERMT_FLSCheck.checkFLS(new List<String>(),ERMT_FLSCheck.FLSType.FLS_DELETE , Account.class.getName());
        System.assert(checkFlag == true);
    }
}