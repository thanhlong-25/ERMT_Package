public with sharing class ERMT_HistoryLogController {
    private static final List<String> objects = new List<String>{'ermt__Incident__c', 'ermt__Risk__c', 'ermt__Control__c'};
    private static final List<String> objectJunctions = new List<String>{'ermt__Incident_Risk_Junc__c', 'ermt__Incident_Control_Junc__c', 'ermt__Risk_Control_Junc__c'};
    private static final String ADD_TYPE = '追加';
    private static final String DELETE_TYPE = '削除';
    private static final String UPDATE_TYPE = '変更';
    private static final String SETING_DISPLAY_ONLY_LOG_JUNCTIONS = '「追加・削除のみ」';

    @AuraEnabled
    public static Map<String, String> getColumnLabel(){

        try {
            Map<String, String> ret = new Map<String, String>();
            SObjectType sObjHistoryLogType = Schema.getGlobalDescribe().get('ermt__History__c');
            List<String> columnFields = new List<String>{'ermt__Type__c', 'ermt__OldValue__c', 'ermt__NewValue__c', 'ermt__FieldName__c', 'OwnerId', 'CreatedDate'};

            for(String columnField : columnFields){
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjHistoryLogType, columnField);
                ret.put(columnField, fieldDesc.getLabel());
            }

            return ret;
        } catch (Exception e) {
            throw e;
        }
    }

    @AuraEnabled
    public static String getObjectLabel(String objectApiName){
        try {
            return Schema.getGlobalDescribe().get(objectApiName).getDescribe().getLabel();
        } catch (Exception e) {
            throw e;
        }
    }

    @AuraEnabled
    public static List<History__c> getNormalObjectHistoryLog(String objectHistoryLog, String recordId){
        try {
            List<String> fieldsAreDisplayed = getFieldsAreDisplayed(objectHistoryLog); //get fields are displayed at history records
            // Get history log
            List<History__c> histories = [ 
                SELECT ID, RecordId__c, toLabel(Type__c), FieldName__c, OldValue__c, NewValue__c, CreatedDate, Owner.Name, ParentRecordId1__c, ParentRecordId2__c, RecordNameObjectLog__c
                FROM History__c
                WHERE ObjectLog__c =: objectHistoryLog AND RecordId__c =: recordId AND FieldName__c IN :fieldsAreDisplayed
                ORDER BY CreatedDate DESC
                LIMIT 50000
            ];
            // Format data to display
            formatDataToDisplay(objectHistoryLog, histories);
            return histories;

        } catch (Exception e) {
            throw e;
        }
    }

    @AuraEnabled
    public static List<History__c> getJunctionObjectHistoryLog(
        String recordId
        , String objectApiName
        , String objectHistoryLog
        , String remainingJuncObjectName
        , Integer orderParent) {

        try {
            // Get all another parent ids in junction
            Set<String> anotherParentIds = new Set<String>();
            switch on objectHistoryLog {
                when 'ermt__Incident_Risk_Junc__c' {
                    List<Incident_Risk_Junc__c> junctions = new List<Incident_Risk_Junc__c>();
                    String junctionQuery = '';
                    junctionQuery += 'SELECT ID, Incident__c, Risk__c';
                    junctionQuery += ' FROM Incident_Risk_Junc__c';
                    junctionQuery += ' WHERE ' + objectApiName +' =: recordId';
                    junctionQuery += ' ORDER BY CreatedDate DESC';

                    junctions = Database.query(junctionQuery);

                    for(Incident_Risk_Junc__c irj : junctions){
                        anotherParentIds.add((String) irj.get(remainingJuncObjectName));
                    }
                }

                when 'ermt__Incident_Control_Junc__c' {
                    List<ermt__Incident_Control_Junc__c> junctions = new List<ermt__Incident_Control_Junc__c>();
                    String junctionQuery = '';
                    junctionQuery += 'SELECT ID, Incident__c, Control__c';
                    junctionQuery += ' FROM Incident_Control_Junc__c';
                    junctionQuery += ' WHERE ' + objectApiName +' =: recordId';
                    junctionQuery += ' ORDER BY CreatedDate DESC';

                    junctions = Database.query(junctionQuery);

                    for(Incident_Control_Junc__c irj : junctions){
                        anotherParentIds.add((String) irj.get(remainingJuncObjectName));
                    }
                }

                when 'ermt__Risk_Control_Junc__c' {
                    List<ermt__Risk_Control_Junc__c> junctions = new List<ermt__Risk_Control_Junc__c>();
                    String junctionQuery = '';
                    junctionQuery += 'SELECT ID, Risk__c, Control__c';
                    junctionQuery += ' FROM Risk_Control_Junc__c';
                    junctionQuery += ' WHERE ' + objectApiName +' =: recordId';
                    junctionQuery += ' ORDER BY CreatedDate DESC';

                    junctions = Database.query(junctionQuery);

                    for(Risk_Control_Junc__c irj : junctions){
                        anotherParentIds.add((String) irj.get(remainingJuncObjectName));
                    }
                }
            }
            List<String> fieldsAreDisplayed = getFieldsAreDisplayed(remainingJuncObjectName); //get fields are displayed at history records
            // Query Junction History Log
            String historyLogQuery = '';
            historyLogQuery += 'SELECT Id, RecordId__c, FieldName__c, Type__c, ObjectLog__c, OldValue__c, NewValue__c, ParentRecordId1__c, ParentRecordId2__c, ParentRecordName1__c, ParentRecordName2__c, CreatedDate, Owner.Name, RecordNameObjectLog__c';
            historyLogQuery += ' FROM History__c';
            historyLogQuery += ' WHERE ( ObjectLog__c =: objectHistoryLog';
                if(orderParent == 1) historyLogQuery += ' AND ParentRecordId1__c =:recordId )';
                if(orderParent == 2) historyLogQuery += ' AND ParentRecordId2__c =:recordId )';
            historyLogQuery += ' OR ( ObjectLog__c =: remainingJuncObjectName';
            historyLogQuery += ' AND FieldName__c IN :fieldsAreDisplayed';
            historyLogQuery += ' AND RecordId__c IN :anotherParentIds )';
            historyLogQuery += ' ORDER BY Id DESC';

            List<History__c> histories = Database.query(historyLogQuery);
            
            //handle records are display
            if (histories.isEmpty()) return histories;
            Boolean isOnlyDisplayedHistoryJunc = getSettingRecordsAreDisplayed(objectHistoryLog, objectApiName);
            histories = getHistoryRecordAreDisplayed(histories, objectApiName, objectHistoryLog, isOnlyDisplayedHistoryJunc);
            
            // Format data to display
            formatDataToDisplay(remainingJuncObjectName, histories);

            return histories;
        } catch (Exception e) {
            throw e;
        }
    }

    //get setting records are displayed
    private static Boolean getSettingRecordsAreDisplayed(String historyLog, String recordPage) {
        //get setting records are displayed. These are set in custom metadata
        String queryRecordsSetting = 'SELECT Listview__c FROM HistoryJunctionDisplayedConfiguration__mdt WHERE Listview__c != null AND HistoryLog__c = \''+ historyLog +'\' AND IsActive__c = True AND RecordPage__c = \''+ recordPage +'\' LIMIT 50000';
        List<HistoryJunctionDisplayedConfiguration__mdt> recordsSetting =  (List<HistoryJunctionDisplayedConfiguration__mdt>) new CustomMetadataDAO().getCustomMetadataRecords(queryRecordsSetting);
        
        if (recordsSetting.isEmpty()) return false;
        Set<String> displaySet = new Set<String>();
        for (HistoryJunctionDisplayedConfiguration__mdt displaySetting : recordsSetting) {
            String displayString = String.valueOf(displaySetting.get('Listview__c'));
            displaySet.add(displayString);
        }
        //check displaySet have all displayed setting
        List<String> listDisplaySetting = new List<String>();
        listDisplaySetting.addAll(displaySet);
        if (listDisplaySetting.size() >= 2) return false;
        if (!(listDisplaySetting[0] == SETING_DISPLAY_ONLY_LOG_JUNCTIONS)) return false;
        return true;
    }

    //get history records of fields are displayed
    private static List<String> getFieldsAreDisplayed(String objectName) {
        //get set field of object
        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Set<String> fieldSetObject = objectType.getDescribe().fields.getMap().keySet();

        //get fields are displayed. These are set in custom metadata
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ objectName +'\' AND IsActive__c = True AND IsDisplayed__c = True LIMIT 50000';
        List<HistoryLogConfiguration__mdt> fieldsSetting =  (List<HistoryLogConfiguration__mdt>) new CustomMetadataDAO().getCustomMetadataRecords(queryFieldSetting);

        Set<String> fieldSet = new Set<String>();
        for (HistoryLogConfiguration__mdt field : fieldsSetting) {
            String fieldString = String.valueOf(field.get('ApiName__c'));
            //check field is exist in object
            if (!fieldSetObject.contains(fieldString.toLowerCase())) continue;
            fieldSet.add(fieldString);
        }
        //check record type id is exist in object
        if (fieldSetObject.contains('RecordTypeId')) fieldSet.add('RecordTypeId');
        List<String> listFields = new List<String>();
        listFields.addAll(fieldSet);
        return listFields;
    }

    //get list history record are displayed
    private static List<History__c> getHistoryRecordAreDisplayed(
        List<History__c> histories, 
        String objectApiName, 
        String objectHistoryLog,
        Boolean isOnlyDisplayedHistoryJunc
    ) {
        List<History__c> historiesDisplayed = new List<History__c>();
        //generate history records map
        Map<Id, List<History__c>> mapHistoryRecord = generateHistoryRecordsMap(histories, objectApiName, objectHistoryLog);
        for (Id recordId : mapHistoryRecord.keySet()) {
            Boolean isSkipAddChangeLog = false;
            List<History__c> historesRelated = mapHistoryRecord.get(recordId);
            for (History__c history : historesRelated) {
                if (history.Type__c == UPDATE_TYPE) {
                    if (!isSkipAddChangeLog) historiesDisplayed.add(history);
                } else {
                    if (history.Type__c == ADD_TYPE) isSkipAddChangeLog = true;
                    historiesDisplayed.add(history);
                }
                
            }
        }

        //fiter history by listview
        List<History__c> historesResult = new List<History__c>();
        if (!isOnlyDisplayedHistoryJunc) return historiesDisplayed;
        for (History__c history : historiesDisplayed) {
            if (!(history.Type__c == UPDATE_TYPE)) {
                historesResult.add(history);
            }
        }
        
        return historesResult;
    }


    //generate history records map
    private static Map<Id, List<History__c>> generateHistoryRecordsMap(List<History__c> histories, String objectApiName, String objectHistoryLog) {
        Map<Id, List<History__c>> mapHistoryRecord = new Map<Id, List<History__c>>();
        for (History__c record : histories) {
            //record is normal object's log
            List<History__c> historiesRelatedRecordId = new List<History__c>();
            if (objects.contains(record.ObjectLog__c)) {
                putRecordInHistoryRecordMap(mapHistoryRecord, record.RecordId__c, record, historiesRelatedRecordId);
            }
            //record is junciton object's log
            if (objectJunctions.contains(record.ObjectLog__c)) {
                switch on objectApiName {
                    //in Incident record page
                    when 'ermt__Incident__c' {
                        putRecordInHistoryRecordMap(mapHistoryRecord, record.ParentRecordId2__c, record, historiesRelatedRecordId);
                    }
                    //in Risk record page
                    when 'ermt__Risk__c' {
                        //in history Incident_Risk_Jun record displayed
                        if (objectHistoryLog == 'ermt__Incident_Risk_Junc__c') {
                            putRecordInHistoryRecordMap(mapHistoryRecord, record.ParentRecordId1__c, record, historiesRelatedRecordId);
                        }
                        //in history Risk_Control_Jun record displayed
                        if (objectHistoryLog == 'ermt__Risk_Control_Junc__c') {
                            putRecordInHistoryRecordMap(mapHistoryRecord, record.ParentRecordId2__c, record, historiesRelatedRecordId);
                        }
                    }
                    //in Control record page
                    when 'ermt__Control__c' {
                        putRecordInHistoryRecordMap(mapHistoryRecord, record.ParentRecordId1__c, record, historiesRelatedRecordId);
                    }
                }
            }
        }
        return mapHistoryRecord;
    } 

    //put record in map history records
    private static void putRecordInHistoryRecordMap(
        Map<Id, List<History__c>> mapHistoryRecord, 
        String key, 
        History__c record,
        List<History__c> historiesRelatedRecordId
    ) {
        if (mapHistoryRecord.keySet().contains(key)) {
            historiesRelatedRecordId = mapHistoryRecord.get(key);
        }
        historiesRelatedRecordId.add(record);
        mapHistoryRecord.put(key, historiesRelatedRecordId);
    }

    //format data to display
    private static void formatDataToDisplay(String objectHistoryLog, List<History__c> histories){
        SObjectType sObjHistoryLogType = Schema.getGlobalDescribe().get(objectHistoryLog);

        for (History__c history : histories){
            if(history.FieldName__c == null) continue; // occur when history log type is insert or delete
            DescribeFieldResult fieldNameDesc = CommonUtil.getFieldDescribe(sObjHistoryLogType, history.FieldName__c);
            if(fieldNameDesc == null) continue; // occur when FieldName__c invalid

            // Format FieldName__c Value to FieldName__c Label
            history.FieldName__c = fieldNameDesc.getLabel();
            String oldValue = history.OldValue__c;
            String newValue = history.NewValue__c;

            // Format FieldName__c Value to FieldName__c Label if FieldType is PICKLIST or MULTIPICKLIST
            Schema.DisplayType fieldType = fieldNameDesc.getType();
            if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                List<Schema.PicklistEntry> spe = fieldNameDesc.getPicklistValues();
                Map<String,String> picklistApiToLabelMap = new Map<String,String>();

                // Get value to label Map of picklist field
                for (Schema.PicklistEntry sp : spe){
                    picklistApiToLabelMap.put(sp.getValue(), sp.getLabel());
                }

                if (fieldType == Schema.DisplayType.PICKLIST) {
                    history.OldValue__c = picklistApiToLabelMap.get(oldValue);
                    history.NewValue__c = picklistApiToLabelMap.get(newValue);
                    continue;
                }
                // format data when fieldType == Schema.DisplayType.MULTIPICKLIST
                List<String> oldPicklistValues = String.isNotBlank(oldValue) ? oldValue.split(';') : new List<String>();
                List<String> newPicklistValues = String.isNotBlank(newValue) ? newValue.split(';') : new List<String>();

                List<String> oldValueFormatteds = new List<String>();
                List<String> newValueFormatteds = new List<String>();

                for (String oldPicklistValue : oldPicklistValues){
                    oldValueFormatteds.add(picklistApiToLabelMap.get(oldPicklistValue));
                }

                for (String newPicklistValue : newPicklistValues){
                    newValueFormatteds.add(picklistApiToLabelMap.get(newPicklistValue));
                }

                history.OldValue__c = String.join(oldValueFormatteds, ';');
                history.NewValue__c = String.join(newValueFormatteds, ';');

            } else if (fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.DATE){
                // * Formatted datetime value corresponding to logged-in user timezone
                Datetime oldDatetimeValue = String.isNotBlank(oldValue) ? Datetime.valueOfGMT(oldValue) : null;
                Datetime newDatetimeValue = String.isNotBlank(newValue) ? Datetime.valueOfGMT(newValue) : null;

                if (fieldType == Schema.DisplayType.DATETIME){
                    // = UserInfo.getTimeZone().getId();
                    // history.OldValue__c = (oldDatetimeValue != null) ? oldDatetimeValue.format('yyyy/MM/dd HH:mm', userTimeZone) : null;
                    // history.NewValue__c = (newDatetimeValue != null) ? newDatetimeValue.format('yyyy/MM/dd HH:mm', userTimeZone) : null;
                    history.OldValue__c = (oldDatetimeValue != null) ? oldDatetimeValue.format() : null;
                    history.NewValue__c = (newDatetimeValue != null) ? newDatetimeValue.format() : null;
                    continue;
                }
                // format data when fieldType == Schema.DisplayType.Date
                history.OldValue__c = (oldDatetimeValue != null) ? oldDatetimeValue.formatGMT('yyyy/MM/dd') : null;
                history.NewValue__c = (newDatetimeValue != null) ? newDatetimeValue.formatGMT('yyyy/MM/dd') : null;
            }
        }
    }

    @AuraEnabled
    public static Map<String,String> getHistoryTypeMap(){
        SObjectType sObjHistoryLogType = Schema.getGlobalDescribe().get('ermt__History__c');
        DescribeFieldResult fieldTypeDesc = CommonUtil.getFieldDescribe(sObjHistoryLogType, 'ermt__Type__c');
        List<Schema.PicklistEntry> spe = fieldTypeDesc.getPicklistValues();
        Map<String,String> picklistApiToLabelMap = new Map<String,String>();
        // Get value to label Map of picklist field
        for (Schema.PicklistEntry sp : spe){
            picklistApiToLabelMap.put(sp.getValue(), sp.getLabel());
        }
        return picklistApiToLabelMap;
    }
}