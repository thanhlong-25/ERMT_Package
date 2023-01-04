trigger ERMT_IncidentTrigger on Incident__c (before delete, before update, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            ERMT_IncidentTriggerHandler.updateIncidentLinkValue(Trigger.old, Trigger.new); // update value of Incident_Links__c field in Risk__c object
            ERMT_IncidentTriggerHandler.updateNewValue(Trigger.new); // update value of Incident_Links__c field in Risk__c object
        }
    } else if (Trigger.isBefore){
        if (Trigger.isDelete) {
            ERMT_IncidentTriggerHandler.deleteAllIncidentRiskJunc(Trigger.old); // Delete all junction record before delete incident parent
            ERMT_IncidentTriggerHandler.deleteAllIncidentControlJunc(Trigger.old); // Delete all junction record before delete incident parent
        }
        if (Trigger.isUpdate) {
            ERMT_IncidentTriggerHandler.saveHistoryLog(Trigger.oldMap, Trigger.newMap); // save History Log
        }
    }
}