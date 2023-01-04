public with sharing class ERMT_FLSCheck {

	public static String getPrefix(){
		String prefix = '';
        StaticResource resource = [SELECT NamespacePrefix FROM StaticResource LIMIT 1];
    	if(resource != null && resource.NamespacePrefix != null){
    	   	prefix = resource.NamespacePrefix + '__';        	   	
    	}
		return prefix;
	}

	public static Boolean checkUpdate(sObject updateObject, String[] fieldCheckFLS) {
      if(updateObject != null){
          Schema.SObjectType sobjectType = updateObject.getSObjectType();
          String sobjectName = sobjectType.getDescribe().getName();
          return  checkFLS(fieldCheckFLS, FLSType.FLS_UPDATE, sobjectName);
      }else{
          return false;
      }
  }


  public static Boolean checkUpdate(List<sObject> updateObject, String[] fieldCheckFLS) {
      if(!updateObject.isEmpty()){
          sObject objInstance = updateObject.get(0);
          if(objInstance != null){
              Schema.SObjectType sobjectType = objInstance.getSObjectType();
              String sobjectName = sobjectType.getDescribe().getName();
              return checkFLS(fieldCheckFLS, FLSType.FLS_UPDATE, sobjectName);
          }else{
              return false;
          }
      }
      return false;
  }

  public enum FLSType {FLS_CREATE, FLS_UPDATE, FLS_VIEW, FLS_DELETE}
  public static Boolean checkFLS(String[] fieldCheckFLS, FLSType type, String objectName){ 
    // if don't add any field to check ==> check all custom field
    Set<String> setFields = new Set<String>();
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType objSchema = schemaMap.get(objectName);
    // get all field
    Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
    if(fieldCheckFLS == null || fieldCheckFLS.isEmpty()){
        for(String key: fieldMap.keySet()){
            if(key.contains('__c')){
                setFields.add(key);
            }
        }
    }
    else{
        setFields = new Set<String>(fieldCheckFLS);
    }
    SObjectField field;
    if(type == FLSType.FLS_CREATE){
        // check field set
        for(String f : setFields){
            field = fieldMap.get(f);
            if(field==null){
                return false;
            }
            // check permission
            if(!field.getDescribe().isCreateable() && !field.getDescribe().isCalculated() && !field.getDescribe().isAutoNumber() && field.getDescribe().getRelationshipOrder() == null){
                return false;
            } 
        }   
    }
    else if(type == FLSType.FLS_UPDATE){
        for(String f : setFields){
            field = fieldMap.get(f);
            if(field==null){return false;}
            // check permission
            if(field != null){
                if(!field.getDescribe().isUpdateable() && !field.getDescribe().isCalculated() && !field.getDescribe().isAutoNumber() && field.getDescribe().getRelationshipOrder() == null){
                    return false;
                }
            }
        }   
    }
    else if(type == FLSType.FLS_DELETE){
        if(!objSchema.getDescribe().isDeletable()){
            return false;
        }
    }
    return true;
  }
}