// リスク分類の参照・編集コントローラ
public without sharing class RiskClassiViewEditCtlr {
    public class CustomException extends Exception {} // カスタム例外クラス

    // プロジェクトIDの取得
    @AuraEnabled
    public static Id getProjectId(Id riskId) {
        Id ret = null;
        // リスクの取得
        for (ermt__Risk__c r : [
            SELECT ermt__Project__c FROM ermt__Risk__c
            WHERE Id = :riskId
            LIMIT 1
        ]) {
            ret = r.ermt__Project__c;
        }
        return ret;
    }

    // 分類グループ情報リストの取得
    @AuraEnabled
    public static List<Map<String, Object>> getClassiGroupInfos(
        Id projectId
    ) {
        // System.debug('projectId=' + projectId);
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        if (projectId != null) {
            // プロジェクト分類の取得
            for (ermt__Project_Classification_Junc__c pc : [
                SELECT ermt__M_Classification__c
                , ermt__M_Classification__r.ermt__GroupId__c
                , ermt__M_Classification__r.ermt__MaxNoOfSelectableItems__c
                FROM ermt__Project_Classification_Junc__c
                WHERE ermt__Project__c = :projectId
                AND ermt__M_Classification__r.RecordType.DeveloperName =
                    :System.Label.ClassiRecordType_RiskClassiGroup
                AND ermt__M_Classification__r.ermt__invalid__c = false
                ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
            ]) {
                Boolean hasReferPermission = true;
                Boolean hasEditPermission = true;
                String groupId = pc.ermt__M_Classification__r.ermt__GroupId__c;
                if (String.isNotEmpty(groupId)) {
                    String customPermissionName = System.Label.RiskClassi_ReferPermPrefix + groupId;
                    hasReferPermission = FeatureManagement.checkPermission(customPermissionName);
                    customPermissionName = System.Label.RiskClassi_EditPermPrefix + groupId;
                    hasEditPermission = FeatureManagement.checkPermission(customPermissionName);
                }
                if (hasReferPermission || Test.isRunningTest()) {
                    Integer inputType = 2;
                    ret.add(new Map<String, Object>{
                        'classiGroupId' => pc.ermt__M_Classification__c
                        , 'groupId' => pc.ermt__M_Classification__r.ermt__GroupId__c
                        , 'selectMax' => pc.ermt__M_Classification__r.ermt__MaxNoOfSelectableItems__c
                        , 'inputType' => inputType
                        , 'isEditable' => hasEditPermission
                    });
                }
            }
        }
        return ret;
    }

    // 分類IDリストの取得
    @AuraEnabled
    public static List<Id> getClassiIds(
        Id riskId
        , Id classiGroupId
    ) {
        // System.debug('riskId=' + riskId);
        // System.debug('classiGroupId=' + classiGroupId);
        List<Id> ret = new List<Id>();
        // リスク分類の取得
        for (ermt__Risk_Classification_Junc__c rc : [
            SELECT ermt__M_Classification__c
            FROM ermt__Risk_Classification_Junc__c
            WHERE ermt__Risk__c = :riskId
            AND ermt__M_Classification__r.ermt__ParentMClassification_del__c = :classiGroupId
            AND ermt__M_Classification__r.RecordType.DeveloperName = :System.Label.ClassiRecordType_Choice
            AND ermt__M_Classification__r.ermt__invalid__c = false
            ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
        ]) {
            ret.add(rc.ermt__M_Classification__c);
        }
        return ret;
    }

    // リスク分類の更新
    @AuraEnabled
	public static Boolean updateRiskClassi(
        Id riskId
        , Id classiGroupId
        , List<Id> classiIds
    ) {
        // System.debug('riskId=' + riskId);
        // System.debug('classiGroupId=' + classiGroupId);
        // System.debug('classiIds=' + classiIds);

        Boolean ret = false;
        Savepoint sp = Database.setSavepoint();
		try {
            if (Schema.SObjectType.ermt__Risk_Classification_Junc__c.isCreateable() &&
                Schema.SObjectType.ermt__Risk_Classification_Junc__c.isDeletable() &&
                Schema.SObjectType.ermt__Risk_Classification_Junc__c.fields.ermt__Risk__c.isCreateable() &&
                Schema.SObjectType.ermt__Risk_Classification_Junc__c.fields.ermt__M_Classification__c.isCreateable()
            ) {
                if (riskId != null) {
                    if (classiGroupId != null) {
                        List<ermt__Risk_Classification_Junc__c> delete_riskClassis;
                        delete_riskClassis = [
                            SELECT Id FROM ermt__Risk_Classification_Junc__c
                            WHERE ermt__Risk__c = :riskId
                            AND ermt__M_Classification__r.ermt__ParentMClassification_del__c = :classiGroupId
                        ];
                        if (!delete_riskClassis.isEmpty()) {
                            if (ermt__Risk_Classification_Junc__c.sObjectType.getDescribe().isDeletable()) {
                                delete delete_riskClassis;
                            }
                        }
                    }
                    if (classiIds != null && !classiIds.isEmpty()) {
                        List<ermt__Risk_Classification_Junc__c> insert_riskClassis;
                        insert_riskClassis = new List<ermt__Risk_Classification_Junc__c>();
                        for (Id classiId : classiIds) {
                            insert_riskClassis.add(new ermt__Risk_Classification_Junc__c(
                                ermt__Risk__c = riskId
                                , ermt__M_Classification__c = classiId
                            ));
                        }
                        if (!insert_riskClassis.isEmpty()) {
                            insert insert_riskClassis;
                        }
                    }
                }
            }
            ret = true;
		} catch(Exception ex) {
            Database.rollback(sp);
            throw new CustomException(ex.getMessage(), ex);
        }
        return ret;
    }
}