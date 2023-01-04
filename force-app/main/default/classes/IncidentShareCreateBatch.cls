global class IncidentShareCreateBatch implements Database.Batchable<sObject> {
    global static final List<String> ruleExecuteBatch = new List<String>{ 'Read', 'Edit' };
    global static Incident_Configration__mdt configMdt = getConfigCustomMeta();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Organization__c,
                    (
                        SELECT Id
                        FROM Shares
                        WHERE
                            RowCause = 'ermt__AccountPublicGroupSharingReason_Read__c'
                            OR RowCause = 'ermt__AccountPublicGroupSharingReason_Edit__c'
                    )
                FROM Incident__c
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<Incident__c> scope) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<String> filterGroup = new List<String>();
            List<Incident__Share> listDelete = new List<Incident__Share>();

            for (Incident__c incident : scope) {
                listDelete.addAll(incident.Shares);
                String organization = incident.Organization__c;

                if (String.isNotBlank(organization)) {
                    filterGroup.add('Account_' + organization);
                }
            }

            delete listDelete;
            if (ruleExecuteBatch.contains(configMdt.Sharing_Incidents_With_Public_Groups__c)) {
                Map<String, String> mapGroupField = convertMapGroup(
                    new List<Group>([SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :filterGroup])
                    );
                List<Incident__Share> listCreate = createListShareRecord(scope, mapGroupField);
                insert listCreate;
            }
        } catch (Exception error) {
            Database.rollback(sp);
            throw error;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    global static Map<String, String> convertMapGroup(List<Group> listGroup) {
        Map<String, String> mapGroup = new Map<String, String>();

        for (Group record : listGroup) {
            String parts = record.DeveloperName.substringAfter('_');
            if (String.isNotBlank(parts)) {
                mapGroup.put(parts, record.Id);
            }
        }

        return mapGroup;
    }

    global List<Incident__Share> createListShareRecord(List<Incident__c> scope, Map<String, String> mapGroup) {
        List<Incident__Share> createRecord = new List<Incident__Share>();

        for (Incident__c record : scope) {
            String userOrGroupId = mapGroup.get(record.Organization__c);

            if (String.isNotBlank(userOrGroupId)) {
                createRecord.add(
                    new Incident__Share(
                        AccessLevel = configMdt.Sharing_Incidents_With_Public_Groups__c,
                        ParentId = record.Id,
                        RowCause = 'ermt__AccountPublicGroupSharingReason_' + configMdt.Sharing_Incidents_With_Public_Groups__c + '__c',
                        UserOrGroupId = userOrGroupId
                    )
                );
            }
        }

        return createRecord;
    }

    global static Incident_Configration__mdt setConfigCustomMeta(String value) {
        return (Incident_Configration__mdt) JSON.deserialize(
            '{"Sharing_Incidents_With_Public_Groups__c": \"' +
            value +
            '\"}',
            Incident_Configration__mdt.class
        );
    }

    global static Incident_Configration__mdt getConfigCustomMeta() {
        Incident_Configration__mdt configDefault=  Incident_Configration__mdt.getInstance('Default');
        if(configDefault == null) {
            configDefault = setConfigCustomMeta('OFF');
        }
        return configDefault;
    }
}