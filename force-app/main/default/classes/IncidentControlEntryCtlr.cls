/**
 * インシデント対応策登録コントローラ
 */
public with sharing class IncidentControlEntryCtlr {
    // インシデント対応策登録設定の取得
    @AuraEnabled(cacheable=true)
	public static ermt__IncidentControlEntrySetting__mdt getIncidentControlEntrySetting() {
        String name = 'ermt__Default';
        String query = '';
        query += 'SELECT ermt__ControlSearchFieldNames__c';
        query += ', ermt__ControlDisplayFieldNames__c';
        query += ', ermt__ControlSelectLimit__c';
        query += ', ermt__ControlPageSize__c';
        query += ' FROM ermt__IncidentControlEntrySetting__mdt';
        query += ' WHERE QualifiedApiName = :name LIMIT 1';
        List<ermt__IncidentControlEntrySetting__mdt> recs = Database.query(query);
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

    // 対応策項目定義リストの取得
    @AuraEnabled(cacheable=true)
    public static List<FieldDefine> getControlFieldDefines(
        List<String> displayFieldNames
    ) {
        List<FieldDefine> fieldDefs = new List<FieldDefine>();
        SObjectType sObjType = ermt__Control__c.getSObjectType();
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

    // 対応策リストの取得
    @AuraEnabled
	public static List<ermt__Control__c> getControls(
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
                'ermt__Control__c'    
                , searchConds
                , searchCondLogic
            );
        }
        // クエリーWHERE句の作成
        String queryWhere = '';
        if (String.isNotEmpty(registerType) && registerType != System.Label.Label_All) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += (registerType == System.Label.Label_Registered ? 'Id IN ' : 'Id NOT IN ');
            queryWhere += '(SELECT ermt__Control__c FROM ermt__Incident_Control_Junc__c';
            queryWhere += ' WHERE ermt__Incident__c = :incidentId)';
        }
        if (String.isNotEmpty(searchCondExp)) {
            queryWhere += (String.isEmpty(queryWhere)? '' : ' AND ');
            queryWhere += '(' + searchCondExp + ')';
        }
        // 対応策の取得
        String query = '';
        query += 'SELECT ' + querySelect;
        query += ', (SELECT Id FROM ermt__Incident_Control_Juncs__r';
        query += ' WHERE ermt__Incident__c = :incidentId';
        query += ' LIMIT 1';
        query += ')';
        query += ', UserRecordAccess.HasEditAccess';
        query += ' FROM ermt__Control__c';
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        query += ' ORDER BY Name';
        query += ' LIMIT :selectLimit';
        //System.debug('query=' + query);
        return Database.query(query);
    }

    // インシデント対応策の登録
    @AuraEnabled
    public static Boolean registerIncidentControl(
        Id incidentId // インシデントID
        , List<Id> controlIds // 対応策IDリスト
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('controlIds=' + controlIds);

        // インシデント対応策の取得
        // 対応策IDセットの作成
        Set<Id> controlIdSet = new Set<Id>();
        for (ermt__Incident_Control_Junc__c ic : [
            SELECT ermt__Control__c
            FROM ermt__Incident_Control_Junc__c
            WHERE ermt__Incident__c = :incidentId
            AND ermt__Control__c IN :controlIds
        ]) {
            controlIdSet.add(ic.ermt__Control__c);
        }

        // 追加用インシデント対応策リストの作成
        List<ermt__Incident_Control_Junc__c> insertIncControl = new List<ermt__Incident_Control_Junc__c>();
        for (Id controlId : controlIds) {
            if (!controlIdSet.contains(controlId)) {
                insertIncControl.add(new ermt__Incident_Control_Junc__c(
                    ermt__Incident__c = incidentId
                    , ermt__Control__c = controlId
                ));
            }
        }

        // インシデント対応策の追加
        if (!insertIncControl.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Control_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isCreateable()) {
                insert insertIncControl;
            }
        }

        return true;
    }

    // インシデント対応策の削除
    @AuraEnabled
    public static Boolean deleteIncidentControl(
        Id incidentId // インシデントID
        , List<Id> controlIds // 対応策IDリスト
    ) {
        // System.debug('incidentId=' + incidentId);
        // System.debug('controlIds=' + controlIds);

        // インシデント対応策の取得
        // 削除用インシデント対応策リストの作成
        List<ermt__Incident_Control_Junc__c> deleteIncControl = [
            SELECT Id
            FROM ermt__Incident_Control_Junc__c
            WHERE ermt__Incident__c = :incidentId
            AND ermt__Control__c IN :controlIds
        ];
        
        // インシデント対応策の削除
        if (!deleteIncControl.isEmpty()) {
            SObjectType sObjType = ermt__Incident_Control_Junc__c.getSObjectType();
            DescribeSObjectResult descSObj = sObjType.getDescribe();
            if (descSObj.isDeletable()) {
                delete deleteIncControl;
            }
        }

        return true;
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