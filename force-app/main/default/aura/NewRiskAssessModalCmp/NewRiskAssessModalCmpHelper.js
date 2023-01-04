({
	getRecordTypeAnalysisId: function(component) { 
     var action = component.get("c.getRecordTypeRiskAssessByName");
     action.setParams({
         "name": "Analysis"       
      });
     action.setCallback(this, function(a) {
       var result = a.getReturnValue();     
       console.log('result ---->' + JSON.stringify(result));
       if(result){
        component.set('v.newRecordRecordTypeId',result);
      }
    });
     $A.enqueueAction(action);
   },
   getFieldsFromLayout: function(component) { 
     var action = component.get("c.getFieldsFromLayoutByName");
      action.setParams({
        'name':'ermt__RiskAssessment__c-ermt__ERMT Evaluation Layout'
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