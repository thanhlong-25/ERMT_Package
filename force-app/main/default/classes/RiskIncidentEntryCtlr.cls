public with sharing class RiskIncidentEntryCtlr {
    //get incident risk entry setting
    @AuraEnabled(cacheable=true)
	public static ermt__RiskIncidentEntrySetting__mdt getRiskIncidentEntrySetting() {
        List<ermt__RiskIncidentEntrySetting__mdt> recs = [SELECT ermt__IncidentDisplayFieldNames__c, ermt__IncidentPageSize__c, ermt__IncidentSearchFieldNames__c, ermt__IncidentSelectLimit__c FROM ermt__RiskIncidentEntrySetting__mdt WHERE QualifiedApiName = 'ermt__Default' LIMIT 1];
        return (recs.isEmpty() ? null : recs[0]);
    }

    //get risk by record id
    @AuraEnabled(cacheable=true)
    public static ermt__Risk__c getRisk(Id riskId) {
        List<ermt__Risk__c> recs = [SELECT Id, Name, ermt__Organization__c, UserRecordAccess.HasEditAccess FROM ermt__Risk__c WHERE Id = :RiskId LIMIT 1];
        return (recs.isEmpty() ? null : recs[0]);
    }

    //get risk fields define
    @AuraEnabled(cacheable=true)
    public static List<FieldDefine> getIncidentFieldDefines(List<String> displayFieldNames) {
        List<FieldDefine> fieldDefs = new List<FieldDefine>();
        SObjectType sObjType = ermt__Incident__c.getSObjectType();
        for (String fieldName : displayFieldNames) {
            DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
            if (fieldDesc != null && fieldDesc.isAccessible()) {
                String parentNameFieldName = CommonUtil.getParentNameFieldName(fieldName, fieldDesc);
                fieldDefs.add(new FieldDefine(
                    fieldName
                    , parentNameFieldName
                    , fieldDesc.getLabel()
                    , String.valueOf(fieldDesc.getType())
                ));
            }
        }
        return fieldDefs;
    }

    //get list incident with conditions
    @AuraEnabled
    public static List<ermt__Incident__c> getIncidents(
        Id riskId
        , List<FieldDefine> fieldDefs // 項目定義リスト
        , String registerType // 登録種別
        , List<Map<String, Object>> searchConds // 検索条件リスト
        , String searchCondLogic // 検索条件ロジック
        , Integer selectLimit // レコード取得限度数
    ) {
        String querySelect = '';
        for (FieldDefine fd : fieldDefs) {
            Boolean isToLabel = (
                fd.fieldType == String.valueOf(Schema.DisplayType.PICKLIST) ||
                fd.fieldType == String.valueOf(Schema.DisplayType.MULTIPICKLIST)
            );
            querySelect += (String.isEmpty(querySelect)? '' : ', ');
            querySelect += (isToLabel ? 'toLabel(' : '');
            querySelect += fd.fieldName;
            querySelect += (isToLabel ? ')' : '');
            if (String.isNotEmpty(fd.parentNameFieldName)) {
                querySelect += (String.isEmpty(querySelect)? '' : ', ');
                querySelect += fd.parentNameFieldName;
            }
        }
        querySelect = (String.isEmpty(querySelect) ? 'Id' : querySelect);
        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__Incident__c'    
                , searchConds
                , searchCondLogic
            );
        }
        // クエリーWHERE句の作成
        String queryWhere = '';
        if (String.isNotEmpty(registerType) && registerType != System.Label.Label_All) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += (registerType == System.Label.Label_Registered ? 'Id IN ' : 'Id NOT IN ');
            queryWhere += '(SELECT ermt__Incident__c FROM ermt__Incident_Risk_Junc__c';
            queryWhere += ' WHERE ermt__Risk__c = :riskId)';
        }
        if (String.isNotEmpty(searchCondExp)) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += '(' + searchCondExp + ')';
        }
        // リスクの取得
        String query = '';
        query += 'SELECT ' + querySelect;
        query += ', (SELECT Id FROM ermt__Incident_Risk_Juncs__r';
        query += ' WHERE ermt__Risk__c = :riskId';
        query += ' LIMIT 1';
        query += ')';
        query += ', UserRecordAccess.HasEditAccess';
        query += ' FROM ermt__Incident__c';
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        query += ' ORDER BY Name';
        query += ' LIMIT :selectLimit';
        List<ermt__Incident__c> incs = Database.query(query);
        System.debug(query);
        return Database.query(query);
    }

    //register risk incident
    @AuraEnabled
    public static Boolean registerRiskIncident(Id riskId, List<Id> incidentIds) {
        // インシデントリスクの取得
        // リスクIDセットの作成
        Set<Id> incidentIdSet = new Set<Id>();
        for (ermt__Incident_Risk_Junc__c ir : [
            SELECT ermt__Incident__c
            FROM ermt__Incident_Risk_Junc__c
            WHERE ermt__Risk__c = :riskId
            AND ermt__Incident__c IN :incidentIds
        ]) {
            incidentIdSet.add(ir.ermt__Incident__c);
        }

        // 追加用インシデントリスクリストの作成
        List<ermt__Incident_Risk_Junc__c> insertRiskInc = new List<ermt__Incident_Risk_Junc__c>();
        for (Id incidentId : incidentIds) {
            if (!incidentIdSet.contains(incidentId)) {
                insertRiskInc.add(new ermt__Incident_Risk_Junc__c(
                    ermt__Incident__c = incidentId
                    , ermt__Risk__c = riskId
                ));
            }
        }

        // インシデントリスクの追加
        if (!insertRiskInc.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Risk_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isCreateable()) {
                insert insertRiskInc;
            }
        }
        return true;
    }

    //delete risk incident
    @AuraEnabled
    public static Boolean deleteRiskIncident(Id riskId, List<Id> incidentIds) {
        // インシデントリスクの取得
        // 削除用インシデントリスクリストの作成
        List<ermt__Incident_Risk_Junc__c> deleteRiskInc = [
            SELECT Id
            FROM ermt__Incident_Risk_Junc__c
            WHERE ermt__Risk__c = :riskId
            AND ermt__Incident__c IN :incidentIds
        ];
        
        // インシデントリスクの削除
        if (!deleteRiskInc.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Risk_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isDeletable()) {
                delete deleteRiskInc;
            }
        }
        return true;
    }

    //register incident control
    @AuraEnabled
    public static Map<String, Object> registerIncidentControl(Id riskId, Id incidentId) {
        Integer registerCount = 0;

        // インシデント対応策の取得
        // 対応策IDセットの作成
        Set<Id> controlIdSet = new Set<Id>();
        for (ermt__Risk_Control_Junc__c ic : [
            SELECT ermt__Control__c
            FROM ermt__Risk_Control_Junc__c
            WHERE ermt__Risk__c = :riskId
        ]) {
            controlIdSet.add(ic.ermt__Control__c);
        }

        if (!controlIdSet.isEmpty()) {
            // リスク対応策の取得
            // 登録済み対応策IDセットの作成
            Set<Id> registerdControlIdSet = new Set<Id>();
            for (ermt__Incident_Control_Junc__c rc : [
                SELECT ermt__Control__c
                FROM ermt__Incident_Control_Junc__c
                WHERE ermt__Incident__c = :incidentId
                AND ermt__Control__c IN :controlIdSet
            ]) {
                registerdControlIdSet.add(rc.ermt__Control__c);
            }

            // 追加用リスク対応策リストの作成
            List<ermt__Incident_Control_Junc__c> insertIncCtls = new List<ermt__Incident_Control_Junc__c>();
            for (Id controlId : controlIdSet) {
                if (!registerdControlIdSet.contains(controlId)) {
                    insertIncCtls.add(new ermt__Incident_Control_Junc__c(
                        ermt__Incident__c = incidentId
                        , ermt__Control__c = controlId
                    ));
                }
            }

            // リスク対応策の追加
            if (!insertIncCtls.isEmpty()) {
                SObjectType sObjType = ermt__Incident_Control_Junc__c.getSObjectType();
                DescribeSObjectResult descSObj = sObjType.getDescribe();
                if (descSObj.isCreateable()) {
                    insert insertIncCtls;
                }
            }

            registerCount = insertIncCtls.size();
        }

        return new Map<String, Object>{
            'registerCount' => registerCount
        };
    }

    // 項目定義クラス
    public class FieldDefine {
        @AuraEnabled public String fieldName {get; set;} // 項目名
        @AuraEnabled public String parentNameFieldName {get; set;} // 親名前項目名
        @AuraEnabled public String fieldLabel {get; set;} // 項目表示ラベル
        @AuraEnabled public String fieldType {get; set;} // 項目データ型
        // コンストラクタ
        public FieldDefine() {
            this(null, null, null, null);
        }
        // コンストラクタ
        public FieldDefine(
            String fieldName
            , String parentNameFieldName
            , String fieldLabel
            , String fieldType
        ) {
            this.fieldName = fieldName;
            this.parentNameFieldName = parentNameFieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
        }
    }
}