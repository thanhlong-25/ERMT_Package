({
	copyData: function(component,recordId,projectId) { 
     var action = component.get("c.copyRiskData");
     action.setParams({
      "recordId": recordId,
      "projectId": projectId
     });
     action.setCallback(this, function(a) {
       var result = a.getReturnValue();     
       console.log(result);
       if(result.isSuccess){
       	alert('Copy data success');
       }
       else{
       	alert(result.message);
       }
    });
     $A.enqueueAction(action);
   },
})