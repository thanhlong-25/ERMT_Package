@isTest
private class ERMT_BubbleChartForRiskCXTest {
	
	@testSetup static void initDataTest(){
  		ERMT_MockDataTest.MockDataInsertedTest();
	}

	@isTest static void test_Contructor_Success() {
		ermt__Risk__c risk = new ermt__Risk__c();
		insert risk;
		Apexpages.StandardController sc = new Apexpages.StandardController(risk);
		ERMT_BubbleChartForRiskCX eRmt =  new ERMT_BubbleChartForRiskCX(sc);
		System.assert(eRmt != null);
	}

	@isTest static void test_GetProjectClassifications_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		ERMT_BubbleChartForRiskCX.ProjectClassificationWrapper pCJun = ERMT_BubbleChartForRiskCX.getProjectClassifications(projects[0].Id);
		ERMT_BubbleChartForRiskCX.ProjectClassificationWrapper pCJun11 = ERMT_BubbleChartForRiskCX.getProjectClassifications(projects[1].Id);
		System.assert(pCJun.juncs.size() > 0);
		System.assert(pCJun11.juncs.size() == 0);
	}

	@isTest static void test_GetAverageRiskAssessment_Success() {
		List<ermt__Risk__c> risks  = [Select Id , Name from ermt__Risk__c limit 10];
		String averageRiskAssessmentStr = ERMT_BubbleChartForRiskCX.getAverageRiskAssessment(risks[0].Id);
		List<ermt__RiskAssessment_Classification_Junc__c> riskAssessment = [select Id ,Name from ermt__RiskAssessment_Classification_Junc__c];
        List<Object> averageRiskAssessment = 
            (List<Object>)
            JSON.deserializeUntyped(averageRiskAssessmentStr);
        System.assert(((Map<String,Object>)averageRiskAssessment[0]).get('point') != null);
	}
    
    @isTest static void test_getMaxViewNoOfClassification(){
        List<RecordType> recordTypeOfChoiceItem = [SELECT Id,Name,DeveloperName FROM RecordType WHERE sObjectType = 'ermt__M_Classification__c' AND isActive = true];
        List<ermt__M_Classification__c> classifications = [SELECT Id FROM ermt__M_Classification__c WHERE RecordTypeId !=:recordTypeOfChoiceItem[0].Id];
        List<Id> classificationIds = new List<Id>();
        for(ermt__M_Classification__c classification:classifications){
            classificationIds.add(classification.id);
        }
        Map<Id, Double> result = ERMT_BubbleChartForRiskCX.getMaxViewNoOfClassification(classificationIds);
        List<ermt__M_Classification__c> classificationList2 = [SELECT Id FROM ermt__M_Classification__c WHERE Name='MTest2'];
        System.assertEquals(4, result.get(classificationList2[0].Id));
    }
}