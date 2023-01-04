public with sharing class ERMT_ControlTriggerHandler {
    private static final String UPDATE_TYPE_LOG = '変更';
    private static final String CONTROL_OBJECT_NAME = 'ermt__Control__c';
    private static final SObjectType sObjType = Schema.getGlobalDescribe().get('ermt__Control__c');

    public static void saveHistoryLog(Map<Id, Control__c> oldControls, Map<Id, Control__c> newControls){
        List<History__c> histories = new List<History__c>();
        Set<String> referenceFields = new Set<String>(); // List reference field of Object Log
        Set<Id> oldControlIds = new Set<Id>();

        for(Control__c oldControl : oldControls.values()){
            oldControlIds.add(oldControl.Id);
            Control__c newControl = newControls.get(oldControl.Id); // Get new Control by old Control Id
            Map<String, Object> oldFields = oldControl.getPopulatedFieldsAsMap(); // Get all field of old Control
            Map<String, Object> newFields = newControl.getPopulatedFieldsAsMap(); // Get all field of new Control
            Map<String, Object> fields = (oldFields.size() > newFields.size()) ? oldFields : newFields;  // assign a larger size Map to fields
            fields = getMapFieldLoggedHistory(fields); //get map fields is logged history
            
            for(String fieldName: fields.keySet()) {
                String recordNameObjectLog = '';
                Boolean isReferenceField = false;
                String relationshipName = '';
                Boolean isReferenceValueFormatted = true;
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
                Schema.DisplayType fieldType = fieldDesc.getType();

                if(!fieldDesc.isCustom() && !fieldDesc.isNameField() && fieldName != 'OwnerId') continue; // Skip save history log when field is standard (not include Name and OwnerId)
                if(fieldDesc.isCalculated()) continue; // Skip save history log when field is formula or roll-up field

                // get update value
                String oldValue = String.valueOf(oldControl.get(fieldName));
                String newValue = String.valueOf(newControl.get(fieldName));

                if(oldValue == newValue) continue; // update same value will skip save log

                //Check filed is Name field of object log
                if (fieldDesc.isNameField()) {
                    recordNameObjectLog = newValue;
                } else {
                    recordNameObjectLog = (String) newControl.get('Name');
                }

                // Check field type is datetime or not
                if(fieldType == Schema.DisplayType.DATETIME) {
                    Datetime oldDatetimeValue = String.isNotBlank(oldValue) ? Datetime.valueOf(oldValue) : null;
                    Datetime newDatetimeValue = String.isNotBlank(newValue) ? Datetime.valueOf(newValue) : null;

                    oldValue = (oldDatetimeValue != null) ? oldDatetimeValue.format('yyyy-MM-dd HH:mm:ss') : null; // format Datetime to GMT
                    newValue = (newDatetimeValue != null) ? newDatetimeValue.format('yyyy-MM-dd HH:mm:ss') : null; // format Datetime to GMT
                } else if(fieldType == Schema.DisplayType.REFERENCE){
                    String parentNameFieldName = CommonUtil.getParentNameFieldName(fieldName, fieldDesc);
                    referenceFields.add(parentNameFieldName);
                    relationshipName = parentNameFieldName;
                    isReferenceField = true;
                    isReferenceValueFormatted = (newValue != null) ? false : true;
                }

                histories.add(new History__c(
                    Type__c = UPDATE_TYPE_LOG,
                    OldValue__c = oldValue,
                    NewValue__c = newValue,
                    ObjectLog__c = CONTROL_OBJECT_NAME,
                    FieldName__c = fieldName,
                    RecordId__c = newControl.Id,
                    IsReferenceField__c = isReferenceField,
                    RelationshipName__c = relationshipName,
                    IsReferenceValueFormatted__c = isReferenceValueFormatted,
                    RecordNameObjectLog__c = recordNameObjectLog
                ));
            }
        }

        //format field reference from ID to Name
        if (referenceFields.size() > 0) {
            String oldControlQueryStr = 'SELECT ID, ' + String.join(new List<String>(referenceFields), ', ') + ' FROM Control__c WHERE ID IN :oldControlIds';
            Map<Id, Control__c> ControlsMap = new Map<Id, Control__c>((List<Control__c>)database.query(oldControlQueryStr));
            for(History__c history : histories){
                if(history.IsReferenceField__c && history.OldValue__c != null){
                    String rcId = history.RecordId__c;
                    String rsName = history.RelationshipName__c;
                    List<String> relationshipWithName =  rsName.split('\\.');
                    history.OldValue__c = (String) ControlsMap.get(rcId).getSObject(relationshipWithName[0]).get(relationshipWithName[1]);
                }
            }
        }

        insert histories;
    }

    // Update NewValue__c field after save History
    public static void updateNewValue(List<Control__c> Controls){
        Set<Id> ControlIds = new Set<Id>();
        for(Control__c Control : Controls){
            ControlIds.add(Control.Id);
        }
        List<History__c> histories = [SELECT ID, IsReferenceField__c, NewValue__c, FieldName__c, ObjectLog__c, RecordId__c, RelationshipName__c
                                        FROM History__c
                                        WHERE RecordId__c IN :ControlIds
                                        AND ObjectLog__c = :CONTROL_OBJECT_NAME
                                        AND IsReferenceField__c = true
                                        AND IsReferenceValueFormatted__c = false
                                    ];
        if(histories.size() > 0) ERMT_HistoryTriggerHandler.updateNewValue(histories);
    }

    //get fields is set in custom metadata
    public static List<HistoryLogConfiguration__mdt> getListFieldSetting(String objectName) {
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ objectName + '\' AND IsActive__c = True LIMIT 50000';
        return (List<HistoryLogConfiguration__mdt>) new CustomMetadataDAO().getCustomMetadataRecords(queryFieldSetting);
    }

    //get list field is logged history
    public static Map<String, Object> getMapFieldLoggedHistory(Map<String, Object> mapFields) {
        List<HistoryLogConfiguration__mdt> fieldsSettingLoggedHistory = getListFieldSetting(CONTROL_OBJECT_NAME); //list field is set in custom metadata
        Map<String, Object> mapFieldLoggedHistory = new Map<String, Object>();
        for (HistoryLogConfiguration__mdt field : fieldsSettingLoggedHistory) {
            String fieldString = String.valueOf(field.get('ApiName__c'));
            //check map fields isn't contains fieldString
            if (!mapFields.keySet().contains(fieldString)) continue;
            mapFieldLoggedHistory.put(fieldString, mapFields.get(fieldString));
        }
        //add value of recordtype in map field logged history
        if (!mapFields.keySet().contains('RecordTypeId')) return mapFieldLoggedHistory;
        mapFieldLoggedHistory.put('RecordTypeId', mapFields.get('RecordTypeId'));
        return mapFieldLoggedHistory;
    }

    // Delete all incident control junction record before delete parent record
    public static void deleteAllIncidentControlJunc(List<Control__c> controls){
        List<Incident_Control_Junc__c> icjs = [SELECT ID FROM Incident_Control_Junc__c WHERE Control__c IN :controls];
        delete icjs;
    }

    // Delete all risk control junction record before delete parent record
    public static void deleteAllRiskControlJunc(List<Control__c> controls){
        List<Risk_Control_Junc__c> rcjs = [SELECT ID FROM Risk_Control_Junc__c WHERE Control__c IN :controls];
        delete rcjs;
    }
}