// リスク分類（プロジェクト内）コンボボックスコントローラ
public without sharing class RiskClassProjectComboboxCtlr {
    // 分類グループリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getClassGroups(
        Id projectId // プロジェクトID
    ) {
        String query = '';
        query += 'SELECT toLabel(ermt__Label_Pick__c), ermt__Label__c';
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
        query += ' AND ermt__Project__c = :projectId';
        query += ')';
        query += ' AND ermt__invalid__c = false';
        query += ' ORDER BY ermt__ViewNo__c';
        //System.debug('query=' + query);
        return Database.query(query);
    }
}