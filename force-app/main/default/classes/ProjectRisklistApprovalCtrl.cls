public with sharing class ProjectRisklistApprovalCtrl {
    private static final Integer QURETY_LIMIT = 1000;

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRiskDisplayFieldNameSels() {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        SObjectType sObjType = ermt__Risk__c.getSObjectType();
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        for (SObjectField field : sObjDesc.fields.getMap().values()) {
            DescribeFieldResult fieldDesc = field.getDescribe();
            ret.add(new Map<String, Object>{
                'label' => fieldDesc.getLabel() + ':' + fieldDesc.getName()
                , 'value' => fieldDesc.getName()
            });
        }
        return ret;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRiskAssessmentDisplayFieldNameSels(
        Id projectId
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();

        SObjectType classiSObjType = ermt__M_Classification__c.getSObjectType();
        DescribeSObjectResult classiSObjDesc = classiSObjType.getDescribe();
        Map<String, RecordTypeInfo> classiRecTypeInfoByRecTypeDevName = classiSObjDesc.getRecordTypeInfosByDeveloperName();

        Map<String, String> labelByRecTypeDevName = new Map<String, String>();
        for (ermt__Project_Classification_Junc__c pcj : [
            SELECT toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)
            , ermt__M_Classification__r.ermt__Label__c
            , ermt__M_Classification__r.RecordType.DeveloperName
            FROM ermt__Project_Classification_Junc__c
            WHERE ermt__Project__c = :projectId
            AND ermt__M_Classification__r.ermt__invalid__c = false
            ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
        ]) {
            String recTypeDevName = pcj.ermt__M_Classification__r.RecordType.DeveloperName;
            if (!labelByRecTypeDevName.containsKey(recTypeDevName)) {
                String label = pcj.ermt__M_Classification__r.ermt__Label_Pick__c;
                label = (String.isNotEmpty(label) ? label : pcj.ermt__M_Classification__r.ermt__Label__c);
                labelByRecTypeDevName.put(recTypeDevName, label);
            }
        }

        List<String> classiRecTypeDevNames = new List<String>{
            System.Label.ClassiRecordType_AnalyseTiming
            , System.Label.ClassiRecordType_Probability
            , System.Label.ClassiRecordType_ResultImpact
            , System.Label.ClassiRecordType_ThirdEvaluation
        };
        for (String recTypeDevName : classiRecTypeDevNames) {
            String label = labelByRecTypeDevName.get(recTypeDevName);
            if (String.isEmpty(label)) {
                RecordTypeInfo classiRecTypeInfo = classiRecTypeInfoByRecTypeDevName.get(recTypeDevName);
                label = (classiRecTypeInfo == null ? System.Label.Select_NotSet : classiRecTypeInfo.getName());
            }
            ret.add(new Map<String, Object>{
                'label' => label + ':' + recTypeDevName
                , 'value' => recTypeDevName
            });
        }
        SObjectType riskAssSObjType = ermt__RiskAssessment__c.getSObjectType();
        DescribeSObjectResult riskAssSObjDesc = riskAssSObjType.getDescribe();
        for (SObjectField field : riskAssSObjDesc.fields.getMap().values()) {
            DescribeFieldResult fieldDesc = field.getDescribe();
            ret.add(new Map<String, Object>{
                'label' => fieldDesc.getLabel() + ':' + fieldDesc.getName()
                , 'value' => fieldDesc.getName()
            });
        }
        return ret;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getControlDisplayFieldNameSels() {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        SObjectType sObjType = ermt__Control__c.getSObjectType();
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        for (SObjectField field : sObjDesc.fields.getMap().values()) {
            DescribeFieldResult fieldDesc = field.getDescribe();
            ret.add(new Map<String, Object>{
                'label' => fieldDesc.getLabel() + ':' + fieldDesc.getName()
                , 'value' => fieldDesc.getName()
            });
        }
        return ret;
    }

    // リスク一覧表示項目名の取得
    @AuraEnabled
	public static String getRisklistDisplayFieldName(
        Id projectId // プロジェクトID
    ) {
        String ret = null;
        for (ermt__Project__c p : [
            SELECT ermt__RisklistDisplayFieldNameApproval__c
            FROM ermt__Project__c
            WHERE Id = :projectId
            LIMIT 1
        ]) {
            ret = p.ermt__RisklistDisplayFieldNameApproval__c;
        }
        return ret;
    }

    @AuraEnabled
	public static ApprovalResult applyApproval(String comment, List<String> riskIdApproval) {
        ApprovalResult result = new ApprovalResult();
        result.successCount = 0;
        result.failCount = 0;
        try {
            List<Approval.ProcessSubmitRequest> apps = new List<Approval.ProcessSubmitRequest>();
            for(String riskId: riskIdApproval){
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setObjectId(riskId);
                approvalRequest.setComments(comment);
                apps.add(approvalRequest);
            }
            Approval.ProcessResult [] proResult = Approval.process(apps);
            for (Approval.ProcessResult re: proResult){
                if (re.isSuccess()){
                    result.successCount += 1;
                } else {
                    result.failCount += 1;
                }
            }
            result.isSuccess = true;
            return result;
        } catch (Exception e) {
            system.debug(e.getMessage() + ': ' + e.getLineNumber() + ': ' + e.getCause());
            result.isSuccess = false;
            result.errorMessage = e.getMessage() + ': ' + e.getLineNumber() + ': ' + e.getCause();
            return result;
        }
    }

    @AuraEnabled
	public static Map<String, FieldDescribe> getRiskFieldDescByName(
        List<String> dispFieldNames
    ) {
        Map<String, FieldDescribe> ret = new Map<String, FieldDescribe>();
        SObjectType sObjType = ermt__Risk__c.getSObjectType();
        for (String fieldName : dispFieldNames) {
            DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
            if (fieldDesc != null && fieldDesc.isAccessible()) {
                ret.put(fieldName, new FieldDescribe(
                    fieldName
                    , fieldDesc.getLabel()
                    , String.valueOf(fieldDesc.getType())
                    , fieldDesc.isNillable()
                    , fieldDesc.isUpdateable()
                ));
            }
        }
        return ret;
    }

    @AuraEnabled
	public static Map<String, FieldDescribe> getRiskAssessmentFieldDescByName(
        Id projectId
        , List<String> dispFieldNames
    ) {
        Map<String, FieldDescribe> ret = new Map<String, FieldDescribe>();

        SObjectType classiSObjType = ermt__M_Classification__c.getSObjectType();
        DescribeSObjectResult classiSObjDesc = classiSObjType.getDescribe();
        Map<String, RecordTypeInfo> classiRecTypeInfoByRecTypeDevName = classiSObjDesc.getRecordTypeInfosByDeveloperName();

        Map<String, String> labelByRecTypeDevName = new Map<String, String>();
        for (ermt__Project_Classification_Junc__c pcj : [
            SELECT toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)
            , ermt__M_Classification__r.ermt__Label__c
            , ermt__M_Classification__r.RecordType.DeveloperName
            FROM ermt__Project_Classification_Junc__c
            WHERE ermt__Project__c = :projectId
            AND ermt__M_Classification__r.ermt__invalid__c = false
            ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
        ]) {
            String recTypeDevName = pcj.ermt__M_Classification__r.RecordType.DeveloperName;
            if (!labelByRecTypeDevName.containsKey(recTypeDevName)) {
                String label = pcj.ermt__M_Classification__r.ermt__Label_Pick__c;
                label = (String.isNotEmpty(label) ? label : pcj.ermt__M_Classification__r.ermt__Label__c);
                labelByRecTypeDevName.put(recTypeDevName, label);
            }
        }
        SObjectType riskAssSObjType = ermt__RiskAssessment__c.getSObjectType();
        SObjectType riskAssClsSObjType = ermt__RiskAssessment_Classification_Junc__c.getSObjectType();
        DescribeSObjectResult riskAssClsSObjDesc = riskAssClsSObjType.getDescribe();
        for (String fieldName : dispFieldNames) {
            if (
                fieldName == System.Label.ClassiRecordType_AnalyseTiming ||
                fieldName == System.Label.ClassiRecordType_Probability ||
                fieldName == System.Label.ClassiRecordType_ResultImpact ||
                fieldName == System.Label.ClassiRecordType_ThirdEvaluation
            ) {
                if (riskAssClsSObjDesc.isAccessible()) {
                    String label = labelByRecTypeDevName.get(fieldName);
                    if (String.isEmpty(label)) {
                        RecordTypeInfo classiRecTypeInfo = classiRecTypeInfoByRecTypeDevName.get(fieldName);
                        label = (classiRecTypeInfo == null ? System.Label.Select_NotSet : classiRecTypeInfo.getName());
                    }
                    ret.put(fieldName, new FieldDescribe(
                        fieldName
                        , label
                        , String.valueOf(Schema.DisplayType.PICKLIST)
                        , true
                        , riskAssClsSObjDesc.isCreateable() && riskAssClsSObjDesc.isDeletable()
                    ));
                }
            } else {
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(riskAssSObjType, fieldName);
                if (fieldDesc != null && fieldDesc.isAccessible()) {
                    ret.put(fieldName, new FieldDescribe(
                        fieldName
                        , fieldDesc.getLabel()
                        , String.valueOf(fieldDesc.getType())
                        , fieldDesc.isNillable()
                        , fieldDesc.isUpdateable()
                    ));
                }
            }
        }
        return ret;
    }

    @AuraEnabled
	public static Map<String, FieldDescribe> getClassificationFieldDescByName(
        List<String> dispFieldNames
    ) {
        Map<String, FieldDescribe> ret = new Map<String, FieldDescribe>();
        SObjectType sObjType = ermt__M_Classification__c.getSObjectType();
        for (String fieldName : dispFieldNames) {
            DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
            if (fieldDesc != null && fieldDesc.isAccessible()) {
                ret.put(fieldName, new FieldDescribe(
                    fieldName
                    , fieldDesc.getLabel()
                    , String.valueOf(fieldDesc.getType())
                    , fieldDesc.isNillable()
                    , fieldDesc.isUpdateable()
                ));
            }
        }
        return ret;
    }

    @AuraEnabled
    public static Map<String, Object> getRisks(
        Id projectId
        , List<String> dispFieldNames
        , Id previousLastId
        , String previousLastName
    ) {
        List<ermt__Risk__c> risks = [SELECT id, ermt__Project__r.ermt__AnalyseTimingDefault__c, ermt__Project__r.ermt__AnalyseTimingDefault__r.RecordType.DeveloperName from ermt__Risk__c k where ermt__Project__c = :projectId];
        List<String> riskIds = new List<String>();
        for (ermt__Risk__c risk: risks){
            riskIds.add(risk.id);
        }
        List<String> mClassificationId = new List<String>();
        for (ermt__Risk__c risk: risks){
            mClassificationId.add(risk.ermt__Project__r.ermt__AnalyseTimingDefault__c);
        }
        List<ermt__RiskAssessment_Classification_Junc__c> riskAss = [select ermt__RiskAssessment__r.ermt__Risk__r.Id from ermt__RiskAssessment_Classification_Junc__c where ermt__M_Classification__c in: mClassificationId and  ermt__RiskAssessment__r.ermt__Risk__r.Id in :riskIds];
        List<String> riskIdFilters = new List<String>();
        for (ermt__RiskAssessment_Classification_Junc__c riskAs: riskAss){
            riskIdFilters.add(riskAs.ermt__RiskAssessment__r.ermt__Risk__r.Id);
        }

        Map<String, String> fieldNameMap = new Map<String, String>();
        SObjectType riskSObjType = ermt__Risk__c.getSObjectType();
        String query = '';
        query += 'SELECT Id, Name, UserRecordAccess.HasEditAccess';
        fieldNameMap.put('Id', 'Id');
        fieldNameMap.put('Name', 'Name');
        for (String fieldName : dispFieldNames) {
            if (fieldName == 'Id' || fieldName == 'Name') {
            } else {
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(riskSObjType, fieldName);
                if (fieldDesc.isAccessible()) {
                    String type = String.valueOf(fieldDesc.getType());
                    query += ', ' + fieldName;
                    fieldNameMap.put(fieldName, fieldName);
                    if (
                        type == String.valueOf(Schema.DisplayType.PICKLIST) ||
                        type == String.valueOf(Schema.DisplayType.MULTIPICKLIST)
                    ) {
                        query += ', toLabel(' + fieldName + ') ' + fieldName + '_Label';
                        fieldNameMap.put(fieldName + '_Label', fieldName + '_Label');
                    } else if (
                        type == String.valueOf(Schema.DisplayType.REFERENCE)
                    ) {
                        String fieldName2 = fieldDesc.getRelationshipName() + '.Name';
                        DescribeFieldResult fieldDesc2 = CommonUtil.getFieldDescribe(riskSObjType, fieldName2);
                        if (fieldDesc2 != null && fieldDesc2.isAccessible()) {
                            query += ', ' + fieldName2;
                            fieldNameMap.put(fieldName2, fieldName + '_Label');
                        }
                    }
                }
            }
        }
        query += ' FROM ermt__Risk__c';
        query += ' WHERE id in :riskIdFilters';
        if (String.isNotEmpty(previousLastId) && String.isNotEmpty(previousLastName)) {
            query += ' AND (Name > :previousLastName';
            query += ' OR (Name = :previousLastName AND Id > :previousLastId))';
        }
        ermt__ProjectRisklistApprovalStatusSetting__c setting = ermt__ProjectRisklistApprovalStatusSetting__c.getInstance();
        List<String> ops = new List<String>();
        if (setting.ermt__ApprovalStatusList__c != '') {
            ops = setting.ermt__ApprovalStatusList__c.split(';');
            query += ' AND (ermt__ApprovalStatus__c = \'\' OR ermt__ApprovalStatus__c IN :ops)';
        }
        query += ' ORDER BY Name, Id';
        query += ' LIMIT :QURETY_LIMIT';
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        Id lastId = null;
        String lastName = null;
        Integer cnt = 0;
        for (ermt__Risk__c r : Database.query(query)) {
            Map<String, Object> rec = new Map<String, Object>();
            for (String fieldName : fieldNameMap.keySet()) {
                String name = fieldNameMap.get(fieldName);
                Object value = CommonUtil.getFieldValue(r, fieldName);
                rec.put(name, value);
            }
            rec.put('HasEditAccess', r.UserRecordAccess.HasEditAccess);
            data.add(rec);
            lastId = r.Id;
            lastName = r.Name;
            cnt++;
        }
        Boolean isContinue = (cnt >= QURETY_LIMIT);
        return new Map<String, Object>{
            'data' => data
            , 'lastId' => lastId
            , 'lastName' => lastName
            , 'isContinue' => isContinue
        };
    }

    @AuraEnabled
    public static Map<String, Object> getRiskAssessmentsByRiskId(
        Id projectId
        , List<String> dispFieldNames
        , Id previousLastId
        , String previousLastName
    ) {
        List<ermt__Risk__c> risks = [SELECT id, ermt__Project__r.ermt__AnalyseTimingDefault__c, ermt__Project__r.ermt__AnalyseTimingDefault__r.RecordType.DeveloperName from ermt__Risk__c k where ermt__Project__c = :projectId];
        List<String> riskIds = new List<String>();
        for (ermt__Risk__c risk: risks){
            riskIds.add(risk.id);
        }
        List<String> mClassificationId = new List<String>();
        for (ermt__Risk__c risk: risks){
            mClassificationId.add(risk.ermt__Project__r.ermt__AnalyseTimingDefault__c);
        }
        List<ermt__RiskAssessment_Classification_Junc__c> riskAss = [select ermt__RiskAssessment__r.ermt__Risk__r.Id from ermt__RiskAssessment_Classification_Junc__c where ermt__M_Classification__c in: mClassificationId and  ermt__RiskAssessment__r.ermt__Risk__r.Id in :riskIds];
        List<String> riskIdFilters = new List<String>();
        for (ermt__RiskAssessment_Classification_Junc__c riskAs: riskAss){
            riskIdFilters.add(riskAs.ermt__RiskAssessment__r.ermt__Risk__r.Id);
        }

        Map<String, String> fieldNameMap = new Map<String, String>();
        SObjectType riskAssSObjType = ermt__RiskAssessment__c.getSObjectType();
        SObjectType riskAssClsSObjType = ermt__RiskAssessment_Classification_Junc__c.getSObjectType();
        DescribeSObjectResult riskAssClsSObjDesc = riskAssClsSObjType.getDescribe();
        String query = '';
        query += 'SELECT Id, Name, ermt__Risk__c, RecordType.DeveloperName, UserRecordAccess.HasEditAccess';
        fieldNameMap.put('Id', 'Id');
        fieldNameMap.put('Name', 'Name');
        fieldNameMap.put('ermt__Risk__c', 'ermt__Risk__c');
        fieldNameMap.put('RecordType.DeveloperName', 'RecordType.DeveloperName');
        for (String fieldName : dispFieldNames) {
            if (
                fieldName == 'Id' ||
                fieldName == 'Name' ||
                fieldName == 'ermt__Risk__c' ||
                fieldName == 'RecordType.DeveloperName'
            ) {
            } else if (
                fieldName == System.Label.ClassiRecordType_AnalyseTiming ||
                fieldName == System.Label.ClassiRecordType_Probability ||
                fieldName == System.Label.ClassiRecordType_ResultImpact ||
                fieldName == System.Label.ClassiRecordType_ThirdEvaluation
            ) {
                if(riskAssClsSObjDesc.isAccessible()) {
                    fieldNameMap.put(fieldName, fieldName);
                }
            } else {
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(riskAssSObjType, fieldName);
                if (fieldDesc.isAccessible()) {
                    String type = String.valueOf(fieldDesc.getType());
                    query += ', ' + fieldName;
                    fieldNameMap.put(fieldName, fieldName);
                    if (
                        type == String.valueOf(Schema.DisplayType.PICKLIST) ||
                        type == String.valueOf(Schema.DisplayType.MULTIPICKLIST)
                    ) {
                        query += ', toLabel(' + fieldName + ') ' + fieldName + '_Label';
                        fieldNameMap.put(fieldName + '_Label', fieldName + '_Label');
                    } else if (
                        type == String.valueOf(Schema.DisplayType.REFERENCE)
                    ) {
                        String fieldName2 = fieldDesc.getRelationshipName() + '.Name';
                        DescribeFieldResult fieldDesc2 = CommonUtil.getFieldDescribe(riskAssSObjType, fieldName2);
                        if (fieldDesc2 != null && fieldDesc2.isAccessible()) {
                            query += ', ' + fieldName2;
                            fieldNameMap.put(fieldName2, fieldName + '_Label');
                        }
                    }
                }
            }
        }
        query += ', (SELECT ermt__M_Classification__c';
        query += ', ermt__M_Classification__r.ermt__Label__c';
        query += ', toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)';
        query += ', ermt__M_Classification__r.ermt__ViewNo__c';
        query += ', ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName';
        query += ' FROM ermt__RiskAssessment_Classification_Junc__r';
        query += ' WHERE (ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName = \'' +
            System.Label.ClassiRecordType_AnalyseTiming + '\'';
        query += ')';
        query += ' OR (ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName = \'' +
            System.Label.ClassiRecordType_Probability + '\'';
        query += ')';
        query += ' OR (ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName = \'' +
            System.Label.ClassiRecordType_ResultImpact + '\'';
        query += ')';
        query += ' OR (ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName = \'' +
            System.Label.ClassiRecordType_ThirdEvaluation + '\'';
        query += ')';
        query += ' ORDER BY ermt__M_Classification__r.ermt__ViewNo__c';
        query += ')';
        query += ' FROM ermt__RiskAssessment__c';
        query += ' WHERE ermt__Risk__c in : riskIdFilters';
        if (String.isNotEmpty(previousLastId) && String.isNotEmpty(previousLastName)) {
            query += ' AND (Name > :previousLastName';
            query += ' OR (Name = :previousLastName AND Id > :previousLastId))';
        }
        query += ' ORDER BY Name, Id';
        query += ' LIMIT :QURETY_LIMIT';
        System.debug('query=' + query);
        Map<Id, List<Map<String, Object>>> data = new Map<Id, List<Map<String, Object>>>();
        Id lastId = null;
        String lastName = null;
        Integer cnt = 0;
        for (ermt__RiskAssessment__c ra : Database.query(query)) {
            Id riskId = ra.ermt__Risk__c;
            Map<String, Object> rec = new Map<String, Object>();

            Boolean isTarget = true;
            if (isTarget) {
                for (String fieldName : fieldNameMap.keySet()) {
                    if (
                        fieldName == System.Label.ClassiRecordType_AnalyseTiming ||
                        fieldName == System.Label.ClassiRecordType_Probability ||
                        fieldName == System.Label.ClassiRecordType_ResultImpact ||
                        fieldName == System.Label.ClassiRecordType_ThirdEvaluation
                    ) {
                        ermt__RiskAssessment_Classification_Junc__c riskAssCls = null;
                        for (ermt__RiskAssessment_Classification_Junc__c rac : ra.ermt__RiskAssessment_Classification_Junc__r) {
                            if (rac.ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName == fieldName) {
                                riskAssCls = rac;
                                break;
                            }
                        }
                        String name = fieldName;
                        rec.put(name, (riskAssCls == null ? null : riskAssCls.ermt__M_Classification__c));
                        name = fieldName + '_Label';
                        rec.put(name, (riskAssCls == null ? null : (String.isEmpty(riskAssCls.ermt__M_Classification__r.ermt__Label_Pick__c) ?
                            riskAssCls.ermt__M_Classification__r.ermt__Label__c : riskAssCls.ermt__M_Classification__r.ermt__Label_Pick__c)));
                        name = fieldName + '_ViewNo';
                        rec.put(name, (riskAssCls == null ? null : riskAssCls.ermt__M_Classification__r.ermt__ViewNo__c));
                    } else {
                        String name = fieldNameMap.get(fieldName);
                        Object value = CommonUtil.getFieldValue(ra, fieldName);
                        rec.put(name, value);
                    }
                }
                rec.put('HasEditAccess', ra.UserRecordAccess.HasEditAccess);
                List<Map<String, Object>> recs = data.get(riskId);
                if (recs == null) {
                    recs = new List<Map<String, Object>>();
                    data.put(riskId, recs);
                }
                recs.add(rec);
            }
            lastId = ra.Id;
            lastName = ra.Name;
            cnt++;
        }
        Boolean isContinue = (cnt >= QURETY_LIMIT);
        return new Map<String, Object>{
            'data' => data
            , 'lastId' => lastId
            , 'lastName' => lastName
            , 'isContinue' => isContinue
        };
    }

    @AuraEnabled
    public static Map<String, Object> getClassificationsByRiskId(
        Id projectId
        , List<String> dispFieldNames
        , String kindRecordType
        , Id previousLastId
        , String previousLastName
    ) {
        List<ermt__Risk__c> risks = [SELECT id, ermt__Project__r.ermt__AnalyseTimingDefault__c, ermt__Project__r.ermt__AnalyseTimingDefault__r.RecordType.DeveloperName from ermt__Risk__c k where ermt__Project__c = :projectId];
        List<String> riskIds = new List<String>();
        for (ermt__Risk__c risk: risks){
            riskIds.add(risk.id);
        }
        List<String> mClassificationId = new List<String>();
        for (ermt__Risk__c risk: risks){
            mClassificationId.add(risk.ermt__Project__r.ermt__AnalyseTimingDefault__c);
        }
        List<ermt__RiskAssessment_Classification_Junc__c> riskAss = [select ermt__RiskAssessment__r.ermt__Risk__r.Id from ermt__RiskAssessment_Classification_Junc__c where ermt__M_Classification__c in: mClassificationId and  ermt__RiskAssessment__r.ermt__Risk__r.Id in :riskIds];
        List<String> riskIdFilters = new List<String>();
        for (ermt__RiskAssessment_Classification_Junc__c riskAs: riskAss){
            riskIdFilters.add(riskAs.ermt__RiskAssessment__r.ermt__Risk__r.Id);
        }
        String key = kindRecordType.split(':').size() > 1? kindRecordType.split(':')[1].trim(): kindRecordType.trim();
        String query = '';
        query += 'SELECT Id, Name, ermt__Risk__c, ermt__M_Classification__c';
        query += ' FROM ermt__Risk_Classification_Junc__c';
        query += ' WHERE ermt__Risk__c in :riskIdFilters and (ermt__M_Classification__r.ermt__ParentMClassification_del__r.Name =:key ';
        query += ' OR ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__Label_Pick__c =:key ';
        query += ' OR toLabel(ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__Label_Pick__c) =:key';
        query += ' OR ermt__M_Classification__r.ermt__ParentMClassification_del__r.ermt__Label__c =:key )' ;
        if (String.isNotEmpty(previousLastId) && String.isNotEmpty(previousLastName)) {
            query += ' AND (Name > :previousLastName';
            query += ' OR (Name = :previousLastName AND Id > :previousLastId))';
        }
        query += ' ORDER BY Name, Id';
        query += ' LIMIT :QURETY_LIMIT';
        Map<Id, List<ermt__Risk_Classification_Junc__c>> riskClassiByClassiId = new Map<Id, List<ermt__Risk_Classification_Junc__c>>();
        Set<Id> classiIdSet = new Set<Id>();
        Id lastId = null;
        String lastName = null;
        Integer cnt = 0;
        for (ermt__Risk_Classification_Junc__c rcj : Database.query(query)) {
            List<ermt__Risk_Classification_Junc__c> riskClassification = riskClassiByClassiId.get(rcj.ermt__M_Classification__c);
            if (riskClassification == null) {
                riskClassification = new List<ermt__Risk_Classification_Junc__c>();
                riskClassiByClassiId.put(rcj.ermt__M_Classification__c, riskClassification);
            }
            riskClassification.add(rcj);
            classiIdSet.add(rcj.ermt__M_Classification__c);
            lastId = rcj.Id;
            lastName = rcj.Name;
            cnt++;
        }
        Boolean isContinue = (cnt >= QURETY_LIMIT);

        Map<String, String> fieldNameMap = new Map<String, String>();
        SObjectType sObjType = ermt__M_Classification__c.getSObjectType();
        query = '';
        query += 'SELECT Id';
        fieldNameMap.put('Id', 'Id');
        dispFieldNames.add('ermt__Label__c');
        for (String fieldName : dispFieldNames) {
            if (fieldName == 'Id') {
            } else {
                DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
                if (fieldDesc.isAccessible()) {
                    String type = String.valueOf(fieldDesc.getType());
                    query += ', ' + fieldName;
                    fieldNameMap.put(fieldName, fieldName);
                    if (
                        type == String.valueOf(Schema.DisplayType.PICKLIST) ||
                        type == String.valueOf(Schema.DisplayType.MULTIPICKLIST)
                    ) {
                        query += ', toLabel(' + fieldName + ') ' + fieldName + '_Label';
                        fieldNameMap.put(fieldName + '_Label', fieldName + '_Label');
                    } else if (
                        type == String.valueOf(Schema.DisplayType.REFERENCE)
                    ) {
                        String fieldName2 = fieldDesc.getRelationshipName() + '.Name';
                        DescribeFieldResult fieldDesc2 = CommonUtil.getFieldDescribe(sObjType, fieldName2);
                        if (fieldDesc2 != null && fieldDesc2.isAccessible()) {
                            query += ', ' + fieldName2;
                            fieldNameMap.put(fieldName2, fieldName + '_Label');
                        }
                    }
                }
            }
        }
        query += ' FROM ermt__M_Classification__c';
        query += ' WHERE Id IN :classiIdSet';
        query += ' ORDER BY Name';
        Map<Id, List<Map<String, Object>>> data = new Map<Id, List<Map<String, Object>>>();
        Map<Id, List<Map<String, Object>>> result = new Map<Id, List<Map<String, Object>>>();
        for (ermt__M_Classification__c c : Database.query(query)) {
            Id controlId = c.Id;
            Map<String, Object> rec = new Map<String, Object>();
            Object value = CommonUtil.getFieldValue(c, 'ermt__Label_Pick__c') != null ? CommonUtil.getFieldValue(c, 'ermt__Label_Pick__c'):CommonUtil.getFieldValue(c, 'ermt__Label__c');
            rec.put('ermt__Label_Pick__c', value);
            List<ermt__Risk_Classification_Junc__c> riskClassification = riskClassiByClassiId.get(controlId);
            if (riskClassification != null) {
                for (ermt__Risk_Classification_Junc__c riskCls : riskClassification) {
                    Map<String, Object> rec2 = rec.clone();
                    rec2.put('riskControlId', riskCls.Id);
                    List<Map<String, Object>> recs = data.get(riskCls.ermt__Risk__c);
                    if (recs == null) {
                        recs = new List<Map<String, Object>>();
                        data.put(riskCls.ermt__Risk__c, recs);
                    }
                    recs.add(rec2);
                }

            }
        }
        //add more label picklist in 1 line
        for(Id riskId : data.keySet()){
            List<String> pickVal = new List<String>();
            Object riskClassiId;
            for (Map<String, Object> t: data.get(riskId)){
                pickVal.add(String.valueOf(t.get('ermt__Label_Pick__c')));
                riskClassiId = t.get('riskControlId');
            }
            Map<String, Object> rec = new Map<String, Object>();
            rec.put('ermt__Label_Pick__c', String.join(pickVal, '；'));
            rec.put('riskControlId', riskClassiId);
            List<Map<String, Object>> recs = new List<Map<String, Object>>();
            recs.add(rec);
            result.put(riskId, recs);
        }
        return new Map<String, Object>{
            'data' => result
            , 'lastId' => lastId
            , 'lastName' => lastName
            , 'isContinue' => isContinue
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getGroupClassiSels(Id projectId, String classiGroupRecordTypeName) {
        List<Map<String, String>> ret = new List<Map<String, String>>();
        for (ermt__Project_Classification_Junc__c pcj : [
            SELECT ermt__M_Classification__c
            , toLabel(ermt__M_Classification__r.ermt__Kind__c)
            , toLabel(ermt__M_Classification__r.ermt__Label_Pick__c)
            , ermt__M_Classification__r.ermt__Label__c
            FROM ermt__Project_Classification_Junc__c
            WHERE ermt__Project__c = :projectId
            AND ermt__M_Classification__r.RecordType.DeveloperName = :classiGroupRecordTypeName
            AND ermt__M_Classification__r.ermt__invalid__c = false
            ORDER BY ermt__M_Classification__r.ermt__ViewNo__c
        ]) {
            String label = '';
            if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Kind__c)) {
                label += pcj.ermt__M_Classification__r.ermt__Kind__c;
            }
            if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Label_Pick__c)) {
                label += (String.isEmpty(label) ? '' : ': ');
                label += pcj.ermt__M_Classification__r.ermt__Label_Pick__c;
            } else if (String.isNotEmpty(pcj.ermt__M_Classification__r.ermt__Label__c)) {
                label += (String.isEmpty(label) ? '' : ': ');
                label += pcj.ermt__M_Classification__r.ermt__Label__c;
            }
            label = (String.isEmpty(label) ? System.Label.Select_NotSet : label);
            ret.add(new Map<String, String>{
                'label' => label
                , 'value' => label
            });
        }
        return ret;
    }

    @AuraEnabled
	public static Boolean saveRisklistDisplayFieldName(Id projectId, String fieldName) {
        ermt__Project__c prj = new ermt__Project__c(
            Id = projectId
            , ermt__RisklistDisplayFieldNameApproval__c = fieldName
        );
        update prj;
        return true;
    }



    public class FieldDescribe {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isNillable;
        @AuraEnabled public Boolean isUpdateable;

        public FieldDescribe(
            String name
            , String label
            , String type
            , Boolean isNillable
            , Boolean isUpdateable
        ) {
            this.name = name;
            this.label = label;
            this.type = type;
            this.isNillable = isNillable;
            this.isUpdateable = isUpdateable;
        }
    }

    public class ApprovalResult {
        @AuraEnabled public Integer successCount {get;set;}
        @AuraEnabled public Integer failCount {get;set;}
        @AuraEnabled public Boolean isSuccess {get;set;}
        @AuraEnabled public String errorMessage {get;set;}
    }
}