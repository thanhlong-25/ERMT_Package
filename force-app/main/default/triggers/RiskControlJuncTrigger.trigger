// リスク対応策のトリガー
trigger RiskControlJuncTrigger on ermt__Risk_Control_Junc__c (after insert, after delete, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            // リスク対応策のリスクロックチェック
            RiskLockHandler.checkRiskLockByRiskControl(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ERMT_RiskControlJuncTriggerHandler.saveHistoryLog(Trigger.new, TriggerOperation.AFTER_INSERT);
        } else if (Trigger.isDelete) {
            ERMT_RiskControlJuncTriggerHandler.saveHistoryLog(Trigger.old, TriggerOperation.AFTER_DELETE);
        }
    }

}