global class ERMT_PublicGroupUpdateBatch implements Database.Batchable<sObject>{
    global final String DEVNAME_PREFIX = 'Account';
    //Start
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, ParentId, Parent.Name, (SELECT ermt__User__c FROM ermt__Account_User__r) FROM Account WHERE RecordType.DeveloperName=\'BranchLocationRecordType\' OR RecordType.DeveloperName=\'OrganizationRecordType\'';
        return Database.getQueryLocator(query);
    }
    //Execute
    global void execute(Database.BatchableContext BC, List<Account> scope){
        Map<String, String> devName_AccName = new Map<String, String>();
        Map<String, Set<Id>> devName_SetUserId = new Map<String, Set<Id>>();
        //Get map devName_accName and devName_SetUserId for further using
        getMapUtility(scope, devName_AccName, devName_SetUserId);
        List<Group> listGroupInserted = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :devName_AccName.keySet()];
        //Create map with key: devName, value: Group was inserted in DB
        Map<String, Group> devName_GroupInserted = new Map<String, Group>();
        for (Group groupInserted: listGroupInserted){
            devName_GroupInserted.put(groupInserted.DeveloperName, groupInserted);
        }
        //Create list Group wasnt inserted in DB
        List<Group> listNewGroup = getListGroupNeedInsert(devName_GroupInserted, devName_AccName);
        try{
            insert listNewGroup;
            List<GroupMember> listGroupMember = new List<GroupMember>();
            //Put listNewGroup into map devName_GroupInserted
            for (Group newGroup: listNewGroup){
                devName_GroupInserted.put(newGroup.DeveloperName, newGroup);
            }
            //Add list GroupMember for User
            listGroupMember.addAll(getGroupMemberForUser(devName_GroupInserted, devName_SetUserId));
            //Add list GroupMember for ChildGroup
            listGroupMember.addAll(getGroupMemberForChildGroup(scope, devName_GroupInserted));
            insert listGroupMember;
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
    //Finish
    global void finish(Database.BatchableContext BC){   
    }
    global void getMapUtility(List<Account> scope, Map<String, String> devName_AccName, Map<String, Set<Id>> devName_SetUserId){
        for(Account acc: scope){
            String devName;
            //Get devName of child group + parent group
            if (acc.ParentId != null){
                devName = getDevName(acc.ParentId);
                devName_AccName.put(devName, acc.Parent.Name);
            }
            devName = getDevName(acc.Id);
            devName_AccName.put(devName, acc.Name);
            //Get list User of Account(scope)
            List<ermt__Account_User__c> listUserOfAcc = acc.ermt__Account_User__r;
            if (!listUserOfAcc.isEmpty()){
                Set<Id> setUserId = new Set<Id>();
                for (ermt__Account_User__c userOfAcc: listUserOfAcc){
                    setUserId.add(userOfAcc.ermt__User__c);
                }
                devName_SetUserId.put(devName, setUserId);
            }
        }
    }
    global List<GroupMember> getGroupMemberForUser(Map<String, Group> devName_GroupInserted, Map<String, Set<Id>> devName_SetUserId){
        List<GroupMember> listGroupMember = new List<GroupMember>();
        for (String devName: devName_SetUserId.keySet()){
            Set<Id> setUserId = devName_SetUserId.get(devName);
            for (Id userId: setUserId){
                Group groupInserted = devName_GroupInserted.get(devName);
                listGroupMember.add(new GroupMember(GroupId=groupInserted.Id,UserOrGroupId=userId));
            }
        }
        return listGroupMember;
    }
    global List<GroupMember> getGroupMemberForChildGroup(List<Account> accs, Map<String, Group> devName_GroupInserted){
       	List<GroupMember> listGroupMember = new List<GroupMember>();
        for (Account acc: accs){
            if (acc.ParentId != null){
                String childDevName = getDevName(acc.Id);
                String parentDevName = getDevName(acc.ParentId);
                Group childGroup = devName_GroupInserted.get(childDevName);
                Group parentGroup = devName_GroupInserted.get(parentDevName);
                listGroupMember.add(new GroupMember(GroupId=childGroup.Id,UserOrGroupId=parentGroup.Id));
            }
        }
        return listGroupMember;
    }
    global List<Group> getListGroupNeedInsert(Map<String, Group> devName_GroupInserted, Map<String, String> devName_AccName){
        List<Group> listNewGroup = new List<Group>();
        for (String devName: devName_AccName.keySet()){
            Group groupInserted = devName_GroupInserted.get(devName);
            if (groupInserted == null){
                String groupName = devName_AccName.get(devName);
                listNewGroup.add(new Group(DeveloperName=devName, Name=groupName));
            }
        }
        return listNewGroup;
    }
    global String getDevName(String accId){
        return DEVNAME_PREFIX + '_' + accId;
    }
}