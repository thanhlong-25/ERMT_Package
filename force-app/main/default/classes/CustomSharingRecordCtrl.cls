public class CustomSharingRecordCtrl {
    public class RequestJson {
        public List<CustomSharingRecordWrapper> UserOrGroupChange;
        public List<Id> UserOrGroupId;
        public String AccessLevel;
        public List<Id> UserOrGroupDelete;
        public RequestJson reqData;

        public void parse(String json) {
            this.reqData = (RequestJson) System.JSON.deserialize(json, RequestJson.class);
        }

        public RequestJson getReq() {
            return (RequestJson) this.reqData;
        }
    }

    public class CustomSharingRecordWrapper {
        public Id RecordID;
        public String UserOrGroupName;
        public String UserOrGroupType;
        public Id UserOrGroupId;
        public String AccessLevel;
        public String RowCause;
    }

    public static List<CustomSharingAccessLevelNotification> lCustomSharingAccessLevelNotification = new List<CustomSharingAccessLevelNotification>();
    public static List<Id> lUserAndGroupIdCurrent = new List<Id>();
    public static List<String> lValueAccessLevel = new List<String>{ 'Read', 'Edit' };
    public static final String USER_KEY = 'USER';
    public static final String GROUP_KEY = 'PUBLIC_GROUP';
    public static final String LIST_KEY = 'LIST_SHARING';
    public static final String OPTION_ACCESS_LEVEL = 'OPTION_ACCESS_LEVEL';
    public static final String OBJECT_NAME_KEY = 'OBJECT_NAME';
    public static final String MESSAGE_ERROR_NO_PERMISSION_EDIT = 'Only the record owner or administrators can access permissions';
    public static final String MESSAGE_ERROR_SHARING_RULE = 'There is no sharing rule for that object. Are you SURE you changed the sharing setting objects to PRIVATE or READ?';
    public static final String MESSAGE_ERROR_NO_PERMISSION_ACTION = 'You don\'t have the proper permissions for this action';
    /**
     * The getRecordSharing method
     * is a static method that takes a single parameter, recordId, which is the ID of a record.
     * The method returns a string that is a serialized JSON object.
     */
    @AuraEnabled
    public static String getRecordSharing(Id recordId) {
        Map<String, Object> mRecordSharing = new Map<String, Object>();
        if (!hasEditPermission(recordId)) {
            throw setThrowExceptionMessage(MESSAGE_ERROR_NO_PERMISSION_EDIT);
        }
        mRecordSharing.put(LIST_KEY, getCurrentShares(recordId));
        mRecordSharing.put(USER_KEY, getUsers());
        mRecordSharing.put(GROUP_KEY, getGroup());
        mRecordSharing.put(OPTION_ACCESS_LEVEL, getAccessLevelOptions(recordId));
        mRecordSharing.put(OBJECT_NAME_KEY, getObjectLabelFromId(recordId));
        return JSON.serialize(mRecordSharing);
    }

    /**
     * editRecordSharing
     * The editRecordSharing method is a static method that takes two parameters: recordId,
     * which is the ID of a record, and dataEdit, which is a string containing data to be edited.
     * The method returns a string that is a serialized JSON object.
     * @param recordId (Id): Write the parameter description
     * @param dataEdit (String): Write the parameter description
     *
     * @return String: Write the return description
     *
     * @throws Class name here Write the class description
     */
    @AuraEnabled
    public static String editRecordSharing(Id recordId, String dataEdit) {
        // Set a savepoint to allow rolling back the transaction if an exception is thrown
        Savepoint sp = Database.setSavepoint();
        try {
            // Parse the data from the request
            RequestJson requestJson = new RequestJson();
            requestJson.parse(dataEdit);
            RequestJson data = requestJson.getReq();
            // Check if the current user has permission to edit the record
            if (!hasEditPermission(recordId)) {
                throw setThrowExceptionMessage(MESSAGE_ERROR_NO_PERMISSION_EDIT);
            }

            // Get the records to delete, create, and update
            List<SObject> recordsToUpsert = new List<SObject>();
            List<SObject> recordsToDelete = deleteRecordShares(recordId, data.UserOrGroupDelete);
            recordsToUpsert.addAll(createRecordShares(recordId, data.UserOrGroupId, data.AccessLevel));
            recordsToUpsert.addAll(upsertRecordSharing(recordId, data.UserOrGroupChange));

            // Delete and upsert the records
            delete recordsToDelete;
            upsert recordsToUpsert;

            // Return the notification data
            return JSON.serialize(lCustomSharingAccessLevelNotification);
        } catch (Exception e) {
            // Roll back the transaction if an exception is thrown
            Database.rollback(sp);
            throw setThrowExceptionMessage(e.getMessage());
        }
    }

    /**
     * upsertRecordSharing permissions
     *
     * @param recordId recordId: an Id representing the record whose sharing information is being modified
     * @param List<Id>  a list of CustomSharingRecordWrapper objects representing the new sharing information to be applied to the record
     * @param level the level of access to be granted
     */
    @AuraEnabled
    public static List<SObject> upsertRecordSharing(Id recordId, List<CustomSharingRecordWrapper> data) {
        List<SObject> updatedRecordShares = new List<SObject>();
        if (data.isEmpty()) {
            return updatedRecordShares;
        }

        String objectName = getObjectNameFromId(recordId);
        String accessLevelField = getAccessLevelField(objectName);
        Map<Id, String> recordChanges = new Map<Id, String>();
        for (CustomSharingRecordWrapper recordWrapper : data) {
            recordChanges.put(recordWrapper.RecordID, recordWrapper.AccessLevel);
        }

        Set<Id> ids = recordChanges.keySet();
        String query = buildQuery(recordId) + ' AND Id IN :ids AND RowCause != \'Owner\'';
        List<SObject> records = Database.query(query);
        for (SObject record : records) {
            String newAccessLevel = recordChanges.get(record.Id);
            if (!lValueAccessLevel.contains(newAccessLevel)) {
                continue;
            }
            record.put(accessLevelField, newAccessLevel);
            updatedRecordShares.add(record);
            lCustomSharingAccessLevelNotification.add(
                getMessage('Record share data for ' + (String) record.getSObject('UserOrGroup').get('Name') + ' was updated.', 'success')
            );
        }

        return updatedRecordShares;
    }

    /**
     * Deletes share records
     * @param recordId the Id of the record the share refers to
     * @param List<Id> lData the Id of the user or group the share refers to
     */
    @AuraEnabled
    public static List<SObject> deleteRecordShares(Id recordId, List<Id> lData) {
        List<SObject> lSharingDelete = new List<SObject>();

        if (lData.isEmpty()) {
            return lSharingDelete;
        }

        // check if you can delete share records
        Schema.DescribeSObjectResult describe = getSharingDescribe(recordId);
        if (!describe.isDeletable() || !describe.isAccessible()) {
            throw setThrowExceptionMessage(MESSAGE_ERROR_NO_PERMISSION_ACTION);
        }

        String query = buildQuery(recordId) + ' AND Id IN :lData AND RowCause != \'Owner\'';
        for (SObject record : Database.query(query)) {
            lSharingDelete.add(record);
            lCustomSharingAccessLevelNotification.add(
                getMessage('Record share data for ' + (String) record.getSObject('UserOrGroup').get('Name') + ' was delete.', 'success')
            );
        }

        return lSharingDelete;
    }

    /**
     * Creates new record sharing for the given record, user/group IDs, and access level
     *
     * @param recordId the ID of the record to create shares for
     * @param lUserOrGroupSharing the list of user or group IDs to share the record with
     * @param accessLevel the access level to grant to the user/group shares
     * @return a list of the newly created share records
     */
    public static List<SObject> createRecordShares(Id recordId, List<Id> lUserOrGroupSharing, String accessLevel) {
        List<SObject> newShares = new List<SObject>();
        if (lUserOrGroupSharing.isEmpty()) {
            return newShares;
        }
        String sObjectName = getObjectNameFromId(recordId);
        SObjectType shareObjectType = Schema.getGlobalDescribe().get(getSharingTableName(sObjectName));
        String accessLevelField = getAccessLevelField(sObjectName);
        String lookupField = getLookupField(sObjectName);
        for (Id userOrGroupId : lUserOrGroupSharing) {
            SObject share = shareObjectType.newSObject();
            share.put(accessLevelField, accessLevel);
            share.put(lookupField, recordId);
            share.put('UserOrGroupId', userOrGroupId);
            newShares.add(share);
            lCustomSharingAccessLevelNotification.add(
                getMessage('Record share data for ' + (String) recordId + ' was created.', 'success')
            );
        }
        return newShares;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getUsers() {
        List<Id> lCurrentUsersId = lUserAndGroupIdCurrent;
        List<SObject> lUser = Database.query(
            'SELECT Id, Name FROM User WHERE IsActive = true AND (ermt__UserToDisplayWhenSharing__c = true AND Id NOT IN :lCurrentUsersId)'
        );
        return lUser == null ? new List<SObject>() : lUser;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getGroup() {
        // Create a set to store the Ids of the groups that should be excluded from the query
        Set<Id> excludedGroupIds = new Set<Id>(lUserAndGroupIdCurrent);

        // Query for the groups that should be included in the result
        List<SObject> queryGroup = [
            SELECT Id, Name, Type, DeveloperName
            FROM Group
            WHERE Type = 'Regular' AND Id NOT IN :excludedGroupIds
        ];

        // Create a set to store the Ids of the accounts to be included in the result
        Set<Id> includedAccountIds = new Set<Id>();
        for (SObject record : queryGroup) {
            String developerName = (String) record.get('DeveloperName');
            if (developerName != null && developerName.startsWith('Account_')) {
                includedAccountIds.add(getValueOfId(developerName.replace('Account_', '')));
            }
        }

        // Query for the accounts to be included in the result
        Map<Id, SObject> queryAccount = new Map<Id, SObject>(
            [
                SELECT Id, Name
                FROM Account
                WHERE ermt__AccountToDisplayWhenSharing__c = TRUE AND IsDeleted = FALSE AND Id IN :includedAccountIds
            ]
        );

        // Create a list to store the groups to be included in the result
        List<SObject> includedGroups = new List<SObject>();
        for (SObject record : queryGroup) {
            String developerName = (String) record.get('DeveloperName');
            if (developerName == null || !developerName.startsWith('Account_')) {
                includedGroups.add(record);
            } else {
                Id accountId = getValueOfId(developerName.replace('Account_', ''));
                if (accountId != null && queryAccount.containsKey(accountId)) {
                    includedGroups.add(record);
                }
            }
        }

        // Return the list of included groups
        return includedGroups;
    }

    /**
     * Gets all the current shares for the record given
     *
     * @param recordId The record who's shares we want
     */
    @AuraEnabled
    public static List<CustomSharingRecordWrapper> getCurrentShares(final Id recordId) {
        // Query for current shares of the given record
        String query = buildQuery(recordId) + ' ORDER BY  UserOrGroup.Name';
        List<SObject> results = Database.query(query);

        // Initialize list of wrapper objects to return
        List<CustomSharingRecordWrapper> output = new List<CustomSharingRecordWrapper>();

        // Iterate over query results and build list of wrapper objects
        for (SObject so : results) {
            // Create new wrapper object
            CustomSharingRecordWrapper sh = new CustomSharingRecordWrapper();

            // Populate wrapper object with data from query result
            sh.RecordID = (Id) so.get('Id');
            sh.RowCause = String.valueOf(so.get('RowCause'));
            sh.AccessLevel = String.valueOf(so.get(getAccessLevelField(getObjectNameFromId(recordId))));
            sh.UserOrGroupId = (Id) so.get('UserOrGroupId');
            SObject userOrGroup = so.getSObject('UserOrGroup');
            sh.UserOrGroupName = userOrGroup == null ? '' : (String) userOrGroup.get('Name');
            sh.UserOrGroupType = getObjectLabelFromId((Id) so.get('UserOrGroupId'));
            lUserAndGroupIdCurrent.add(sh.UserOrGroupId);

            // Add wrapper object to output list
            output.add(sh);
        }

        return output;
    }

    public static String buildQuery(final Id recordId) {
        // Get the object name and describe the object
        String objectName = getObjectNameFromId(recordId);
        Schema.DescribeSObjectResult describe = getSharingDescribe(recordId);

        // Get the field names for the access level and the lookup field
        final String accessLevelField = getAccessLevelField(objectName);
        final String lookupField = getLookupField(objectName);

        // Check if the current user has access to the required fields
        if (
            !describe.isAccessible() ||
            !describe.fields.getMap().get('Id').getDescribe().isAccessible() ||
            !describe.fields.getMap().get('RowCause').getDescribe().isAccessible() ||
            !describe.fields.getMap().get('UserOrGroupId').getDescribe().isAccessible() ||
            !describe.fields.getMap().get(accessLevelField).getDescribe().isAccessible() ||
            !describe.fields.getMap().get(lookupField).getDescribe().isAccessible()
        ) {
            throw setThrowExceptionMessage(MESSAGE_ERROR_NO_PERMISSION_ACTION);
        }

        // Build the query
        String query = 'SELECT Id, RowCause, UserOrGroupId, UserOrGroup.Name, UserOrGroup.Type, ' + accessLevelField;
        query += ' FROM ' + getSharingTableName(objectName) + ' WHERE ' + lookupField + ' = \'';
        query += String.escapeSingleQuotes(String.valueOf(recordId)) + '\'';
        return query;
    }

    public static Id getValueOfId(String idStr) {
        try {
            return Id.valueOf(idStr);
        } catch (Exception e) {
            return null;
        }
    }

    private static AuraHandledException setThrowExceptionMessage(String errMsg) {
        AuraHandledException ex = new AuraHandledException(errMsg);
        ex.setMessage(errMsg);
        return ex;
    }

    /**
     * Returns the serialized access level for the given record
     *
     * @param recordId the Id of the record we are checking
     * @return list of access level options
     */
    private static List<CustomSharingAccessLevelWrapper> getAccessLevelOptions(Id recordId) {
        Schema.DescribeSObjectResult describe = getSharingDescribe(recordId);
        Schema.DescribeFieldResult fieldResult = describe.fields.getMap().get('AccessLevel').getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<CustomSharingAccessLevelWrapper> accessLevelWrapper = new List<CustomSharingAccessLevelWrapper>();
        List<String> filterLabel = lValueAccessLevel;

        // Add default option
        CustomSharingAccessLevelWrapper defaultOption = new CustomSharingAccessLevelWrapper();
        defaultOption.label = '--None--';
        defaultOption.value = '';
        accessLevelWrapper.add(defaultOption);

        // Add active picklist values
        for (Schema.PicklistEntry pick : picklistValues) {
            if (!pick.isActive() || !filterLabel.contains(pick.getValue())) {
                continue;
            }
            CustomSharingAccessLevelWrapper option = new CustomSharingAccessLevelWrapper();
            option.label = pick.getLabel();
            option.value = pick.getValue();
            accessLevelWrapper.add(option);
        }

        return accessLevelWrapper;
    }

    /**
     * Verifies if the user has permission to edit the record
     *
     * @param recordId the Id of the record to be checked
     * @return boolean indicating whether the user has permission to edit the record
     */
    private static boolean hasEditPermission(final Id recordId) {
        try {
            // Check if the user is the owner of the record
            String query =
                'SELECT OwnerId FROM ' +
                getObjectNameFromId(recordId) +
                ' WHERE Id = \'' +
                String.escapeSingleQuotes(String.valueOf(recordId)) +
                '\'';
            SObject record = Database.query(query);
            if (record.get('OwnerId') == UserInfo.getUserId()) {
                return true;
            }

            // Check if the user has Modify All Data permission
            List<PermissionSetAssignment> permissionSetAssignments = [
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.PermissionsModifyAllData = TRUE AND AssigneeId = :UserInfo.getUserId()
            ];
            if (!permissionSetAssignments.isEmpty()) {
                return true;
            }
        } catch (Exception e) {
            return false;
        }

        return false;
    }

    private static String getObjectNameFromId(final Id recordId) {
        Schema.SObjectType objectType = recordId.getSObjectType();
        Schema.DescribeSObjectResult objectDescription = objectType.getDescribe();
        return objectDescription.getName();
    }

    /**
    Returns the label of the object associated with the given record Id
    @param recordId the Id of the record whose object label we want to retrieve
    @return the label of the object associated with the given record Id
    */
    public static String getObjectLabelFromId(final Id recordId) {
        Schema.SObjectType objectType = recordId.getSObjectType();
        Schema.DescribeSObjectResult objectDescription = objectType.getDescribe();
        return objectDescription.getLabel();
    }

    private static boolean isStandard(final String sobj) {
        return !sobj.contains('__c');
    }

    private static String getLookupField(final String sobj) {
        if (isStandard(sobj)) {
            return sobj + 'Id';
        } else {
            return 'ParentId';
        }
    }

    private static String getAccessLevelField(final String sobj) {
        if (isStandard(sobj)) {
            return sobj + 'AccessLevel';
        } else {
            return 'AccessLevel';
        }
    }

    private static String getSharingTableName(final String sobj) {
        if (isStandard(sobj)) {
            return sobj + 'Share';
        } else {
            return sobj.replace('__c', '__Share');
        }
    }

    /**
     * Returns the SObject describe result for the sharing object for the given record
     *
     * @param recordId the Id of the record
     * @return the SObject describe result for the sharing object
     * @throws Exception if the sharing object does not exist
     */
    private static Schema.DescribeSObjectResult getSharingDescribe(final Id recordId) {
        try {
            String objectName = getObjectNameFromId(recordId);
            String sharingObjectName = getSharingTableName(objectName);
            return Schema.getGlobalDescribe().get(sharingObjectName).getDescribe();
        } catch (Exception e) {
            throw setThrowExceptionMessage(MESSAGE_ERROR_SHARING_RULE);
        }
    }

    public class CustomSharingAccessLevelWrapper {
        @auraEnabled
        public string label { get; set; }
        @auraEnabled
        public string value { get; set; }
    }

    private class CustomSharingAccessLevelNotification {
        private String message;
        private String variant;
    }

    private static CustomSharingAccessLevelNotification getMessage(String message, String variant) {
        CustomSharingAccessLevelNotification notify = new CustomSharingAccessLevelNotification();
        notify.message = message;
        notify.variant = variant;
        return notify;
    }
}