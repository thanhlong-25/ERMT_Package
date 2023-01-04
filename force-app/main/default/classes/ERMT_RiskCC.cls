public with sharing class ERMT_RiskCC {
	/*
	Get selected ermt__M_Classification__c of ermt__Risk__c.ermt__Project__c and it's child
	 */
	@AuraEnabled
	public static List<ermt__M_Classification__c> getListSelectAndChild(string projectId){
		return [Select Id, Name,ermt__ParentMClassification_del__r.Name,ermt__Help_Text__c,ermt__Label__c,(Select Id,Name,ermt__Label__c From ermt__MClassifications_del__r Order By ermt__ViewNo__c) From ermt__M_Classification__c Where Id In (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName = 'ClassificationGroup') Order By ermt__ViewNo__c];
	}

	/*
	Get selected ermt__Risk_Classification_Junc__c of ermt__Risk__c from ermt__Risk_Classification_Junc__c
	 */
	@AuraEnabled
	public static List<ermt__Risk_Classification_Junc__c> getSelectedClassification(string riskId){
		return [Select Id,ermt__M_Classification__r.ermt__ParentMClassification_del__c From ermt__Risk_Classification_Junc__c Where ermt__Risk__c =:riskId];
	}

	/*
	insert new and delete old ermt__Risk_Classification_Junc__c when combobox value changed
	 */
	@AuraEnabled
	public static void upsertSelectedClassification(string riskId, string classiId, string parentclassiId){
		try {
			delete [Select Id From ermt__Risk_Classification_Junc__c Where ermt__Risk__c=:riskId And ermt__M_Classification__r.ermt__ParentMClassification_del__c =:parentclassiId];
			if(String.isNotBlank(classiId)){
				ermt__Risk_Classification_Junc__c junc = new ermt__Risk_Classification_Junc__c();
				junc.ermt__Risk__c = riskId;
				junc.ermt__M_Classification__c = classiId;
				insert junc;
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
	}

	/**
	* insert classification list
	**/
	@AuraEnabled
	public static void insertClassification(string riskId, List<String> classiIds, string parentclassiId){
		try {
			Set<String> classiSet = new Set<String>(classiIds);
			if (String.isNotBlank(riskId)){
				delete [Select Id From ermt__Risk_Classification_Junc__c Where ermt__Risk__c=:riskId And ermt__M_Classification__r.ermt__ParentMClassification_del__c =:parentclassiId];
				List<ermt__Risk_Classification_Junc__c> classiList = new List<ermt__Risk_Classification_Junc__c>();
				for(String a : classiSet){
					if(ERMT_Utils.isValid(a, ermt__M_Classification__c.getSObjectType())){
						ermt__Risk_Classification_Junc__c junc = new ermt__Risk_Classification_Junc__c();
						junc.ermt__Risk__c = riskId;
						junc.ermt__M_Classification__c = a;
						classiList.add(junc);
					}
				}
				if (!classiList.isEmpty()){
					insert classiList;
				}
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
	}

	/*
	* change record type of Risk
	*/
	@AuraEnabled
	public static void changeRiskRecordType(string riskId, String recordTypeName){
		try {
			if (String.isNotBlank(riskId) && String.isNotBlank(recordTypeName)){
				List<ermt__Risk__c> listRisks = [Select Id From ermt__Risk__c Where Id=:riskId];
				List<RecordType> types = [SELECT Id FROM RecordType WHERE DeveloperName =:recordTypeName AND SobjectType = 'ermt__Risk__c'];
				if (listRisks.size() > 0 && types.size() > 0){
					listRisks[0].RecordTypeId = types[0].Id;
					update listRisks;
				}
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
	}
}