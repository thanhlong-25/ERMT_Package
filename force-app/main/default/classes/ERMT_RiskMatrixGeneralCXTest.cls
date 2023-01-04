@isTest
private class ERMT_RiskMatrixGeneralCXTest {
	
	@testSetup static void initDataTest(){
  		ERMT_MockDataTest.MockDataInsertedTest();
	}

	@isTest static void test_Contructor_Success() {
		ermt__Project__c newProject = new ermt__Project__c();
		newProject.Name = 'Project 3';
		insert newProject;
		Apexpages.StandardController sc = new Apexpages.StandardController(newProject);
		ERMT_RiskMatrixGeneralCX eRmt =  new ERMT_RiskMatrixGeneralCX(sc);
		ermt__Project__c project  = [Select Id , Name  from ermt__Project__c Where Name = 'Project 3' ];
		System.assertEquals('Project 3' , project.Name);
	}

	@isTest static void test_getRiskOfProjectByClassification() {
		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(new List<String>(), new List<String>(), new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification1() {
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10]) {
			listIds.add(pr.Id);
		}
		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(listIds, new List<String>(), new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification2() {
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10]) {
			listIds.add(pr.Id);
		}
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}
		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(listIds, parentClassiIds, new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification21() {
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}
		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(new List<String>(), parentClassiIds, new List<String>());
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification3() {
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10]) {
			listIds.add(pr.Id);
		}
		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(listIds, new List<String>(), childClassiIds);
		System.assert(risks.size()>0);
	}
	@isTest static void test_getRiskOfProjectByClassification31() {
		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(new List<String>(), new List<String>(), childClassiIds);
		System.assert(risks.size()>0);
	}

	@isTest static void test_getRiskOfProjectByClassification4() {
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10]) {
			listIds.add(pr.Id);
		}
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}

		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(listIds, parentClassiIds, childClassiIds);
		System.assert(risks.size()>0);
	}
	@isTest static void test_getRiskOfProjectByClassification41() {
		List<String> parentClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName != 'ChoiceItem' Limit 100]){
			parentClassiIds.add(rec.Id);
		}

		List<String> childClassiIds = new List<String>();
		for(ermt__M_Classification__c rec : [Select Id from ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' Limit 100]){
			childClassiIds.add(rec.Id);
		}

		List<ermt__Risk__c> risks = ERMT_RiskMatrixGeneralCX.getRiskOfProjectByClassification(new List<String>(), parentClassiIds, childClassiIds);
		System.assert(risks.size()>0);
	}

	@isTest static void test_GetAverageRisk_Success() {
		Test.startTest();
		String evaluationTest = 'なし';

		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> listIds = new List<String>();
		listIds.add(projects[0].Id);
		AggregateResult[] averageRisk = ERMT_RiskMatrixGeneralCX.getAverageRiskAssessment(listIds , evaluationTest);
		List<ermt__Risk__c> risks = [select Id from ermt__Risk__c];
		Test.stopTest();

		System.assertEquals(2.0  , averageRisk[0].get('point'));
		
	}

	@isTest static void test_GetAverageRisk_Success2() {
		Test.startTest();
		String evaluationTest = 'なし';

		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> listIds = new List<String>();
		listIds.add(projects[0].Id);
		AggregateResult[] averageRisk = ERMT_RiskMatrixGeneralCX.getAverageRiskAssessment(new List<String>() , evaluationTest);
		List<ermt__Risk__c> risks = [select Id from ermt__Risk__c];
		Test.stopTest();

		System.assert(averageRisk[0].get('point') != null);
		
	}

	@isTest static void test_GetAverageRisk_Success3() {
		Test.startTest();
		String evaluationTest = 'FY-18 (Target)';
		AggregateResult[] averageRisk = ERMT_RiskMatrixGeneralCX.getAverageRiskAssessment(new List<String>() , evaluationTest);
		Test.stopTest();

		System.assert(averageRisk.isEmpty());
		
	}

	@isTest static void test_GetAverageRisk_Success4() {
		Test.startTest();
		String evaluationTest = 'FY-18 (Target)';

		List<ermt__Project__c> projects  = [Select Id , Name from ermt__Project__c Where Name='Project 1' limit 10];
		List<String> listIds = new List<String>();
		listIds.add(projects[0].Id);
		AggregateResult[] averageRisk = ERMT_RiskMatrixGeneralCX.getAverageRiskAssessment(listIds , evaluationTest);
		Test.stopTest();

		System.assert(averageRisk.isEmpty());
		
	}

	@isTest static void test_GetAxisLabel_Success() {
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c limit 10]) {
			listIds.add(pr.Id);
		}
		ERMT_RiskMatrixGeneralCX.AxisWrapper axisLabel = ERMT_RiskMatrixGeneralCX.getAxisLabel(listIds);

		System.assert(axisLabel.xAxis.size() != 0);
		System.assert(axisLabel.yAxis.size() != 0);
	}

	@isTest static void test_GetAxisLabel_Success1() {
		ERMT_RiskMatrixGeneralCX.AxisWrapper axisLabel = ERMT_RiskMatrixGeneralCX.getAxisLabel(new List<String>());

		System.assert(axisLabel.xAxis.size() != 0);
		System.assert(axisLabel.yAxis.size() != 0);
	}

	@isTest static void test_GetCellColor_Success() {
		Test.startTest();
		List<String> listIds = new List<String>();
		for (ermt__Project__c pr : [Select Id , Name from ermt__Project__c limit 10]) {
			listIds.add(pr.Id);
		}
		List<ermt__CellColor__c> cellColors = ERMT_RiskMatrixGeneralCX.getCellColor(listIds);
		Test.stopTest();
		System.assertEquals(2, cellColors.size());
		
	}

	@isTest static void test_GetCellColor_Success1() {
		Test.startTest();
		List<ermt__CellColor__c> cellColors = ERMT_RiskMatrixGeneralCX.getCellColor(new List<String>());
		Test.stopTest();
		System.assertEquals(2, cellColors.size());
		
	}

	@isTest static void test_getEvaluationList_Success() {
		List<ermt__M_Classification__c>  entry = ERMT_RiskMatrixGeneralCX.getEvaluationList();
		System.assert(entry.size() >  0);
	}

	@isTest static void test_getProjects_Success() {
		List<ermt__Project__c>  entry = ERMT_RiskMatrixGeneralCX.getProjects();
		System.assert(entry.size() > 0);
	}

	@isTest static void test_getLabelMetadata_Success() {
		Map<String, Object> maptmp = ERMT_RiskMatrixGeneralCX.getLabelMetadata();
		System.assert(maptmp.keySet().size() > 0);
	}

	@isTest static void test_getClassificationList() {
		List<ermt__M_Classification__c> classis = ERMT_RiskMatrixGeneralCX.getClassificationList();
		System.assert(classis.size()>0);
	}
}