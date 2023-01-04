trigger ERMT_IncidentRiskJuncTrigger on Incident_Risk_Junc__c (after insert, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ERMT_IncidentRiskJuncTriggerHandler.updateIncidentLinkValue(Trigger.new);
            ERMT_IncidentRiskJuncTriggerHandler.saveHistoryLog(Trigger.new, TriggerOperation.AFTER_INSERT);
        } else if (Trigger.isDelete) {
            ERMT_IncidentRiskJuncTriggerHandler.updateIncidentLinkValue(Trigger.old);
            ERMT_IncidentRiskJuncTriggerHandler.saveHistoryLog(Trigger.old, TriggerOperation.AFTER_DELETE);
        }
    }
}