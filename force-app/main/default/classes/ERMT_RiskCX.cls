public with sharing class ERMT_RiskCX {

    public ERMT_RiskCX(ApexPages.StandardSetController stdController) {

    }

    @RemoteAction
    public static List<ermt__Project__c> getAllProject(){
        return [Select Id, Name From ermt__Project__c];
    }

    @RemoteAction
    public static ERMT_EnhancedCloneHelper.CloneModel copyRiskData(List<String> recordId, string projectId){
    try {
        ERMT_EnhancedCloneHelper.CloneModel cloneObj = (ERMT_EnhancedCloneHelper.CloneModel)JSON.deserialize(ERMT_EnhancedCloneHelper.clone(recordId, projectId), ERMT_EnhancedCloneHelper.CloneModel.class);
        System.debug(cloneObj);
        return cloneObj;
    } 
    catch(Exception e) {
        System.debug(e.getMessage());
        return null;
    }
}

}