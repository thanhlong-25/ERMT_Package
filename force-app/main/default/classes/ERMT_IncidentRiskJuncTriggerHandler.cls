public class ERMT_IncidentRiskJuncTriggerHandler {
    private static final String ELLIPSIS_CHAR = '...';
    private static final Integer INCIDENT_LINKS_LENGTH = Risk__c.Incident_Links__c.getDescribe().getLength(); // get length of Incident_Links__c
    private static final String INSERT_TYPE_LOG = '追加';
    private static final String DELETE_TYPE_LOG = '削除';
    private static final String INCIDENT_JP_CHAR = 'インシデント'; // Incident character in Japanese
    private static final String RISK_JP_CHAR = 'リスク'; // Risk character in Japanese

    public static void updateIncidentLinkValue(List<Incident_Risk_Junc__c> incidentRiskJuncs){
        // Get List RiskId
        Set<Id> riskIds = new Set<Id>();
        for(Incident_Risk_Junc__c irj : incidentRiskJuncs){
            riskIds.add(irj.Risk__c);
        }

        // Get Risk with Incident_Risk_Junction related by RiskId
        List<Risk__c> risks = [SELECT ID
                                        , Incident_Links__c
                                        , (
                                            SELECT ID, Incident__c, Incident__r.Title__c
                                            FROM Incident_Risk_Juncs__r
                                            ORDER BY CreatedDate
                                            LIMIT 50000
                                        )
                                    FROM Risk__c
                                    WHERE ID IN :riskIds
                                    LIMIT 50000 ];

        for (Risk__c risk : risks) {
            List<Incident_Risk_Junc__c> irjs = risk.Incident_Risk_Juncs__r;
            String incidentLinkValue = '';
            if(irjs != null){
                Integer i = 0;
                for (Incident_Risk_Junc__c irj : irjs) {

                    String incidentId = irj.Incident__c;
                    String incidentTitle = irj.Incident__r.Title__c;
                    Boolean isLastItemOnLoop = (i + 1 == irjs.size());

                    ResultWrapper ret = formatIncidentLinkValue(incidentLinkValue, incidentId, incidentTitle, isLastItemOnLoop);
                    incidentLinkValue += ret.value;
                    i++;

                    if(ret.isBreak) break;
                }
            }
            risk.Incident_Links__c = incidentLinkValue;
        }
        update risks;
    }

    // Formatted data for Incident_Links__c field
    @TestVisible
    private static ResultWrapper formatIncidentLinkValue(String currentIncidentLinkValue, String incidentId, String incidentTitle, Boolean isLastItemOnLoop){
        ResultWrapper resWrp = new ResultWrapper();
        String currentValue = String.format('<p><a href="/{0}" target="_blank">{1}</a></p>', new List<String>{ incidentId, incidentTitle });
        String formatIncidentLinkValueLength = currentIncidentLinkValue + currentValue;

        if( formatIncidentLinkValueLength.length() > INCIDENT_LINKS_LENGTH) {
            resWrp.value = ELLIPSIS_CHAR;
            resWrp.isBreak = true;
        } else {
            if(isLastItemOnLoop){
                resWrp.value = currentValue;
                resWrp.isBreak = true;
            } else {
                if((INCIDENT_LINKS_LENGTH - formatIncidentLinkValueLength.length()) < ELLIPSIS_CHAR.length()){
                    resWrp.value = ELLIPSIS_CHAR;
                    resWrp.isBreak = true;
                } else {
                    resWrp.value = currentValue;
                    resWrp.isBreak = false;
                }
            }
        }
        return resWrp;
    }

    public static void saveHistoryLog(List<Incident_Risk_Junc__c> irjs, TriggerOperation operationType){
        List<History__c> histories = new List<History__c>();

        Set<Id> riskIds = new Set<Id>();
        Set<Id> incidentIds = new Set<Id>();
        for(Incident_Risk_Junc__c irj : irjs){
            riskIds.add(irj.Risk__c);
            incidentIds.add(irj.Incident__c);
        }
        Map<Id, Risk__c> risks = new Map<Id, Risk__c>([SELECT ID, Name FROM Risk__c WHERE ID IN :riskIds]);
        Map<Id, Incident__c> incidents = new Map<Id, Incident__c>([SELECT ID, Title__c FROM Incident__c WHERE ID IN :incidentIds]);

        for(Incident_Risk_Junc__c irj : irjs){
            String incidentId = irj.Incident__c;
            String riskId = irj.Risk__c;
            String incidentTitle = incidents.get(incidentId).Title__c;
            String riskName = risks.get(riskId).Name;

            histories.add(new History__c(
                Type__c = (operationType == TriggerOperation.AFTER_DELETE) ? DELETE_TYPE_LOG : INSERT_TYPE_LOG,
                ParentRecordId1__c = incidentId,
                ParentRecordId2__c = riskId,
                ParentRecordName1__c = incidentTitle,
                ParentRecordName2__c = riskName,
                ObjectLog__c = 'ermt__Incident_Risk_Junc__c',
                RecordId__c = irj.Id
            ));
        }

        insert histories;
    }

    public class ResultWrapper {
        public String value { get; set; }
        public Boolean isBreak { get; set; }

        public ResultWrapper() {
            this.value = null;
            this.isBreak = false;
        }
    }
}