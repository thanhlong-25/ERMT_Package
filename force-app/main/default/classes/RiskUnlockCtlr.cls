// リスクのロック解除コントローラ
public without sharing class RiskUnlockCtlr {
    public class RiskUnlockException extends Exception {} // 独自の例外クラス

    // ラベルマップの取得
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLabelMap() {
        Map<String, String> ret = new Map<String, String>();
        ret.put('title', System.Label.RiskUnlock_Title);
        ret.put('content', System.Label.RiskUnlock_Content);
        ret.put('save', System.Label.RiskUnlock_Save);
        ret.put('save_success_title', System.Label.RiskUnlock_Save_Success_Title);
        ret.put('save_success_content', System.Label.RiskUnlock_Save_Success_Content);
        ret.put('save_error_title', System.Label.RiskUnlock_Save_Error_Title);
        ret.put('cancel', System.Label.RiskUnlock_Cancel);
        return ret;
    }

    // リスクの更新
    @AuraEnabled
	public static Map<String, Object> updateRisk(
        Id projectId // プロジェクトID
        , Id previousLastRiskId // 前回の最終リスクID
    ) {
        // System.debug('projectId=' + projectId);
        // System.debug('previousLastRiskId=' + previousLastRiskId);
        Boolean isDone = true;
        Id lastRiskId = null;
        Savepoint sp = Database.setSavepoint();
		try {
            // リスクロック設定のロック有効が有効な場合、一時的に無効にする
            ermt__RiskLockSetting__c setting = ermt__RiskLockSetting__c.getInstance();
            ermt__RiskLockSetting__c tmpSetting = null;
            if (setting.ermt__IsLockEnabled__c) {
                tmpSetting = new ermt__RiskLockSetting__c(
                    Id = setting.Id
                    , SetupOwnerId = setting.SetupOwnerId
                    , ermt__IsLockEnabled__c = false
                );
                upsert tmpSetting;
            }

            // リスクの取得、更新用リスクの作成
            List<ermt__Risk__c> updRisks = new List<ermt__Risk__c>();
            String query = '';
            query += 'SELECT Id';
            query += ' FROM ermt__Risk__c';
            query += ' WHERE ermt__Project__c = :projectId';
            if (previousLastRiskId != null) {
                query += ' AND Id > :previousLastRiskId';
            }
            query += ' ORDER BY Id';
            query += ' LIMIT 100';
            //System.debug('query=' + query);
            for (ermt__Risk__c risk : Database.query(query)) {
                updRisks.add(new ermt__Risk__c(
                    Id = risk.Id
                    , ermt__ApprovalStatus__c = System.Label.Risk_ApprovalStatus_Unapplied
                ));
                isDone = false;
                lastRiskId = risk.Id;
            }

            if (!updRisks.isEmpty()) {
                // リスクのレコードロック状況の取得
                Map<Id, Boolean> isLockedByRiskId = Approval.isLocked(updRisks);
                List<Id> lockedRiskIds = new List<Id>();
                for (Id riskId : isLockedByRiskId.keySet()) {
                    Boolean isLocked = isLockedByRiskId.get(riskId);
                    if (isLocked) {
                        lockedRiskIds.add(riskId);
                    }
                }

                // リスクのレコードロックの解除
                // オブジェクトレベルセキュリティで、
                // リスクレコードの全ての編集権限が無いと、
                // レコードロック解除でエラーになる。
                if (!lockedRiskIds.isEmpty()) {
                    Approval.unlock(lockedRiskIds, true);
                }

                // リスクの更新
                update updRisks;
            }

            // リスクロック設定のロック有効が有効な場合、元に戻す
            if (tmpSetting != null) {
                if (setting.Id == null) {
                    delete tmpSetting;
                } else {
                    tmpSetting.ermt__IsLockEnabled__c = true;
                    update tmpSetting;
                }
            }
		} catch(Exception ex) {
            Database.rollback(sp);
            throw new RiskUnlockException(ex.getMessage(), ex);
        }
        return new Map<String, Object>{
            'isDone' => isDone
            , 'lastRiskId' => lastRiskId
        };
    }
}