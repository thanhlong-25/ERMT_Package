({
	getDatas: function(component,parentId,isRiskDetail) { 	
      isRiskDetail = isRiskDetail || false;
      // create a server side action. 
      var action = component.get(isRiskDetail?"c.getRiskAssessmentDataForRiskDetail":"c.getRiskAssessmentDataForRiskDetail");
      action.setParams({
         "parentId": parentId       
      });
      // set a call back   
      action.setCallback(this, function(a) {
         // store the response return value (wrapper class insatance)  
         var result = a.getReturnValue();     
         // console.log('result ---->' + JSON.stringify(result));
         // set the component attributes value with wrapper class properties.
         if(result && a.getState() === "SUCCESS"){
           component.set("v.records", result); 
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   getRecordTypeDatas: function(component,parentId) {  
      var action = component.get("c.getRiskAssessRecordType");
      action.setParams({

      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();     
         // console.log('result ---->' + JSON.stringify(result));
         if(result){
            component.set("v.recordTypes", result); 
         }

      });
      $A.enqueueAction(action);
   },
   clearAllTab: function(component, event) {
    $("#panel .slds-tabs_scoped__item").removeClass("slds-is-active");
    $("#panel .slds-tabs_scoped__content").removeClass("slds-show").addClass("slds-hide");
   },
   getRecordTypeEvaluationId: function(component) { 
     var action = component.get("c.getRecordTypeRiskAssessByName");
     action.setParams({
         "name": "Evaluation"       
      });
     action.setCallback(this, function(a) {
       var result = a.getReturnValue();     
       // console.log('result ---->' + JSON.stringify(result));
       if(result){
        component.set('v.newRecordRecordTypeId',result);
      }
    });
     $A.enqueueAction(action);
   },
})