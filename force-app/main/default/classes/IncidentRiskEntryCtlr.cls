/**
 * インシデントリスク登録コントローラ
 */
public with sharing class IncidentRiskEntryCtlr {
    // インシデントリスク登録設定の取得
    @AuraEnabled(cacheable=true)
	public static ermt__IncidentRiskEntrySetting__mdt getIncidentRiskEntrySetting() {
        String name = 'ermt__Default';
        String query = '';
        query += 'SELECT ermt__RiskSearchFieldNames__c';
        query += ', ermt__RiskDisplayFieldNames__c';
        query += ', ermt__RiskSelectLimit__c';
        query += ', ermt__RiskPageSize__c';
        query += ' FROM ermt__IncidentRiskEntrySetting__mdt';
        query += ' WHERE QualifiedApiName = :name LIMIT 1';
        List<ermt__IncidentRiskEntrySetting__mdt> recs = Database.query(query);
        return (recs.isEmpty() ? null : recs[0]);
    }

    // インシデントの取得
    @AuraEnabled(cacheable=true)
    public static ermt__Incident__c getIncident(Id incidentId) {
        String query = '';
        query += 'SELECT Name, ermt__Title__c, ermt__Organization__c';
        query += ', UserRecordAccess.HasEditAccess';
        query += ' FROM ermt__Incident__c';
        query += ' WHERE Id = :incidentId LIMIT 1';
        List<ermt__Incident__c> recs = Database.query(query);
        return (recs.isEmpty() ? null : recs[0]);
    }

    // リスク項目定義リストの取得
    @AuraEnabled(cacheable=true)
    public static List<FieldDefine> getRiskFieldDefines(
        List<String> displayFieldNames
    ) {
        List<FieldDefine> fieldDefs = new List<FieldDefine>();
        SObjectType sObjType = ermt__Risk__c.getSObjectType();
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

    // リスクリストの取得
    @AuraEnabled
	public static List<ermt__Risk__c> getRisks(
        Id incidentId // インシデントID
        , List<FieldDefine> fieldDefs // 項目定義リスト
        , String registerType // 登録種別
        , List<Map<String, Object>> searchConds // 検索条件リスト
        , String searchCondLogic // 検索条件ロジック
        , Integer selectLimit // レコード取得限度数
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('fieldDefs=' + fieldDefs);
        // System.debug('registerType=' + registerType);
        // System.debug('searchConds=' + searchConds);
        // System.debug('searchCondLogic=' + searchCondLogic);
        // System.debug('selectLimit=' + selectLimit);
        // クエリーSELECT句の作成
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
                'ermt__Risk__c'    
                , searchConds
                , searchCondLogic
            );
        }
        // クエリーWHERE句の作成
        String queryWhere = '';
        if (String.isNotEmpty(registerType) && registerType != System.Label.Label_All) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += (registerType == System.Label.Label_Registered ? 'Id IN ' : 'Id NOT IN ');
            queryWhere += '(SELECT ermt__Risk__c FROM ermt__Incident_Risk_Junc__c';
            queryWhere += ' WHERE ermt__Incident__c = :incidentId)';
        }
        if (String.isNotEmpty(searchCondExp)) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += '(' + searchCondExp + ')';
        }
        // リスクの取得
        String query = '';
        query += 'SELECT ' + querySelect;
        query += ', (SELECT Id FROM ermt__Incident_Risk_Juncs__r';
        query += ' WHERE ermt__Incident__c = :incidentId';
        query += ' LIMIT 1';
        query += ')';
        query += ', UserRecordAccess.HasEditAccess';
        query += ' FROM ermt__Risk__c';
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        query += ' ORDER BY Name';
        query += ' LIMIT :selectLimit';
        //System.debug('query=' + query);
        return Database.query(query);
    }

    // インシデントリスクの登録
    @AuraEnabled
    public static Boolean registerIncidentRisk(
        Id incidentId // インシデントID
        , List<Id> riskIds // リスクIDリスト
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('riskIds=' + riskIds);

        // インシデントリスクの取得
        // リスクIDセットの作成
        Set<Id> riskIdSet = new Set<Id>();
        for (ermt__Incident_Risk_Junc__c ir : [
            SELECT ermt__Risk__c
            FROM ermt__Incident_Risk_Junc__c
            WHERE ermt__Incident__c = :incidentId
            AND ermt__Risk__c IN :riskIds
        ]) {
            riskIdSet.add(ir.ermt__Risk__c);
        }

        // 追加用インシデントリスクリストの作成
        List<ermt__Incident_Risk_Junc__c> insertIncRisk = new List<ermt__Incident_Risk_Junc__c>();
        for (Id riskId : riskIds) {
            if (!riskIdSet.contains(riskId)) {
                insertIncRisk.add(new ermt__Incident_Risk_Junc__c(
                    ermt__Incident__c = incidentId
                    , ermt__Risk__c = riskId
                ));
            }
        }

        // インシデントリスクの追加
        if (!insertIncRisk.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Risk_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isCreateable()) {
                insert insertIncRisk;
            }
        }

        return true;
    }

    // インシデントリスクの削除
    @AuraEnabled
    public static Boolean deleteIncidentRisk(
        Id incidentId // インシデントID
        , List<Id> riskIds // リスクIDリスト
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('riskIds=' + riskIds);

        // インシデントリスクの取得
        // 削除用インシデントリスクリストの作成
        List<ermt__Incident_Risk_Junc__c> deleteIncRisk = [
            SELECT Id
            FROM ermt__Incident_Risk_Junc__c
            WHERE ermt__Incident__c = :incidentId
            AND ermt__Risk__c IN :riskIds
        ];
        
        // インシデントリスクの削除
        if (!deleteIncRisk.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Risk_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isDeletable()) {
                delete deleteIncRisk;
            }
        }

        return true;
    }

    // リスク対応策の登録
    @AuraEnabled
    public static Map<String, Object> registerRiskControl(
        Id incidentId // インシデントID
        , Id riskId // リスクID
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('riskId=' + riskId);

        Integer registerCount = 0;

        // インシデント対応策の取得
        // 対応策IDセットの作成
        Set<Id> controlIdSet = new Set<Id>();
        for (ermt__Incident_Control_Junc__c ic : [
            SELECT ermt__Control__c
            FROM ermt__Incident_Control_Junc__c
            WHERE ermt__Incident__c = :incidentId
        ]) {
            controlIdSet.add(ic.ermt__Control__c);
        }

        if (!controlIdSet.isEmpty()) {
            // リスク対応策の取得
            // 登録済み対応策IDセットの作成
            Set<Id> registerdControlIdSet = new Set<Id>();
            for (ermt__Risk_Control_Junc__c rc : [
                SELECT ermt__Control__c
                FROM ermt__Risk_Control_Junc__c
                WHERE ermt__Risk__c = :riskId
                AND ermt__Control__c IN :controlIdSet
            ]) {
                registerdControlIdSet.add(rc.ermt__Control__c);
            }

            // 追加用リスク対応策リストの作成
            List<ermt__Risk_Control_Junc__c> insertRiskCtls = new List<ermt__Risk_Control_Junc__c>();
            for (Id controlId : controlIdSet) {
                if (!registerdControlIdSet.contains(controlId)) {
                    insertRiskCtls.add(new ermt__Risk_Control_Junc__c(
                        ermt__Risk__c = riskId
                        , ermt__Control__c = controlId
                    ));
                }
            }
            System.debug(insertRiskCtls);

            // リスク対応策の追加
            if (!insertRiskCtls.isEmpty()) {
                SObjectType sObjType = ermt__Risk_Control_Junc__c.getSObjectType();
                DescribeSObjectResult descSObj = sObjType.getDescribe();
                if (descSObj.isCreateable()) {
                    insert insertRiskCtls;
                }
            }

            registerCount = insertRiskCtls.size();
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