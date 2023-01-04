public with sharing class ERMT_RiskAssessClassificationJuncHandler {
	public static void updateRiskAssessment(List<ermt__RiskAssessment_Classification_Junc__c> raJuncList){
		try {
			//Generate set of ermt__RiskAssessment__c Ids
			Set<Id> raIds = new Set<Id>();
			Set<Id> classIds = new Set<Id>();
			for(ermt__RiskAssessment_Classification_Junc__c raJunc : raJuncList){
				classIds.add(raJunc.ermt__M_Classification__c);
			}
			//Query to get Recordtype Developer name of Parent 
			Map<ID, ermt__M_Classification__c> mapClassi = new Map<ID, ermt__M_Classification__c>([Select ermt__ParentMClassification_del__r.RecordType.DeveloperName From ermt__M_Classification__c Where Id In :classIds]);
			List<ermt__RiskAssessment__c> updateList = new List<ermt__RiskAssessment__c>();
			Map<Id, ermt__RiskAssessment__c> updateMap = new Map<Id, ermt__RiskAssessment__c>();
			for(ermt__RiskAssessment_Classification_Junc__c raJunc : raJuncList){
				//Update Likelihood or Consequence of ermt__RiskAssessment__c
				ermt__RiskAssessment__c record;
				if(updateMap.containsKey(raJunc.ermt__RiskAssessment__c)){
					record = updateMap.get(raJunc.ermt__RiskAssessment__c);
				}
				else{
					record = new ermt__RiskAssessment__c();
					if(Schema.sObjectType.ermt__RiskAssessment__c.isUpdateable()){
						record.Id = raJunc.ermt__RiskAssessment__c;
						updateMap.put(raJunc.ermt__RiskAssessment__c,record);
					}
				}

				ermt__M_Classification__c classi = mapClassi.get(raJunc.ermt__M_Classification__c);
				if(classi.ermt__ParentMClassification_del__r.RecordType.DeveloperName == 'LikelihoodGroup'){
					record.ermt__Likelihood__c = null;
					record.ermt__NumberLikelihood__c = 0;
				}
				else if(classi.ermt__ParentMClassification_del__r.RecordType.DeveloperName == 'ConsequenceGroup'){
					record.ermt__Consequence__c = null;
					record.ermt__NumberConsequence__c = 0;
				}
				else if(classi.ermt__ParentMClassification_del__r.RecordType.DeveloperName == 'SeverityRiskLevelGroup'){
					record.ermt__SeverityRiskLevel__c = null;
					record.ermt__NumberSeverityRiskLevel__c = 0;
				}
				else if(classi.ermt__ParentMClassification_del__r.RecordType.DeveloperName == 'EvaluationPeriodGroup'){
					record.ermt__EvaluationTime__c = null;
				}
			}
			List<String> listUpdateField = new List<String>();
			listUpdateField.add('ermt__Likelihood__c');
			listUpdateField.add('ermt__NumberLikelihood__c');
			listUpdateField.add('ermt__Consequence__c');
			listUpdateField.add('ermt__NumberConsequence__c');
			listUpdateField.add('ermt__SeverityRiskLevel__c');
			listUpdateField.add('ermt__NumberSeverityRiskLevel__c');
			listUpdateField.add('ermt__EvaluationTime__c');
			updateList.addAll(updateMap.values());
			//if(Schema.sObjectType.ermt__RiskAssessment__c.isUpdateable()){
			//	updateList.addAll(updateMap.values());

			//	System.debug(updateList);
			//	update updateList;
			//}
			if(ERMT_FLSCheck.checkUpdate(updateList , listUpdateField)){
				System.debug(updateList);
				update updateList;
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
	}
}