// リスクのトリガー
trigger RiskTrigger on ermt__Risk__c (before delete, before update, after insert, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            // リスクロックチェック
            RiskLockHandler.checkRiskLock(Trigger.old);
            ERMT_RiskTriggerHandler.deleteAllIncidentRiskJunc(Trigger.old); // Delete all junction record before delete incident parent
            ERMT_RiskTriggerHandler.deleteAllRiskControlJunc(Trigger.old); // Delete all junction record before delete incident parent
        }
        if(Trigger.isUpdate){
            ERMT_RiskTriggerHandler.saveHistoryLog(Trigger.oldMap, Trigger.newMap); // save History Log
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // 対象のリスクIDセットの作成
            Set<Id> riskIdSet = new Set<Id>();
            if (Trigger.isInsert) {
                for (ermt__Risk__c r : Trigger.new) {
                    riskIdSet.add(r.Id);
                }
                //ERMT_RiskTriggerHandler.saveHistoryLog(Trigger.new, TriggerOperation.AFTER_INSERT); // save History Log
            } else if (Trigger.isUpdate) {
                for (ermt__Risk__c r : Trigger.new) {
                    ermt__Risk__c oldRisk = Trigger.oldMap.get(r.Id);
                    if (oldRisk.ermt__Organization__c != r.ermt__Organization__c) {
                        riskIdSet.add(r.Id);
                    }
                }
                ERMT_RiskTriggerHandler.updateNewValue(Trigger.new);
            }
            if (!riskIdSet.isEmpty()) {
                // リスクIDごとのグループIDセットを作成
                Map<Id, Set<Id>> groupIdSetByRiskId = RiskShareHandler.createGroupIdSetByRiskId(riskIdSet);

                // リスク共有の更新
                RiskShareHandler.updateRiskShare(riskIdSet, groupIdSetByRiskId);

                // リスクアセスメントIDセットの取得
                Set<Id> riskAssessIdSet = RiskAssessShareHandler.getRiskAssesssIdSet(riskIdSet);

                if (!riskAssessIdSet.isEmpty()) {
                    // リスクアセスメントIDごとのグループIDセットを作成
                    Map<Id, Set<Id>> groupIdSetByRiskAssessId = RiskAssessShareHandler.createGroupIdSetByRiskAssessId(riskAssessIdSet, groupIdSetByRiskId);

                    // リスクアセスメント共有の更新
                    RiskAssessShareHandler.updateRiskAssessShare(riskAssessIdSet, groupIdSetByRiskAssessId);
                }
            }
        }
    }
}