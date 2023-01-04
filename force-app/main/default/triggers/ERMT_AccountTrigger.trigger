trigger ERMT_AccountTrigger on Account (after delete) {
    if(Trigger.isAfter){
		if(Trigger.isDelete){
			ERMT_AccountHandler.deletePublicGroupRelated(Trigger.old); 
		}
	}
}