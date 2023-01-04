public with sharing class ERMT_ProjectCX {

    private final sObject mysObject;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public ERMT_ProjectCX(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
         
        this.mysObject = (sObject)stdController.getRecord();
    }

    @RemoteAction
    public static List<ermt__Risk__c> getRiskOfProject(string projectId) {
        return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId];
    }

    @RemoteAction
    public static List<ermt__Risk__c> getRiskOfProjectByClassification(string projectId, List<String> parentClassiIds,List<String> childClassiIds) {
        if(parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
            return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId];
        }
        else if(!parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
            return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId And Id In (Select ermt__Risk__c From ermt__Risk_Classification_Junc__c Where ermt__M_Classification__r.ermt__ParentMClassification_del__c In :parentClassiIds)];
        }
        else if(parentClassiIds.isEmpty() && !childClassiIds.isEmpty()){
            return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId And Id In (Select ermt__Risk__c From ermt__Risk_Classification_Junc__c Where ermt__M_Classification__c In :childClassiIds)];
        }
        else{
            return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId And Id In (Select ermt__Risk__c From ermt__Risk_Classification_Junc__c Where ermt__M_Classification__r.ermt__ParentMClassification_del__c In :parentClassiIds Or ermt__M_Classification__c In :childClassiIds)];
        }
        
    }

    @RemoteAction
    public static List<ermt__Risk__c> getRiskOfProjectByEvaluationTime(string projectId, String evalutionTime) {
        Set<String> rIds = getRiskIdValidFromJunc(projectId, evalutionTime);
        return [Select Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(select  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name From ermt__Risk_Classification_Junc__r) From ermt__Risk__c Where ermt__Project__c =:projectId And Id In:rIds];
    }

    @RemoteAction
    public static AggregateResult[] getAverageRisk(string projectId, String evalutionTime) {
        Set<String> rAssesIds = getRiskAssessIdValidFromJunc(projectId);
        if(evalutionTime == 'なし'){
            return [Select ermt__Risk__c, AVG(ermt__NumberConsequence__c) avgImpact, AVG(ermt__NumberLikelihood__c) avgLike, AVG(ermt__NumberEvaluationCostEstimate__c) avgEva, AVG(ermt__NumberSeverityRiskLevel__c) avgSeverity from ermt__RiskAssessment__c Where ermt__Risk__r.ermt__Project__c =:projectId And ermt__isActive__c = true And ermt__Current_Valuation__c = true And Id in :rAssesIds Group by ermt__Risk__c];
        }
        return [Select ermt__Risk__c, AVG(ermt__NumberConsequence__c) avgImpact, AVG(ermt__NumberLikelihood__c) avgLike, AVG(ermt__NumberEvaluationCostEstimate__c) avgEva, AVG(ermt__NumberSeverityRiskLevel__c) avgSeverity from ermt__RiskAssessment__c Where ermt__Risk__r.ermt__Project__c =:projectId And ermt__isActive__c = true And ermt__EvaluationTime__c =: evalutionTime And Id in :rAssesIds Group by ermt__Risk__c];
    }

    @RemoteAction
    public static AggregateResult[] getAverageRiskAssessment(string projectId, String evalutionTime) { 
        Set<String> rAssesIds = getRiskAssessIdValidFromJunc(projectId);
        if(evalutionTime == 'なし'){
            return [select ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point from ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c =:projectId And ermt__RiskAssessment__r.ermt__isActive__c = true And ermt__RiskAssessment__r.ermt__Current_Valuation__c = true And ermt__RiskAssessment__c in :rAssesIds Group by ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
        }
        return [select ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point from ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c =:projectId And ermt__RiskAssessment__r.ermt__isActive__c = true And ermt__RiskAssessment__r.ermt__EvaluationTime__c =:evalutionTime And ermt__RiskAssessment__c in :rAssesIds Group by ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
    }
    @RemoteAction
    public static List<ermt__Project_Classification_Junc__c> getProjectClassifications(string projectId) {
        return [select ermt__M_Classification__r.RecordType.DeveloperName, ermt__M_Classification__c, toLabel(ermt__M_Classification__r.ermt__Label_Pick__c), ermt__M_Classification__r.ermt__Label__c  from ermt__Project_Classification_Junc__c where ermt__Project__c =:projectId and ermt__M_Classification__r.RecordType.DeveloperName != 'ClassificationGroup' and ermt__M_Classification__r.RecordType.DeveloperName != 'EvaluationPeriodGroup' and ermt__M_Classification__r.RecordType.DeveloperName != 'ChoiceItem' Order By  ermt__M_Classification__r.RecordType.DeveloperName];
    }

    @RemoteAction
    public static AxisWrapper getAxisLabel(string projectId) {
        // 2021/02/05 tsuji mod start 不具合修正
        // List<ermt__M_Classification__c> xClass = [Select Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c From ermt__M_Classification__c Where ermt__ParentMClassification_del__c In (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName = 'LikelihoodGroup')];
        // List<ermt__M_Classification__c> yClass = [Select Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c From ermt__M_Classification__c Where ermt__ParentMClassification_del__c In (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName = 'ConsequenceGroup')];
        List<ermt__M_Classification__c> xClass = [
            Select Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c
            From ermt__M_Classification__c
            Where ermt__ParentMClassification_del__c
            In (Select ermt__M_Classification__c
            From ermt__Project_Classification_Junc__c
            Where ermt__Project__c =:projectId
            And ermt__M_Classification__r.RecordType.DeveloperName = 'LikelihoodGroup')
            ORDER BY ermt__ViewNo__c
        ];
        List<ermt__M_Classification__c> yClass = [
            Select Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c
            From ermt__M_Classification__c
            Where ermt__ParentMClassification_del__c
            In (Select ermt__M_Classification__c
            From ermt__Project_Classification_Junc__c
            Where ermt__Project__c =:projectId
            And ermt__M_Classification__r.RecordType.DeveloperName = 'ConsequenceGroup')
            ORDER BY ermt__ViewNo__c
        ];
        // 2021/02/05 tsuji mod end
        AxisWrapper wrap = new AxisWrapper();
        wrap.xAxis = xClass;
        wrap.yAxis = yClass;
        return wrap;
    }

    @RemoteAction
    public static List<ermt__CellColor__c> getCellColor(String projectId){
        return [Select Name, ermt__XCordinate__c, ermt__YCordinate__r.Name , ermt__ColorCode__c , ermt__ColorLinkCode__C,ermt__Project__r.Name   from ermt__CellColor__c Where ermt__Project__c =:projectId];

    }
    @RemoteAction
    public static List<ermt__Cell_Color__mdt> getCustomMetadataCellColor(){
        return [Select Id,DeveloperName, ermt__Base_Color__c, ermt__Dark_Color__c  from ermt__Cell_Color__mdt order by DeveloperName]; 

    }
    @RemoteAction
    public static Boolean addCellColor(List<ermt__CellColor__c> cellColor, String projectId){
        try{
            upsert cellColor;
        }catch(Exception e){
            System.debug(e);
            return false;
        }
        return true;

    }
    @RemoteAction
    public static List<ermt__M_Classification__c> getEvaluationList(String projectId){
        return [Select ermt__Label__c, ermt__ViewNo__c, ermt__ParentMClassification_del__r.ermt__Label__c From ermt__M_Classification__c Where ermt__ParentMClassification_del__c in (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName='EvaluationPeriodGroup') Order By ermt__ViewNo__c];
    }

    @RemoteAction
    public static List<ermt__M_Classification__c> getClassificationList(String projectId){
        return [Select Id,Name, (Select Id,ermt__Label__c From ermt__MClassifications_del__r Order by ermt__ViewNo__c) From ermt__M_Classification__c Where Id in (Select ermt__M_Classification__c From ermt__Project_Classification_Junc__c Where ermt__Project__c =:projectId And ermt__M_Classification__r.RecordType.DeveloperName='ClassificationGroup') Order By ermt__ViewNo__c];
    }

    private static Set<String> getRiskAssessIdValidFromJunc(string projectId){
        Set<String> result = new Set<String>();
        AggregateResult[] groupedResults
        = [Select ermt__RiskAssessment__c 
        From ermt__RiskAssessment_Classification_Junc__c 
        Where ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName in ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') And ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c =:projectId
        Group By ermt__RiskAssessment__c
        Having count(ermt__RiskAssessment__c) = 3];
        for (AggregateResult ar : groupedResults)  {
            result.add(String.valueOf(ar.get('ermt__RiskAssessment__c')));
        }

        return result;
    }

    private static Set<String> getRiskIdValidFromJunc(string projectId, string evalutionTime){
        Set<String> result = new Set<String>();
        AggregateResult[] groupedResults = new AggregateResult[]{};
        if(evalutionTime == 'なし'){
            groupedResults = [Select ermt__RiskAssessment__r.ermt__Risk__c 
            From ermt__RiskAssessment_Classification_Junc__c 
            Where ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName in ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') And ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c =:projectId
            Group By ermt__RiskAssessment__c, ermt__RiskAssessment__r.ermt__Risk__c
            Having count(ermt__RiskAssessment__c) = 3];
        }
        else{
            groupedResults = [Select ermt__RiskAssessment__r.ermt__Risk__c 
            From ermt__RiskAssessment_Classification_Junc__c 
            Where ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName in ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') And ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c =:projectId And ermt__RiskAssessment__r.ermt__EvaluationTime__c=:evalutionTime
            Group By ermt__RiskAssessment__c, ermt__RiskAssessment__r.ermt__Risk__c
            Having count(ermt__RiskAssessment__c) = 3];
        }

        for (AggregateResult ar : groupedResults)  {
            result.add(String.valueOf(ar.get('ermt__Risk__c')));
        }

        return result;
    }

    public class AxisWrapper {
        public List<ermt__M_Classification__c> xAxis {get;set;}
        public List<ermt__M_Classification__c> yAxis {get;set;}
    }
}