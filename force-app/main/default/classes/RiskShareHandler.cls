// リスク共有ハンドラ
public class RiskShareHandler {
    public class OrginalException extends Exception {} // 独自の例外クラス
    @TestVisible private static final String ACCOUNT_GROUP_NAME_PREFIX = 'Account_'; // 組織・部門グループ名接頭辞
    @TestVisible private static final String RISK_SHARE_REASON = 'ermt__AccountPublicGroupSharingReason__c'; // リスク共有の理由
    @TestVisible private static final String RISK_SHARE_ACCESS_LEVEL = 'Edit'; // リスク共有のアクセス権
    
    // リスク共有の更新
    public static Boolean updateRiskShare(
        Set<Id> riskIdSet
        , Map<Id, Set<Id>> groupIdSetByRiskId
    ) {
        Boolean ret = false;

        // リスクIDごとのリスク共有リストを作成
        Map<Id, List<ermt__Risk__Share>> riskSharesByRiskId = createRiskSharesByRiskId(riskIdSet);

        // 削除用リスク共有リストの作成
        List<ermt__Risk__Share> delRiskShares = createDeleteRiskShares(riskSharesByRiskId, groupIdSetByRiskId);

        // 追加用リスク共有リストの作成
        List<ermt__Risk__Share> insRiskShares = createInsertRiskShares(riskSharesByRiskId, groupIdSetByRiskId);

        Savepoint sp = Database.setSavepoint();
		try {
            // リスク共有の削除
            if (!delRiskShares.isEmpty()) {
                delete delRiskShares;
            }

            // リスク共有の追加
            if (!insRiskShares.isEmpty()) {
                insert insRiskShares;
            }
            ret = true;
        } catch(Exception ex) {
            Database.rollback(sp);
            throw new OrginalException('line.' + ex.getLineNumber() + ':' + ex.getMessage(), ex);
        }
        return ret;
    }

    // リスクIDごとのグループIDセットを作成
    public static Map<Id, Set<Id>> createGroupIdSetByRiskId(
        Set<Id> riskIdSet
    ) {
        Map<Id, Set<Id>> ret = new Map<Id, Set<Id>>();

        // リスクIDごとの組織・部門IDセットを作成
        Map<Id, Set<Id>> accIdSetByRiskId = createAccountIdSetByRiskId(riskIdSet);

        // 組織・部門IDセットの作成
        Set<Id> accIdSet = createAccountIdSet(accIdSetByRiskId);

        // 組織・部門IDごとのグループIDを作成
        Map<Id, Id> groupIdByAccId = createGroupIdByAccountId(accIdSet);
        for (Id riskId : accIdSetByRiskId.keySet()) {
            Set<Id> groupIdSet = ret.get(riskId);
            if (groupIdSet == null) {
                groupIdSet = new Set<Id>();
                ret.put(riskId, groupIdSet);
            }
            for (Id accId : accIdSetByRiskId.get(riskId)) {
                Id groupId = groupIdByAccId.get(accId);
                if (groupId != null) {
                    groupIdSet.add(groupId);
                }
            }
        }
        return ret;
    }

    // リスクIDごとの組織・部門IDセットを作成
    private static Map<Id, Set<Id>> createAccountIdSetByRiskId(
        Set<Id> riskIdSet
    ) {
        Map<Id, Set<Id>> ret = new Map<Id, Set<Id>>();

        // リスクの取得
        for (ermt__Risk__c r : [
            SELECT ermt__Organization__c
            FROM ermt__Risk__c
            WHERE Id IN :riskIdSet
            AND ermt__Organization__c != null
        ]) {
            Set<Id> accIdSet = ret.get(r.Id);
            if (accIdSet == null) {
                accIdSet = new Set<Id>();
                ret.put(r.Id, accIdSet);
            }
            accIdSet.add(r.ermt__Organization__c);
        }

        // リスク組織・部門の取得
        for (ermt__Risk_Account_Junc__c raj : [
            SELECT ermt__Risk__c, ermt__Department__c
            FROM ermt__Risk_Account_Junc__c
            WHERE ermt__Risk__c IN :riskIdSet
        ]) {
            Set<Id> accIdSet = ret.get(raj.ermt__Risk__c);
            if (accIdSet == null) {
                accIdSet = new Set<Id>();
                ret.put(raj.ermt__Risk__c, accIdSet);
            }
            accIdSet.add(raj.ermt__Department__c);
        }
        return ret;
    }

    // 組織・部門IDセットの作成
    private static Set<Id> createAccountIdSet(Map<Id, Set<Id>> accountIdSetByRiskId) {
        Set<Id> ret = new Set<Id>();
        for (Set<Id> accIdSet : accountIdSetByRiskId.values()) {
            ret.addAll(accIdSet);
        }
        return ret;
    }

    // 組織・部門IDごとのグループIDを作成
    private static Map<Id, Id> createGroupIdByAccountId(Set<Id> accountIdSet) {
        Map<Id, Id> ret = new Map<Id, Id>();

        // グループ名セットを作成
        Set<String> groupNameSet = new Set<String>();
        for (Id accountId : accountIdSet) {
            groupNameSet.add(ACCOUNT_GROUP_NAME_PREFIX + accountId);
        }
        
        // グループを取得
        for (Group g : [
            SELECT DeveloperName
            FROM group
            WHERE DeveloperName IN :groupNameSet
            AND Type = 'Regular'
        ]) {
            String accountId = g.DeveloperName.removeStart(ACCOUNT_GROUP_NAME_PREFIX);
            ret.put(accountId, g.Id);
        }
        return ret;
    }

    // リスクIDごとのリスク共有リストを作成
    private static Map<Id, List<ermt__Risk__Share>> createRiskSharesByRiskId(
        Set<Id> riskIdSet
    ) {
        Map<Id, List<ermt__Risk__Share>> ret = new Map<Id, List<ermt__Risk__Share>>();

        // リスク共有の取得
        for (ermt__Risk__Share rs : [
            SELECT ParentId, UserOrGroupId
            FROM ermt__Risk__Share
            WHERE ParentId IN :riskIdSet
            AND RowCause = :RISK_SHARE_REASON
        ]) {
            List<ermt__Risk__Share> riskShares = ret.get(rs.ParentId);
            if (riskShares == null) {
                riskShares = new List<ermt__Risk__Share>();
                ret.put(rs.ParentId, riskShares);
            }
            riskShares.add(rs);
        }
        return ret;
    }

    // 削除用リスク共有リストの作成
    private static List<ermt__Risk__Share> createDeleteRiskShares(
        Map<Id, List<ermt__Risk__Share>> riskSharesByRiskId
        , Map<Id, Set<Id>> groupIdSetByRiskId
    ) {
        List<ermt__Risk__Share> ret = new List<ermt__Risk__Share>();
        for (Id riskId : riskSharesByRiskId.keySet()) {
            List<ermt__Risk__Share> riskShares = riskSharesByRiskId.get(riskId);
            Set<Id> groupIdSet = groupIdSetByRiskId.get(riskId);
            groupIdSet = (groupIdSet != null ? groupIdSet : new Set<Id>());
            for (ermt__Risk__Share rs : riskShares) {
                if (!groupIdSet.contains(rs.UserOrGroupId)) {
                    ret.add(new ermt__Risk__Share(
                        Id = rs.Id
                    ));
                }
            }
        }
        return ret;
    }

    // 追加用リスク共有リストの作成
    private static List<ermt__Risk__Share> createInsertRiskShares(
        Map<Id, List<ermt__Risk__Share>> riskSharesByRiskId
        , Map<Id, Set<Id>> groupIdSetByRiskId
    ) {
        List<ermt__Risk__Share> ret = new List<ermt__Risk__Share>();
        for (Id riskId : groupIdSetByRiskId.keySet()) {
            Set<Id> groupIdSet = groupIdSetByRiskId.get(riskId);
            List<ermt__Risk__Share> riskShares = riskSharesByRiskId.get(riskId);

            // 旧グループIDセットの作成
            Set<Id> oldGroupIdSet = new Set<Id>();
            if (riskShares != null) {
                for (ermt__Risk__Share rs : riskShares) {
                    oldGroupIdSet.add(rs.UserOrGroupId);
                }
            }
            for (Id groupId : groupIdSet) {
                if (!oldGroupIdSet.contains(groupId)) {
                    ret.add(new ermt__Risk__Share(
                        ParentId = riskId
                        , UserOrGroupId = groupId
                        , AccessLevel = RISK_SHARE_ACCESS_LEVEL
                        , RowCause = RISK_SHARE_REASON
                    ));
                }
            }
        }
        return ret;
    }
}