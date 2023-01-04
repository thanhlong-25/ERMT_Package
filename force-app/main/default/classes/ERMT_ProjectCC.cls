public with sharing class ERMT_ProjectCC {

	//Get option for dual list box component
	@AuraEnabled
	public static List<ermt__M_Classification__c> getListSelect(string recordTypeName){
		return [Select Id,Name,ermt__ViewNo__c From ermt__M_Classification__c Where RecordType.DeveloperName =:recordTypeName And ermt__Invalid__c = false Order By ermt__ViewNo__c];
	}

	//Get selected option for dual list box component
	@AuraEnabled
	public static List<ermt__Project_Classification_Junc__c> getSelectedClassification(string projectId, string recordTypeName){
		return [Select Id,ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName =:recordTypeName];
	}

	//Insert selected option for dual list box component 
	@AuraEnabled
	public static void insertClassification(List<String> classiIds, string projectId, string recordTypeName){
		try {
			Set<String> classiSet = new Set<String>(classiIds);
			Set<String> classiDbSet = new Set<String>();

			//Delete old classify in DB and not in selected list
			delete [Select Id From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__c Not In :classiSet And ermt__M_Classification__r.RecordType.DeveloperName =:recordTypeName];

			//Find old classify in DB and in selected list
			for(ermt__Project_Classification_Junc__c junc : [Select Id, ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__c In :classiSet And ermt__M_Classification__r.RecordType.DeveloperName =:recordTypeName]){
				classiDbSet.add(junc.ermt__M_Classification__c);
			}

			//Insert classify not in DB but do exist in selected list
			classiSet.removeAll(classiDbSet);
			if(classiSet.size() > 0){
				List<ermt__Project_Classification_Junc__c> classiList = new List<ermt__Project_Classification_Junc__c>();
				for(String a : classiSet){
					if(ERMT_Utils.isValid(a, ermt__M_Classification__c.getSObjectType())){
						ermt__Project_Classification_Junc__c classi = new ermt__Project_Classification_Junc__c();
						classi.ermt__Project__c = projectId;
						classi.ermt__M_Classification__c = a;
						classiList.add(classi);
					}
				}
				insert classiList;
			}
			
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
		}
	}

	//Get account and its childs for tree grid component
	@AuraEnabled
    public static List<Account> getAccountChilds(){
        List<Account> accountChilds =
            [SELECT Id, Name, Type, ParentId FROM Account];
        return accountChilds;
    }

    //Get selected option for tree grid component
	@AuraEnabled
	public static List<ermt__Project_Participant_Junc__c> getSelectedPrjPart(string projectId){
		return [Select Id,ermt__Account__c From ermt__Project_Participant_Junc__c Where ermt__Project__c =:projectId];
	}

    //Insert selected option for tree grid component
	@AuraEnabled
	public static void insertProjectParticipant(List<String> accountIds, string projectId){
		try {
			System.debug('ben trong he thong');
			Set<String> accountSet = new Set<String>(accountIds);
			Set<String> accountDbSet = new Set<String>();

			//Delete old account in DB and not in selected list
			delete [Select Id From ermt__Project_Participant_Junc__c Where ermt__Project__c =:projectId And ermt__Account__c Not In :accountSet];

			//Find old account in DB and in selected list
			for(ermt__Project_Participant_Junc__c junc : [Select Id, ermt__Account__c From ermt__Project_Participant_Junc__c Where ermt__Project__c =:projectId And ermt__Account__c In :accountSet]){
				accountDbSet.add(junc.ermt__Account__c);
			}

			//Insert classify not in DB but do exist in selected list
			accountSet.removeAll(accountDbSet);
			if(accountSet.size() > 0){
				List<ermt__Project_Participant_Junc__c> accountList = new List<ermt__Project_Participant_Junc__c>();
				for(String a : accountSet){
					if(ERMT_Utils.isValid(a, Account.getSObjectType())){
						ermt__Project_Participant_Junc__c acc = new ermt__Project_Participant_Junc__c();
						acc.ermt__Project__c = projectId;
						acc.ermt__Account__c = a;
						accountList.add(acc);
					}
				}
				insert accountList;
			}
			
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
		}
	}
}