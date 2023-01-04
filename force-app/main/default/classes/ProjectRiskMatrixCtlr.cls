// プロジェクトのリスクマトリックスコントローラ
public with sharing class ProjectRiskMatrixCtlr {
    private static final Integer QURETY_LIMIT = 1000; // クエリーのリミット値

    // 分類・評価軸のグループ選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGroupClassiSels(
        Id projectId // プロジェクトID
        , String classiGroupRecordTypeName // 分類・評価軸グループのレコードタイプ名
        , Boolean isOptionsBlankAdd // 選択リストに空白を追加するか
    ) {
        List<Map<String, String>> ret = new List<Map<String, String>>();

        // 選択リストに空白を追加
        if (isOptionsBlankAdd) {
            ret.add(new Map<String, String>{
                'label' => ''
                , 'value' => ''
            });
        }

        // 分類・評価軸設定の取得
        for (ermt__Project_Classification_Junc__c pcj : [
            SELECT ermt__M_Classification__c
            , toLabel(ermt__M_Classification__r.ermt__Kind__c)
            , toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)
            , ermt__M_Classification__r.ermt__Label__c
            FROM ermt__Project_Classification_Junc__c
            WHERE ermt__Project__c = :projectId
            AND ermt__M_Classification__r.RecordType.DeveloperName = :classiGroupRecordTypeName
            AND ermt__M_Classification__r.ermt__invalid__c = false
            ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
        ]) {
            String label = '';
            if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Kind__c)) {
                label += pcj.ermt__M_Classification__r.ermt__Kind__c;
            }
            if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Label_Pick__c)) {
                label += (String.isEmpty(label) ? '' : ': ');
                label += pcj.ermt__M_Classification__r.ermt__Label_Pick__c;
            } else if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Label__c)) {
                label += (String.isEmpty(label) ? '' : ': ');
                label += pcj.ermt__M_Classification__r.ermt__Label__c;
            }
            label = (String.isEmpty(label) ? System.Label.Select_NotSet : label);
            ret.add(new Map<String, String>{
                'label' => label
                , 'value' => pcj.ermt__M_Classification__c
            });
        }
        return ret;
    }

    // 分類・評価軸リストの取得
    @AuraEnabled(cacheable=true)
    public static List<ermt__M_Classification__c> getClassis(
        Id classiGroupId // 分類・評価軸グループID
    ) {
        List<ermt__M_Classification__c> ret = new List<ermt__M_Classification__c>();
        if (classiGroupId != null) {
            ret = [
                SELECT toLabel(ermt__Label_Pick__c)
                , ermt__Label__c
                FROM ermt__M_Classification__c
                WHERE ermt__ParentMClassification_del__c = :classiGroupId
                AND ermt__invalid__c = false
                ORDER BY ermt__ViewNo__c
            ];
        }
        return ret;
    }

    // リスクマトリックスのセル色の取得
    @AuraEnabled
	public static String getRiskMatrixCellColor(
        Id projectId // プロジェクトID
    ) {
        String ret = null;
        for (ermt__Project__c p : [
            SELECT ermt__RiskMatrixCellColor__c
            FROM ermt__Project__c
            WHERE Id = :projectId
            LIMIT 1
        ]) {
            ret = p.ermt__RiskMatrixCellColor__c;
        }
        return ret;
    }

    // リスクマトリックスのセル色の保存
    @AuraEnabled
	public static Boolean saveRiskMatrixCellColor(
        Id projectId // プロジェクトID
        , String cellColor // セル色
    ) {
        ermt__Project__c prj = new ermt__Project__c(
            Id = projectId
            , ermt__RiskMatrixCellColor__c = cellColor
        );
        update prj;
        return true;
    }

    // リスクリストの取得
    @AuraEnabled
    public static Map<String, Object> getRisks(
        Id projectId // プロジェクトID
        , List<Id> accountIds // 部門・組織IDリスト
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

        // リスクの取得
        String query = '';
        query += 'SELECT Id, Name';
        query += ', (SELECT ermt__M_Classification__c';
        query += ' FROM ermt__Risk_Classification_Junc__r)';
        query += ' FROM ermt__Risk__c';
        query += ' WHERE ermt__Project__c = :projectId';
        if (String.isNotEmpty(previousLastId) && String.isNotEmpty(previousLastName)) {
            query += ' AND (Name > :previousLastName';
            query += ' OR (Name = :previousLastName AND Id > :previousLastId))';
        }
        if (accountIds != null && !accountIds.isEmpty()) {
            query += ' AND ermt__Organization__c IN :accountIds';
        }
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Name, Id';
        query += ' LIMIT :QURETY_LIMIT';
        List<ermt__Risk__c> data = new List<ermt__Risk__c>();
        Id lastId = null;
        String lastName = null;
        Integer cnt = 0;
        for (ermt__Risk__c r : Database.query(query)) {
            data.add(r);
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

    // リスクアセスメントリストマップの取得
    @AuraEnabled
    public static Map<String, Object> getRiskAssessmentsByRiskId(
        Id projectId // プロジェクトID
        , Id analyseTimingClassiId // 分析タイミングの分類・評価軸ID
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
        if (analyseTimingClassiId != null) {
            query += ', (SELECT Id';
            query += ' FROM ermt__RiskAssessment_Classification_Junc__r';
            query += ' WHERE ermt__M_Classification__c = :analyseTimingClassiId)';
        }
        query += ' FROM ermt__RiskAssessment__c';
        query += ' WHERE ermt__Risk__r.ermt__Project__c = :projectId';
        if (String.isNotEmpty(previousLastId)) {
            query += ' AND Id > :previousLastId';
        }
        if (String.isNotEmpty(searchCondExp)) {
            query += searchCondExp;
        }
        query += ' ORDER BY Id';
        query += ' LIMIT :QURETY_LIMIT';
        //System.debug('query=' + query);
        Map<Id, List<ermt__RiskAssessment__c>> data = new Map<Id, List<ermt__RiskAssessment__c>>();
        Id lastId = null;
        Integer cnt = 0;
        for (ermt__RiskAssessment__c ra : Database.query(query)) {
            Id riskId = ra.ermt__Risk__c;

            // 対象の判定
            Boolean isTarget = true;
            if (analyseTimingClassiId != null) {
                isTarget = !ra.ermt__RiskAssessment_Classification_Junc__r.isEmpty();
            }
            if (isTarget) {
                List<ermt__RiskAssessment__c> riskAsss = data.get(riskId);
                if (riskAsss == null) {
                    riskAsss = new List<ermt__RiskAssessment__c>();
                    data.put(riskId, riskAsss);
                }
                riskAsss.add(ra);
            }
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