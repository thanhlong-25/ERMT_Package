// リスク分類出力コントローラ
public without sharing class RiskClassiOutputCtlr {
    // 分類・評価軸のグループラベルの取得
    @AuraEnabled(cacheable=true)
    public static String getClassiGroupLabel(
        Id classiGroupId // 分類・評価軸グループID
    ) {
        String ret = '';
        for (ermt__M_Classification__c c : [
            SELECT toLabel(ermt__Kind__c)
            , toLabel(ermt__Label_Pick__c), ermt__Label__c
            FROM ermt__M_Classification__c
            WHERE Id = :classiGroupId
            LIMIT 1
        ]) {
            if (String.isNotEmpty(c.ermt__Kind__c)) {
                ret += c.ermt__Kind__c;
            }
            if (
                String.isNotEmpty(c.ermt__Label_Pick__c) ||
                String.isNotEmpty(c.ermt__Label__c)
            ) {
                ret += (String.isEmpty(ret) ? '' : ': ');
                ret += (String.isNotEmpty(c.ermt__Label_Pick__c) ? c.ermt__Label_Pick__c : c.ermt__Label__c);
            }
        }
        ret = (String.isEmpty(ret) ? System.Label.Select_NotSet : ret);
        return ret;
    }

    // 分類・評価軸リストの取得
    @AuraEnabled(cacheable=true)
    public static List<ermt__M_Classification__c> getClassis(
        List<Id> classiIds // 分類・評価軸IDリスト
    ) {
        // 分類・評価軸設定の取得
        String query = '';
        query += 'SELECT toLabel(ermt__Kind__c)';
        query += ', toLabel(ermt__Label_Pick__c), ermt__Label__c';
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE Id = :classiIds';
        query += ' ORDER BY ermt__ViewNo__c';
        return Database.query(query);
    }
}