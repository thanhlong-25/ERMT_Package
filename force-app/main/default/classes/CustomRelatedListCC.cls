public with sharing class CustomRelatedListCC {
    @AuraEnabled
    public static RiskDataWrapper getData(Id parentId,Integer offset,Integer defaultSize){    
        Set<Schema.FieldSetMember> fsMembers = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__Risk__c.fieldSets.Default.getFields());
        List<LabelWrapper> fieldList = new List<LabelWrapper>();
        Set<String> fieldNames = new Set<String>();

        generateFieldListAndFieldName(fieldList, fieldNames, fsMembers, ermt__Risk__c.sObjectType,true);
        List<String> listStrings = new List<String>(fieldNames);
        String queryFields = String.join(listStrings, ',');

        String queryTotal = 'Select count() From ermt__Risk__c Where ermt__Project__c = \'' + String.escapeSingleQuotes(parentId) + '\'';
        String queryData = 'Select '+queryFields+' From ermt__Risk__c Where ermt__Project__c = \'' + String.escapeSingleQuotes(parentId) + '\' limit '+ defaultSize +' offset '+ offset;  
        system.debug(queryData) ;
    
    // create a instance of wrapper class.
    List<SObject> objects = Database.query(queryData);  
    RiskDataWrapper obj =  new RiskDataWrapper();
    // set the pageSize,Page(Number), total records and accounts List(using OFFSET)   
    obj.pageSize = defaultSize;
    //obj.page = page;
    obj.total = Database.countQuery(queryTotal);
    obj.records = objects;
    obj.objectIcon = getObjectIcon(Schema.SObjectType.ermt__Risk__c.getName());
    obj.fieldList = fieldList;
    obj.objLabel = Schema.SObjectType.ermt__Risk__c.getLabel();
    // return the wrapper class instance .
    System.debug(obj);
    return obj;
}

@AuraEnabled
public static List<RiskAssessmentDataWrapper> getRiskAssessmentData(string parentId){
    List<ermt__Risk__c> riskList = [Select Id, ermt__AssessmentStatus__c From ermt__Risk__c Where Id =:parentId];
    ermt__Risk__c risk = new ermt__Risk__c();
    if(riskList.isEmpty()){
        throw new System.QueryException();
    }

    risk = riskList[0];

    //string keyPrefix = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
    //String keyPrefix = ermt__Risk__c.SObjectType.getDescribe().getKeyPrefix();
    String keyPrefix = ERMT_FLSCheck.getPrefix();
    String tempStatus = risk.ermt__AssessmentStatus__c;
    risk.ermt__AssessmentStatus__c = keyPrefix  + risk.ermt__AssessmentStatus__c;

    Set<Schema.FieldSetMember> fsMembers = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__RiskAssessment__c.fieldSets.getMap().get(risk.ermt__AssessmentStatus__c).getFields());

    List<LabelWrapper> fieldList = new List<LabelWrapper>();
    Set<String> fieldNames = new Set<String>();
    
    generateFieldListAndFieldName(fieldList, fieldNames, fsMembers, ermt__RiskAssessment__c.sObjectType);
    List<String> listStrings = new List<String>(fieldNames);
    String queryFields = String.join(listStrings, ',');
    risk.ermt__AssessmentStatus__c =  tempStatus;
    String s = '\'' + String.escapeSingleQuotes(risk.ermt__AssessmentStatus__c)  + '\'';
    String query = String.format('Select {0} From ermt__RiskAssessment__c Where RecordType.DeveloperName={1}', new List<String>{queryFields,s});
    System.debug(query);
    List<RiskAssessmentDataWrapper> result = new List<RiskAssessmentDataWrapper>();
    
    for(ermt__RiskAssessment__c riskAssest : Database.query(query)){
        RiskAssessmentDataWrapper wrap = new RiskAssessmentDataWrapper();
        wrap.record = riskAssest;
        wrap.fieldList = fieldList;
        wrap.recordType = risk.ermt__AssessmentStatus__c;
        result.add(wrap);
    }
    return result;
}

@AuraEnabled
public static List<RiskAssessmentDataWrapper> getRiskAssessmentDataForRiskDetail(string parentId){
    //Add all fieldset to set to query
    Set<Schema.FieldSetMember> setFields = new Set<Schema.FieldSetMember>();
    Set<Schema.FieldSetMember> setFieldsAnalysis = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__RiskAssessment__c.fieldSets.Analysis.getFields());
    Set<Schema.FieldSetMember> setFieldsEvaluation = new Set<Schema.FieldSetMember>(Schema.SObjectType.ermt__RiskAssessment__c.fieldSets.Evaluation.getFields());
    setFields.addAll(setFieldsAnalysis);
    setFields.addAll(setFieldsEvaluation);

    //Generate soql
    List<LabelWrapper> fieldList = new List<LabelWrapper>();
    Set<String> fieldNames = new Set<String>();
    
    generateFieldListAndFieldName(fieldList, fieldNames, setFields, ermt__RiskAssessment__c.sObjectType);
    fieldNames.add('RecordType.DeveloperName');
    fieldNames.add('ermt__isActive__c');
    fieldNames.add('ermt__Risk__c');
    fieldNames.add('ermt__SeverityRiskLevel__c');
    fieldNames.add('ermt__RiskClassification__c');
    fieldNames.add('ermt__Likelihood__c');
    fieldNames.add('ermt__AssumedCost__c');
    fieldNames.add('ermt__Consequence__c');
    fieldNames.add('ermt__RemainingRisk_DerivativeRisk__c');
    fieldNames.add('ermt__AnalysisCurrentAnalysis__c');
    fieldNames.add('ermt__RiskAnalysis__c');
    List<String> listStrings = new List<String>(fieldNames);
    String queryFields = String.join(listStrings, ',');
    String s = '\'' + String.escapeSingleQuotes(parentId)  + '\'';
    String query = String.format('Select {0} From ermt__RiskAssessment__c Where ermt__Risk__c={1} Order By ermt__isActive__c DESC', new List<String>{queryFields,s});
    System.debug(query);

    //Generate field list to display
    List<LabelWrapper> fieldListAnalysis = new List<LabelWrapper>();
    generateFieldListAndFieldName(fieldListAnalysis, fieldNames, setFieldsAnalysis, ermt__RiskAssessment__c.sObjectType);

    List<LabelWrapper> fieldListEvaluation = new List<LabelWrapper>();
    generateFieldListAndFieldName(fieldListEvaluation, fieldNames, setFieldsEvaluation, ermt__RiskAssessment__c.sObjectType);

    //Final result
    List<RiskAssessmentDataWrapper> result = new List<RiskAssessmentDataWrapper>();
    
    for(ermt__RiskAssessment__c riskAssest : Database.query(query)){
        RiskAssessmentDataWrapper wrap = new RiskAssessmentDataWrapper();
        wrap.record = riskAssest;
        wrap.recordType = riskAssest.RecordType.DeveloperName;
        switch on riskAssest.RecordType.DeveloperName {
            when 'Analysis' {
                wrap.fieldList = fieldListAnalysis;
            }
            when 'Evaluation' {
                wrap.fieldList = fieldListEvaluation;
            }
            when else {
                //default
                wrap.fieldList = fieldList;
            }
        }
        result.add(wrap);
    }
    
    return result;
}

@AuraEnabled
public static List<RecordType> getRiskAssessRecordType(){
    return ERMT_RecordTypeCache.get(ermt__RiskAssessment__c.sObjectType).values();
}
@AuraEnabled
public static Boolean enableRiskAssessmentData(string recordId){
    try {
        List<ermt__RiskAssessment__c> riskAssessList= [Select Id, ermt__isActive__c From ermt__RiskAssessment__c Where Id = :recordId];
        for(ermt__RiskAssessment__c riskAssess : riskAssessList){
            riskAssess.ermt__isActive__c = true;
        }
        update riskAssessList;
        return true;
    } 
    catch(Exception e) {
        System.debug(e.getMessage());
        return false;
    }
}

@AuraEnabled
public static ERMT_EnhancedCloneHelper.CloneModel copyRiskData(string recordId, string projectId){
    try {
        ERMT_EnhancedCloneHelper.CloneModel cloneObj = (ERMT_EnhancedCloneHelper.CloneModel)JSON.deserialize(ERMT_EnhancedCloneHelper.clone(new List<String>{recordId}, projectId), ERMT_EnhancedCloneHelper.CloneModel.class);
        System.debug(cloneObj);
        return cloneObj;
    } 
    catch(Exception e) {
        System.debug(e.getMessage());
        return null;
    }
}

//Get Record Type ID
@AuraEnabled
public static String getRecordTypeRiskAssessByName(string name) {
    return Schema.SObjectType.ermt__RiskAssessment__c.getRecordTypeInfosByDeveloperName().get(name).getRecordTypeId();
}

//Get Fields From Page Layout
@AuraEnabled
public static List<String> getFieldsFromLayoutByName(string name) {
    List<String> fieldLst = new List<String>();
    List<Metadata.Metadata> layouts = 
    Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
       new List<String> {name});

    Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
    for (Metadata.LayoutSection section : layoutMd.layoutSections) {
        for (Metadata.LayoutColumn column : section.layoutColumns) {
            if (column.layoutItems != null) {
                for (Metadata.LayoutItem item : column.layoutItems) {
                    //System.debug(section.label + ' '+ item.field+' - '+item.behavior);
                    if(item.behavior != Metadata.UiBehavior.Readonly){
                        if(!item.field.startsWithIgnoreCase('ermt__') && item.field.endsWithIgnoreCase('__c')){
                            fieldLst.add('ermt__'+item.field);
                        }
                        else{
                            fieldLst.add(item.field);
                        }
                        
                    }
                }
            }
        }
    }
    return fieldLst;
}

//Get Fields From Page Layout
@AuraEnabled
public static Boolean insertRAssessClassiJunc(String rAssessId, String classId) {
    try {

        ermt__M_Classification__c classi = [Select ermt__ParentMClassification_del__r.RecordType.DeveloperName From ermt__M_Classification__c Where Id =:classId];
        if(classi != null){
            if (RiskAssessment_Classification_Junc__c.getSObjectType().getDescribe().isDeletable()) {         
                delete [Select Id From ermt__RiskAssessment_Classification_Junc__c Where ermt__RiskAssessment__c=:rAssessId And ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName =:classi.ermt__ParentMClassification_del__r.RecordType.DeveloperName];
            }
        }
        ermt__RiskAssessment_Classification_Junc__c junc = new ermt__RiskAssessment_Classification_Junc__c();
        junc.ermt__RiskAssessment__c = rAssessId;
        junc.ermt__M_Classification__c = classId;
        if(ERMT_FLSCheck.checkFLS(new String[]{'ermt__RiskAssessment__c', 'ermt__M_Classification__c'}, ERMT_FLSCheck.FLSType.FLS_CREATE,RiskAssessment_Classification_Junc__c.class.getName())){
            insert junc;
        }
        
    } catch(Exception e) {
        return false;
    }
    return true;
}

//@AuraEnabled
//public static DataWrapper deleteRecord(String objectName,Id parentId,String parentField,String fields,Integer offset,Integer defaultSize,String recordId){
//   DataWrapper data =  new DataWrapper();
//   List<String> params = new List<String>{String.escapeSingleQuotes(objectName),'\''+String.escapeSingleQuotes(recordId)+'\''};
//   String query = String.format('Select Id From {0} Where Id = {1}', params);
//   system.debug(query);
//   sObject obj = Database.query(query);
//   Database.DeleteResult rs = Database.Delete(obj,false);
//   if(rs.isSuccess()){
//    String queryTotal = 'Select count() From ' + String.escapeSingleQuotes(objectName) + ' where '+ String.escapeSingleQuotes(parentField) +' = \'' + String.escapeSingleQuotes(parentId) + '\'';
//    String queryData = 'SELECT '+String.escapeSingleQuotes(fields)+' FROM '+String.escapeSingleQuotes(objectName) +' where '+String.escapeSingleQuotes(parentField)+' = \'' + String.escapeSingleQuotes(parentId) + '\' limit '+ defaultSize +' offset '+ offset;  
    
//        // create a instance of wrapper class.
//        List<SObject> objects = Database.query(queryData);  
//        system.debug(objects) ; 

//        // set the pageSize,Page(Number), total records and accounts List(using OFFSET)   
//        data.pageSize = defaultSize;
//        //obj.page = page;
//        data.total = Database.countQuery(queryTotal);
//        data.records = objects;
//        data.showLabels = getObjectLabels(objectName,fields);
//        data.objectIcon = getObjectIcon(objectName);
//        system.debug(data.objectIcon)    ;
//        List<String> dspFields = new List<String>();    
//        for(String f: fields.split(',')){
//            dspFields.add(f);
//          /*  if(f!='Id'){
               
//            }*/
//        }    
//        data.showFields = dspFields;
//    }

//    return data;
//}
/*==================== PRIVATE METHOD =================*/
@TestVisible private static List<String> getObjectLabels(String objectName,String fields){
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType objSchema = schemaMap.get(objectName);
    Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
    List<String> labels = new List<String>();
    for(String f: fields.trim().toLowerCase().split(',')){
        for (String fieldName: fieldMap.keySet()) {
            if(fieldName==f.trim()){
                String label = fieldMap.get(fieldName).getDescribe().getLabel();
                labels.add(label);
                break;
            }
        }
    }
    return labels;
}
private static String getObjectIcon(String objectName){
    List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
    List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
    String icon = '';
    for(DescribeTabSetResult tsr : tabSetDesc) {
        List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();
        for(Schema.DescribeTabResult tr : tabDesc) {
            if(tr.getSobjectName() == objectName){
                iconDesc.addAll(tr.getIcons());
                break;                
            }
        }        
        for (Schema.DescribeIconResult ir : iconDesc) {
            //system.debug(ir);
            if (ir.getContentType() == 'image/svg+xml'){
                icon = ir.getUrl();
                break;
            }
        } // end for DescribeIconResult
        if(String.isNotBlank(icon)){
            Integer s = icon.indexOf('/custom/') + '/custom/'.length(),
            e = icon.length() - 4;
            icon = icon.substring(s, e);
            break;
        }
    } // end for DescribeTabSetResult
    return icon;
}

private static void generateFieldListAndFieldName(List<LabelWrapper> fieldList,Set<String> fieldNames,Set<Schema.FieldSetMember> fsMembers, Schema.SObjectType sType){
    generateFieldListAndFieldName(fieldList,fieldNames,fsMembers,sType,false);
}

private static void generateFieldListAndFieldName(List<LabelWrapper> fieldList,Set<String> fieldNames,Set<Schema.FieldSetMember> fsMembers, Schema.SObjectType sType, Boolean isRename){
    LabelWrapper labelWrap;
    for(Schema.FieldSetMember f : fsMembers) {
        Schema.DescribeFieldResult des = sType.getDescribe().fields.getMap().get(f.getFieldPath()).getDescribe();
        if( ! des.isAccessible()) {
            throw new System.NoAccessException();
        }

        labelWrap = new LabelWrapper();
        labelWrap.objLabel = des.getLabel();
        labelWrap.isRelationship = false;
        labelWrap.fieldType = des.getType().name();
        if(des.getType() == Schema.DisplayType.Reference && isRename){
            labelWrap.objName = String.format('{0}.{1}', new List<String>{des.getRelationshipName(), 'Name'});
            labelWrap.isRelationship = true;
        }
        else{
            labelWrap.objName = f.getFieldPath();
        }
        fieldList.add(labelWrap);
        if(des.getType() == Schema.DisplayType.Picklist && isRename){
            fieldNames.add(String.format('toLabel({0})', new List<String>{f.getFieldPath()}));
        }
        else {
            fieldNames.add(labelWrap.objName);
        }

    }
}

public class RiskAssessRecordTypeDataWrapper {
    @AuraEnabled public RecordType recordType {get;set;}
    @AuraEnabled public String key {get;set;}
}

public class RiskAssessmentDataWrapper {
    @AuraEnabled public ermt__RiskAssessment__c record {get;set;}
    @AuraEnabled public List<LabelWrapper> fieldList {get;set;}
    @AuraEnabled public String recordType {get;set;}
}

private class LabelWrapper {
    @AuraEnabled public String objLabel {get;set;}
    @AuraEnabled public String objName {get;set;}
    @AuraEnabled public Boolean isRelationship {get;set;}
    @AuraEnabled public String fieldType {get;set;}
}

 // create a wrapper class with @AuraEnabled Properties    
 public class RiskDataWrapper {
    @AuraEnabled public String objLabel {get;set;}
    @AuraEnabled public String objectIcon {get;set;}
    @AuraEnabled public Integer pageSize {get;set;}
    @AuraEnabled public Integer page {get;set;}
    @AuraEnabled public Integer total {get;set;}
    @AuraEnabled public List<Object> records {get;set;}
    @AuraEnabled public List<LabelWrapper> fieldList {get;set;}
}
}