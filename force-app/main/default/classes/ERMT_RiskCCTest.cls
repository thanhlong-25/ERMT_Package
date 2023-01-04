@isTest
private class ERMT_RiskCCTest {
	@testSetup static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();
	}
	
	@isTest static void test_getListSelectAndChild() {
		List<ermt__Project__c> projectList = [Select Id, Name From ermt__Project__c];
		List<ermt__M_Classification__c> mClassList = ERMT_RiskCC.getListSelectAndChild(projectList[0].Id);
		System.assert(mClassList.size() > 0);
	}

	@isTest static void test_getSelectedClassification(){
		List<ermt__Risk__c> risktList = [Select Id, Name From ermt__Risk__c];		
		List<ermt__Risk_Classification_Junc__c> rJuncList = ERMT_RiskCC.getSelectedClassification(risktList[0].Id);
		System.assertEquals(1, rJuncList.size());
	}
	@isTest static void test_upsertSelectedClassification(){
		List<ermt__M_Classification__c> mClassList = [Select Id, Name , ermt__ParentMClassification_del__c From ermt__M_Classification__c Where RecordType.DeveloperName='ChoiceItem' And ermt__ParentMClassification_del__r.RecordType.DeveloperName='ClassificationGroup'];
		List<ermt__Risk__c> risktList = [Select Id, Name From ermt__Risk__c];
		ERMT_RiskCC.upsertSelectedClassification(risktList[0].id , mClassList[0].Id , mClassList[0].ermt__ParentMClassification_del__c );
		List<ermt__Risk_Classification_Junc__c> rJuncList = [Select Id , Name , ermt__M_Classification__c  From ermt__Risk_Classification_Junc__c Where ermt__M_Classification__r.RecordType.DeveloperName='ChoiceItem' And ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName='ClassificationGroup' And ermt__Risk__c=:risktList[0].id];
		System.assertEquals( mClassList[0].Id , rJuncList[0].ermt__M_Classification__c);

	}

	@isTest static void test_insertClassification(){
		List<ermt__M_Classification__c> listParents = [
			SELECT Id FROM ermt__M_Classification__c
			WHERE RecordType.DeveloperName='ClassificationGroup'
		];

		List<ermt__M_Classification__c> classiList = [
			Select Id, Name , ermt__ParentMClassification_del__c
			From ermt__M_Classification__c
			Where RecordType.DeveloperName='ChoiceItem'
			AND ermt__ParentMClassification_del__c =: listParents[0].Id
		];

		List<String> mClassListIds = new List<String>();
		for(ermt__M_Classification__c junc: classiList){
			mClassListIds.add(String.valueOf(junc.Id));
		}

		List<ermt__Risk__c> riskList = [Select Id, Name From ermt__Risk__c];
		ERMT_RiskCC.insertClassification(String.valueOf(riskList[0].Id), mClassListIds , String.valueOf(listParents[0].Id));
		List<ermt__Risk_Classification_Junc__c> rJuncList = [
			Select Id , Name , ermt__M_Classification__c  
			From ermt__Risk_Classification_Junc__c 
			Where ermt__M_Classification__r.RecordType.DeveloperName='ChoiceItem' 
			And ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName='ClassificationGroup' 
			And ermt__Risk__c=:riskList[0].id
		];
		//System.assertEquals( rJuncList.size() , mClassListIds.size());
		System.assert(!rJuncList.isEmpty());
	}
	
	@isTest static void test_changeRiskRecordType(){

		List<ermt__Risk__c> riskList = [Select Id, Name From ermt__Risk__c WHERE RecordType.DeveloperName != 'ClassifiedRisk'];
		ERMT_RiskCC.changeRiskRecordType(String.valueOf(riskList[0].Id), 'ClassifiedRisk');
		
		List<ermt__Risk__c> riskListResult = [Select Id, RecordType.DeveloperName From ermt__Risk__c WHERE Id=:riskList[0].Id];

		System.assertEquals( riskListResult[0].RecordType.DeveloperName , 'ClassifiedRisk');

	}
}