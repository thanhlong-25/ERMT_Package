// リスクアセスメント分類のコンボボックスコントローラ
public with sharing class RiskAssessmentClassiComboboxCtlr {
    // 分類・評価軸の選択リスト情報の取得
    @AuraEnabled(cacheable=true)
    public static ClassiSelsInfo getClassiSelsInfo(
        String classiGroupRecordTypeName // 分類・評価軸グループのレコードタイプ名
        , Id projectId // プロジェクトID
        , Boolean isOptionsBlankAdd // 選択リストに空白を追加するか
    ) {
        ClassiSelsInfo ret = new ClassiSelsInfo();
        if (projectId == null) {
            if (classiGroupRecordTypeName == System.Label.ClassiRecordType_AnalyseTiming) {
                ret.label = System.Label.ClassiGroupLabel_AnalyseTiming;
            } else if (classiGroupRecordTypeName == System.Label.ClassiRecordType_Probability) {
                ret.label = System.Label.ClassiGroupLabel_Probability;
            } else if (classiGroupRecordTypeName == System.Label.ClassiRecordType_ResultImpact) {
                ret.label = System.Label.ClassiGroupLabel_ResultImpact;
            } else if (classiGroupRecordTypeName == System.Label.ClassiRecordType_ThirdEvaluation) {
                ret.label = System.Label.ClassiGroupLabel_ThirdEvaluation;
            }
            if (isOptionsBlankAdd) {
                ret.options.add(new Map<String, String>{
                    'label' => Label.Input_NotSelected
                    , 'value' => ''
                });
            }

            // 分類・評価軸設定の取得
            String query = '';
            query += 'SELECT ermt__Label__c, toLabel(ermt__Label_Pick__c)';
            query += ' FROM ermt__M_Classification__c';
            query += ' WHERE RecordType.DeveloperName = \'' + String.escapeSingleQuotes(System.Label.ClassiRecordType_Choice) + '\'';
            query += ' AND ermt__ParentMClassification_del__r.RecordType.DeveloperName = :classiGroupRecordTypeName';
            query += ' AND ermt__invalid__c = false';
            query += ' ORDER BY ermt__ViewNo__c';
            for (ermt__M_Classification__c c : Database.query(query)) {
                ret.options.add(new Map<String, String>{
                    'label' => String.isNotBlank(c.ermt__Label_Pick__c) ? c.ermt__Label_Pick__c : c.ermt__Label__c
                    , 'value' => c.Id
                });
            }
        } else {
            // 分類・評価軸設定の取得
            String query = '';
            query += 'SELECT ermt__Label__c, toLabel(ermt__Label_Pick__c), ermt__Help_Text__c';
            query += ', (SELECT ermt__Label__c, toLabel(ermt__Label_Pick__c)';
            query += ' FROM MClassifications_del__r';
            query += ' WHERE ermt__invalid__c = false';
            query += ' AND RecordType.DeveloperName = \'' + String.escapeSingleQuotes(System.Label.ClassiRecordType_Choice) + '\'';
            query += ' ORDER BY ermt__ViewNo__c)';
            query += ' FROM ermt__M_Classification__c';
            query += ' WHERE Id IN (SELECT ermt__M_Classification__c';
            query += ' FROM ermt__Project_Classification_Junc__c';
            query += ' WHERE ermt__M_Classification__r.RecordType.DeveloperName = :classiGroupRecordTypeName';
            query += ' AND ermt__Project__c = :projectId';
            query += ')';
            query += ' AND ermt__invalid__c = false';
            query += ' ORDER BY ermt__ViewNo__c';
            query += ' LIMIT 1';
            for (ermt__M_Classification__c cg : Database.query(query)) {
                ret.classiGroupId = cg.Id;
                ret.label = String.isNotBlank(cg.ermt__Label_Pick__c) ? cg.ermt__Label_Pick__c : cg.ermt__Label__c;
                ret.helpText = cg.ermt__Help_Text__c;
                if (isOptionsBlankAdd) {
                    ret.options.add(new Map<String, String>{
                        'label' => Label.Input_NotSelected
                        , 'value' => ''
                    });
                }
                for (ermt__M_Classification__c c : cg.MClassifications_del__r) {
                    ret.options.add(new Map<String, String>{
                        'label' => String.isNotBlank(c.ermt__Label_Pick__c) ? c.ermt__Label_Pick__c : c.ermt__Label__c
                        , 'value' => c.Id
                    });
                }
            }
        }
        return ret;
    }

    // 分類選択情報クラス
    public class ClassiSelsInfo {
        @AuraEnabled public Id classiGroupId; // 分類グループID
        @AuraEnabled public String label; // 表示ラベル
        @AuraEnabled public String helpText; // ヘルプテキスト
        @AuraEnabled public List<Map<String, String>> options; // 選択リスト

        // コンストラクタ
        public ClassiSelsInfo() {
            this.classiGroupId = null;
            this.label = null;
            this.helpText = null;
            this.options = new List<Map<String, String>>();
        }
    }
}