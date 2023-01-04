// リスク分類のトリガー
trigger RiskClassificationJuncTrigger on ermt__Risk_Classification_Junc__c (before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            // リスク分類のリスクロックチェック
            RiskLockHandler.checkRiskLockByRiskClassi(Trigger.old);
        }
    }
}