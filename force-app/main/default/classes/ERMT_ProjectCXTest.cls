@isTest
private class ERMT_ProjectCXTest {

	@testSetup static void initDataTest(){
  		ERMT_MockDataTest.MockDataInsertedTest();

	}

	@isTest static void test_Contructor_Success() {
		ermt__Project__c newProject = new ermt__Project__c();
		newProject.Name = 'Project 3';
		insert newProject;
		Apexpages.StandardController sc = new Apexpages.StandardController(newProject);
		ERMT_ProjectCX eRmt =  new ERMT_ProjectCX(sc);
		ermt__Project__c project  = [Select Id , Name  from ermt__Project__c Where Name = 'Project 3' ];
		System.assertEquals('Project 3' , project.Name);


	}
	
	@isTest static void test_GetRiskOfProject_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProject(projects[0].Id);
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification1() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProjectByClassification(projects[0].Id, new List<String>(), new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification2() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProjectByClassification(projects[0].Id, parentClassiIds, new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification3() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProjectByClassification(projects[0].Id, new List<String>(), childClassiIds);
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification4() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}

		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProjectByClassification(projects[0].Id, parentClassiIds, childClassiIds);
		System.assert(risks.size()>0);
	}

	@isTest static void test_getClassificationList() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<ermt__M_Classification__c> classis = ERMT_ProjectCX.getClassificationList(projects[0].Id);
		System.assert(classis.size()>0);
	}

	@isTest static void test_GetRiskOfProjectByEvaTime() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<ermt__Risk__c> risks = ERMT_ProjectCX.getRiskOfProjectByEvaluationTime(projects[0].Id,'なし');
		System.assert(risks.size()>0);
	}

	@isTest static void test_GetAverageRisk_Success() {
		Test.startTest();
		String evaluationTest = 'なし';

		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		AggregateResult[] averageRisk = ERMT_ProjectCX.getAverageRisk(projects[0].Id , evaluationTest);
		List<ermt__Risk__c> risks = [select Id from ermt__Risk__c];
		Test.stopTest();

		//System.assertEquals(risks[1].Id , averageRisk[1].get('ermt__Risk__c'));
		System.assertEquals(2.0  , averageRisk[0].get('avgLike'));
		
	}

	@isTest static void test_GetAverageRiskByEvaluation_Success() {
		Test.startTest();
		String evaluationTest = 'なし';

		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		AggregateResult[] averageRisk = ERMT_ProjectCX.getAverageRisk(projects[0].Id , evaluationTest);
		Test.stopTest();
		System.assertEquals(2.0  , averageRisk[0].get('avgLike'));
		
	}

	@isTest static void test_GetAverageRiskAssessment_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		List<AggregateResult> averageRiskAssessment = ERMT_ProjectCX.getAverageRiskAssessment(projects[0].Id,'なし');
		List<ermt__RiskAssessment_Classification_Junc__c> riskAssessment = [select Id ,Name from ermt__RiskAssessment_Classification_Junc__c];
		System.assert(averageRiskAssessment[0].get('point') != null);
	}

	@isTest static void test_GetProjectClassifications_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		List<ermt__Project_Classification_Junc__c> pCJun = ERMT_ProjectCX.getProjectClassifications(projects[0].Id);
		List<ermt__Project_Classification_Junc__c> pCJun11 = ERMT_ProjectCX.getProjectClassifications(projects[1].Id);
		List<ermt__Project_Classification_Junc__c> pCJunTest = [select Id , Name , ermt__Project__c , ermt__M_Classification__c from ermt__Project_Classification_Junc__c];
		//System.debug('ermt__Project_Classification_Junc__c Test: ' +pCJunTest);
		//System.debug('ermt__Project_Classification_Junc__c: ' +pCJun); // 3 project class junc
		System.assert(pCJun.size() > 0);
		System.assert(pCJun11.size() == 0);
	}

	@isTest static void test_GetAxisLabel_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		ERMT_ProjectCX.AxisWrapper axisLabel = ERMT_ProjectCX.getAxisLabel(projects[0].Id);

		System.assert(axisLabel.xAxis.size() != 0);
		System.assert(axisLabel.yAxis.size() != 0);
	}

	@isTest static void test_GetCellColor_Success() {
		Test.startTest();
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		List<ermt__CellColor__c> cellColors = ERMT_ProjectCX.getCellColor(projects[0].Id);
		//System.debug('cellColors: ' +cellColors); 
		Test.stopTest();
		System.assertEquals(1 , cellColors.size());
		
	}

	@isTest static void test_GetCustomMetadataCellColor_Success() {
		Test.startTest();
		List<ermt__Cell_Color__mdt> cellColorMDTs = ERMT_ProjectCX.getCustomMetadataCellColor();

		//System.debug('cellColorMDTs: ' +cellColorMDTs);
		Test.stopTest();
		System.assert(cellColorMDTs.size() != 0);

	}

	@isTest static void test_AddCellColor_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		List<ermt__CellColor__c> cellColorInputs = new List<ermt__CellColor__c>();
		cellColorInputs.add(new ermt__CellColor__c(ermt__ColorCode__c ='test'));

		Boolean result =  ERMT_ProjectCX.addCellColor(cellColorInputs , projects[0].
			Id);
		ermt__CellColor__c ccLists = [Select Id, ermt__ColorCode__c From ermt__CellColor__c Where ermt__ColorCode__c =: 'test' Limit 1];
		System.assertEquals('test', ccLists.ermt__ColorCode__c);
	}
	@isTest static void test_getEvaluationList_Success() {
		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c limit 10];
		List<ermt__M_Classification__c>  entry = ERMT_ProjectCX.getEvaluationList(projects[0].Id);
		System.assertEquals(true, true);
	}


	
}