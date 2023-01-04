public with sharing class ERMT_RiskControlJuncTriggerHandler {
    private static final String INSERT_TYPE_LOG = '追加';
    private static final String DELETE_TYPE_LOG = '削除';

    public static void saveHistoryLog(List<Risk_Control_Junc__c> icjs, TriggerOperation operationType){
        List<History__c> histories = new List<History__c>();

        Set<Id> riskIds = new Set<Id>();
        Set<Id> controlIds = new Set<Id>();
        for(Risk_Control_Junc__c irj : icjs){
            controlIds.add(irj.Control__c);
            riskIds.add(irj.Risk__c);
        }
        Map<Id, Control__c> controls = new Map<Id, Control__c>([SELECT ID, Name FROM Control__c WHERE ID IN :controlIds]);
        Map<Id, Risk__c> risks = new Map<Id, Risk__c>([SELECT ID, Name FROM Risk__c WHERE ID IN :riskIds]);

        for(Risk_Control_Junc__c irj : icjs){
            String riskId = irj.Risk__c;
            String controlId = irj.Control__c;
            String riskName = risks.get(riskId).Name;
            String controlName = controls.get(controlId).Name;

            histories.add(new History__c(
                Type__c = (operationType == TriggerOperation.AFTER_DELETE) ? DELETE_TYPE_LOG : INSERT_TYPE_LOG,
                ParentRecordId1__c = riskId,
                ParentRecordId2__c = controlId,
                ParentRecordName1__c = riskName,
                ParentRecordName2__c = controlName,
                ObjectLog__c = 'ermt__Risk_Control_Junc__c',
                RecordId__c = irj.Id
            ));
        }

        insert histories;
    }
}