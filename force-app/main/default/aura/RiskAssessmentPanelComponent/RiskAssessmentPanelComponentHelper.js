({
   enableRiskAssessment: function(component,recordId) { 
     component.set("v.hideSpinner", true); 
     var action = component.get("c.enableRiskAssessmentData");
     action.setParams({
      "recordId": recordId 
     });
     action.setCallback(this, function(a) {
       var result = a.getReturnValue();     
       // console.log('result ---->' + JSON.stringify(result));
       if(result){
        // component.find('recordUpdater').reloadRecord(true);
      }
      component.set("v.hideSpinner", false);
    });
     $A.enqueueAction(action);
   },
   getFieldsFromLayout: function(component) { 
     var action = component.get("c.getFieldsFromLayoutByName");
      action.setParams({
        'name':'ermt__RiskAssessment__c-ermt__ERMT Analysis Layout'
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();  
         // console.log('result ---->' + JSON.stringify(result));
         if(result && a.getState() === "SUCCESS"){
           component.set('v.fieldsLayout',result);
           // console.log(component.get('v.fieldsLayout'));
         }
      });
      // enqueue the action 
      $A.enqueueAction(action);
   }
})