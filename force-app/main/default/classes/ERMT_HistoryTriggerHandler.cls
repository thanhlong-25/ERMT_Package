public with sharing class ERMT_HistoryTriggerHandler {
    // public static void updateNewValue(List<History__c> histories){
    //     Set<String> riskReferenceFields = new Set<String>();
    //     Set<Id> newRiskIds = new Set<Id>();
    //     String queryRisk = '';

    //     Set<String> incidentReferenceFields = new Set<String>();
    //     Set<Id> newIncidentIds = new Set<Id>();
    //     String queryIncident = '';

    //     for(History__c hs : histories){
    //         String fieldName = hs.FieldName__c;
    //         String objName = hs.ObjectLog__c;
    //         String rcId = hs.RecordId__c;

    //         switch on objName {
    //             when 'ermt__Risk__c' {
    //                 SObjectType sObjType = Schema.getGlobalDescribe().get('ermt__Risk__c');
    //                 DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
    //                 riskReferenceFields.add(fieldDesc.getRelationshipName() + '.Name');
    //                 newRiskIds.add(rcId);
    //             }
    //             when 'ermt__Incident__c'{
    //                 SObjectType sObjType = Schema.getGlobalDescribe().get('ermt__Incident__c');
    //                 DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
    //                 incidentReferenceFields.add(fieldDesc.getRelationshipName() + '.Name');
    //                 newIncidentIds.add(rcId);
    //             }
    //         }
    //     }

    //     if(riskReferenceFields.size() > 0 ) queryRisk = 'SELECT ID, ' + String.join(new List<String>(riskReferenceFields), ', ') + ' FROM Risk__c WHERE ID IN :newRiskIds';
    //     if(incidentReferenceFields.size() > 0 ) queryIncident = 'SELECT ID, ' + String.join(new List<String>(incidentReferenceFields), ', ') + ' FROM Incident__c WHERE ID IN :newIncidentIds';

    //     Map<Id, Risk__c> risks = String.isNotEmpty(queryRisk) ? new Map<Id, Risk__c>((List<Risk__c>)database.query(queryRisk)) : null;
    //     Map<Id, Incident__c> incidents = String.isNotEmpty(queryIncident) ? new Map<Id, Incident__c>((List<Incident__c>)database.query(queryIncident)) : null;

    //     for(History__c hs : histories){
    //         String rcId = hs.RecordId__c;
    //         String objName = hs.ObjectLog__c;
    //         String rsName = hs.RelationshipName__c;

    //         if(objName == 'ermt__Risk__c'){
    //             hs.NewValue__c = (String) risks.get(rcId).getSObject(rsName).get('Name');
    //         } else if(objName == 'ermt__Incident__c'){
    //             hs.NewValue__c = (String) incidents.get(rcId).getSObject(rsName).get('Name');
    //         }
    //         hs.IsReferenceValueFormatted__c = true;
    //     }

    //     update histories;
    // }


    public static void updateNewValue(List<History__c> histories){
        String objName = histories[0].ObjectLog__c;
        SObjectType sObjType = Schema.getGlobalDescribe().get(objName);

        Set<String> referenceFields = new Set<String>();
        Set<Id> recordIds = new Set<Id>();
        String queryStr = '';

        for(History__c hs : histories){
            String fieldName = hs.FieldName__c;
            String rcId = hs.RecordId__c;
            String rsName = hs.RelationshipName__c;

            referenceFields.add(rsName);
            recordIds.add(rcId);
        }

        if(referenceFields.size() > 0 ){
            queryStr += 'SELECT ID, ' + String.join(new List<String>(referenceFields), ', ');
            queryStr += ' FROM ' + objName;
            queryStr += ' WHERE ID IN :recordIds';
        }

        Map<Id, sObject> sObjectResult = String.isNotEmpty(queryStr) ? new Map<Id, sObject>((List<sObject>)database.query(queryStr)) : null;

        for(History__c hs : histories){
            String rcId = hs.RecordId__c;
            String rsName = hs.RelationshipName__c;
            List<String> relationshipWithName =  rsName.split('\\.');
            hs.NewValue__c = (String) sObjectResult.get(rcId).getSObject(relationshipWithName[0]).get(relationshipWithName[1]);
            hs.IsReferenceValueFormatted__c = true;
        }

        update histories;
    }
}