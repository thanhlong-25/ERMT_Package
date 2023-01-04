public class ERMT_RiskTriggerHandler {
    private static final String UPDATE_TYPE_LOG = '変更';
    private static final String RISK_OBJECT_NAME = 'ermt__Risk__c';
    private static final SObjectType sObjType = Schema.getGlobalDescribe().get('ermt__Risk__c');

    public static void saveHistoryLog(Map<Id, Risk__c> oldRisks, Map<Id, Risk__c> newRisks){
        List<History__c> histories = new List<History__c>();
        Set<String> referenceFields = new Set<String>(); // List reference field of Object Log
        Set<Id> oldRiskIds = new Set<Id>();

        for(Risk__c oldRisk : oldRisks.values()){
            oldRiskIds.add(oldRisk.Id);
            Risk__c newRisk = newRisks.get(oldRisk.Id); // Get new Risk by old Risk Id
            List<History__c> historiesRelated = new List<History__c>(); //get list histories are related with one risk id
            Map<Id, List<History__c>> mapHistoriesRelated = new Map<Id, List<History__c>>(); //get map for list history related with risk id 
            Map<String, Object> oldFields = oldRisk.getPopulatedFieldsAsMap(); // Get all field of old Risk
            Map<String, Object> newFields = newRisk.getPopulatedFieldsAsMap(); // Get all field of new Risk
            Map<String, Object> fields = (oldFields.size() > newFields.size()) ? oldFields : newFields;  // assign a larger size Map to fields
            fields = getMapFieldLoggedHistory(fields); //get map fields are logged history

                for(String fieldName: fields.keySet()) {
                    String recordNameObjectLog = '';
                    Boolean isReferenceField = false;
                    String relationshipName = '';
                    Boolean isReferenceValueFormatted = true;
                    DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
                    Schema.DisplayType fieldType = fieldDesc.getType();

                    if(!fieldDesc.isCustom() && !fieldDesc.isNameField() && fieldName != 'OwnerId' && fieldName != 'RecordTypeId') continue; // Skip save history log when field is standard (not include Name and OwnerId)
                    if(fieldDesc.isCalculated()) continue; // Skip save history log when field is formula or roll-up field

                    // get update value
                    String oldValue = String.valueOf(oldRisk.get(fieldName));
                    String newValue = String.valueOf(newRisk.get(fieldName));

                    if(oldValue == newValue) continue; // update same value will skip save log

                    //Check filed is Name field of object log
                    if (fieldDesc.isNameField()) {
                        recordNameObjectLog = newValue;
                    } else {
                        recordNameObjectLog = (String) newRisk.get('Name');
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

                    History__c history = new History__c(
                        Type__c = UPDATE_TYPE_LOG,
                        OldValue__c = oldValue,
                        NewValue__c = newValue,
                        ObjectLog__c = RISK_OBJECT_NAME,
                        FieldName__c = fieldName,
                        RecordId__c = newRisk.Id,
                        IsReferenceField__c = isReferenceField,
                        RelationshipName__c = relationshipName,
                        IsReferenceValueFormatted__c = isReferenceValueFormatted,
                        RecordNameObjectLog__c = recordNameObjectLog
                    );

                    histories.add(history);

                    if (mapHistoriesRelated.keySet().contains(newRisk.Id)) {
                        historiesRelated = mapHistoriesRelated.get(newRisk.Id);
                    }
                    historiesRelated.add(history);
                    mapHistoriesRelated.put(newRisk.Id, historiesRelated);


            }
        }

        //format field reference from ID to Name
        if (referenceFields.size() > 0) {
            String oldRiskQueryStr = 'SELECT ID, ' + String.join(new List<String>(referenceFields), ', ') + ' FROM Risk__c WHERE ID IN :oldRiskIds';
            Map<Id, Risk__c> risksMap = new Map<Id, Risk__c>((List<Risk__c>)database.query(oldRiskQueryStr));
            for(History__c history : histories){
                if(history.IsReferenceField__c && history.OldValue__c != null){
                    String rcId = history.RecordId__c;
                    String rsName = history.RelationshipName__c;
                    List<String> relationshipWithName =  rsName.split('\\.');
                    history.OldValue__c = (String) risksMap.get(rcId).getSObject(relationshipWithName[0]).get(relationshipWithName[1]);
                }
            }
        }

        insert histories;
    }

    // Update NewValue__c field after save History
    public static void updateNewValue(List<Risk__c> risks){
        Set<Id> riskIds = new Set<Id>();
        for(Risk__c risk : risks){
            riskIds.add(risk.Id);
        }
        List<History__c> histories = [SELECT ID, IsReferenceField__c, NewValue__c, FieldName__c, ObjectLog__c, RecordId__c, RelationshipName__c
                                        FROM History__c
                                        WHERE RecordId__c IN :riskIds
                                        AND ObjectLog__c = :RISK_OBJECT_NAME
                                        AND IsReferenceField__c = true
                                        AND IsReferenceValueFormatted__c = false
                                    ];
        if(histories.size() > 0) ERMT_HistoryTriggerHandler.updateNewValue(histories);
    }

    //get map groupId is shared for History__c
    public static Map<Id, List<History__c>> getMapGroupIdIsSharedForHistory(List<Risk__c> risks, Map<Id, List<History__c>> mapHistoriesRelated) {
        Map<Id, List<Id>> mapGroupIdSharedForRisk = new Map<Id, List<Id>>();
        Map<Id, List<History__c>> mapGroupIdSharedForHistory = new Map<Id, List<History__c>>();
        for (Risk__c risk : risks) {
            List<Id> riskIds = new List<Id>();
            if (String.isBlank(risk.Organization__c)) continue;
            if (mapGroupIdSharedForRisk.keySet().contains(risk.Organization__c)) {
                riskIds = mapGroupIdSharedForRisk.get(risk.Organization__c);
            }
            riskIds.add(risk.Id);
            mapGroupIdSharedForRisk.put(risk.Organization__c, riskIds);
        }

        for (Id groupId : mapGroupIdSharedForRisk.keySet()) {
            for (Id riskId : mapGroupIdSharedForRisk.get(groupId)) {
                List<History__c> historyForShared = new List<History__c>();
                if (mapGroupIdSharedForHistory.keySet().contains(groupId)) {
                    historyForShared = mapHistoriesRelated.get(riskId);
                }
                historyForShared.addAll(historyForShared);
                mapGroupIdSharedForHistory.put(groupId, historyForShared);
            }
        }
        return mapGroupIdSharedForHistory;
    }

    //get fields is set in custom metadata
    public static List<HistoryLogConfiguration__mdt> getListFieldSetting(String objectName) {
        String queryFieldSetting = 'SELECT ApiName__c FROM HistoryLogConfiguration__mdt WHERE ApiName__c != null AND ObjectApiName__c = \''+ objectName + '\' AND IsActive__c = True LIMIT 50000';
        return (List<HistoryLogConfiguration__mdt>) new CustomMetadataDAO().getCustomMetadataRecords(queryFieldSetting);
    }

    //get list field is logged history
    public static Map<String, Object> getMapFieldLoggedHistory(Map<String, Object> mapFields) {
        List<HistoryLogConfiguration__mdt> fieldsSettingLoggedHistory = getListFieldSetting(RISK_OBJECT_NAME); //list field is set in custom metadata
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
    public static void deleteAllIncidentRiskJunc(List<Risk__c> risks){
        List<Incident_Risk_Junc__c> irjs = [SELECT ID FROM Incident_Risk_Junc__c WHERE Risk__c IN :risks];
        delete irjs;
    }

    // Delete all risk control junction record before delete parent record
    public static void deleteAllRiskControlJunc(List<Risk__c> risks){
        List<Risk_Control_Junc__c> rcjs = [SELECT ID FROM Risk_Control_Junc__c WHERE Risk__c IN :risks];
        delete rcjs;
    }
}