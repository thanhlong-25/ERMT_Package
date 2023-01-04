@isTest
private class ERMT_ProjectCCTest {
	@testSetup static void initDataTest(){
		ERMT_MockDataTest.MockDataInsertedTest();
	}
	
	@isTest static void test_getListSelect() {

		List<RecordType> recordTypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'ermt__M_Classification__c' AND isActive = true];
		Test.startTest();
		 List<ermt__M_Classification__c> mClassRecordType = ERMT_ProjectCC.getListSelect('LikelihoodGroup');
		Test.stopTest();
		System.assert(mClassRecordType.size() > 0);
	}

	@isTest static void test_getSelectedClassification() {
		String recordTypeName = 'LikelihoodGroup';
		ermt__Project__c project = [Select Id , Name From ermt__Project__c Where Name =: 'Project 1'];

		Test.startTest();
		List<ermt__Project_Classification_Junc__c> pClassJunc = ERMT_ProjectCC.getSelectedClassification(project.Id , recordTypeName);
		Test.stopTest();
		System.debug('P classs Junc : ' + pClassJunc);
		ermt__M_Classification__c mClassResult = [Select Id, Name From ermt__M_Classification__c Where Id =: pClassJunc[0].ermt__M_Classification__c];
		// length = 0  data test haven't any project class junc
		System.assertEquals('MTest', mClassResult.Name);
	}

	@isTest static void test_insertClassification() {
		String recordTypeName = '選択肢';
		List<String> mClassIds = new List<String>();
		List<ermt__Project_Classification_Junc__c> pClassJuncs = [Select Id From ermt__Project_Classification_Junc__c];
		System.debug('ermt__Project_Classification_Junc__c before' + pClassJuncs);
		ermt__Project__c project = [Select Id , Name From ermt__Project__c Where Name =: 'Project 1'];

		List<ermt__M_Classification__c> mClasses = [Select Id , Name From ermt__M_Classification__c Limit 1];
		for(ermt__M_Classification__c mclass : mClasses){
			mClassIds.add(mclass.Id);
		}

		Test.startTest();

		 ERMT_ProjectCC.insertClassification(mClassIds, project.Id , recordTypeName);

		//System.debug('insertClassification');
		Test.stopTest();
		List<ermt__Project_Classification_Junc__c> pClassJuncs1 = [Select Id From ermt__Project_Classification_Junc__c];
		System.assertEquals(1 , (pClassJuncs1.size() - pClassJuncs.size()));
	}

	@isTest static void test_getAccountChilds() {
		
		Test.startTest();
		 List<Account> accs = ERMT_ProjectCC.getAccountChilds();

		Test.stopTest();
		System.assertEquals(2 , accs.size());
		
	}
	@isTest static void test_getSelectedPrjPart() {
		ermt__Project__c project = [Select Id , Name From ermt__Project__c Where Name =: 'Project 1'];
		Test.startTest();
		 List<ermt__Project_Participant_Junc__c> pClassJuncs = ERMT_ProjectCC.getSelectedPrjPart(project.Id);

		Test.stopTest();
		//do not insert project participant jun 
		System.assertEquals(1 , pClassJuncs.size());
		
	}


	@isTest static void test_insertProjectParticipant() {
		String recordTypeName = '選択肢';
		List<String> accIds = new List<String>();
		List<ermt__Project_Participant_Junc__c> pParJuncs = [Select Id From ermt__Project_Participant_Junc__c];
		ermt__Project__c project = [Select Id , Name From ermt__Project__c Where Name =: 'Project 1'];

		List<Account> accs = [Select Id , Name From Account];
		for(Account acc : accs){
			accIds.add(acc.Id);
		}

		Test.startTest();

		 ERMT_ProjectCC.insertProjectParticipant(accIds, project.Id );
		Test.stopTest();
		List<ermt__Project_Participant_Junc__c> pParJuncs1 = [Select Id From ermt__Project_Participant_Junc__c];
		Integer countNew = pParJuncs1.size() - pParJuncs.size();
		System.assert(countNew != 0);
	}
}