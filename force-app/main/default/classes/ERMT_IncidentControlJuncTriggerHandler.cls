public with sharing class ERMT_IncidentControlJuncTriggerHandler {
    private static final String INSERT_TYPE_LOG = '追加';
    private static final String DELETE_TYPE_LOG = '削除';

    public static void saveHistoryLog(List<Incident_Control_Junc__c> icjs, TriggerOperation operationType){
        List<History__c> histories = new List<History__c>();

        Set<Id> incidentIds = new Set<Id>();
        Set<Id> controlIds = new Set<Id>();
        for(Incident_Control_Junc__c irj : icjs){
            controlIds.add(irj.Control__c);
            incidentIds.add(irj.Incident__c);
        }
        Map<Id, Control__c> controls = new Map<Id, Control__c>([SELECT ID, Name FROM Control__c WHERE ID IN :controlIds]);
        Map<Id, Incident__c> incidents = new Map<Id, Incident__c>([SELECT ID, Title__c FROM Incident__c WHERE ID IN :incidentIds]);

        for(Incident_Control_Junc__c irj : icjs){
            String incidentId = irj.Incident__c;
            String controlId = irj.Control__c;
            String incidentTitle = incidents.get(incidentId).Title__c;
            String controlName = controls.get(controlId).Name;

            histories.add(new History__c(
                Type__c = (operationType == TriggerOperation.AFTER_DELETE) ? DELETE_TYPE_LOG : INSERT_TYPE_LOG,
                ParentRecordId1__c = incidentId,
                ParentRecordId2__c = controlId,
                ParentRecordName1__c = incidentTitle,
                ParentRecordName2__c = controlName,
                ObjectLog__c = 'ermt__Incident_Control_Junc__c',
                RecordId__c = irj.Id
            ));
        }

        insert histories;
    }
}