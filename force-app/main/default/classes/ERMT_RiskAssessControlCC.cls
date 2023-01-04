public with sharing class ERMT_RiskAssessControlCC {
	/** 
	* get Classification by risk and record type is EvaluationPeriodGroup
	*/
	@AuraEnabled
	public static ermt__RiskAssessment_Classification_Junc__c[] getClassificationEvaluations(string riskId){
		Set<String> classIds = getClassificationIdFromJunc(riskId);
		return [SELECT ermt__M_Classification__c, ermt__M_Classification__r.ermt__Label__c, toLabel(ermt__M_Classification__r.ermt__Label_Pick__c), ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName,
		ermt__RiskAssessment__c, ermt__RiskAssessment__r.ermt__isActive__c, ermt__RiskAssessment__r.ermt__Current_Valuation__c
		FROM ermt__RiskAssessment_Classification_Junc__c
		WHERE ermt__M_Classification__c IN :classIds
		AND ermt__RiskAssessment__r.ermt__Risk__c =: riskId
		ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
		];
	}

    private static Set<String> getClassificationIdFromJunc(string riskId){
        Set<String> result = new Set<String>();
        AggregateResult[] groupedResults = new AggregateResult[]{};
        groupedResults = [Select ermt__M_Classification__c 
        From ermt__RiskAssessment_Classification_Junc__c 
        Where ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName = 'EvaluationPeriodGroup' And ermt__RiskAssessment__r.ermt__Risk__c =:riskId
        Group By ermt__M_Classification__c];

        for (AggregateResult ar : groupedResults)  {
            result.add(String.valueOf(ar.get('ermt__M_Classification__c')));
        }

        return result;
    }

	/** 
	* update recordType for RiskAssessment
	*/
	@AuraEnabled
	public static void changeRiskAssessmentRecordType(string recordId, String recordTypeName){
		try {
			if (String.isNotBlank(recordId) && String.isNotBlank(recordTypeName)){
				List<ermt__RiskAssessment__c> listAssess = [Select Id From ermt__RiskAssessment__c Where Id=:recordId];
				List<RecordType> types = [SELECT Id FROM RecordType WHERE DeveloperName =:recordTypeName AND SobjectType = 'ermt__RiskAssessment__c'];
				if (listAssess.size() > 0 && types.size() > 0){
					listAssess[0].RecordTypeId = types[0].Id;
					update listAssess;
				}
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<LabelWrapper> getRiskAssessmentFieldDetail(string riskAssessId){
		//Add all fieldset to set to query
		Set<Schema.FieldSetMember> setFields = new Set<Schema.FieldSetMember>();
		Set<Schema.FieldSetMember> setFieldsAnalysis = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__RiskAssessment__c.fieldSets.Analysis.getFields());
		Set<Schema.FieldSetMember> setFieldsEvaluation = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__RiskAssessment__c.fieldSets.Evaluation.getFields());
		setFields.addAll(setFieldsAnalysis);
		setFields.addAll(setFieldsEvaluation);

		//Generate soql
		List<LabelWrapper> fieldList = new List<LabelWrapper>();
		Set<String> fieldNames = new Set<String>();
		
		generateFieldListAndFieldName(fieldList, fieldNames, setFields, ermt__RiskAssessment__c.sObjectType);
		fieldNames.add('RecordType.DeveloperName');
		fieldNames.add('ermt__isActive__c');
		fieldNames.add('ermt__Risk__c');
		fieldNames.add('ermt__SeverityRiskLevel__c');
		fieldNames.add('ermt__RiskClassification__c');
		fieldNames.add('ermt__Likelihood__c');
		fieldNames.add('ermt__AssumedCost__c');
		fieldNames.add('ermt__Consequence__c');
		fieldNames.add('ermt__RemainingRisk_DerivativeRisk__c');
		fieldNames.add('ermt__AnalysisCurrentAnalysis__c');
		fieldNames.add('ermt__RiskAnalysis__c');

		//Generate field list to display
		List<LabelWrapper> fieldListAnalysis = new List<LabelWrapper>();
		generateFieldListAndFieldName(fieldListAnalysis, fieldNames, setFieldsAnalysis, ermt__RiskAssessment__c.sObjectType);

		List<LabelWrapper> fieldListEvaluation = new List<LabelWrapper>();
		generateFieldListAndFieldName(fieldListEvaluation, fieldNames, setFieldsEvaluation, ermt__RiskAssessment__c.sObjectType);

		List<ermt__RiskAssessment__c> riskAssests = [SELECT Id, RecordType.DeveloperName FROM ermt__RiskAssessment__c WHERE Id =: riskAssessId];
		ermt__RiskAssessment__c riskAssest = riskAssests[0];
		switch on riskAssest.RecordType.DeveloperName {
			when 'Analysis' {
				return fieldListAnalysis;
			}
			when 'Evaluation' {
				return fieldListEvaluation;
			}
			when else {
				//default
				return fieldList;
			}
		}
	}

	private class LabelWrapper {
		@AuraEnabled public String objLabel {get;set;}
		@AuraEnabled public String objName {get;set;}
		@AuraEnabled public Boolean isRelationship {get;set;}
		@AuraEnabled public String fieldType {get;set;}
	}

	private static void generateFieldListAndFieldName(List<LabelWrapper> fieldList,Set<String> fieldNames,Set<Schema.FieldSetMember> fsMembers, Schema.SObjectType sType){
		generateFieldListAndFieldName(fieldList,fieldNames,fsMembers,sType,false);
	}

	private static void generateFieldListAndFieldName(List<LabelWrapper> fieldList,Set<String> fieldNames,Set<Schema.FieldSetMember> fsMembers, Schema.SObjectType sType, Boolean isRename){
		LabelWrapper labelWrap;
		for(Schema.FieldSetMember f : fsMembers) {
			Schema.DescribeFieldResult des = sType.getDescribe().fields.getMap().get(f.getFieldPath()).getDescribe();
			if( ! des.isAccessible()) {
				throw new System.NoAccessException();
			}

			labelWrap = new LabelWrapper();
			labelWrap.objLabel = des.getLabel();
			labelWrap.isRelationship = false;
			labelWrap.fieldType = des.getType().name();
			if(des.getType() == Schema.DisplayType.Reference && isRename){
				labelWrap.objName = String.format('{0}.{1}', new List<String>{des.getRelationshipName(), 'Name'});
				labelWrap.isRelationship = true;
			}
			else{
				labelWrap.objName = f.getFieldPath();
			}
			fieldList.add(labelWrap);
			if(des.getType() == Schema.DisplayType.Picklist && isRename){
				fieldNames.add(String.format('toLabel({0})', new List<String>{f.getFieldPath()}));
			}
			else {
				fieldNames.add(labelWrap.objName);
			}

		}
	}

	/**
	* check custom permission 
	* Can edit confirmed risk assessment, use in classified risk record detail
	*/
	@AuraEnabled
	public static Boolean checkEditPermission(){
		return FeatureManagement.checkPermission('Can_edit_confirmed_risk_assessment');
	}

	// 確定できるかチェック
	@AuraEnabled
	public static Boolean checkCanConfirm() {
		return FeatureManagement.checkPermission('Can_confirm_risk_assessment');
	}

	// コピーできるかチェック
	@AuraEnabled
	public static Boolean checkCanCopy() {
		return FeatureManagement.checkPermission('Can_copy_risk_assessment');
	}

	// リスク分析の新規作成の設定の取得
	@AuraEnabled
    public static Map<String, Object> getRiskAnalysisNewCreateSetting() {
		return RiskAnalysisNewCreateCtlr.getSetting();
	}
}