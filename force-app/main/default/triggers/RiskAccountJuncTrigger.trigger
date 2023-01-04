// リスク組織・部門のトリガー
trigger RiskAccountJuncTrigger on ermt__Risk_Account_Junc__c (after insert, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isDelete || Trigger.isUndelete) {
            // 対象のリスクIDセットの作成
            Set<Id> riskIdSet = new Set<Id>();
            if (Trigger.isInsert || Trigger.isUndelete) {
                for (ermt__Risk_Account_Junc__c raj : Trigger.new) {
                    riskIdSet.add(raj.ermt__Risk__c);
                }
            } else if (Trigger.isDelete) {
                for (ermt__Risk_Account_Junc__c raj : Trigger.old) {
                    riskIdSet.add(raj.ermt__Risk__c);
                }
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