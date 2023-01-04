trigger ERMT_ProjectClassificationJuncTrigger on ermt__Project_Classification_Junc__c (after delete) {
	if(Trigger.isAfter){
		if(Trigger.isDelete){
			ERMT_ProjectClassificationJuncHandler.deleteRiskClassiJuncChild(Trigger.old);

			// リスクマップのセル色の削除
			ERMT_ProjectClassificationJuncHandler.deleteCellColor(Trigger.old);
		}
	}
}