public with sharing class ERMT_RiskAssessCC {
	/*
	Get selected ermt__M_Classification__c of ermt__RiskAssessment__c.ermt__Risk__c.ermt__Project__c and it's child
	 */
	@AuraEnabled
	public static List<ermt__M_Classification__c> getListSelectAndChild(string projectId, string recordTypeName){
		return [Select Id, Name,ermt__ParentMClassification_del__r.Name,ermt__Help_Text__c,ermt__Help_Text_Pick__c,ermt__Label__c,toLabel(ermt__Label_Pick__c),(Select Id,Name,ermt__Label__c,toLabel(ermt__Label_Pick__c) From MClassifications_del__r Order By ermt__ViewNo__c) From ermt__M_Classification__c Where Id In (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName =:recordTypeName) Order By ermt__ViewNo__c];
	}

	/*
	Get selected ermt__RiskAssessment_Classification_Junc__c of ermt__RiskAssessment__c from ermt__RiskAssessment_Classification_Junc__c
	 */
	@AuraEnabled
	public static List<ermt__RiskAssessment_Classification_Junc__c> getSelectedClassification(string riskAssessId, string recordTypeName){
		return [Select Id,ermt__M_Classification__r.ermt__ParentMClassification_del__c From ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__c =:riskAssessId And ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName =:recordTypeName];
	}

	/*
	insert new and delete old ermt__RiskAssessment_Classification_Junc__c when combobox value changed
	 */
	@AuraEnabled
	public static void upsertSelectedClassification(string riskAssessId, string classiId, string parentclassiId){
		try {
			delete [Select Id From ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__c=:riskAssessId And ermt__M_Classification__r.ermt__ParentMClassification_del__c =:parentclassiId];

			if(String.isNotBlank(classiId)){
				ermt__RiskAssessment_Classification_Junc__c junc = new ermt__RiskAssessment_Classification_Junc__c();
				junc.ermt__RiskAssessment__c = riskAssessId;
				junc.ermt__M_Classification__c = classiId;
				insert junc;
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
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
}