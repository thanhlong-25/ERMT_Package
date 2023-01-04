({
	upsertSelected: function(component,riskAssessId) { 	
      var action = component.get("c.upsertSelectedClassification");
      action.setParams({
      	"riskAssessId": riskAssessId,
      	"classiId": component.get("v.record.selected"),
      	"parentclassiId": component.get("v.record.Id")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
         	
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
})