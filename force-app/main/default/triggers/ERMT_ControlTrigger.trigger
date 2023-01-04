trigger ERMT_ControlTrigger on Control__c (before insert, before update, before delete, after update) {
    if (Trigger.isBefore){
        if (Trigger.isDelete) {
            ERMT_ControlTriggerHandler.deleteAllIncidentControlJunc(Trigger.old); // Delete all incident control junction record before delete Control parent
            ERMT_ControlTriggerHandler.deleteAllRiskControlJunc(Trigger.old); // Delete all risk control junction record before delete Control parent
        }
        if (Trigger.isUpdate) {
            ERMT_ControlTriggerHandler.saveHistoryLog(Trigger.oldMap, Trigger.newMap); // save History Log
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            ERMT_ControlTriggerHandler.updateNewValue(Trigger.new); // update value of Control_Links__c field in Risk__c object
        }
    } 
}