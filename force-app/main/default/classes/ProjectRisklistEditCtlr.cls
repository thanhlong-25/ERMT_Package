// プロジェクトのリスク一覧（編集用）コントローラ
public without sharing class ProjectRisklistEditCtlr {
    // リスク関連の更新
    @AuraEnabled
    public static Boolean updateRiskRelation(
        List<Map<String, Object>> risks
        , List<Map<String, Object>> riskAssessments
        , List<Map<String, Object>> riskAssessmentClassis
        , List<Map<String, Object>> riskControls
    ) {
        //System.debug('risks=' + risks);
        //System.debug('riskAssessments=' + riskAssessments);
        //System.debug('riskAssessmentClassis=' + riskAssessmentClassis);
        //System.debug('riskControls=' + riskControls);
        Boolean ret = false;
        Savepoint sp = Database.setSavepoint();
        try {
            // リスク
            if (risks != null && !risks.isEmpty()) {
                // リスクIDセットの作成
                Set<Id> riskIdSet = new Set<Id>();
                for (Map<String, Object> rec : risks) {
                    Map<Object, Object> item = (Map<Object, Object>)rec.get('Id');
                    if (item != null) {
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        Id riskId = (Id)value;
                        if (riskId != null) {
                            riskIdSet.add(riskId);
                        }
                    }
                }

                // リスクの取得
                Map<Id, ermt__Risk__c> riskById = new Map<Id, ermt__Risk__c>([
                    SELECT Id FROM ermt__Risk__c
                    WHERE Id IN :riskIdSet
                ]);

                // 更新用リスクの作成
                List<ermt__Risk__c> updRisks = new List<ermt__Risk__c>();
                Map<Id, Decimal> noByRiskId = new Map<Id, Decimal>();
                for (Map<String, Object> rec : risks) {
                    Decimal no = null;
                    ermt__Risk__c risk = new ermt__Risk__c();
                    for (String fieldName : rec.keySet()) {
                        Map<Object, Object> item = (Map<Object, Object>)rec.get(fieldName);
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        if (no == null) no = (Decimal)item.get('no');
                        risk.put(fieldName, value);
                    }
                    if (risk.Id != null && riskById.containsKey(risk.Id)) {
                        updRisks.add(risk);
                        noByRiskId.put(risk.Id, no);
                    }
                }

                // リスクの更新
                if (!updRisks.isEmpty()) {
                    Database.SaveResult[] srs = Database.update(updRisks, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.SaveResult sr : srs) {
                        index++;
                        if (!sr.isSuccess()) {
                            isError = true;
                            ermt__Risk__c risk = updRisks[index];
                            Decimal no = noByRiskId.get(risk.Id);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((no == null ? '' : String.valueOf(no)), sr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
            }

            // リスクアセスメント
            if (riskAssessments != null && !riskAssessments.isEmpty()) {
                // リスクアセスメントIDセットの作成
                Set<Id> riskAssessIdSet = new Set<Id>();
                for (Map<String, Object> rec : riskAssessments) {
                    Map<Object, Object> item = (Map<Object, Object>)rec.get('Id');
                    if (item != null) {
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        Id riskAssessId = (Id)value;
                        if (riskAssessId != null) {
                            riskAssessIdSet.add(riskAssessId);
                        }
                    }
                }

                // リスクアセスメントの取得
                Map<Id, ermt__RiskAssessment__c> riskAssessById = new Map<Id, ermt__RiskAssessment__c>([
                    SELECT Id FROM ermt__RiskAssessment__c
                    WHERE Id IN :riskAssessIdSet
                ]);

                // 更新用のリスクアセスメントの作成
                List<ermt__RiskAssessment__c> updRiskAssesss = new List<ermt__RiskAssessment__c>();
                Map<Id, Decimal> noByRiskAssessId = new Map<Id, Decimal>();
                for (Map<String, Object> rec : riskAssessments) {
                    Decimal no = null;
                    ermt__RiskAssessment__c riskAssess = new ermt__RiskAssessment__c();
                    for (String fieldName : rec.keySet()) {
                        Map<Object, Object> item = (Map<Object, Object>)rec.get(fieldName);
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        if (no == null) no = (Decimal)item.get('no');
                        riskAssess.put(fieldName, value);
                    }
                    if (riskAssess.Id != null && riskAssessById.containsKey(riskAssess.Id)) {
                        updRiskAssesss.add(riskAssess);
                        noByRiskAssessId.put(riskAssess.Id, no);
                    }
                }

                // リスクアセスメントの更新
                if (!updRiskAssesss.isEmpty()) {
                    Database.SaveResult[] srs = Database.update(updRiskAssesss, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.SaveResult sr : srs) {
                        index++;
                        if (!sr.isSuccess()) {
                            isError = true;
                            ermt__RiskAssessment__c riskAssess = updRiskAssesss[index];
                            Decimal no = noByRiskAssessId.get(riskAssess.Id);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((no == null ? '' : String.valueOf(no)), sr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
            }

            // リスクアセスメント分類
            if (riskAssessmentClassis != null && !riskAssessmentClassis.isEmpty()) {
                // リスクアセスメントIDセットの作成
                Set<Id> riskAssessIdSet = new Set<Id>();
                for (Map<String, Object> rec : riskAssessmentClassis) {
                    Map<Object, Object> item = (Map<Object, Object>)rec.get('riskAssessmentId');
                    if (item != null) {
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        Id riskAssessId = (Id)value;
                        if (riskAssessId != null) {
                            riskAssessIdSet.add(riskAssessId);
                        }
                    }
                }

                // リスクアセスメント分類の取得
                Map<String, ermt__RiskAssessment_Classification_Junc__c> riskAssessClassiByKey = new Map<String, ermt__RiskAssessment_Classification_Junc__c>();
                for (ermt__RiskAssessment_Classification_Junc__c rac : [
                    SELECT ermt__RiskAssessment__c
                    , ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName
                    FROM ermt__RiskAssessment_Classification_Junc__c
                    WHERE ermt__RiskAssessment__c IN :riskAssessIdSet
                    AND ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName IN (
                        :System.Label.ClassiRecordType_AnalyseTiming
                        , :System.Label.ClassiRecordType_Probability
                        , :System.Label.ClassiRecordType_ResultImpact
                        , :System.Label.ClassiRecordType_ThirdEvaluation
                    )
                ]) {
                    String key = '';
                    key += rac.ermt__RiskAssessment__c;
                    key += '\t';
                    key += rac.ermt__M_Classification__r.ermt__ParentMClassification_del__r.RecordType.DeveloperName;
                    riskAssessClassiByKey.put(key, rac);
                }

                // 削除・追加用のリスクアセスメント分類の作成
                List<ermt__RiskAssessment_Classification_Junc__c> insRiskAssessClassis = new List<ermt__RiskAssessment_Classification_Junc__c>();
                List<ermt__RiskAssessment_Classification_Junc__c> delRiskAssessClassis = new List<ermt__RiskAssessment_Classification_Junc__c>();
                Map<Id, Decimal> noById = new Map<Id, Decimal>();
                for (Map<String, Object> rec : riskAssessmentClassis) {
                    Decimal no = null;
                    String classiRecTypeDevName = null;
                    Id riskAssessId = null;
                    Id classiId = null;
                    for (String fieldName : rec.keySet()) {
                        Map<Object, Object> item = (Map<Object, Object>)rec.get(fieldName);
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        if (no == null) no = (Decimal)item.get('no');
                        if (fieldName == 'ClassiRecordType') {
                            classiRecTypeDevName = (String)value;
                        } else if (fieldName == 'riskAssessmentId') {
                            riskAssessId = (Id)value;
                        } else if (fieldName == 'classiId') {
                            classiId = (Id)value;
                        }
                    }
                    if (riskAssessId != null && classiId != null) {
                        insRiskAssessClassis.add(new ermt__RiskAssessment_Classification_Junc__c(
                            ermt__RiskAssessment__c = riskAssessId
                            , ermt__M_Classification__c = classiId
                        ));
                        noById.put(riskAssessId, no);
                    }
                    String key = '';
                    if (riskAssessId != null) key += riskAssessId;
                    key += '\t';
                    if (classiRecTypeDevName != null) key += classiRecTypeDevName;
                    ermt__RiskAssessment_Classification_Junc__c riskAssessClassi = riskAssessClassiByKey.get(key);
                    if (riskAssessClassi != null) {
                        delRiskAssessClassis.add(new ermt__RiskAssessment_Classification_Junc__c(
                            Id = riskAssessClassi.Id
                        ));
                        noById.put(riskAssessClassi.Id, no);
                    }
                }

                // リスクアセスメント分類の削除・追加
                if (!delRiskAssessClassis.isEmpty()) {
                    Database.DeleteResult[] drs = Database.delete(delRiskAssessClassis, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.DeleteResult dr : drs) {
                        index++;
                        if (!dr.isSuccess()) {
                            isError = true;
                            ermt__RiskAssessment_Classification_Junc__c riskAssessClassi = delRiskAssessClassis[index];
                            Decimal no = noById.get(riskAssessClassi.Id);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((no == null ? '' : String.valueOf(no)), dr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
                if (!insRiskAssessClassis.isEmpty()) {
                    Database.SaveResult[] srs = Database.insert(insRiskAssessClassis, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.SaveResult sr : srs) {
                        index++;
                        if (!sr.isSuccess()) {
                            isError = true;
                            ermt__RiskAssessment_Classification_Junc__c riskAssessClassi = insRiskAssessClassis[index];
                            Decimal no = noById.get(riskAssessClassi.ermt__RiskAssessment__c);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((no == null ? '' : String.valueOf(no)), sr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
            }

            // リスク対応策
            if (riskControls != null && !riskControls.isEmpty()) {
                // リスク対応策IDセットの作成
                Set<Id> riskControlIdSet = new Set<Id>();
                for (Map<String, Object> rec : riskControls) {
                    Map<Object, Object> item = (Map<Object, Object>)rec.get('Id');
                    if (item != null) {
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        Id riskControlId = (Id)value;
                        if (riskControlId != null) {
                            riskControlIdSet.add(riskControlId);
                        }
                    }
                }

                // リスク対応策の取得
                Map<Id, ermt__Risk_Control_Junc__c> riskControlById = new Map<Id, ermt__Risk_Control_Junc__c>([
                    SELECT Id, ermt__Risk__c FROM ermt__Risk_Control_Junc__c
                    WHERE Id IN :riskControlIdSet
                ]);

                // 削除・追加用のリスク対応策の作成
                List<ermt__Risk_Control_Junc__c> insRiskControls = new List<ermt__Risk_Control_Junc__c>();
                List<ermt__Risk_Control_Junc__c> delRiskControls = new List<ermt__Risk_Control_Junc__c>();
                Map<String, List<Decimal>> nosByKey = new Map<String, List<Decimal>>();
                for (Map<String, Object> rec : riskControls) {
                    Decimal no = null;
                    Id riskControlId = null;
                    Id riskId = null;
                    Id controlId = null;
                    for (String fieldName : rec.keySet()) {
                        Map<Object, Object> item = (Map<Object, Object>)rec.get(fieldName);
                        String type = (String)item.get('type');
                        Object value = convertValue(item.get('value'), type);
                        no = (Decimal)item.get('no');
                        if (fieldName == 'Id') {
                            riskControlId = (Id)value;
                        } else if (fieldName == 'ermt__Risk__c') {
                            riskId = (Id)value;
                        } else if (fieldName == 'ermt__Control__c') {
                            controlId = (Id)value;
                        }
                    }
                    if (riskId != null && controlId != null) {
                        insRiskControls.add(new ermt__Risk_Control_Junc__c(
                            ermt__Risk__c = riskId
                            , ermt__Control__c = controlId
                        ));
                        String key = riskId + ',' + controlId;
                        List<Decimal> nos = nosByKey.get(key);
                        if (nos == null) {
                            nos = new List<Decimal>();
                            nosByKey.put(key, nos);
                        }
                        nos.add(no);
                    }
                    ermt__Risk_Control_Junc__c riskControl = riskControlById.get(riskControlId);
                    if (riskControl != null) {
                        delRiskControls.add(new ermt__Risk_Control_Junc__c(
                            Id = riskControl.Id
                        ));
                        List<Decimal> nos = nosByKey.get(riskControl.Id);
                        if (nos == null) {
                            nos = new List<Decimal>();
                            nosByKey.put(riskControl.Id, nos);
                        }
                        nos.add(no);
                    }
                }
                
                // リスク対応策の削除・追加
                if (!delRiskControls.isEmpty()) {
                    Database.DeleteResult[] drs = Database.delete(delRiskControls, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.DeleteResult dr : drs) {
                        index++;
                        if (!dr.isSuccess()) {
                            isError = true;
                            ermt__Risk_Control_Junc__c riskControl = delRiskControls[index];
                            List<Decimal> nos = nosByKey.get(riskControl.Id);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((nos == null ? '' : String.join(nos, ',')), dr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
                if (!insRiskControls.isEmpty()) {
                    Database.SaveResult[] srs = Database.insert(insRiskControls, false);
                    Integer index = -1;
                    Boolean isError = false;
                    String errMsg = '';
                    for (Database.SaveResult sr : srs) {
                        index++;
                        if (!sr.isSuccess()) {
                            isError = true;
                            ermt__Risk_Control_Junc__c riskControl = insRiskControls[index];
                            String key = riskControl.ermt__Risk__c + ',' + riskControl.ermt__Control__c;
                            List<Decimal> nos = nosByKey.get(key);
                            errMsg += (String.isEmpty(errMsg) ? '' : ' ') + 
                                getErrorMessage((nos == null ? '' : String.join(nos, ',')), sr.getErrors());
                        }
                    }
                    if (isError) {
                        AuraHandledException ex = new AuraHandledException(errMsg);
                        ex.setMessage(errMsg);
                        throw ex;
                    }
                }
            }
            ret = true;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('LineNo.' + e.getLineNumber() + ':' + e.getMessage());
            String errMsg = System.Label.ProjectRisklist_SaveError;
            errMsg += e.getMessage();
            AuraHandledException ex = new AuraHandledException(errMsg);
            ex.setMessage(errMsg);
            throw ex;
        }
        return ret;
    }

    // 値の変換
    @TestVisible
    private static Object convertValue(Object value, String type) {
        Object ret = null;
        if (type == String.valueOf(Schema.DisplayType.BOOLEAN)) {
            ret = (String.valueOf(value) == FieldValueInputCtlr.VALUE_TRUE);
        } else if (
            type == String.valueOf(Schema.DisplayType.CURRENCY)
            || type == String.valueOf(Schema.DisplayType.DOUBLE)
            || type == String.valueOf(Schema.DisplayType.INTEGER)
            || type == String.valueOf(Schema.DisplayType.LONG)
            || type == String.valueOf(Schema.DisplayType.PERCENT)
        ) {
            String s = String.valueOf(value);
            if (String.isNotEmpty(s)) {
                ret = Decimal.valueOf(s);
            }
        } else if (type == String.valueOf(Schema.DisplayType.DATE)) {
            String s = String.valueOf(value);
            if (String.isNotEmpty(s)) {
                ret = Date.valueOf(s);
            }
        } else if (type == String.valueOf(Schema.DisplayType.TIME)) {
            String s = String.valueOf(value);
            if (String.isNotEmpty(s)) {
                List<String> arr = s.split('[:.Z]');
                Integer size = arr.size();
                Integer hour = (size < 1 ? 0 : Integer.valueOf(arr[0]));
                Integer minute = (size < 2 ? 0 : Integer.valueOf(arr[1]));
                Integer second = (size < 3 ? 0 : Integer.valueOf(arr[2]));
                Integer millisecond = (size < 4 ? 0 : Integer.valueOf(arr[3]));
                ret = Time.newInstance(hour, minute, second, millisecond);
            }
        } else if (type == String.valueOf(Schema.DisplayType.DATETIME)) {
            String s = String.valueOf(value);
            if (String.isNotEmpty(s)) {
                s = s.replace('T', ' ');
                s = s.replace('.000Z', '');
                ret = Datetime.valueOfGMT(s);
            }
        } else if (type == String.valueOf(Schema.DisplayType.MULTIPICKLIST)) {
            if (value instanceof List<Object>) {
                String s = '';
                for (Object o : (List<Object>)value) {
                    s += (String.isEmpty(s) ? '' : ';');
                    s += String.valueOf(o);
                }
                ret = s;
            }
        } else if (
            type == String.valueOf(Schema.DisplayType.ID) ||
            type == String.valueOf(Schema.DisplayType.REFERENCE)
        ) {
            String s = String.valueOf(value);
            if (String.isNotEmpty(s)) {
                ret = s;
            }
        } else {
            ret = value;
        }
        return ret;
    }

    // エラーメッセージの取得
    private static String getErrorMessage(String nos, List<Database.Error> errors) {
        String ret = '';
        if (String.isNotEmpty(nos)) ret += 'No.' + nos + ':';
        if (errors != null) {
            for(Database.Error err : errors) {
                ret += err.getMessage();
            }
        }
        return ret;
    }
}