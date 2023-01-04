public without sharing class ERMT_AccountHandler {
    public static void deletePublicGroupRelated(List<Account> accs){

        if (accs == null || accs.isEmpty()) return;

        List<String> listDeveloperNames = new List<String>();

        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName IN ('BranchLocationRecordType','OrganizationRecordType') AND SobjectType = 'Account'];

        if (recordTypes.isEmpty()) return;
        
        for (Account acc : accs) {
            for (RecordType type : recordTypes){
                if (acc.RecordTypeId == type.Id) {
                    listDeveloperNames.add('Account_' + acc.Id + '%');
                    break;
                }
            }
        }

        List<Group> listTmps = new List<Group>(); 
        try {
            listTmps = [Select Id From Group Where DeveloperName like :listDeveloperNames];
        } catch (QueryException e) {
            System.debug(e.getMessage());
        }
        
        Set<Id> listGroupIds = new Set<Id>();
        if (!listTmps.isEmpty()) {
            listGroupIds = (new Map<Id,SObject>(listTmps)).keySet();
            deleteGroup(listGroupIds);
        }
    }

    @future
    public static void deleteGroup (Set<Id> listIds){
        try {
            if (Group.getSObjectType().getDescribe().isDeletable()) {
                delete [Select Id From Group Where Id IN :listIds];
            }
        } catch (DmlException e){
            System.debug(e.getMessage());
        }
    }
}