trigger ERMT_IncidentControlJuncTrigger on Incident_Control_Junc__c (after insert, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ERMT_IncidentControlJuncTriggerHandler.saveHistoryLog(Trigger.new, TriggerOperation.AFTER_INSERT);
        } else if (Trigger.isDelete) {
            ERMT_IncidentControlJuncTriggerHandler.saveHistoryLog(Trigger.old, TriggerOperation.AFTER_DELETE);
        }
    }
}