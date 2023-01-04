({
	insertClassification: function(component) { 	
		var action = component.get("c.insertClassification");
		action.setParams({
			"riskId": component.get("v.riskId"),
			"classiIds": component.get("v.values"),
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