({
	doInit : function(component, event, helper) {
		helper.getRecordTypeAnalysisId(component);
    helper.getFieldsFromLayout(component);
  },
  hideNewPopup: function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },
  handleLoad: function(component, event, helper) {
    component.find('rTypeField').set('v.value', component.get("v.newRecordRecordTypeId"));
    for(var i = 0;i<component.find("preField").length;i++){
      var item = component.find("preField")[i];
      var str="";
      if(item.get("v.fieldName") == "ermt__Risk__c"){
        str = "v.recordId";
      }else{
        str = "v.record."+item.get("v.fieldName");
      }
      component.find("preField")[i].set("v.value",component.get(str));
    }
  },
  handleSave: function(component, event, helper) {
    if(!component.get("v.newRAssessIdAfterSuccess"))
     component.find('newRiskForm').submit();
 },
 handleSuccess: function(component, event, helper) {
  var payload = event.getParams().response;
  console.log(payload.id);
  component.set("v.newRAssessIdAfterSuccess",payload.id);
  var objCompA = component.find('cmpEva');
  if(objCompA)
    objCompA.sampleMethod(payload.id);

  var objCompB = component.find('cmpLike');
  if(objCompB)
    objCompB.sampleMethod(payload.id);
  
  var objCompC = component.find('cmpCons');
  if(objCompC)
    objCompC.sampleMethod(payload.id);
  
  var objCompD = component.find('cmpSever');
  if(objCompD)
    objCompD.sampleMethod(payload.id);

  var evt = $A.get("e.c:PassVariable");
  evt.setParams({"Pass_Variable":component.get("v.recordId")});
  evt.fire();
  $A.get("e.force:closeQuickAction").fire();
  // $A.get('e.force:refreshView').fire();
}
})