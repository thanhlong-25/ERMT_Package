/**
* @description Helper class to clone parent and its children sObjects
*/
public without sharing class ERMT_EnhancedCloneHelper {
       
    /**
    * @description Clone parent and its children
    * @param id of the parent sObject
    * @return String Serialized result
    */
    public static String clone (List<String> sObjectIds, string projectId) {
        
        List<ermt__Risk__c> parentSObjects = new List<ermt__Risk__c>();
        List<ermt__Risk__c> parentClone = new List<ermt__Risk__c>();
        CloneModel cloneModelResult = new CloneModel();
        Map<String, String> idsMap = new Map<String, String>();
        List<String> idsFormatted = new List<String>{};
        for(String recId : sObjectIds) {
        	idsFormatted.add(String.format('\'\'{0}\'\'', new String[] {recId}));
        }
		// Parent query
        String query = String.format(
            'SELECT {0} FROM {1} WHERE Id In ({2})',
            new String[] {
                String.join(
                    new List<String>(
                        ermt__Risk__c.SObjectType.getDescribe().fields.getMap().keySet()
                    ),
                    ','
                ),
                String.valueOf(ermt__Risk__c.SObjectType),
                String.join(idsFormatted, ',')
           }
        );

        try {
            
            // Query and gets results
            parentSObjects = Database.query(query);         
            
            for(ermt__Risk__c risk : parentSObjects) {
            	ermt__Risk__c riskClone = risk.clone(false, true, false, true);
            	riskClone.ermt__Project__c = projectId;
            	riskClone.ermt__Clone_From_ID__c = risk.Id;
            	parentClone.add(riskClone);
            }

            Database.insert(parentClone);

            //Add new id to map with old id
            for(ermt__Risk__c riskClone : parentClone) {
            	idsMap.put(riskClone.ermt__Clone_From_ID__c,riskClone.Id);
            }

        } catch (DmlException error) {
            cloneModelResult.message = 'An error occurred while cloning the object.' + error.getMessage();
            return JSON.serialize(cloneModelResult);        
        }
        
        // Children query  
        query = String.format(
            'SELECT {0} FROM {1} WHERE ermt__Risk__c In ({2})',
            new String[] {
                String.join(
                    new List<String>(
                        ermt__RiskAssessment__c.SObjectType.getDescribe().fields.getMap().keySet()
                    ),
                    ','
                ),
                String.valueOf(ermt__RiskAssessment__c.SObjectType),
                String.join(idsFormatted, ',')
           }
        );
        
        List<ermt__RiskAssessment__c> children = new List<ermt__RiskAssessment__c>();
        
        try {
            
            // Query and clone the children. Here you can change anything without affecting the original sObject
            for (ermt__RiskAssessment__c child:(List<ermt__RiskAssessment__c>)Database.query(query)) {
            	ermt__RiskAssessment__c childClone = child.clone(false,true,false,false);
            	childClone.ermt__Clone_From_ID__c = child.Id;
                children.add(childClone);
            }
            
            // If there isn't any children ends the process and return success
            if (children.isEmpty()) {
                cloneModelResult.isSuccess = true;
                cloneModelResult.message = 'Object successfully cloned!';
                cloneModelResult.cloneList = parentClone;

                return JSON.serialize(cloneModelResult);
            }
            
			// Set the parent's Id
            for (ermt__RiskAssessment__c child : children) {
                child.ermt__Risk__c = idsMap.get(child.ermt__Risk__c);
            }
        
            Database.insert(children);
    	
    		//Add new id to map with old id
            for(ermt__RiskAssessment__c child : children) {
            	idsMap.put(child.ermt__Clone_From_ID__c,child.Id);
            }

            //Update beforeAssessment new Id after insert success
            Boolean isNeedUpdate = false;
            for(ermt__RiskAssessment__c child : children) {
            	if(idsMap.containsKey(child.ermt__beforeAssessment__c) && String.isNotBlank(idsMap.get(child.ermt__beforeAssessment__c))){
                    child.ermt__beforeAssessment__c = idsMap.get(child.ermt__beforeAssessment__c);
                    isNeedUpdate = true;
                }
            }

            if(isNeedUpdate){
                Database.update(children);
            }
            
        }  catch(DMLException error) {
            cloneModelResult.message = 'An error occurred while cloning the object.' + error.getMessage();
            return JSON.serialize(cloneModelResult); 
        }
        
        // Return success at the end of the process
        cloneModelResult.isSuccess = true;
        cloneModelResult.message = 'Object and its children successfully cloned!';
        cloneModelResult.cloneList = parentClone;
        
        return JSON.serialize(cloneModelResult);
    }

    public class CloneModel {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public List<ermt__Risk__c> cloneList;
    }
}