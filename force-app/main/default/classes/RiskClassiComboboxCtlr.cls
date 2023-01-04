// リスク分類コンボボックスコントローラ
public without sharing class RiskClassiComboboxCtlr {
    // 種別選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getKindSels(
        Id classiGroupId // 分類・評価軸グループID
        , Boolean isOptionsBlankAdd // 選択リストに空白を追加するか
    ) {
        List<Map<String, String>> ret = new List<Map<String, String>>();
        if (isOptionsBlankAdd) {
            ret.add(new Map<String, String>{
                'label' => ''
                , 'value' => ''
            });
        }

        // 分類・評価軸設定の取得
        Set<String> kindSet = new Set<String>();
        String query = '';
        query += 'SELECT ermt__Kind__c, toLabel(ermt__Kind__c) KindLabel';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE RecordType.DeveloperName = \'' + String.escapeSingleQuotes(System.Label.ClassiRecordType_Choice) + '\'';
        query += ' AND ermt__invalid__c = false';
        query += ' AND ermt__Kind__c != null';
        query += ' AND ermt__ParentMClassification_del__c = :classiGroupId';
        query += ' ORDER BY ermt__ViewNo__c';
        for (ermt__M_Classification__c c : Database.query(query)) {
            if (!kindSet.contains(c.ermt__Kind__c)) {
                kindSet.add(c.ermt__Kind__c);
                ret.add(new Map<String, String>{
                    'label' => (String)c.get('KindLabel')
                    , 'value' => c.ermt__Kind__c
                });
            }
        }
        return ret;
    }
    
    // 分類・評価軸リストの取得
    @AuraEnabled(cacheable=true)
    public static List<ermt__M_Classification__c> getClassis(
        Id classiGroupId // 分類・評価軸グループID
    ) {
        // 分類・評価軸設定の取得
        String query = '';
        query += 'SELECT ermt__Kind__c, toLabel(ermt__Kind__c) KindLabel';
        query += ', toLabel(ermt__Label_Pick__c), ermt__Label__c';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE RecordType.DeveloperName = \'' + String.escapeSingleQuotes(System.Label.ClassiRecordType_Choice) + '\'';
        query += ' AND ermt__invalid__c = false';
        query += ' AND ermt__ParentMClassification_del__c = :classiGroupId';
        query += ' ORDER BY ermt__ViewNo__c';
        return Database.query(query);
    }
}