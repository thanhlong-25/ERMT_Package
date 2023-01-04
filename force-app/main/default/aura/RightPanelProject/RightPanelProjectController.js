({
	doInit : function(component, event, helper) {

    helper.getRecordTypeEvaluationId(component);
		var sType = component.get("v.sObjectName");
		if(sType == "ermt__Risk__c"){
			component.set("v.parentId",component.get("v.recordId"));
			component.set("v.isRiskDetail",true); 
    }
  },
  GetValueFromPassVariable : function(component, event, helper) {
    var parentId = event.getParam("Pass_Variable");
    if(component.get("v.parentId") == parentId){
      var a = component.get('c.parentIdChange');
      $A.enqueueAction(a); 
    }
    else{
      component.set("v.parentId",parentId);
    }
  }, 
  handleRecordUpdated: function(component, event, helper) {
    var eventParams = event.getParams();
    if(eventParams.changeType === "LOADED" && component.get("v.recordField.ermt__AssessmentStatus__c") != "Specific") {
     var parentId = component.get("v.parentId");
     helper.getRecordTypeDatas(component,parentId);
   }
 },
 newRecord:function(component, event, helper){
   var recordId = component.get("v.recordId");
   var createRecordEvent = $A.get("e.force:createRecord")           
   createRecordEvent.setParams({
    "entityApiName": "ermt__RiskAssessment__c",
    "defaultFieldValues":{
      "ermt__Risk__c": recordId,
      "RecordTypeId": event.getSource().get("v.name")
    }
  });
   createRecordEvent.fire(); 
 },
 clickTab: function(component, event, helper) {
  helper.clearAllTab(component, event);
  $("#"+event.currentTarget.id).attr('class', 'slds-tabs_scoped__item slds-is-active');
  $("#"+event.currentTarget.id+"_TabData").attr('class', 'slds-tabs_scoped__content slds-show');
  $("#"+event.currentTarget.id+" > a").blur();
 },
 parentIdChange: function(component, event, helper) {
  helper.getDatas(component,component.get("v.parentId"),true);
  component.find('recordLoader').reloadRecord(true);
 },
 doReloadParentId : function(component, event, helper) {
  console.log('hehe');
  var a = component.get('c.parentIdChange');
  $A.enqueueAction(a); 
 }
})