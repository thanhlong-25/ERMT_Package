public with sharing class ERMT_RiskMatrixGeneralCX {

    private final sObject mysObject;

    public ERMT_RiskMatrixGeneralCX(ApexPages.StandardController stdController) {
    }

    @RemoteAction
    public static List<ermt__Risk__c> getRiskOfProjectByClassification(List<String> projectIds, List<String> parentClassiIds,List<String> childClassiIds) {
        if (!projectIds.isEmpty()){
            if(parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE ermt__Project__c IN :projectIds ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else if(!parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE ermt__Project__c IN :projectIds AND Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :parentClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else if(parentClassiIds.isEmpty() && !childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE ermt__Project__c IN :projectIds AND Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__c IN :childClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else{
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE ermt__Project__c IN :projectIds AND Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :parentClassiIds OR ermt__M_Classification__c IN :childClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
        } else {
            if(parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else if(!parentClassiIds.isEmpty() && childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :parentClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else if(parentClassiIds.isEmpty() && !childClassiIds.isEmpty()){
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__c IN :childClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
            else{
                return [SELECT Id,Name, ermt__Organization__r.Type,ermt__Organization__r.Name, ermt__RiskCategory__c, ermt__RiskContents__c ,(SELECT  ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name, ermt__M_Classification__r.Name FROM ermt__Risk_Classification_Junc__r) FROM ermt__Risk__c WHERE Id IN (SELECT ermt__Risk__c FROM ermt__Risk_Classification_Junc__c WHERE ermt__M_Classification__r.ermt__ParentMClassification_del__c IN :parentClassiIds OR ermt__M_Classification__c IN :childClassiIds) ORDER BY ermt__Project__r.CreatedDate DESC, CreatedDate DESC];
            }
        }
    }

    @RemoteAction
    public static AggregateResult[] getAverageRiskAssessment(List<String> projectIds, String evalutionTime) { 
        if(evalutionTime == 'なし'){
            if (!projectIds.isEmpty()) {
                return [SELECT ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point FROM ermt__RiskAssessment_Classification_Junc__c WHERE ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c IN :projectIds AND ermt__RiskAssessment__r.ermt__isActive__c = true AND ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName IN ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') GROUP BY ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
            }
            return [SELECT ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point FROM ermt__RiskAssessment_Classification_Junc__c WHERE ermt__RiskAssessment__r.ermt__isActive__c = true AND ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName IN ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') GROUP BY ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
        }
        if (projectIds.isEmpty()) {
            return [SELECT ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point FROM ermt__RiskAssessment_Classification_Junc__c WHERE  ermt__RiskAssessment__r.ermt__isActive__c = true AND ermt__RiskAssessment__r.ermt__EvaluationTime__c =:evalutionTime AND ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName IN ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') GROUP BY ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
        }
        return [SELECT ermt__RiskAssessment__r.ermt__Risk__c ,ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName, AVG(ermt__M_Classification__r.ermt__ViewNo__c) point FROM ermt__RiskAssessment_Classification_Junc__c WHERE ermt__RiskAssessment__r.ermt__Risk__r.ermt__Project__c IN :projectIds AND ermt__RiskAssessment__r.ermt__isActive__c = true AND ermt__RiskAssessment__r.ermt__EvaluationTime__c =:evalutionTime AND ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName IN ('LikelihoodGroup', 'ConsequenceGroup', 'EvaluationPeriodGroup') GROUP BY ermt__RiskAssessment__r.ermt__Risk__c, ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
    }

    @RemoteAction
    public static AxisWrapper getAxisLabel(List<String> projectIds) {
		List<ermt__M_Classification__c> xClass = new List<ermt__M_Classification__c>();
		List<ermt__M_Classification__c> yClass = new List<ermt__M_Classification__c>();
		if (!projectIds.isEmpty()) {
			xClass = [SELECT Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__c In (SELECT ermt__M_Classification__c FROM ermt__Project_Classification_Junc__c WHERE ermt__Project__c IN :projectIds AND ermt__M_Classification__r.RecordType.DeveloperName = 'LikelihoodGroup')];

			yClass = [SELECT Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__c In (SELECT ermt__M_Classification__c FROM ermt__Project_Classification_Junc__c WHERE ermt__Project__c IN :projectIds AND ermt__M_Classification__r.RecordType.DeveloperName = 'ConsequenceGroup')];
		} else {
			xClass = [SELECT Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__c In (SELECT ermt__M_Classification__c FROM ermt__Project_Classification_Junc__c WHERE ermt__M_Classification__r.RecordType.DeveloperName = 'LikelihoodGroup')];

			yClass = [SELECT Name,ermt__ViewNo__c,ermt__ParentMClassification_del__r.ermt__Label__c,ermt__Label__c FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__c In (SELECT ermt__M_Classification__c FROM ermt__Project_Classification_Junc__c WHERE ermt__M_Classification__r.RecordType.DeveloperName = 'ConsequenceGroup')];
		}	
        
        AxisWrapper wrap = new AxisWrapper();
        wrap.xAxis = xClass;
        wrap.yAxis = yClass;
        return wrap;
    }

    @RemoteAction
    public static List<ermt__CellColor__c> getCellColor(List<String> projectIds){
		if (!projectIds.isEmpty()) {
			return [SELECT Name, ermt__XCordinate__c, ermt__YCordinate__r.Name , ermt__ColorCode__c , ermt__ColorLinkCode__C,ermt__Project__r.Name   FROM ermt__CellColor__c WHERE ermt__Project__c IN :projectIds];
		} else {
			return [SELECT Name, ermt__XCordinate__c, ermt__YCordinate__r.Name , ermt__ColorCode__c , ermt__ColorLinkCode__C,ermt__Project__r.Name   FROM ermt__CellColor__c];
		}
    }
   
    @RemoteAction
    public static List<ermt__M_Classification__c> getEvaluationList(){
        return [SELECT ermt__Label__c, ermt__ViewNo__c, ermt__ParentMClassification_del__r.ermt__Label__c FROM ermt__M_Classification__c WHERE ermt__ParentMClassification_del__r.RecordType.DeveloperName='EvaluationPeriodGroup' ORDER BY ermt__ViewNo__c];
    }

    @RemoteAction
    public static List<ermt__M_Classification__c> getClassificationList(){
        return [SELECT Id,Name, (SELECT Id,ermt__Label__c FROM ermt__MClassifications_del__r ORDER BY ermt__ViewNo__c) FROM ermt__M_Classification__c WHERE RecordType.DeveloperName='ClassificationGroup' ORDER BY ermt__ViewNo__c];
    }

    @RemoteAction
    public static List<ermt__Project__c> getProjects(){
        return [SELECT Id, Name FROM ermt__Project__c];
    }

    public class AxisWrapper {
        public List<ermt__M_Classification__c> xAxis {get;set;}
        public List<ermt__M_Classification__c> yAxis {get;set;}
    }

    @RemoteAction
    public static Map<String, String> getLabelMetadata(){
        ermt__Label_for_risk_matrix__mdt[] labelMappings = [SELECT ermt__Cross_projects_risk_matrix_X_axis_label__c, ermt__Cross_projects_risk_matrix_Y_axis_label__c, ermt__Cross_projects_risk_matrix_timing_label__c FROM ermt__Label_for_risk_matrix__mdt LIMIT 1];
        Map<String, String> mapXY = new Map<String, String>();
        for (ermt__Label_for_risk_matrix__mdt tmp : labelMappings) {
            mapXY.put('xLabel', String.valueOf(tmp.ermt__Cross_projects_risk_matrix_X_axis_label__c));
            mapXY.put('yLabel', String.valueOf(tmp.ermt__Cross_projects_risk_matrix_Y_axis_label__c));
            mapXY.put('timingLabel', String.valueOf(tmp.ermt__Cross_projects_risk_matrix_timing_label__c));
        } 
        return mapXY;
    }
}