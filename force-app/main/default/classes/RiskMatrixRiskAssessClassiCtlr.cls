// リスクマトリックス（リスクアセスメント分類軸）コントローラ
public with sharing class RiskMatrixRiskAssessClassiCtlr {
    private static final Integer QURETY_LIMIT = 1000; // クエリーのリミット値

    // リスクマトリックスの設定の取得
    @AuraEnabled
	public static ermt__RiskMatrixSetting__mdt getRiskMatrixSetting() {
        ermt__RiskMatrixSetting__mdt ret = null;
        for (ermt__RiskMatrixSetting__mdt rms : [
            SELECT ermt__RiskSearchFieldName__c
            , ermt__RiskAssessSearchFieldName__c
            FROM ermt__RiskMatrixSetting__mdt
            WHERE QualifiedApiName = 'ermt__Default'
            LIMIT 1
        ]) {
            ret = rms;
        }
        return ret;
    }

    // リスクマトリックスのセル色の取得
    @AuraEnabled
	public static List<ermt__CellColor__c> getRiskMatrixCellColor(
        Id projectId // プロジェクトID
    ) {
        return [
            SELECT ermt__XCordinate__c, ermt__YCordinate__c
            , ermt__ColorCode__c, ermt__ColorLinkCode__c
            FROM ermt__CellColor__c
            WHERE ermt__Project__c = :projectId
        ];
    }

    // プロジェクト選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProjectSels() {
        List<Map<String, String>> ret = new List<Map<String, String>>();
        for (ermt__Project__c p : [
            SELECT Name
            FROM ermt__Project__c
            ORDER BY Name
        ]) {
            ret.add(new Map<String, String>{
                'label' => p.Name
                , 'value' => p.Id
            });
        }
        return ret;
    }

    // 分類・評価軸選択リストグループリストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getClassiSelsGroups(
        Id projectId // プロジェクトID
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        String query = '';
        query += 'SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c';
        query += ', ermt__GroupId__c';
        query += ', (SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c';
        query += ' FROM ermt__MClassifications_del__r';
        query += ' WHERE RecordType.DeveloperName = \'' +
            String.escapeSingleQuotes(System.Label.ClassiRecordType_Choice) + '\'';
        query += ' AND ermt__invalid__c = false';
        query += ' ORDER BY ermt__ViewNo__c)';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE Id IN (SELECT ermt__M_Classification__c';
        query += ' FROM ermt__Project_Classification_Junc__c';
        query += ' WHERE ermt__M_Classification__r.RecordType.DeveloperName = \'' +
            String.escapeSingleQuotes(System.Label.ClassiRecordType_RiskClassiGroup) + '\'';
        if (projectId != null) {
            query += ' AND ermt__Project__c = :projectId';
        }
        query += ')';
        query += ' AND ermt__invalid__c = false';
        query += ' ORDER BY ermt__ViewNo__c';
        for (ermt__M_Classification__c cg : Database.query(query)) {
            Boolean hasReferPermission = true;
            String groupId = cg.ermt__GroupId__c;
            if (String.isNotEmpty(groupId)) {
                String customPermissionName = System.Label.RiskClassi_ReferPermPrefix + groupId;
                hasReferPermission = FeatureManagement.checkPermission(customPermissionName);
            }
            if (hasReferPermission || Test.isRunningTest()) {
                List<Map<String, String>> options = new List<Map<String, String>>();
                for (ermt__M_Classification__c c : cg.ermt__MClassifications_del__r) {
                    options.add(new Map<String, String>{
                        'label' => (String.isNotEmpty(c.ermt__Label_Pick__c) ? c.ermt__Label_Pick__c : c.ermt__Label__c)
                        , 'value' => c.Id
                    });
                }
                ret.add(new Map<String, Object>{
                    'classiGroupId' => cg.Id
                    , 'groupId' => cg.ermt__GroupId__c
                    , 'label' => (String.isNotEmpty(cg.ermt__Label_Pick__c) ? cg.ermt__Label_Pick__c : cg.ermt__Label__c)
                    , 'options' => options
                });
            }
        }
        return ret;
    }

    // 軸選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAxisSels(
        Id projectId // プロジェクトID
    ) {
        List<Map<String, String>> ret = new List<Map<String, String>>();
        if (projectId == null) {
            ret.add(new Map<String, String>{
                'label' => System.Label.ClassiGroupLabel_Probability
                , 'value' => System.Label.ClassiRecordType_Probability
            });
            ret.add(new Map<String, String>{
                'label' => System.Label.ClassiGroupLabel_ResultImpact
                , 'value' => System.Label.ClassiRecordType_ResultImpact
            });
        } else {
            Map<String, String> labelByValue = new Map<String, String>();
            for (ermt__Project_Classification_Junc__c pcj : [
                SELECT toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)
                , ermt__M_Classification__r.ermt__Label__c
                , ermt__M_Classification__r.RecordType.DeveloperName
                FROM ermt__Project_Classification_Junc__c
                WHERE ermt__Project__c = :projectId
                AND ermt__M_Classification__r.RecordType.DeveloperName IN (
                    :System.Label.ClassiRecordType_Probability
                    , :System.Label.ClassiRecordType_ResultImpact
                )
                AND ermt__M_Classification__r.ermt__invalid__c = false
            ]) {
                String label = pcj.ermt__M_Classification__r.ermt__Label_Pick__c;
                label = (String.isNotEmpty(label) ? label : pcj.ermt__M_Classification__r.ermt__Label__c);
                labelByValue.put(
                    pcj.ermt__M_Classification__r.RecordType.DeveloperName
                    , label
                );
            }
            String label = labelByValue.get(System.Label.ClassiRecordType_Probability);
            label = (label != null ? label : System.Label.ClassiGroupLabel_Probability);
            ret.add(new Map<String, String>{
                'label' => label
                , 'value' => System.Label.ClassiRecordType_Probability
            });
            label = labelByValue.get(System.Label.ClassiRecordType_ResultImpact);
            label = (label != null ? label : System.Label.ClassiGroupLabel_ResultImpact);
            ret.add(new Map<String, String>{
                'label' => label
                , 'value' => System.Label.ClassiRecordType_ResultImpact
            });
        }
        return ret;
    }

    // 分類・評価軸リストの取得
    @AuraEnabled(cacheable=true)
    public static List<ermt__M_Classification__c> getClassis(
        String classiGroupRecordTypeName // 分類・評価軸グループのレコードタイプ名
        , List<Id> projectIds // プロジェクトIDリスト
    ) {
        String query = '';
        query += 'SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c, ermt__ViewNo__c';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE ermt__ParentMClassification_del__c';
        query += ' IN (SELECT ermt__M_Classification__c';
        query += ' FROM ermt__Project_Classification_Junc__c';
        query += ' WHERE ermt__M_Classification__r.RecordType.DeveloperName = :classiGroupRecordTypeName';
        if (projectIds != null && !projectIds.isEmpty()) {
            query += ' AND ermt__Project__c IN :projectIds';
        }
        query += ')';
        query += ' AND ermt__invalid__c = false';
        query += ' ORDER BY ermt__ViewNo__c';
        return Database.query(query);
    }

    // // 組織・部門リストの取得
    // @AuraEnabled
    // public static List<Account> getAccounts() {
    //     return [
    //         SELECT Name, ParentId
    //         FROM Account
    //         ORDER BY Name
    //     ];
    // }

    // リスクリストの取得
    @AuraEnabled
    public static Map<String, Object> getRisks(
        List<Id> projectIds // プロジェクトIDリスト
        , List<Id> accountIds // 部門・組織IDリスト
        , List<Id> classiIds // リスクの分類・評価軸IDリスト
        , List<Map<String, Object>> searchConds // リスクの検索条件リスト
        , String searchCondLogic // リスクの検索条件ロジック
        , Id previousLastId // 前の最終ID
        , String previousLastName // 前の最終名
    ) {
        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__Risk__c'    
                , searchConds
                , searchCondLogic
            );
            if (String.isNotEmpty(searchCondExp)) {
                searchCondExp = ' AND (' + searchCondExp + ')';
            }
        }

        // リスク、リスク分類の取得
        Boolean isClassiExist = (classiIds != null && !classiIds.isEmpty());
        String query = '';
        query += 'SELECT Name';
        if (isClassiExist) {
            query += ', (SELECT Id';
            query += ' FROM ermt__Risk_Classification_Junc__r';
            query += ' WHERE ermt__M_Classification__c IN :classiIds';
            query += ' LIMIT 1)';
        }
        query += ' FROM ermt__Risk__c';
        query += ' WHERE Id != null';
        if (String.isNotEmpty(previousLastId) && String.isNotEmpty(previousLastName)) {
            query += ' AND (Name > :previousLastName';
            query += ' OR (Name = :previousLastName AND Id > :previousLastId))';
        }
        if (projectIds != null && !projectIds.isEmpty()) {
            query += ' AND ermt__Project__c IN :projectIds';
        }
        if (accountIds != null && !accountIds.isEmpty()) {
            query += ' AND ermt__Organization__c IN :accountIds';
        }
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Name, Id';
        query += ' LIMIT :QURETY_LIMIT';
        //System.debug('query=' + query);
        List<ermt__Risk__c> data = new List<ermt__Risk__c>();
        Id lastId = null;
        String lastName = null;
        Integer cnt = 0;
        for (ermt__Risk__c r : Database.query(query)) {
            // 対象の判定
            Boolean isTarget = true;
            if (isClassiExist) {
                isTarget = !r.ermt__Risk_Classification_Junc__r.isEmpty();
            }
            if (isTarget) {
                data.add(r);
            }
            lastId = r.Id;
            lastName = r.Name;
            cnt++;
        }
        Boolean isContinue = (cnt >= QURETY_LIMIT);
        return new Map<String, Object>{
            'data' => data
            , 'lastId' => lastId
            , 'lastName' => lastName
            , 'isContinue' => isContinue
        };
    }

    // リスクアセスメントリストの取得
    @AuraEnabled
    public static Map<String, Object> getRiskAssessments(
        List<Id> projectIds // プロジェクトIDリスト
        , List<Map<String, Object>> searchConds // 検索条件リスト
        , String searchCondLogic // 検索条件ロジック
        , Id previousLastId // 前の最終ID
    ) {
        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__RiskAssessment__c'    
                , searchConds
                , searchCondLogic
            );
            if (String.isNotEmpty(searchCondExp)) {
                searchCondExp = ' AND (' + searchCondExp + ')';
            }
        }

        // リスクアセスメント、リスクアセスメント分類の取得
        String query = '';
        query += 'SELECT ermt__Risk__c';
        query += ', (SELECT ermt__M_Classification__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName';
        query += ', ermt__M_Classification__r.ermt__ViewNo__c';
        query += ' FROM ermt__RiskAssessment_Classification_Junc__r)';
        query += ' FROM ermt__RiskAssessment__c';
        query += ' WHERE ermt__Risk__c != null';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        if (projectIds != null && !projectIds.isEmpty()) {
            query += ' AND ermt__Risk__r.ermt__Project__c IN :projectIds';
        }
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Id';
        query += ' LIMIT :QURETY_LIMIT';
        //System.debug('query=' + query);
        List<ermt__RiskAssessment__c> data = new List<ermt__RiskAssessment__c>();
        Id lastId = null;
        Integer cnt = 0;
        for (ermt__RiskAssessment__c ra : Database.query(query)) {
            data.add(ra);
            lastId = ra.Id;
            cnt++;
        }
        Boolean isContinue = (cnt >= QURETY_LIMIT);
        return new Map<String, Object>{
            'data' => data
            , 'lastId' => lastId
            , 'isContinue' => isContinue
        };
    }
}