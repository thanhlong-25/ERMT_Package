({
	getDatas: function(component,isNew) { 	
      var action = component.get("c.getListSelectAndChild");
      action.setParams({
          "projectId": component.get("v.projectId"),
          "recordTypeName": component.get("v.recordTypeName")
        });
      if(isNew){
        action.setCallback(this, function(a) {
         var result = a.getReturnValue();  
         if(result && a.getState() === "SUCCESS"){
           component.set("v.records", result); 
         }
       });
      }else{
        action.setCallback(this, function(a) {
         var result = a.getReturnValue();  
         if(result && a.getState() === "SUCCESS"){
           this.getSelectedClassification(component, result);
         }
       });
      }
      
      // enqueue the action 
      $A.enqueueAction(action);
   },
   getSelectedClassification: function(component, records) {   
      var action = component.get("c.getSelectedClassification");
      action.setParams({
        "riskAssessId": component.get("v.riskAssessId"),
        "recordTypeName": component.get("v.recordTypeName")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
          var selectedArr = [];
          records.forEach(function(element) {
            result.forEach(function(element2) {
              if(element.Id == element2.ermt__M_Classification__r.ermt__ParentMClassification_del__c)
              element.selected = element2.ermt__M_Classification__c;
            });
          });
          component.set("v.records", records); 
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   checkPermission: function(cmp, records) {   
      var action = cmp.get("c.checkEditPermission");
      action.setCallback(this, function(a) {
        var result = a.getReturnValue();
        cmp.set("v.hasEditPermission", result);
      });
      $A.enqueueAction(action);
    }
})