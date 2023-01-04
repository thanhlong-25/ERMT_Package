@isTest
private class ERMT_PublicGroupUpdateBatchTest {
    private static final String DEVNAME_PREFIX = 'Account';
    private static final Datetime NOW_DATETIME = Datetime.now();
    private static final Integer NUM_ACC = 20;

    private static Map<String, Profile> profileByName {
        get {
            if (profileByName == null) {
                profileByName = new Map<String, Profile>();
                for (Profile p : [
                    SELECT Name FROM Profile
                    ORDER BY Name
                ]) {
                    profileByName.put(p.Name, p);
                }
            }
            return profileByName;
        }
        private set;
    }
    private static String getDevName(String accId){
        return DEVNAME_PREFIX + '_' + accId;
    }
    @testSetup static void initDataTest(){
        Test.startTest();
        //Create large amount of Account
        List<Account> accs = new List<Account>();
        for(Integer i = 0; i < NUM_ACC; i++){
            Account a = new Account(Name='testAccount'+ String.valueOf(i), RecordTypeId=[SELECT Id FROM RecordType WHERE DeveloperName = 'BranchLocationRecordType' AND SobjectType = 'Account'].Id); 
            accs.add(a);
        }
        insert accs;
        // Create user
        List<User> usrs = new List<User>();
        Integer usrsSize = 3;
        for (Integer i = 0; i < usrsSize; i++) {
            Integer no = i + 1;
            User usr = new User(
                LastName = 'Test' + no
                , Alias = 'Test' + no
                , UserName = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , Email = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , EmailEncodingKey = 'ISO-2022-JP'
                , TimeZoneSidKey = 'Asia/Tokyo'
                , LocaleSidKey = 'ja_JP'
                , LanguageLocaleKey = 'ja'
                , ProfileId = profileByName.get(System.Label.Profile_System_Admin).Id
            );
            usrs.add(usr);
        }
        insert usrs;
        Test.stopTest();
    }
    @isTest static void testUpsertPublicGroup(){
        List<Account> allAccs = [SELECT Id, Name FROM Account];
        Set<String> listDevName = new Set<String>();
        for (Account acc: allAccs){
            listDevName.add(getDevName(acc.Id));
        }        
        Test.startTest();
        	//Create noise data
        	Group noiseGroup = new Group(DeveloperName=getDevName(allAccs[0].Id+'Test'), Name=allAccs[0].Name);
        	insert noiseGroup;
        	ID batchId = Database.executeBatch(new ERMT_PublicGroupUpdateBatch(), NUM_ACC);
        Test.stopTest();
        List<Group> upsertGroup = [SELECT Id FROM Group WHERE DeveloperName IN :listDevName];
        System.assert(upsertGroup.size() == NUM_ACC);
    }
    @isTest static void testGroupMemberUserAndChildGroup(){
        Account acc1 = [SELECT Id FROM Account WHERE Name='testAccount1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name='testAccount2' LIMIT 1];
        acc1.ParentId = acc2.Id;
        User user1 = [SELECT Id FROM User WHERE LastName='Test1' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE LastName='Test2' LIMIT 1];
        List<ermt__Account_User__c> listAccUser = new List<ermt__Account_User__c>();
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user1.Id));
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user2.Id));
        Test.startTest();
        	upsert acc1;
        	insert listAccUser;
        	ID batchId = Database.executeBatch(new ERMT_PublicGroupUpdateBatch(), NUM_ACC);
        Test.stopTest();
        String group1DevName = getDevName(acc1.Id);
        Group group1 = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName= :group1DevName LIMIT 1];
        System.assert(group1.GroupMembers.size() == 3);
    }
    @isTest static void testGroupMemberUser(){
        Account acc1 = [SELECT Id FROM Account WHERE Name='testAccount1' LIMIT 1];
        User user1 = [SELECT Id FROM User WHERE LastName='Test1' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE LastName='Test2' LIMIT 1];
        List<ermt__Account_User__c> listAccUser = new List<ermt__Account_User__c>();
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user1.Id));
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user2.Id));
        Test.startTest();
        	insert listAccUser;
        	ID batchId = Database.executeBatch(new ERMT_PublicGroupUpdateBatch(), NUM_ACC);
        Test.stopTest();
        String group1DevName = getDevName(acc1.Id);
        Group group1 = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName= :group1DevName LIMIT 1];
        System.assert(group1.GroupMembers.size() == 2);
    }
    @isTest static void testGroupMemberUserParent(){
        // Child: acc1, Parent: acc2, Account_User of acc1: user1, user2, Account_User of acc2: user3
        Account acc1 = [SELECT Id FROM Account WHERE Name='testAccount1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name='testAccount2' LIMIT 1];
        acc1.ParentId = acc2.Id;
        User user1 = [SELECT Id FROM User WHERE LastName='Test1' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE LastName='Test2' LIMIT 1];
        User user3 = [SELECT Id FROM User WHERE LastName='Test3' LIMIT 1];
        List<ermt__Account_User__c> listAccUser = new List<ermt__Account_User__c>();
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user1.Id));
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc1.Id, ermt__User__c=user2.Id));
        listAccUser.add(new ermt__Account_User__c(ermt__Account__c=acc2.Id, ermt__User__c=user3.Id));
        Test.startTest();
        	insert listAccUser;
        	ID batchId = Database.executeBatch(new ERMT_PublicGroupUpdateBatch(), NUM_ACC);
        Test.stopTest();
        String group1DevName = getDevName(acc1.Id);
        String group2DevName = getDevName(acc2.Id);
        Group group1 = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName= :group1DevName LIMIT 1];
        Group group2 = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE DeveloperName= :group2DevName LIMIT 1];
        System.assert(group1.GroupMembers.size() == 2);
        System.assert(group2.GroupMembers.size() == 1);
    }
    
}