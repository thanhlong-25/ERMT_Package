public with sharing class ERMT_ChecklistCC {
	/**
	*	Update submited state for Checklist User
	**/
	@AuraEnabled
	public static boolean submitChecklist(String checklistId){
        List<ermt__Checklist_User__c> listChecklistUsers  = [SELECT Id, ermt__Checklist__c, ermt__User__c, ermt__Is_Submit__c 
        FROM ermt__Checklist_User__c WhERE ermt__Checklist__c =: checklistId AND ermt__User__c =: UserInfo.getUserId()];

        if (!listChecklistUsers.isEmpty()){
            listChecklistUsers[0].ermt__Is_Submit__c = true;
            update listChecklistUsers[0]; 

			// Lock the checklistUser
			Approval.lock(listChecklistUsers, false);
			// Lock the answers
			List<ermt__Answer__c> listAnswers  = [SELECT Id FROM ermt__Answer__c WHERE ermt__Checklist_User__c =: listChecklistUsers[0].Id];
			System.debug(listAnswers);
			Approval.lock(listAnswers, false);
        }
		return false;
	}

	/**
	*	Check Checklist has been submited or user has answered all of questions
	**/
	@AuraEnabled
	public static CheckSubmit checkChecklistSubmitable(String checklistId){
		// check permission
		if (!FeatureManagement.checkPermission('Can_answer_checklist')){
			return new CheckSubmit(Label.You_can_not_answer, false);
		}

		// check valid
		List<ermt__Checklist__c> listChecklists  = [SELECT Id, ermt__Valid__c FROM ermt__Checklist__c WHERE Id =: checklistId];
		if (!listChecklists.isEmpty()){
			if (!listChecklists[0].ermt__Valid__c) {
				return new CheckSubmit(Label.Checklist_is_invalid, false);
			}
		}
		
		List<ermt__Checklist_User__c> listChecklistUsers  = [SELECT Id, ermt__Checklist__c, ermt__User__c, ermt__Is_Submit__c 
        FROM ermt__Checklist_User__c WhERE ermt__Checklist__c =: checklistId AND ermt__User__c =: UserInfo.getUserId()];
		
        if (!listChecklistUsers.isEmpty()){
			// check submited
			if (listChecklistUsers[0].ermt__Is_Submit__c) {
				return new CheckSubmit(Label.Has_been_submitted, false);
			}
			// check answer
            List<ermt__Answer__c> listAnswers = [SELECT Id FROM ermt__Answer__c WHERE ermt__Question__r.ermt__Section__r.ermt__category__r.ermt__checklist__c =:checklistId AND ermt__Checklist_User__c =: listChecklistUsers[0].Id];
            List<ermt__Question__c> listAllQuestions = [SELECT Id FROM ermt__Question__c WHERE ermt__Section__r.ermt__category__r.ermt__checklist__c =:checklistId];
            if (listAnswers.size() < listAllQuestions.size()){
				return new CheckSubmit(Label.All_questions_must_be_answered, false);
            } else {
                return new CheckSubmit(Label.Are_you_sure, true);
            }
        } else {
			return new CheckSubmit(Label.All_questions_must_be_answered, false);
		}
	}
	
	public class CheckSubmit {
		@AuraEnabled
		public String message;
		@AuraEnabled
		public boolean submitable;

		public CheckSubmit(String mess, boolean submit){
			this.message = mess;
			this.submitable = submit;
		}
	}
}