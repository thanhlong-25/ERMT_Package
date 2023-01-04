public with sharing class ERMT_AccountUserHandler {
    public static void deleteGroupMemberRelated(List<ermt__Account_User__c> accUsers){
        if (accUsers == null || accUsers.isEmpty()) return;

        Set<String> developerNames = new Set<String>();
        Set<String> userOrGroupIds = new Set<String>();

        for (ermt__Account_User__c item : accUsers) {
            developerNames.add('Account_' + item.ermt__Account__c);
            userOrGroupIds.add(item.ermt__User__c);
        }

        List<GroupMember> listTmps = new List<GroupMember>(); 
        try {
            listTmps = [Select Id, GroupId, UserOrGroupId, Group.DeveloperName From GroupMember Where Group.DeveloperName IN :developerNames AND UserOrGroupId IN :userOrGroupIds];
        } catch (QueryException e) {
            System.debug(e.getMessage());
        }
        Set<Id> listGroupMemberIds = new Set<Id>(); 
        List<ermt__Account_User__c> accUserTmps = new List<ermt__Account_User__c>();
        accUserTmps.addAll(accUsers);
        if (!listTmps.isEmpty()){
            for (GroupMember gr : listTmps){
                for (ermt__Account_User__c au : accUserTmps){
                    if (gr.Group.DeveloperName.equals('Account_' + au.ermt__Account__c) && gr.UserOrGroupId == au.ermt__User__c)  {
                        listGroupMemberIds.add(gr.Id);
                    } 
                }
            }
        }
        if (!listGroupMemberIds.isEmpty()){
            try {
                deleteGroupMember(listGroupMemberIds);
            } catch (DmlException e){
                System.debug(e.getMessage());
            }
        }
    }

    @future
    public static void deleteGroupMember (Set<Id> listGroupMemberIds){
        try {
            if (GroupMember.getSObjectType().getDescribe().isDeletable()) {
                delete [Select Id From GroupMember Where Id IN :listGroupMemberIds];
            }
        } catch (DmlException e){
            throw e;
        }
    }
}