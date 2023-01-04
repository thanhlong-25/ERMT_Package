@isTest
public class CustomSharingRecordCtrlTest {
    public class ParseCustomSharingRecordCtrl {
        public List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> LIST_SHARING;
        public String OBJECT_NAME;
        public List<User> USER;
        public List<Group> PUBLIC_GROUP;
        List<CustomSharingRecordCtrl.CustomSharingAccessLevelWrapper> OPTION_ACCESS_LEVEL;

        public ParseCustomSharingRecordCtrl parse(String json) {
            return (ParseCustomSharingRecordCtrl) System.JSON.deserialize(json, ParseCustomSharingRecordCtrl.class);
        }
    }
    private static ParseCustomSharingRecordCtrl getParseJson(String requestJson) {
        ParseCustomSharingRecordCtrl parseJson = new ParseCustomSharingRecordCtrl().parse(requestJson);
        return parseJson;
    }

    @isTest
    public static void testGetRecordSharingForOwner() {
        Test.startTest();
        try {
            Map<String, Object> factoryData = factoryDataTest(2);
            List<User> users = (List<User>) factoryData.get('User');
            System.runAs(users[0]) {
                List<ermt__Risk__c> recordRisk = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = (Id) recordRisk.get(0).get('Id');
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
                ParseCustomSharingRecordCtrl parseJson = getParseJson(requestJson);
                List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> recordSharing = parseJson.LIST_SHARING;
                System.assertEquals(2, recordSharing.size(), 'Should be return total 2 record , 1 record share owner and public group');
                System.assertEquals(
                    parseJson.OBJECT_NAME,
                    CustomSharingRecordCtrl.getObjectLabelFromId(riskId),
                    'Should be return equals objects name risk'
                );
            }

        } catch (Exception e) {
            System.assert(String.isBlank(e.getMessage()), 'Not should be return message errors');
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetRecordSharingOnNotPermission() {
        Test.startTest();
        try {
            // Create the test data
            Map<String, Object> factoryData = factoryDataTest(2);
            List<User> users = (List<User>) factoryData.get('User');

            // Run the code in the context of a standard user
            System.runAs(factoryStandardUser()) {
                // Get the first risk in the list
                List<ermt__Risk__c> risks = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = (Id) risks.get(0).get('Id');

                // Try to get the record sharing for the risk
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
            }
        } catch (Exception e) {
            // Assert that the exception has a message
            System.assert(String.isNotBlank(e.getMessage()), 'Exception test throw message should be return equals not empty');
            // Assert that the exception message is correct
            System.assertEquals(
                CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT,
                e.getMessage(),
                'Should be return message errors equals' + CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT
            );
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetRecordSharingOnEmptyRecord() {
        Test.startTest();
        try {
            String requestJson = CustomSharingRecordCtrl.getRecordSharing(null);
        } catch (Exception e) {
            System.assert(String.isNotBlank(e.getMessage()), 'Exception test throw message should be return equals not empty');
            System.assertEquals(
                CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT,
                e.getMessage(),
                'Should be return message errors equals' + CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT
            );
        }
        Test.stopTest();
    }

    @isTest
    public static void testGetRecordSharingOnNoSharingRule() {
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            try {
                Map<String, Object> factoryData = factoryDataTest(2);
                List<Group> groups = (List<Group>) factoryData.get('Group');

                String requestJson = CustomSharingRecordCtrl.getRecordSharing(groups[0].Id);
            } catch (Exception e) {
                System.assert(String.isNotBlank(e.getMessage()));
                System.assertEquals(
                    CustomSharingRecordCtrl.MESSAGE_ERROR_SHARING_RULE,
                    e.getMessage(),
                    'Exception test when not sharing rule , should be return message equals' +
                    CustomSharingRecordCtrl.MESSAGE_ERROR_SHARING_RULE
                );
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnNullParams() {
        Test.startTest();
        Map<String, Object> factoryData = factoryDataTest(2);
        List<User> users = (List<User>) factoryData.get('User');

        System.runAs(users[0]) {
            try {
                String requestJson = CustomSharingRecordCtrl.editRecordSharing(null, null);
            } catch (Exception e) {
                System.assert(String.isNotBlank(e.getMessage()), 'Throw handle exception and return message');
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnDelete() {
        Map<String, Object> factoryData = factoryDataTest(2);
        List<User> users = (List<User>) factoryData.get('User');
        Test.startTest();

        System.runAs(users[0]) {
            try {
                List<ermt__Risk__c> risks = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = risks[0].Id;
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
                ParseCustomSharingRecordCtrl parseJson = getParseJson(requestJson);
                List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> recordSharings = parseJson.LIST_SHARING;

                CustomSharingRecordCtrl.RequestJson fakeRequestJson = new CustomSharingRecordCtrl.RequestJson();
                List<Id> deleteGroupOrUserIds = new List<Id>();

                for (CustomSharingRecordCtrl.CustomSharingRecordWrapper record : recordSharings) {
                    deleteGroupOrUserIds.add(record.RecordID);
                }

                fakeRequestJson.UserOrGroupChange = new List<CustomSharingRecordCtrl.CustomSharingRecordWrapper>();
                fakeRequestJson.UserOrGroupId = new List<Id>();
                fakeRequestJson.UserOrGroupDelete = deleteGroupOrUserIds;
                String editRecord = CustomSharingRecordCtrl.editRecordSharing(riskId, JSON.serialize(fakeRequestJson));
                List<SObject> userOrGroupAccessLevel = Database.query(CustomSharingRecordCtrl.buildQuery((Id) riskId));
                System.assertEquals(2, recordSharings.size(), 'Should be return total 2 record , 1 record share owner and public group');
                System.assertEquals(
                    1,
                    userOrGroupAccessLevel.size(),
                    'Should be return total record sharing after delete record  , access level is read or edit no delete record access level is all'
                );
            } catch (Exception e) {
                System.assert(String.isBlank(e.getMessage()), 'Not return error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnRead() {
        Map<String, Object> factoryData = factoryDataTest(2);
        List<User> users = (List<User>) factoryData.get('User');
        Test.startTest();

        System.runAs(users[0]) {
            try {
                List<ermt__Risk__c> risks = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = risks[0].Id;
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
                ParseCustomSharingRecordCtrl parseJson = getParseJson(requestJson);
                List<User> usersToShareWith = parseJson.USER;
                List<Group> groupsToShareWith = parseJson.PUBLIC_GROUP;
                List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> lRecordSharing = parseJson.LIST_SHARING;
                List<Id> userOrGroupIds = new List<Id>();

                for (User user : usersToShareWith) {
                    userOrGroupIds.add(user.Id);
                }

                for (Group groups : groupsToShareWith) {
                    userOrGroupIds.add(groups.Id);
                }

                CustomSharingRecordCtrl.RequestJson fakeRequestJson = new CustomSharingRecordCtrl.RequestJson();
                fakeRequestJson.UserOrGroupChange = new List<CustomSharingRecordCtrl.CustomSharingRecordWrapper>();
                fakeRequestJson.UserOrGroupId = userOrGroupIds;
                fakeRequestJson.UserOrGroupDelete = new List<Id>();
                fakeRequestJson.AccessLevel = 'Read';
                String editRecord = CustomSharingRecordCtrl.editRecordSharing(riskId, JSON.serialize(fakeRequestJson));
                List<SObject> userOrGroupAccessLevelRead = Database.query(
                    CustomSharingRecordCtrl.buildQuery((Id) riskId) + ' AND AccessLevel = \'Read\' AND UserOrGroupId IN :userOrGroupIds'
                );
                System.assertEquals(2, lRecordSharing.size(), 'Should be return total 2 record , 1 record share owner and public group');
                System.assertEquals(
                    userOrGroupIds.size(),
                    userOrGroupAccessLevelRead.size(),
                    'Should be return total record sharing access level Read  , users and public group'
                );
            } catch (Exception e) {
                System.assert(String.isBlank(e.getMessage()), 'Not return error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnUserOrGroupChangAccessLevelEdit() {
        Map<String, Object> factoryData = factoryDataTest(2);
        List<User> users = (List<User>) factoryData.get('User');
        Test.startTest();

        System.runAs(users[0]) {
            try {
                List<ermt__Risk__c> risks = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = risks[0].Id;
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
                ParseCustomSharingRecordCtrl parseJson = getParseJson(requestJson);
                List<User> usersToShareWith = parseJson.USER;
                List<Group> groupsToShareWith = parseJson.PUBLIC_GROUP;
                List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> lRecordSharing = parseJson.LIST_SHARING;
                List<Id> userOrGroupIds = new List<Id>();
                for (User user : usersToShareWith) {
                    userOrGroupIds.add(user.Id);
                }
                for (Group groups : groupsToShareWith) {
                    userOrGroupIds.add(groups.Id);
                }
                CustomSharingRecordCtrl.RequestJson fakeRequestJson = new CustomSharingRecordCtrl.RequestJson();
                fakeRequestJson.UserOrGroupChange = new List<CustomSharingRecordCtrl.CustomSharingRecordWrapper>();
                fakeRequestJson.UserOrGroupId = userOrGroupIds;
                fakeRequestJson.UserOrGroupDelete = new List<Id>();
                fakeRequestJson.AccessLevel = 'Edit';
                String editRecord = CustomSharingRecordCtrl.editRecordSharing(riskId, JSON.serialize(fakeRequestJson));
                List<SObject> userOrGroupAccessLevelEdit = Database.query(
                    CustomSharingRecordCtrl.buildQuery((Id) riskId) + ' AND AccessLevel = \'Edit\' AND UserOrGroupId IN :userOrGroupIds'
                );
                System.assertEquals(2, lRecordSharing.size(), 'Should be return total 2 record , 1 record share owner and public group');
                System.assertEquals(
                    userOrGroupIds.size(),
                    userOrGroupAccessLevelEdit.size(),
                    'Should be return total record sharing access level edit  , users and public group'
                );
            } catch (Exception e) {
                System.assert(String.isBlank(e.getMessage()), 'Not return error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnUserOrGroupChange() {
        Map<String, Object> mFactoryData = factoryDataTest(2);
        List<User> users = (List<User>) mFactoryData.get('User');
        Test.startTest();

        System.runAs(users[0]) {
            try {
                // Create variables for read access level and lists of records and IDs
                String readAccessLevel = 'Read';
                List<CustomSharingRecordCtrl.CustomSharingRecordWrapper> recordsToEdit = new List<CustomSharingRecordCtrl.CustomSharingRecordWrapper>();
                Set<Id> userOrGroupIds = new Set<Id>();

                // Get record and parse JSON
                List<ermt__Risk__c> recordRisk = (List<ermt__Risk__c>) mFactoryData.get('Risk');
                Id riskId = recordRisk[0].Id;
                String requestJson = CustomSharingRecordCtrl.getRecordSharing(riskId);
                ParseCustomSharingRecordCtrl parseJson = getParseJson(requestJson);

                // Populate sets and lists
                Set<String> accessLevels = new Set<String>();
                for (CustomSharingRecordCtrl.CustomSharingAccessLevelWrapper level : parseJson.OPTION_ACCESS_LEVEL) {
                    accessLevels.add(level.value);
                }
                for (CustomSharingRecordCtrl.CustomSharingRecordWrapper record : parseJson.LIST_SHARING) {
                    if (accessLevels.contains(record.AccessLevel)) {
                        record.AccessLevel = readAccessLevel;
                        recordsToEdit.add(record);
                        userOrGroupIds.add(record.UserOrGroupId);
                    }
                }

                // Create fake request JSON and edit record sharing
                CustomSharingRecordCtrl.RequestJson fakeRequestJson = new CustomSharingRecordCtrl.RequestJson();
                fakeRequestJson.UserOrGroupChange = recordsToEdit;
                fakeRequestJson.UserOrGroupId = new List<Id>();
                fakeRequestJson.UserOrGroupDelete = new List<Id>();
                fakeRequestJson.AccessLevel = readAccessLevel;
                String editRecord = CustomSharingRecordCtrl.editRecordSharing(riskId, JSON.serialize(fakeRequestJson));

                // Query for record shares with read access level and assert that the correct number of records were returned
                List<SObject> recordSharesRead = Database.query(
                    CustomSharingRecordCtrl.buildQuery(riskId) + ' AND AccessLevel = \'' + readAccessLevel + '\''
                );
                System.assertEquals(
                    2,
                    parseJson.LIST_SHARING.size(),
                    'Should be return total 2 record , 1 record share owner and public group'
                );
                System.assertEquals(recordsToEdit.size(), recordSharesRead.size(), 'Check if number of record shares is correct');
            } catch (Exception e) {
                System.assert(String.isBlank(e.getMessage()), 'Not return error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testEditRecordSharingOnUserOrGroupChangeNotPermission() {
        Test.startTest();
        try {
            // Create the test data
            Map<String, Object> factoryData = factoryDataTest(2);
            List<User> users = (List<User>) factoryData.get('User');

            // Run the code in the context of a standard user
            System.runAs(factoryStandardUser()) {
                // Get the first risk in the list
                List<ermt__Risk__c> risks = (List<ermt__Risk__c>) factoryData.get('Risk');
                Id riskId = (Id) risks.get(0).get('Id');

                CustomSharingRecordCtrl.RequestJson fakeRequestJson = new CustomSharingRecordCtrl.RequestJson();
                fakeRequestJson.UserOrGroupChange = new List<CustomSharingRecordCtrl.CustomSharingRecordWrapper>();
                fakeRequestJson.UserOrGroupId = new List<Id>();
                fakeRequestJson.UserOrGroupDelete = new List<Id>();
                fakeRequestJson.AccessLevel = 'Read';
                String editRecord = CustomSharingRecordCtrl.editRecordSharing(riskId, JSON.serialize(fakeRequestJson));
            }
        } catch (Exception e) {
            
            // Assert that the exception has a message
            System.assert(String.isNotBlank(e.getMessage()), 'Exception test throw message should be return equals not empty');
            // Assert that the exception message is correct
            System.assertEquals(
                CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT,
                e.getMessage(),
                'Should be return message errors equals' + CustomSharingRecordCtrl.MESSAGE_ERROR_NO_PERMISSION_EDIT
            );
        }
        Test.stopTest();
    }

    private static User factoryStandardUser() {
        String profileReadOnly = System.Label.Profile_Read_Only;
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileReadOnly LIMIT 1];
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg.com'
        );
        insert u;
        return u;
    }

    private static Map<String, Object> factoryDataTest(Integer numberFactory) {
        Map<String, Object> ret = new Map<String, Object>();

        // Create and insert the users
        List<User> users = new List<User>();
        for (Integer i = 0; i < numberFactory; i++) {
            User user = TestDataFactory.createUser(i + 1);
            user.ermt__UserToDisplayWhenSharing__c = true;
            users.add(user);
        }
        insert users;
        ret.put('User', users);

        // Run the rest of the code in the context of the first user
        System.runAs(users[0]) {
            // Create and insert the accounts
            List<Account> accounts = new List<Account>();
            // Create the groups and risks
            List<Group> groups = new List<Group>();
            List<ermt__Risk__c> risks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < numberFactory; i++) {
                Account account = TestDataFactory.createAccount(i + 1);
                account.ermt__AccountToDisplayWhenSharing__c = true;
                Group factoryGroup = factoryGroup(account.Id, account.Name + i, null);
                groups.add(factoryGroup);
                accounts.add(account);
            }
            insert accounts;
            ret.put('Account', accounts);

            Map<Id, Group> groupByAccountId = getGroupByAccountId('Account');
            for (Account account : accounts) {
                // If the account doesn't have an associated group, create one
                if (!groupByAccountId.containsKey(account.Id)) {
                    Group record = factoryGroup(account.Id, account.Name, 'Account');
                    groups.add(record);
                }
                // Create the risks for the account
                for (Integer i = 0; i < numberFactory; i++) {
                    ermt__Risk__c risk = TestDataFactory.createRisk(i + 1, account);
                    risks.add(risk);
                }
            }
            // Insert the groups and risks
            insert groups;
            insert risks;

            // Add the existing groups to the list of groups
            for (Group groupRecord : groupByAccountId.values()) {
                groups.add(groupRecord);
            }
            ret.put('Group', groups);
            ret.put('Risk', risks);
        }
        return ret;
    }

    private static Group factoryGroup(String groupId, String groupName, String prefix) {
        String developerName = prefix == null ? null : (prefix + '_') + groupId;
        Group grp = new Group(DeveloperName = developerName, Name = groupName);
        return grp;
    }

    private static Map<Id, Group> getGroupByAccountId(String groupDevNamePrefix) {
        Map<Id, Group> ret = new Map<Id, Group>();
        for (Group g : [
            SELECT DeveloperName
            FROM Group
            WHERE DeveloperName LIKE :groupDevNamePrefix + '%'
        ]) {
            String accountId = g.DeveloperName.removeStart(groupDevNamePrefix + '_');
            ret.put(accountId, g);
        }
        return ret;
    }
}