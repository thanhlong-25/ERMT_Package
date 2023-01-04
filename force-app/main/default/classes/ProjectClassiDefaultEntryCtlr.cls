// プロジェクトの分類・評価軸の初期値登録コントローラ
public with sharing class ProjectClassiDefaultEntryCtlr {
    private static final String CLASSI_RECORD_TYPE_CHOICE = 'ChoiceItem'; // 分類・評価軸設定の選択肢のレコードタイプ

    // ラベルマップの取得
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLabelMap() {
        Map<String, String> ret = new Map<String, String>();
        ret.put('title', System.Label.ProjectClassiDefaultEntry_Title);
        ret.put('save', System.Label.ProjectClassiDefaultEntry_Save);
        ret.put('save_success_title', System.Label.ProjectClassiDefaultEntry_Save_Success_Title);
        ret.put('save_success_content', System.Label.ProjectClassiDefaultEntry_Save_Success_Content);
        ret.put('save_error_title', System.Label.ProjectClassiDefaultEntry_Save_Error_Title);
        ret.put('cancel', System.Label.ProjectClassiDefaultEntry_Cancel);

        DescribeFieldResult fldDesc = ermt__Project__c.ermt__AnalyseTimingDefault__c.getDescribe();
        ret.put('analyseTimingDefault', fldDesc.getLabel());
        
        return ret;
    }

    // 分類・評価軸の選択リスト情報の取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getClassiSelsInfo(
        Id projectId // プロジェクトID
        , String classiGroupRecordTypeName // 分類・評価軸グループのレコードタイプ名
        , Boolean isOptionsBlankAdd // 選択リストに空白を追加するか
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();

        // 分類・評価軸設定の取得
        String query = '';
        query += 'SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c, ermt__Help_Text__c';
        query += ', (SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c';
        query += ' FROM MClassifications_del__r';
        query += ' WHERE ermt__invalid__c = false';
        query += ' AND RecordType.DeveloperName = :CLASSI_RECORD_TYPE_CHOICE';
        query += ' ORDER BY ermt__ViewNo__c)';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE Id IN (SELECT ermt__M_Classification__c';
        query += ' FROM ermt__Project_Classification_Junc__c';
        query += ' WHERE ermt__M_Classification__r.RecordType.DeveloperName = :classiGroupRecordTypeName';
        query += ' AND ermt__Project__c = :projectId';
        query += ')';
        query += ' AND ermt__invalid__c = false';
        query += ' ORDER BY ermt__ViewNo__c';
        for (ermt__M_Classification__c cg : Database.query(query)) {
            List<Map<String, String>> opts = new List<Map<String, String>>();
            if (isOptionsBlankAdd) {
                opts.add(new Map<String, String>{
                    'label' => ''
                    , 'value' => ''
                });
            }
            for (ermt__M_Classification__c c : cg.MClassifications_del__r) {
                opts.add(new Map<String, String>{
                    'label' => (String.isNotEmpty(c.ermt__Label_Pick__c) ? c.ermt__Label_Pick__c : c.ermt__Label__c)
                    , 'value' => c.Id
                });
            }
            ret.add(new Map<String, Object>{
                'id' => cg.Id
                , 'label' => (String.isNotEmpty(cg.ermt__Label_Pick__c) ? cg.ermt__Label_Pick__c : cg.ermt__Label__c)
                , 'helpText' => cg.ermt__Help_Text__c
                , 'options' => opts
            });
        }
        return ret;
    }
}