({
	getDatas: function(component) { 	
      var action = component.get("c.getListSelectAndChild");
      action.setParams({
      	"projectId": component.get("v.riskField.ermt__Project__c")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
           this.getSelectedClassi(component, result);
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   getSelectedClassi: function(component, records) {   
      var action = component.get("c.getSelectedClassification");
      action.setParams({
        "riskId": component.get("v.recordId")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
          var selectedArr = [];
          records.forEach(function(element) {
            var values = [];
            result.forEach(function(element2) {
              if(element.Id == element2.ermt__M_Classification__r.ermt__ParentMClassification_del__c)
              values.push(element2.ermt__M_Classification__c);
            });
            element['values'] = values;
          });
          component.set("v.records", records); 
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
})