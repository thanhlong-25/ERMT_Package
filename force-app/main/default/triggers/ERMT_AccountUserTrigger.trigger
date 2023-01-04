trigger ERMT_AccountUserTrigger on ermt__Account_User__c (after delete) {
    if(Trigger.isAfter){
		if(Trigger.isDelete){
			ERMT_AccountUserHandler.deleteGroupMemberRelated(Trigger.old); 
		}
	}
}