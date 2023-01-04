public with sharing class ERMT_BubbleChartForRiskCX {
    public static final Double DEFAULT_MAX = 5.0;
    public ERMT_BubbleChartForRiskCX(ApexPages.StandardController stdController) {
        List<String> fields = new List<String> { 'Project__c' };
        if (!Test.isRunningTest()) stdController.addFields(fields);
    }

    @RemoteAction
    public static ProjectClassificationWrapper getProjectClassifications(string projectId) {
        ProjectClassificationWrapper wrapper = new ProjectClassificationWrapper();
        wrapper.juncs = ERMT_ProjectCX.getProjectClassifications(projectId);
        List<Id> classificationIds = new List<Id>();
        for(ermt__Project_Classification_Junc__c junc : wrapper.juncs){
            classificationIds.add(junc.ermt__M_Classification__c);
        }
        wrapper.mapClassificationWithMaxNo = getMaxViewNoOfClassification(classificationIds);
        return wrapper;
    }

    @RemoteAction
    public static String getAverageRiskAssessment(string riskId) { 
    	Set<String> rAssesIds = getRiskAssessIdValidFromJunc(riskId);
        AggregateResult[] ars = [Select ermt__RiskAssessment__c,ermt__M_Classification__c ,ermt__M_Classification__r.ermt__Label_Pick__c,ermt__M_Classification__r.ermt__Label__c,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point from ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__r.ermt__Risk__c =:riskId And ermt__RiskAssessment__r.ermt__isActive__c = true And ermt__RiskAssessment__c in :rAssesIds Group by ermt__M_Classification__r.ermt__Label_Pick__c, ermt__M_Classification__c, ermt__M_Classification__r.ermt__Label__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName,ermt__RiskAssessment__c];
        
        List<Schema.PicklistEntry> entries = ermt__M_Classification__c.ermt__Label_Pick__c.getDescribe().getPickListValues();
        Map<String, String> mapPicklistValue = new Map<String, String>();
        for(Schema.PicklistEntry entry: entries){
            mapPicklistValue.put(entry.getValue(), entry.getLabel());
        }
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(AggregateResult ar:ars){
            gen.writeStartObject();
            gen.writeStringField('ermt__RiskAssessment__c', (String)ar.get('ermt__RiskAssessment__c'));
            gen.writeStringField('ermt__M_Classification__c', (String)ar.get('ermt__M_Classification__c'));
            gen.writeStringField('ermt__Label__c', (String)(ar.get('ermt__Label__c')) ) ;
            gen.writeStringField('DeveloperName',(String) ar.get('DeveloperName'));
            gen.writeNumberField('point',(Double)ar.get('point'));
            String labelPick = mapPicklistValue.get((String)ar.get('ermt__Label_Pick__c'));
            if(labelPick != null){
                gen.writeStringField('ermt__Label_Pick__c', labelPick);    
            }
            gen.writeEndObject();
        }
        gen.writeEndArray();

        return gen.getAsString();
    }

    @TestVisible
    private static Map<Id, Double> getMaxViewNoOfClassification(List<Id> classificationIds){
        Map<Id, Double> mapClassificationWithMaxViewNo = new Map<Id, Double>();
        for(Id id: classificationIds){
            mapClassificationWithMaxViewNo.put(id, DEFAULT_MAX);
        }
        List<AggregateResult> groupedResults = [SELECT ermt__ParentMClassification_del__c ,MAX(ermt__ViewNo__c) maxPoint FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__c IN: classificationIds GROUP BY ermt__ParentMClassification_del__c];
        
        for(AggregateResult ar:groupedResults){
            mapClassificationWithMaxViewNo.put((Id)ar.get('ermt__ParentMClassification_del__c'), (Double)ar.get('maxPoint'));
        }
        return mapClassificationWithMaxViewNo;
    } 

    private static Set<String> getRiskAssessIdValidFromJunc(string riskId){
        Set<String> result = new Set<String>();
        AggregateResult[] groupedResults = new AggregateResult[]{};
        groupedResults = [Select ermt__RiskAssessment__c 
        From ermt__RiskAssessment_Classification_Junc__c 
        Where ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName in ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') And ermt__RiskAssessment__r.ermt__Risk__c =:riskId
        Group By ermt__RiskAssessment__c
        Having count(ermt__RiskAssessment__c) = 3];

        for (AggregateResult ar : groupedResults)  {
            result.add(String.valueOf(ar.get('ermt__RiskAssessment__c')));
        }

        return result;
    }

    public class ProjectClassificationWrapper {
        public List<ermt__Project_Classification_Junc__c> juncs {get;set;}
        public Map<Id, Double> mapClassificationWithMaxNo {get;set;}
    }
}