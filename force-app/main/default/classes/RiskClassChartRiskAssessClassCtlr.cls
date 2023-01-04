/**
 * リスク分類チャート（リスクアセスメント分類軸）コントローラ
 */
public with sharing class RiskClassChartRiskAssessClassCtlr {
    // リスク分類チャートの設定の取得
    @AuraEnabled(cacheable=true)
	public static SObject getRiskClassChartSetting() {
        List<ermt__RiskClassChartSetting__mdt> settings = [
            SELECT ermt__RiskSearchFieldName__c
            , ermt__RiskAssessSearchFieldName__c
            FROM ermt__RiskClassChartSetting__mdt
            WHERE QualifiedApiName = 'ermt__Default'
            LIMIT 1
        ];

        return (settings.isEmpty() ? null : settings[0]);
    }

    // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の取得
    @AuraEnabled
	public static String getRiskClassChartRacBackColorInfo(
        Id projectId // プロジェクトID
    ) {
        List<ermt__Project__c> prjs = [
            SELECT ermt__RiskClassChartRacBackColorInfo__c
            FROM ermt__Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        
        return (prjs.isEmpty() ? null : prjs[0].ermt__RiskClassChartRacBackColorInfo__c);
    }

    // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の保存
    @AuraEnabled
	public static Boolean saveRiskClassChartRacBackColorInfo(
        Id projectId,  // プロジェクトID
        String backColorInfo // 背景色情報
    ) {
        ermt__Project__c prj = new ermt__Project__c(
            Id = projectId
            , ermt__RiskClassChartRacBackColorInfo__c = backColorInfo
        );

        SObjectType sObjType = ermt__Project__c.getSObjectType();
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        if (sObjDesc.isUpdateable()) {
            update prj;
        }

        return true;
    }

    // 分類グループリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getClassGroups(
        Id projectId // プロジェクトID
    ) {
        return [
            SELECT toLabel(ermt__Label_Pick__c)
            , ermt__Label__c
            FROM ermt__M_Classification__c
            WHERE Id IN (SELECT ermt__M_Classification__c
                FROM ermt__Project_Classification_Junc__c
                WHERE ermt__Project__c = :projectId
            )
            AND RecordType.DeveloperName IN (
                :System.Label.ClassiRecordType_Probability
                , :System.Label.ClassiRecordType_ResultImpact
                , :System.Label.ClassiRecordType_ThirdEvaluation
            )
            AND ermt__invalid__c = false
            ORDER BY ermt__ViewNo__c
        ];
    }

    // 分類リストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getClasses(
        Id classGroupId // 分類グループID
    ) {
        return [
            SELECT ermt__ViewNo__c
            FROM ermt__M_Classification__c
            WHERE ermt__ParentMClassification_del__c = :classGroupId
            AND RecordType.DeveloperName = :System.Label.ClassiRecordType_Choice
            AND ermt__invalid__c = false
        ];
    }

    // リスクリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRisks(
        Id projectId, // プロジェクトIDリスト
        List<Id> accountIds, // 組織・部門IDリスト
        List<Map<String, Object>> searchConds, // リスクの検索条件リスト
        String searchCondLogic, // リスクの検索条件ロジック
        Id previousLastId, // 前の最終ID
        Integer queryLimit // クエリーのリミット値
    ) {
        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__Risk__c', searchConds, searchCondLogic
            );
            if (String.isNotEmpty(searchCondExp)) {
                searchCondExp = ' AND (' + searchCondExp + ')';
            }
        }

        // リスクの取得
        String query = '';
        query += 'SELECT ermt__Organization__c';
        query += ', ermt__Organization__r.Name';
        query += ', ermt__Organization__r.ermt__RiskClassChartRacDataLabelBackColor__c';
        query += ' FROM ermt__Risk__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        if (!accountIds.isEmpty()) {
            query += ' AND ermt__Organization__c IN :accountIds';
        }
        query += ' AND ermt__Project__c = :projectId';
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Id';
        if (queryLimit != null) {
            query += ' LIMIT :queryLimit';
        }
        //System.debug('query=' + query);

        return Database.query(query);
    }

    // リスク分類リストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRiskClasses(
        List<Id> riskIds, // リスクIDリスト
        List<Id> classIds, // 分類IDリスト
        List<Id> classGroupIds, // 分類グループIDリスト
        Id previousLastId, // 前の最終ID
        Integer queryLimit // クエリーのリミット値
    ) {
        // リスク分類の取得
        String query = '';
        query += 'SELECT ermt__Risk__c';
        query += ', ermt__M_Classification__c';
        query += ', toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)';
        query += ', ermt__M_Classification__r.ermt__Label__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__c';
        query += ', toLabel(ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__Label_Pick__c)';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__Label__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__RiskClassChartRacDataLabelBackColor__c';
        query += ' FROM ermt__Risk_Classification_Junc__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        query += ' AND ermt__Risk__c IN :riskIds';
        if (!classIds.isEmpty() || !classGroupIds.isEmpty()) {
            query += ' AND (ermt__M_Classification__c IN :classIds';
            query += ' OR ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :classGroupIds)';
        }
        query += ' ORDER BY Id';
        if (queryLimit != null) {
            query += ' LIMIT :queryLimit';
        }
        //System.debug('query=' + query);

        return Database.query(query);
    }

    // リスク組織・部門リストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRiskAccounts(
        List<Id> riskIds, // リスクIDリスト
        List<Id> accountIds, // 組織・部門IDリスト
        Id previousLastId, // 前の最終ID
        Integer queryLimit // クエリーのリミット値
    ) {
        // リスク組織・部門の取得
        String query = '';
        query += 'SELECT ermt__Risk__c, ermt__Department__c';
        query += ', ermt__Department__r.Name';
        query += ', ermt__Department__r.ermt__RiskClassChartRacDataLabelBackColor__c';
        query += ' FROM ermt__Risk_Account_Junc__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        query += ' AND ermt__Risk__c IN :riskIds';
        if (!accountIds.isEmpty()) {
            query += ' AND ermt__Department__c IN :accountIds';
        }
        query += ' ORDER BY Id';
        if (queryLimit != null) {
            query += ' LIMIT :queryLimit';
        }
        //System.debug('query=' + query);

        return Database.query(query);
    }

    // リスクアセスメントリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRiskAssessments(
        List<Id> riskAssessmentIds, // リスクアセスメントIDリスト
        List<Id> riskIds, // リスクIDリスト
        List<Map<String, Object>> searchConds, // リスクの検索条件リスト
        String searchCondLogic, // リスクの検索条件ロジック
        Id previousLastId, // 前の最終ID
        Integer queryLimit // クエリーのリミット値
    ) {
        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__RiskAssessment__c', searchConds, searchCondLogic
            );
            if (String.isNotEmpty(searchCondExp)) {
                searchCondExp = ' AND (' + searchCondExp + ')';
            }
        }

        // リスクアセスメントの取得
        String query = '';
        query += 'SELECT ermt__Risk__c';
        query += ' FROM ermt__RiskAssessment__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        if (!riskAssessmentIds.isEmpty()) {
            query += ' AND Id IN :riskAssessmentIds';
        }
        if (!riskIds.isEmpty()) {
            query += ' AND ermt__Risk__c IN :riskIds';
        }
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Id';
        if (queryLimit != null) {
            query += ' LIMIT :queryLimit';
        }
        //System.debug('query=' + query);

        return Database.query(query);
    }

    // リスクアセスメント分類リストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRiskAssessmentClasses(
        List<Id> riskAssessmentIds, // リスクアセスメントIDリスト
        List<Id> riskIds, // リスクIDリスト
        List<Id> classIds, // 分類IDリスト
        List<Id> classGroupIds, // 分類グループIDリスト
        Id previousLastId, // 前の最終ID
        Integer queryLimit // クエリーのリミット値
    ) {
        // リスクアセスメント分類の取得
        String query = '';
        query += 'SELECT ermt__RiskAssessment__c';
        query += ', ermt__RiskAssessment__r.ermt__Risk__c';
        query += ', ermt__M_Classification__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__c';
        query += ', ermt__M_Classification__r.ermt__ViewNo__c';
        query += ' FROM ermt__RiskAssessment_Classification_Junc__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        if (!riskAssessmentIds.isEmpty()) {
            query += ' AND ermt__RiskAssessment__c IN :riskAssessmentIds';
        }
        if (!riskIds.isEmpty()) {
            query += ' AND ermt__RiskAssessment__r.ermt__Risk__c IN :riskIds';
        }
        if (!classIds.isEmpty()) {
            query += ' AND ermt__M_Classification__c IN :classIds';
        }
        if (!classGroupIds.isEmpty()) {
            query += ' AND ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :classGroupIds';
        }
        query += ' ORDER BY Id';
        if (queryLimit != null) {
            query += ' LIMIT :queryLimit';
        }
        //System.debug('query=' + query);

        return Database.query(query);
    }

}