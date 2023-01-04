({
	getDatas: function(component) { 	
      var action = component.get("c.getListSelect");
      action.setParams({
        "recordTypeName": component.get("v.recordTypeName")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
           var selectArr = [];
           result.forEach(function(element) {
           	selectArr.push({label:element.Name,value:element.Id});
           });
           component.set("v.options", selectArr); 
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   insertClassification: function(component) { 	
      var action = component.get("c.insertClassification");
      action.setParams({
      	"classiIds": component.get("v.values"),
      	"projectId": component.get("v.recordId"),
        "recordTypeName": component.get("v.recordTypeName")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
         	
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   getSelectedClassification: function(component) { 	
      var action = component.get("c.getSelectedClassification");
      action.setParams({
      	"projectId": component.get("v.recordId"),
        "recordTypeName": component.get("v.recordTypeName")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
         	var selectedArr = [];
         	result.forEach(function(element) {
         		selectedArr.push(element.ermt__M_Classification__c);
         	});
         	component.set("v.values", selectedArr);
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
})