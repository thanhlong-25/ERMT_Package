public class ERMT_CategoryCC {
    /**
        insert/update list of answers
    **/
    @AuraEnabled
    public static List<ermt__Answer__c> upsertAnswers(String checklistId, List<ermt__Answer__c> listAnswers) {
        // check ChecklistUser existed
        String userId = UserInfo.getUserId();
        List<ermt__Checklist_User__c> listChecklistUsers  = [SELECT Id, ermt__Checklist__c, ermt__User__c, ermt__Is_Submit__c 
        FROM ermt__Checklist_User__c WhERE ermt__Checklist__c =: checklistId AND ermt__User__c =: userId];

        ermt__Checklist_User__c pu = null;
        System.debug(listChecklistUsers);
        if (listChecklistUsers.isEmpty()){
            // if ChecklistUser not exists then create new record
            pu = new ermt__Checklist_User__c();
            pu.ermt__Checklist__c = checklistId;
            pu.ermt__User__c = userId;

            try {
                insert pu;
            } catch (DmlException e) {
                System.debug('The following exception has occurred insert ermt__Checklist_User__c: ' + e.getMessage());
            }
        } else {
            pu = listChecklistUsers.get(0);
        }
        
        if (pu != null && listAnswers != null && !listAnswers.isEmpty()) {
            for (ermt__Answer__c a : listAnswers) {
                a.ermt__Checklist_User__c = pu.Id;
            }
            try {
                upsert listAnswers;
            } catch (DmlException e) {
                System.debug('The following exception has occurred where upsert ermt__Answer__c: ' + e.getMessage());
            }
        }
        return listAnswers;
    }
}