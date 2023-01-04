public class ERMT_IncidentTriggerHandler {
    private static final String UPDATE_TYPE_LOG = '変更';
    private static final String INCIDENT_OBJECT_NAME = 'ermt__Incident__c';
    private static final SObjectType sObjType = Schema.getGlobalDescribe().get('ermt__Incident__c');

    // update value of Incident_Links__c field in Risk__c object if Title__c had change
    public static void updateIncidentLinkValue(List<Incident__c> oldIncidents, List<Incident__c> newIncidents){
        Set<Id> incidentHadChangeTitleList = new Set<Id>();
        for(Integer i = 0; i < oldIncidents.size(); i++){
            if(oldIncidents[i].Title__c != newIncidents[i].Title__c){
                incidentHadChangeTitleList.add(oldIncidents[i].Id);
            }
        }
        List<Incident_Risk_Junc__c> irjs = [SELECT ID, Risk__c FROM Incident_Risk_Junc__c WHERE Incident__c IN :incidentHadChangeTitleList];
        ERMT_IncidentRiskJuncTriggerHandler.updateIncidentLinkValue(irjs);
    }

    public static void saveHistoryLog(Map<Id, Incident__c> oldIncidents, Map<Id, Incident__c> newIncidents){
        List<History__c> histories = new List<History__c>();
        Set<String> referenceFields = new Set<String>(); // List reference field of Object Log
        Set<Id> oldIncidentIds = new Set<Id>();

        for(Incident__c oldInc : oldIncidents.values()){
            oldIncidentIds.add(oldInc.Id);
            Incident__c newInc = newIncidents.get(oldInc.Id); // Get new Incident by old Incident Id
            Map<String, Object> oldFields = oldInc.getPopulatedFieldsAsMap(); // Get all field of old Incident
            Map<String, Object> newFields = newInc.getPopulatedFieldsAsMap(); // Get all field of new Incident
            Map<String, Object> fields = (oldFields.size() > newFields.size()) ? oldFields : newFields; // assign a larger size Map to fields
            fields = getMapFieldLoggedHistory(fields); //get map fields is logged history
                for(String fieldName: fields.keySet()) {
                    DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
                    Schema.DisplayType fieldType = fieldDesc.getType();
                    String recordNameObjectLog = '';
                    Boolean isReferenceField = false;
                    String relationshipName = '';
                    Boolean isReferenceValueFormatted = true;

                    if(!fieldDesc.isCustom() && !fieldDesc.isNameField() && fieldName != 'OwnerId') continue; // Skip save history log when field is standard (not include Name and OwnerId)
                    if(fieldDesc.isCalculated()) continue; // Skip save history log when field is formula or roll-up field

                    // get update value
                    String oldValue = String.valueOf(oldInc.get(fieldName));
                    String newValue = String.valueOf(newInc.get(fieldName));

                    if(oldValue == newValue) continue; // update same value will skip save log

                    //Check filed is Name field of object log
                    if (fieldName == 'ermt__Title__c') {
                        recordNameObjectLog = newValue;
                    } else {
                        recordNameObjectLog = (String) newInc.get('ermt__Title__c');
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
                        ObjectLog__c = INCIDENT_OBJECT_NAME,
                        FieldName__c = fieldName,
                        RecordId__c = newInc.Id,
                        IsReferenceField__c = isReferenceField,
                        RelationshipName__c = relationshipName,
                        IsReferenceValueFormatted__c = isReferenceValueFormatted,
                        RecordNameObjectLog__c = recordNameObjectLog
                    ));
            }
        }
        //format field reference from ID to Name
        if (referenceFields.size() > 0) {
            String oldIncidentQueryStr = 'SELECT ID, ' + String.join(new List<String>(referenceFields), ', ') + ' FROM Incident__c WHERE ID IN :oldIncidentIds';
            Map<Id, Incident__c> incidentsMap = new Map<Id, Incident__c>((List<Incident__c>)database.query(oldIncidentQueryStr));
            for(History__c history : histories){
                if(history.IsReferenceField__c && history.OldValue__c != null){
                    String rcId = history.RecordId__c;
                    String rsName = history.RelationshipName__c;
                    List<String> relationshipWithName =  rsName.split('\\.');
                    history.OldValue__c = (String) incidentsMap.get(rcId).getSObject(relationshipWithName[0]).get(relationshipWithName[1]);
                }
            }
        }
        
        insert histories;
    }

    // Update NewValue__c field after save History
    public static void updateNewValue(List<Incident__c> incidents){
        Set<Id> incidentIds = new Set<Id>();
        for(Incident__c inc : incidents){
            incidentIds.add(inc.Id);
        }

        List<History__c> histories = [SELECT ID, IsReferenceField__c, NewValue__c, FieldName__c, ObjectLog__c, RecordId__c, RelationshipName__c
                                        FROM History__c
                                        WHERE RecordId__c IN :incidentIds
                                        AND ObjectLog__c = :INCIDENT_OBJECT_NAME
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
        List<HistoryLogConfiguration__mdt> fieldsSettingLoggedHistory = getListFieldSetting(INCIDENT_OBJECT_NAME); //list field is set in custom metadata
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

    // Delete all junction record before delete parent record
    public static void deleteAllIncidentRiskJunc(List<Incident__c> incidents){
        List<Incident_Risk_Junc__c> irjs = [SELECT ID FROM Incident_Risk_Junc__c WHERE Incident__c IN :incidents];
        delete irjs;
    }

    // Delete all incident control junction record before delete parent record
    public static void deleteAllIncidentControlJunc(List<Incident__c> incidents){
        List<Incident_Control_Junc__c> icjs = [SELECT ID FROM Incident_Control_Junc__c WHERE Incident__c IN :incidents];
        delete icjs;
    }
}