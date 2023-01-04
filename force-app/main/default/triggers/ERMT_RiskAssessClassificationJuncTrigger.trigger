// リスクアセスメント分類のトリガー
trigger ERMT_RiskAssessClassificationJuncTrigger on ermt__RiskAssessment_Classification_Junc__c (before delete, after delete) {
	if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            // リスクアセスメント分類のリスクロックチェック
            RiskLockHandler.checkRiskLockByRiskAssessClassi(Trigger.old);
        }
    } else if(Trigger.isAfter){
		if(Trigger.isDelete){
			ERMT_RiskAssessClassificationJuncHandler.updateRiskAssessment(Trigger.old);
		}
	}
}