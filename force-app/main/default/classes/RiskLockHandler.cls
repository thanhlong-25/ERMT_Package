// リスクロックハンドラ
public class RiskLockHandler {
    // リスクロックチェック
    public static Boolean checkRiskLock(List<ermt__Risk__c> risks) {
        Boolean ret = true;
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__Risk__c risk : risks) {
            riskIdSet.add(risk.Id);
        }
        // ロック済みリスクIDセットの取得
        riskIdSet = getLockedRiskIdSet(riskIdSet);
        for (ermt__Risk__c risk : risks) {
            // リスクがロック済みの場合、エラー
            if (riskIdSet.contains(risk.Id)) {
                risk.addError(System.Label.RiskLock_Error);
                ret = false;
            }
        }
        return ret;
    }

    // リスク分類のリスクロックチェック
    public static Boolean checkRiskLockByRiskClassi(List<ermt__Risk_Classification_Junc__c> riskClassis) {
        Boolean ret = true;
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__Risk_Classification_Junc__c riskClassi : riskClassis) {
            riskIdSet.add(riskClassi.ermt__Risk__c);
        }
        // ロック済みリスクIDセットの取得
        riskIdSet = getLockedRiskIdSet(riskIdSet);
        for (ermt__Risk_Classification_Junc__c riskClassi : riskClassis) {
            // リスクがロック済みの場合、エラー
            if (riskIdSet.contains(riskClassi.ermt__Risk__c)) {
                riskClassi.addError(System.Label.RiskLock_Error);
                ret = false;
            }
        }
        return ret;
    }

    // リスクアセスメントのリスクロックチェック
    public static Boolean checkRiskLockByRiskAssess(List<ermt__RiskAssessment__c> riskAssesss) {
        Boolean ret = true;
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__RiskAssessment__c riskAssess : riskAssesss) {
            if (riskAssess.ermt__Risk__c != null) {
                riskIdSet.add(riskAssess.ermt__Risk__c);
            }
        }
        // ロック済みリスクIDセットの取得
        riskIdSet = getLockedRiskIdSet(riskIdSet);
        for (ermt__RiskAssessment__c riskAssess : riskAssesss) {
            // リスクがロック済みの場合、エラー
            if (riskIdSet.contains(riskAssess.ermt__Risk__c)) {
                riskAssess.addError(System.Label.RiskLock_Error);
                ret = false;
            }
        }
        return ret;
    }

    // リスクアセスメント分類のリスクロックチェック
    public static Boolean checkRiskLockByRiskAssessClassi(List<ermt__RiskAssessment_Classification_Junc__c> riskAssessClassis) {
        Boolean ret = true;
        // リスクアセスメントIDセットの作成
        Set<Id> riskAssessIdSet = new Set<Id>();
        for (ermt__RiskAssessment_Classification_Junc__c riskAssessClassi : riskAssessClassis) {
            riskAssessIdSet.add(riskAssessClassi.ermt__RiskAssessment__c);
        }
        // リスクアセスメントマップの作成
        Map<Id, ermt__RiskAssessment__c> riskAssessById = new Map<Id, ermt__RiskAssessment__c>([
            SELECT ermt__Risk__c
            FROM ermt__RiskAssessment__c
            WHERE Id IN :riskAssessIdSet
        ]);
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__RiskAssessment__c riskAssess : riskAssessById.values()) {
            if (riskAssess.ermt__Risk__c != null) {
                riskIdSet.add(riskAssess.ermt__Risk__c);
            }
        }
        // ロック済みリスクIDセットの取得
        riskIdSet = getLockedRiskIdSet(riskIdSet);
        for (ermt__RiskAssessment_Classification_Junc__c riskAssessClassi : riskAssessClassis) {
            ermt__RiskAssessment__c riskAssess = riskAssessById.get(riskAssessClassi.ermt__RiskAssessment__c);
            if (riskAssess != null) {
                // リスクがロック済みの場合、エラー
                if (riskIdSet.contains(riskAssess.ermt__Risk__c)) {
                    riskAssessClassi.addError(System.Label.RiskLock_Error);
                    ret = false;
                }
            }
        }
        return ret;
    }

    // リスク対応策のリスクロックチェック
    public static Boolean checkRiskLockByRiskControl(List<ermt__Risk_Control_Junc__c> riskControls) {
        Boolean ret = true;
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__Risk_Control_Junc__c riskControl : riskControls) {
            riskIdSet.add(riskControl.ermt__Risk__c);
        }
        // ロック済みリスクIDセットの取得
        riskIdSet = getLockedRiskIdSet(riskIdSet);
        for (ermt__Risk_Control_Junc__c riskControl : riskControls) {
            // リスクがロック済みの場合、エラー
            if (riskIdSet.contains(riskControl.ermt__Risk__c)) {
                riskControl.addError(System.Label.RiskLock_Error);
                ret = false;
            }
        }
        return ret;
    }

    // ロック済みリスクIDセットの取得
    private static Set<Id> getLockedRiskIdSet(Set<Id> riskIdSet) {
        Set<Id> ret = new Set<Id>();
        ermt__RiskLockSetting__c setting = ermt__RiskLockSetting__c.getInstance();
        // リスクロック設定のロック有効が有効な場合のみチェックする
        if (setting.ermt__IsLockEnabled__c) {
            // リスクの取得
            // 承認ステータスが申請中または、承認済の場合、ロック済
            for (ermt__Risk__c risk : [
                SELECT Id
                FROM ermt__Risk__c
                WHERE Id IN :riskIdSet
                AND (ermt__ApprovalStatus__c = :System.Label.Risk_ApprovalStatus_Applying
                OR ermt__ApprovalStatus__c = :System.Label.Risk_ApprovalStatus_Approved)
            ]) {
                ret.add(risk.Id);
            }
        }
        return ret;
    }
}