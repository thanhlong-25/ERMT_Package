// レコード検索コントローラ
public with sharing class RecordLookupCtlr {
    // レコードの取得
    @AuraEnabled(cacheable=true)
    public static SObject getRecord(
        String objectName
        , Id recordId
    ) {
        SObject ret = null;
        if (String.isEmpty(objectName)) return ret;
        if (recordId == null) return ret;
        String query = '';
        query += 'SELECT Name';
        query += ' FROM ' + objectName;
        query += ' WHERE Id = :recordId';
        query += ' LIMIT 1';
        for (SObject so : Database.query(query)) {
            ret = so;
        }
        return ret;
    }

    // レコードリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(
        String objectName
        , String recordName
    ) {
        if (String.isEmpty(objectName)) return null;
        String query = '';
        String queryWhere = '';
        String queryOrder = '';
        query += 'SELECT Name';
        query += ' FROM ' + objectName;
        if (String.isNotEmpty(recordName)) {
            queryWhere = 'Name LIKE \'%' + String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(recordName)) + '%\'';
        }
        SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType != null) {
            DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, 'LastReferencedDate');
            if (fieldDesc != null) {
                queryWhere = (String.isEmpty(queryWhere) ? 'LastReferencedDate != null' : queryWhere);
                queryOrder = 'LastReferencedDate NULLS LAST';
            }
        }
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        queryOrder += (String.isEmpty(queryOrder) ? '' : ', ');
        queryOrder += 'Name';
        query += ' ORDER BY ' + queryOrder;
        query += ' LIMIT 32';
        return Database.query(query);
    }

    // グループのレコードリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getGroupRecords(
        String objectName
        , String recordName
        , List<String> groupTypes
    ) {
        if (String.isEmpty(objectName)) return null;
        String query = '';
        String queryWhere = '';
        query += 'SELECT Name';
        query += ' FROM ' + objectName;
        if (String.isNotEmpty(recordName)) {
            queryWhere = 'Name LIKE \'%' + String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(recordName)) + '%\'';
        }
        if (groupTypes != null && !groupTypes.isEmpty()) {
            queryWhere += (String.isEmpty(queryWhere) ? '' : ' AND ');
            queryWhere += 'Type IN :groupTypes';
        }
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        query += ' ORDER BY Name NULLS LAST';
        query += ' LIMIT 32';
        return Database.query(query);
    }

    // レコードタイプのレコードリストの取得
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordTypeRecords(
        String objectName
        , String recordName
        , String recordTypeObjectName
    ) {
        if (String.isEmpty(objectName)) return null;
        String query = '';
        String queryWhere = '';
        query += 'SELECT Name';
        query += ' FROM ' + objectName;
        if (String.isNotEmpty(recordName)) {
            queryWhere = 'Name LIKE \'%' + String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(recordName)) + '%\'';
        }
        if (String.isNotEmpty(recordTypeObjectName)) {
            queryWhere += (String.isEmpty(queryWhere) ? '' : ' AND ');
            queryWhere += 'SobjectType = \'' + String.escapeSingleQuotes(recordTypeObjectName) + '\'';
        }
        if (String.isNotEmpty(queryWhere)) {
            query += ' WHERE ' + queryWhere;
        }
        query += ' ORDER BY Name NULLS LAST';
        query += ' LIMIT 32';
        return Database.query(query);
    }
}