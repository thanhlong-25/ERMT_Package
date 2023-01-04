@isTest
private class ERMT_EnhancedCloneHelperTest {
	@testSetup static void setup() {
  		ERMT_MockDataTest.MockDataInsertedTest(); 
    }

	@isTest static void test_Clone_Risk_Success() {
		List<String> ids = new List<String>();
		List<ermt__Risk__c> listRisks = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c];
		for(ermt__Risk__c risk : listRisks){
			ids.add(risk.Id);
		}

		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];

		ERMT_EnhancedCloneHelper.clone(ids, prj2.Id);
		List<ermt__Risk__c> listRisksClone = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c Where ermt__Clone_From_ID__c in:ids];

		System.assert(listRisksClone[0].ermt__Project__c == prj2.Id);
	}
	
	@isTest static void test_Clone_RiskAssessment_Success() {
		List<String> ids = new List<String>();
		List<ermt__Risk__c> listRisks = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c];
		for(ermt__Risk__c risk : listRisks){
			ids.add(risk.Id);
		}

		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];

		ERMT_EnhancedCloneHelper.clone(ids, prj2.Id);
		List<ermt__Risk__c> listRisksClone = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c Where ermt__Clone_From_ID__c in:ids];

		List<ermt__RiskAssessment__c> listRiskAssessClone = [Select Id, ermt__Risk__r.ermt__Project__c From ermt__RiskAssessment__c Where ermt__Risk__c in:listRisksClone];

		System.assert(listRiskAssessClone.size() > 0);
		System.assert(listRiskAssessClone[0].ermt__Risk__r.ermt__Project__c == prj2.Id);
	}

	@isTest static void test_Clone_RiskAssessmentBefore_Success() {
		ermt__Project__c prj1 = [Select Id,Name from ermt__Project__c Where Name='Project 1' limit 1];

		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];

		List<String> ids = new List<String>();
		List<ermt__Risk__c> listRisks = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c Where ermt__Project__c = :prj1.Id];

		for(ermt__Risk__c risk : listRisks){
			ids.add(risk.Id);
		}

		ERMT_EnhancedCloneHelper.clone(ids, prj2.Id);

		List<ermt__RiskAssessment__c> listRisksAssessPrj1 = [Select Id, ermt__beforeAssessment__c from ermt__RiskAssessment__c Where ermt__Risk__r.ermt__Project__c =:prj1.Id];
		Map<Id,ermt__RiskAssessment__c> riskAssessMap1 = new Map<Id,ermt__RiskAssessment__c>(listRisksAssessPrj1);

		List<ermt__RiskAssessment__c> listRisksAssessPrj2 = [Select Id, ermt__beforeAssessment__c, ermt__Clone_From_ID__c from ermt__RiskAssessment__c Where ermt__Risk__r.ermt__Project__c =:prj2.Id];
		Map<Id,ermt__RiskAssessment__c> riskAssessMap2 = new Map<Id,ermt__RiskAssessment__c>(listRisksAssessPrj2);

		for(ermt__RiskAssessment__c riskAssess : listRisksAssessPrj2){
			if(riskAssess.ermt__beforeAssessment__c != null){
				String idSrc1 = riskAssessMap1.get(riskAssess.ermt__Clone_From_ID__c).ermt__beforeAssessment__c;
				String idSrc2 = riskAssessMap2.get(riskAssess.ermt__beforeAssessment__c).ermt__Clone_From_ID__c;
				System.assert(idSrc1 == idSrc2);
			}
		}

	}

	@isTest static void test_Clone_CC() {
		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];
		ermt__Risk__c risk = [Select Id From ermt__Risk__c limit 1];
		ERMT_EnhancedCloneHelper.CloneModel result = CustomRelatedListCC.copyRiskData(risk.Id, prj2.Id);
		System.assert(result.isSuccess == true);
	}

	@isTest static void test_Clone_RiskAssessment_IsEmpty() {
		List<String> ids = new List<String>();
		List<ermt__Risk__c> listRisks = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c];
		for(ermt__Risk__c risk : listRisks){
			ids.add(risk.Id);
		}
		List<ermt__RiskAssessment__c> rAsessmentDelete = [Select Id From ermt__RiskAssessment__c];
		delete rAsessmentDelete;

		ermt__Project__c prj2 = [Select Id,Name from ermt__Project__c Where Name='Project 2' limit 1];

		ERMT_EnhancedCloneHelper.clone(ids, prj2.Id);
		List<ermt__Risk__c> listRisksClone = [Select Id, ermt__RiskContents__c, ermt__Project__c from ermt__Risk__c Where ermt__Clone_From_ID__c in:ids];
		List<ermt__RiskAssessment__c> listRiskAssessClone = [Select Id, ermt__Risk__r.ermt__Project__c From ermt__RiskAssessment__c Where ermt__Risk__c in:listRisksClone];
		System.assert(listRiskAssessClone.size() == 0);
	}
	
}