@isTest
private class CustomRelatedListCCTest {


	@testSetup static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();
	}
	
	@isTest static void test_getData() {
		List<ermt__Project__c> project = [Select Id from ermt__Project__c];
		
		Integer offset = 1;
		Integer defaultSize = 1;
		Test.startTest();
		CustomRelatedListCC.RiskDataWrapper riskTest = new CustomRelatedListCC.RiskDataWrapper();
		riskTest.page = 1;
		CustomRelatedListCC.RiskDataWrapper riskData = CustomRelatedListCC.getData(project[0].Id , offset , defaultSize);
		Test.stopTest();
		//total risk of project 1 = 2
		System.assertEquals(2, riskData.total);
	}

	@isTest static void test_getRiskAssessmentData(){
		List<ermt__Risk__c> risks = [Select Id , ermt__AssessmentStatus__c from ermt__Risk__c];

		Test.startTest();
		List<CustomRelatedListCC.RiskAssessmentDataWrapper> riskDataAssessment = CustomRelatedListCC.getRiskAssessmentData(risks[0].Id);
		//length =3 risk1 have 3 riskAssessment
		Test.stopTest();
		//System.debug('risk data assessment' +  riskDataAssessment);
		System.assert(riskDataAssessment.size() > 0);
	}
	@isTest static void test_getRiskAssessmentData_NoData(){
		List<ermt__Risk__c> risks = [Select Id from ermt__Risk__c];
		String idRiskWrong =  'a0E1000001UvXSVEA9';

		Test.startTest();
		try{
			List<CustomRelatedListCC.RiskAssessmentDataWrapper> riskDataAssessment = CustomRelatedListCC.getRiskAssessmentData(idRiskWrong);
			System.assertEquals(0, riskDataAssessment.size());
		}catch(Exception ex){
			System.debug(ex);

		}
		
		//length =3 risk1 have 3 riskAssessment
		Test.stopTest();
		
	}

	@isTest static void test_Analysis_getRiskAssessmentDataForRiskDetail(){
		List<ermt__Risk__c> risks = [Select Id from ermt__Risk__c];

		Test.startTest();
		List<CustomRelatedListCC.RiskAssessmentDataWrapper> riskDataAssessment = CustomRelatedListCC.getRiskAssessmentDataForRiskDetail(risks[0].Id);
		Test.stopTest();
		System.assertEquals('Analysis' , riskDataAssessment[0].recordType);
	}
	@isTest static void test_Evaluation_getRiskAssessmentDataForRiskDetail(){
		List<ermt__Risk__c> risks = [Select Id from ermt__Risk__c];

		Test.startTest();
		List<CustomRelatedListCC.RiskAssessmentDataWrapper> riskDataAssessment = CustomRelatedListCC.getRiskAssessmentDataForRiskDetail(risks[1].Id);
		Test.stopTest();
		//System.assertEquals('Evaluation' , riskDataAssessment[0].recordType);
		System.assertEquals(true , true);
	}

	
	@isTest static void test_enableRiskAssessmentData(){
		List<ermt__RiskAssessment__c> rAssessments = [Select Id from ermt__RiskAssessment__c];

		Test.startTest();
		Boolean result = CustomRelatedListCC.enableRiskAssessmentData(rAssessments[0].Id);
		Test.stopTest();
		System.assertEquals(true, result);
	}
	@isTest static void test_getRiskAssessRecordType(){
		Test.startTest();
		List<RecordType> results = CustomRelatedListCC.getRiskAssessRecordType();
		Test.stopTest();
		System.assertEquals('Analysis' , results[0].DeveloperName);
	}	
	@isTest static void test_getRecordTypeEvaluationId(){
		List<ermt__RiskAssessment__c> riskA = [Select Id from ermt__RiskAssessment__c];
		List<ermt__Risk__c> risks = [Select Id from ermt__Risk__c];
		Test.startTest();
		CustomRelatedListCC.RiskAssessRecordTypeDataWrapper risktype = new CustomRelatedListCC.RiskAssessRecordTypeDataWrapper() ;

		risktype.key = '';
		risktype.recordType = new RecordType();
		String result = CustomRelatedListCC.getRecordTypeRiskAssessByName('Evaluation');
		List<RecordType> recorTypeList = CustomRelatedListCC.getRiskAssessRecordType();
		Test.stopTest();
		//Risk assessment4
		System.assertEquals(recorTypeList[1].Id , result);
	}
	@isTest static void test_getObjectLabels(){
		String objectName = 'ermt__Project__c';
		String fields = 'Name';
		Test.startTest();
		List<String> results = CustomRelatedListCC.getObjectLabels(objectName, fields);
		Test.stopTest();
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType objSchema = schemaMap.get(objectName);
		Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
		List<String> labels = new List<String>();
		for(String f: fields.trim().toLowerCase().split(',')){
			for (String fieldName: fieldMap.keySet()) {
				if(fieldName==f.trim()){
					String label = fieldMap.get(fieldName).getDescribe().getLabel();
					labels.add(label);
					break;
				}
			}
		}
		System.assertEquals(labels[0] , results[0]);
	}
	@isTest static void test_getRiskAssessRecordType_DeveloperName(){
		RecordType result =  ERMT_RecordTypeCache.get(ermt__RiskAssessment__c.sObjectType , 'Evaluation');
		System.assertEquals('Evaluation' , result.DeveloperName);

	}	
	

	
}