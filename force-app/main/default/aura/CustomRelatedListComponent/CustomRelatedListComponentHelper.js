({
   //, page, recordToDisply
   getDatas: function(component,parentId,offset,defaultSize) { 	
      // create a server side action. 
      var action = component.get("c.getData");
      var page = (offset/defaultSize)+1;
      // console.log(page);
      action.setParams({
         "parentId": parentId,
         "offset": offset,
         "defaultSize" : defaultSize         
      });
      // set a call back   
      action.setCallback(this, function(a) {
         // store the response return value (wrapper class insatance)  
         var result = a.getReturnValue();     
         // console.log('result ---->' + JSON.stringify(result));
         // set the component attributes value with wrapper class properties.
        component.set("v.objectIcon", result.objectIcon);
         component.set("v.records", result.records);
         component.set("v.showFields", result.fieldList); 
         component.set("v.page", page);
         component.set("v.total", result.total);
         component.set("v.pages", Math.ceil(result.total/defaultSize)); 
         component.set("v.objLabel", result.objLabel); 

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   delete:function(component,parentId,fields,offset,defaultSize,recordId){
       var action = component.get("c.deleteRecord");
       // set the parameters to method 
      var page = (offset/defaultSize)+1;
      action.setParams({
        "parentId": parentId,
        "fields": fields,
        "offset": offset,
        "defaultSize" : defaultSize,  
        "recordId": recordId
      });
      // set a call back   
      action.setCallback(this, function(a) {
         // store the response return value (wrapper class insatance)  
         var result = a.getReturnValue();
         // set data
         component.set("v.objectIcon", result.objectIcon);
         component.set("v.records", result.records);
         component.set("v.showFields", result.showFields); 
         component.set("v.showLabels", result.showLabels);
         component.set("v.page", page);
         component.set("v.total", result.total);
         component.set("v.pages", Math.ceil(result.total/defaultSize)); 
      });
      $A.enqueueAction(action);
   }
})