public class ERMT_QuestionCC {
	/**
	*	Get all Questions by Checklist Id
	*   Get info related: section, category, answer 
	**/
	@AuraEnabled
	public static List<ermt__Question__c> getAllQuestionByChecklist(string checklistId){

		String userId = UserInfo.getUserId();

		List<ermt__Checklist_User__c> listChecklistUsers  = [SELECT Id, ermt__Checklist__c, ermt__User__c, ermt__Is_Submit__c 
        FROM ermt__Checklist_User__c WhERE ermt__Checklist__c =: checklistId AND ermt__User__c =: userId];

		String checklistUserId = null;
		if (!listChecklistUsers.isEmpty()){
			checklistUserId = listChecklistUsers[0].Id;
		} 

		return [
			Select Id, Name, ermt__Order__c, ermt__Title__c, ermt__Label_Textarea__c, ermt__Label_Date_field__c
			, ermt__Value_to_display_date_field__c, ermt__Label_0__c, ermt__Label_1__c, ermt__Label_2__c
			, ermt__Label_3__c, ermt__Label_4__c, ermt__Label_5__c
			, ermt__Supplement_Image_1__c, ermt__Supplement_Image_2__c
			, ermt__Section__r.ermt__Title__c, ermt__Section__r.ermt__Order__c
			, ermt__Section__r.ermt__Category__r.ermt__Title__c, ermt__Section__r.ermt__Category__r.ermt__Order__c
			, (Select ermt__Answer_0__c, ermt__Answer_1__c, ermt__Answer_2__c, ermt__Answer_3__c, ermt__Answer_4__c
			, ermt__Answer_5__c, ermt__Answer_Datefield__c, ermt__Answer_Textarea__c
			From ermt__Answer__r
			Where ermt__Checklist_User__c =: checklistUserId)
			From ermt__Question__c
			where ermt__Section__r.ermt__category__r.ermt__checklist__c =:checklistId
		];
	}
    
	/**
	*	Check User has permission answer checklist
	**/
	@AuraEnabled
	public static boolean getChecklistAnswerPermission(){
		return FeatureManagement.checkPermission('Can_answer_checklist');
	}

	/**
	*	Check Checklist is Valid and not submitted yet
	**/
	@AuraEnabled
	public static boolean checkChecklistValidAnswer(string checklistId){
		List<ermt__Checklist__c> listChecklists  = [SELECT Id, ermt__Valid__c FROM ermt__Checklist__c WHERE Id =: checklistId];
		if (!listChecklists.isEmpty()){
			if (!listChecklists[0].ermt__Valid__c) {
				// not valid
				return false;
			} else {
				// valid
				List<ermt__Checklist_User__c> listChecklistUsers  = [SELECT Id, ermt__Is_Submit__c 
				FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =: checklistId AND ermt__User__c =: UserInfo.getUserId()];
				
				if (!listChecklistUsers.isEmpty()){
					// has been saved
					if (listChecklistUsers[0].ermt__Is_Submit__c) {
						// has been submitted
						return false;
					} else {
						// not submitted yet
						return true;
					}
				} else {
					// not saved yet
					return true;
				}
			}
		}
		return false;
	}

	/**
	*	Get all Questions by Checklist User Id
	*   Get info related: section, category, answer 
	**/
	@AuraEnabled
	public static List<ermt__Question__c> getAllQuestionByChecklistUser(string checklistUserId){

		if (String.isNotBlank(checklistUserId)){
			List<ermt__Checklist_User__c> checklistUsers  = [SELECT Id, ermt__Checklist__c, ermt__User__c, ermt__Is_Submit__c 
			FROM ermt__Checklist_User__c WhERE Id=:checklistUserId];

			if (!checklistUsers.isEmpty()){
				return [
					Select Id, Name, ermt__Order__c, ermt__Title__c, ermt__Label_Textarea__c, ermt__Label_Date_field__c
					, ermt__Value_to_display_date_field__c, ermt__Label_0__c, ermt__Label_1__c, ermt__Label_2__c
					, ermt__Label_3__c, ermt__Label_4__c, ermt__Label_5__c
					, ermt__Supplement_Image_1__c, ermt__Supplement_Image_2__c
					, ermt__Section__r.ermt__Title__c, ermt__Section__r.ermt__Order__c
					, ermt__Section__r.ermt__Category__r.ermt__Title__c, ermt__Section__r.ermt__Category__r.ermt__Order__c
					, (Select ermt__Answer_0__c, ermt__Answer_1__c, ermt__Answer_2__c, ermt__Answer_3__c, ermt__Answer_4__c
					, ermt__Answer_5__c, ermt__Answer_Datefield__c, ermt__Answer_Textarea__c
					From ermt__Answer__r
					Where ermt__Checklist_User__c =: checklistUserId)
					From ermt__Question__c
					where ermt__Section__r.ermt__category__r.ermt__checklist__c =:checklistUsers[0].ermt__Checklist__c
				];
			}
		}
		return new List<ermt__Question__c>();
		
	}
	
}