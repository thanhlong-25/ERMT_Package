// リスク分析の新規作成コントローラ
public with sharing class RiskAnalysisNewCreateCtlr {
    public class OrginalException extends Exception {} // 独自の例外クラス

    // ラベルマップの取得
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLabelMap() {
        Map<String, String> ret = new Map<String, String>();
        ret.put('title', System.Label.RiskAnalysisNewCreate_Title);
        ret.put('save', System.Label.RiskAnalysisNewCreate_Save);
        ret.put('save_success_title', System.Label.RiskAnalysisNewCreate_Save_Success_Title);
        ret.put('save_success_content', System.Label.RiskAnalysisNewCreate_Save_Success_Content);
        ret.put('save_error_title', System.Label.RiskAnalysisNewCreate_Save_Error_Title);
        ret.put('cancel', System.Label.RiskAnalysisNewCreate_Cancel);
        return ret;
    }

    // 設定の取得
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSetting() {
        Map<String, Object> ret = new Map<String, Object>();
        ermt__RiskAnalysisNewCreateSetting__c setting = ermt__RiskAnalysisNewCreateSetting__c.getOrgDefaults();
        List<SortRecord> sortRecs = new List<SortRecord>();
        sortRecs.add(new SortRecord(setting.ermt__AnalyseTimingDispOrder__c, 'analyseTimingDispOrder'));
        sortRecs.add(new SortRecord(setting.ermt__ProbabilityDispOrder__c, 'probabilityDispOrder'));
        sortRecs.add(new SortRecord(setting.ermt__ResultImpactDispOrder__c, 'resultImpactDispOrder'));
        sortRecs.add(new SortRecord(setting.ermt__ThirdEvaluationDispOrder__c, 'thirdEvaluationDispOrder'));
        sortRecs.sort();
        Integer cnt = 0;
        for (SortRecord sr : sortRecs) {
            cnt++;
            ret.put((String)sr.value, cnt);
        }
        return ret; 
    }

    // リスクアセスメントのレコードタイプIDの取得
    @AuraEnabled(cacheable=true)
    public static Id getRiskAssessRecTypeId(String recTypeName) {
        Id ret = null;
        Schema.DescribeSObjectResult sObjDesc = Schema.SObjectType.ermt__RiskAssessment__c;
        Schema.RecordTypeInfo recTypeInfo = sObjDesc.getRecordTypeInfosByDeveloperName().get(recTypeName);
        if (recTypeInfo != null) {
            ret = recTypeInfo.getRecordTypeId();
        }
        return ret;
    }

    // リスクアセスメントの取得
    @AuraEnabled
    public static ermt__RiskAssessment__c getRiskAssess(
        Id riskAssessId
    ) {
        // System.debug('riskAssessId=' + riskAssessId);
        ermt__RiskAssessment__c ret = null;
        if (riskAssessId != null) {
            String fieldNames = CommonUtil.getSoqlCreateableFieldNames('ermt__RiskAssessment__c', true);
            if (String.isNotEmpty(fieldNames)) {
                String soql = 'SELECT';
                soql += ' ' + fieldNames;
                soql += ' FROM ermt__RiskAssessment__c';
                soql += ' WHERE Id = :riskAssessId';
                soql += ' LIMIT 1';
                for (ermt__RiskAssessment__c ra : Database.query(soql)) {
                    ret = ra;
                }
            }
        }
        return ret;
    }

    // 分類・評価軸IDの取得
    @AuraEnabled
    public static Id getClassiId(
        Id riskAssessId
        , Id parentClassiId
    ) {
        // System.debug('riskAssessId=' + riskAssessId);
        // System.debug('parentClassiId=' + parentClassiId);
        Id ret = null;
        if (riskAssessId != null && parentClassiId != null) {
            for (ermt__RiskAssessment_Classification_Junc__c rcj : [
                SELECT ermt__M_Classification__c
                FROM ermt__RiskAssessment_Classification_Junc__c
                WHERE ermt__RiskAssessment__c = :riskAssessId
                AND ermt__M_Classification__r.ermt__ParentMClassification_del__c = :parentClassiId
                ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
                LIMIT 1
            ]) {
                ret = rcj.ermt__M_Classification__c;
            }
        }
        return ret;
    }

    // リスクアセスメント分類・評価軸連携の更新
    @AuraEnabled
	public static Boolean updateRiskAssessClassi(
        Id riskAssessId
        , Id classiId
        , Id parentClassiId
    ) {
        // System.debug('riskAssessId=' + riskAssessId);
        // System.debug('classiId=' + classiId);
        // System.debug('parentClassiId=' + parentClassiId);

        Boolean ret = false;
        Savepoint sp = Database.setSavepoint();
		try {
            if (riskAssessId != null) {
                if (parentClassiId != null) {
                    List<ermt__RiskAssessment_Classification_Junc__c> delRskClss;
                    delRskClss = [
                        SELECT Id FROM ermt__RiskAssessment_Classification_Junc__c
                        WHERE ermt__RiskAssessment__c = :riskAssessId
                        AND ermt__M_Classification__r.ermt__ParentMClassification_del__c = :parentClassiId
                    ];
                    if (!delRskClss.isEmpty()) {
                        delete delRskClss;
                    }
                }
                if (classiId != null) {
                    ermt__RiskAssessment_Classification_Junc__c insRskCls;
                    insRskCls = new ermt__RiskAssessment_Classification_Junc__c(
                        ermt__RiskAssessment__c = riskAssessId
                        , ermt__M_Classification__c = classiId
                    );
                    insert insRskCls;
                }
            }
            ret = true;
		} catch(Exception ex) {
            Database.rollback(sp);
            throw new OrginalException(ex.getMessage(), ex);
        }
        return ret;
    }

    // リスクアセスメントの削除
    @AuraEnabled
    public static Boolean deleteRiskAssess(
        Id riskAssessId
    ) {
        // System.debug('riskAssessId=' + riskAssessId);
        if (riskAssessId != null) {
            // 削除用リスクアセスメントの作成
            ermt__RiskAssessment__c delRiskAssess = null;
            for (ermt__RiskAssessment__c ra : [
                SELECT Id FROM ermt__RiskAssessment__c
                WHERE Id = :riskAssessId
                LIMIT 1
            ]) {
                delRiskAssess = ra;
            }

            // リスクアセスメントの削除
            if (delRiskAssess != null) {
                delete delRiskAssess;
            }
        }
        return true;
    }
    
    // ソートレコードクラス
    public class SortRecord implements Comparable {
        public Decimal sortNo; // ソート番号
        public Object value; // 値

        // コンストラクタ
        public SortRecord(Decimal sortNo, Object value) {
            this.sortNo = sortNo;
            this.value = value;
        }

        // 比較関数
        public Integer compareTo(Object obj) {
            SortRecord sortRec = (SortRecord)obj;
            if (this.sortNo > sortRec.sortNo) return 1;
            if (this.sortNo < sortRec.sortNo) return -1;
            return 0;    
        }
    }
}