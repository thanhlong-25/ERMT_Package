public with sharing class ERMT_Utils {
	public static Boolean isValid(String stringValue, Schema.SObjectType sObjectType) {
		Id sObjectId;
		if(isId(stringValue)) sObjectId = (Id)stringValue;
		return isValid(sObjectId, sObjectType);
	}
	
	public static Boolean isValid(Id sObjectId, Schema.SObjectType sObjectType) {
		return !(sObjectId==null || sObjectId.getSObjectType()!=sObjectType);
	}
	
	public static Boolean isId(String stringValue) {
		return stringValue InstanceOf Id;
	}
}