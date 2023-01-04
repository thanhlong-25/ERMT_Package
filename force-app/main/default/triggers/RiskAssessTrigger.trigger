// リスクアセスメントのトリガー
trigger RiskAssessTrigger on ermt__RiskAssessment__c (before delete, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            // リスクアセスメントのリスクロックチェック
            RiskLockHandler.checkRiskLockByRiskAssess(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // 対象のリスクアセスメントIDセットの作成
            Set<Id> riskAssessIdSet = new Set<Id>();
            if (Trigger.isInsert) {
                for (ermt__RiskAssessment__c ra : Trigger.new) {
                    riskAssessIdSet.add(ra.Id);
                }
            } else if (Trigger.isUpdate) {
                for (ermt__RiskAssessment__c ra : Trigger.new) {
                    ermt__RiskAssessment__c oldRiskAssess = Trigger.oldMap.get(ra.Id);
                    if (oldRiskAssess.ermt__Risk__c != ra.ermt__Risk__c) {
                        riskAssessIdSet.add(ra.Id);
                    }
                }
            }
            if (!riskAssessIdSet.isEmpty()) {
                // リスクIDセットの取得
                Set<Id> riskIdSet = RiskAssessShareHandler.getRiskIdSet(riskAssessIdSet);

                // リスクIDごとのグループIDセットを作成
                Map<Id, Set<Id>> groupIdSetByRiskId = RiskShareHandler.createGroupIdSetByRiskId(riskIdSet);

                // リスクアセスメントIDごとのグループIDセットを作成
                Map<Id, Set<Id>> groupIdSetByRiskAssessId = RiskAssessShareHandler.createGroupIdSetByRiskAssessId(riskAssessIdSet, groupIdSetByRiskId);

                // リスクアセスメント共有の更新
                RiskAssessShareHandler.updateRiskAssessShare(riskAssessIdSet, groupIdSetByRiskAssessId);
            }
        }
    }
}