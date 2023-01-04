// リスクアセスメント共有ハンドラ
public class RiskAssessShareHandler {
    public class OrginalException extends Exception {} // 独自の例外クラス
    @TestVisible private static final String RISK_ASSESS_SHARE_REASON = 'ermt__AccountPublicGroupSharingReason__c'; // リスクアセスメント共有の理由
    @TestVisible private static final String RISK_ASSESS_SHARE_ACCESS_LEVEL = 'Edit'; // リスクアセスメント共有のアクセス権

    // リスクアセスメント共有の更新
    public static Boolean updateRiskAssessShare(
        Set<Id> riskAssessIdSet
        , Map<Id, Set<Id>> groupIdSetByRiskAssessId
    ) {
        Boolean ret = false;

        // リスクアセスメントIDごとのリスクアセスメント共有リストを作成
        Map<Id, List<ermt__RiskAssessment__Share>> riskAssSharesByRiskAssId = createRiskAssessSharesByRiskAssessId(riskAssessIdSet);

        // 削除用リスクアセスメント共有リストの作成
        List<ermt__RiskAssessment__Share> delRiskAssShares = createDeleteRiskAssessShares(riskAssSharesByRiskAssId, groupIdSetByRiskAssessId);

        // 追加用リスクアセスメント共有リストの作成
        List<ermt__RiskAssessment__Share> insRiskAssShares = createInsertRiskAssessShares(riskAssSharesByRiskAssId, groupIdSetByRiskAssessId);

        Savepoint sp = Database.setSavepoint();
		try {
            // リスクアセスメント共有の削除
            if (!delRiskAssShares.isEmpty()) {
                delete delRiskAssShares;
            }

            // リスクアセスメント共有の追加
            if (!insRiskAssShares.isEmpty()) {
                insert insRiskAssShares;
            }
            ret = true;
        } catch(Exception ex) {
            Database.rollback(sp);
            throw new OrginalException('line.' + ex.getLineNumber() + ':' + ex.getMessage(), ex);
        }
        return ret;
    }

    // リスクIDセットの取得
    public static Set<Id> getRiskIdSet(
        Set<Id> riskAssessIdSet
    ) {
        Set<Id> ret = new Set<Id>();
        for (ermt__RiskAssessment__c ra : [
            SELECT ermt__Risk__c
            FROM ermt__RiskAssessment__c
            WHERE Id IN :riskAssessIdSet
        ]) {
            ret.add(ra.ermt__Risk__c);
        }
        return ret;
    }

    // リスクアセスメントIDセットの取得
    public static Set<Id> getRiskAssesssIdSet(
        Set<Id> riskIdSet
    ) {
        Set<Id> ret = new Set<Id>();
        for (ermt__RiskAssessment__c ra : [
            SELECT Id
            FROM ermt__RiskAssessment__c
            WHERE ermt__Risk__c IN :riskIdSet
        ]) {
            ret.add(ra.Id);
        }
        return ret;
    }

    // リスクアセスメントIDごとのグループIDセットを作成
    public static Map<Id, Set<Id>> createGroupIdSetByRiskAssessId(
        Set<Id> riskAssessIdSet
        , Map<Id, Set<Id>> groupIdSetByRiskId
    ) {
        Map<Id, Set<Id>> ret = new Map<Id, Set<Id>>();
        for (ermt__RiskAssessment__c ra : [
            SELECT ermt__Risk__c
            FROM ermt__RiskAssessment__c
            WHERE Id IN :riskAssessIdSet
            AND ermt__Risk__c != null
        ]) {
            Set<Id> groupIdSet = groupIdSetByRiskId.get(ra.ermt__Risk__c);
            if (groupIdSet != null) {
                ret.put(ra.Id, groupIdSet);
            }
        }
        return ret;
    }

    // リスクアセスメントIDごとのリスクアセスメント共有リストを作成
    private static Map<Id, List<ermt__RiskAssessment__Share>> createRiskAssessSharesByRiskAssessId(
        Set<Id> riskAssessIdSet
    ) {
        Map<Id, List<ermt__RiskAssessment__Share>> ret = new Map<Id, List<ermt__RiskAssessment__Share>>();

        // リスクアセスメント共有の取得
        for (ermt__RiskAssessment__Share ras : [
            SELECT ParentId, UserOrGroupId
            FROM ermt__RiskAssessment__Share
            WHERE ParentId IN :riskAssessIdSet
            AND RowCause = :RISK_ASSESS_SHARE_REASON
        ]) {
            List<ermt__RiskAssessment__Share> riskAssShares = ret.get(ras.ParentId);
            if (riskAssShares == null) {
                riskAssShares = new List<ermt__RiskAssessment__Share>();
                ret.put(ras.ParentId, riskAssShares);
            }
            riskAssShares.add(ras);
        }
        return ret;
    }

    // 削除用リスクアセスメント共有リストの作成
    private static List<ermt__RiskAssessment__Share> createDeleteRiskAssessShares(
        Map<Id, List<ermt__RiskAssessment__Share>> riskAssSharesByRiskAssId
        , Map<Id, Set<Id>> groupIdSetByRiskAssessId
    ) {
        List<ermt__RiskAssessment__Share> ret = new List<ermt__RiskAssessment__Share>();
        for (Id riskAssId : riskAssSharesByRiskAssId.keySet()) {
            List<ermt__RiskAssessment__Share> riskAssShares = riskAssSharesByRiskAssId.get(riskAssId);
            Set<Id> groupIdSet = groupIdSetByRiskAssessId.get(riskAssId);
            groupIdSet = (groupIdSet != null ? groupIdSet : new Set<Id>());
            for (ermt__RiskAssessment__Share ras : riskAssShares) {
                if (!groupIdSet.contains(ras.UserOrGroupId)) {
                    ret.add(new ermt__RiskAssessment__Share(
                        Id = ras.Id
                    ));
                }
            }
        }
        return ret;
    }

    // 追加用リスクアセスメント共有リストの作成
    private static List<ermt__RiskAssessment__Share> createInsertRiskAssessShares(
        Map<Id, List<ermt__RiskAssessment__Share>> riskAssSharesByRiskAssId
        , Map<Id, Set<Id>> groupIdSetByRiskAssessId
    ) {
        List<ermt__RiskAssessment__Share> ret = new List<ermt__RiskAssessment__Share>();
        for (Id riskAssId : groupIdSetByRiskAssessId.keySet()) {
            Set<Id> groupIdSet = groupIdSetByRiskAssessId.get(riskAssId);
            List<ermt__RiskAssessment__Share> riskAssShares = riskAssSharesByRiskAssId.get(riskAssId);

            // 旧グループIDセットの作成
            Set<Id> oldGroupIdSet = new Set<Id>();
            if (riskAssShares != null) {
                for (ermt__RiskAssessment__Share ras : riskAssShares) {
                    oldGroupIdSet.add(ras.UserOrGroupId);
                }
            }
            for (Id groupId : groupIdSet) {
                if (!oldGroupIdSet.contains(groupId)) {
                    ret.add(new ermt__RiskAssessment__Share(
                        ParentId = riskAssId
                        , UserOrGroupId = groupId
                        , AccessLevel = RISK_ASSESS_SHARE_ACCESS_LEVEL
                        , RowCause = RISK_ASSESS_SHARE_REASON
                    ));
                }
            }
        }
        return ret;
    }
}