({
 doInit: function(component, event, helper) {
      // this function call on the component load first time
      // get the page Number if it's not define, take 1 as default
      var page = component.get("v.page") || 1;
      // get  selected object
      var recordToDisply = component.get("v.pageSize");
      var parentId = component.get("v.recordId");
      var offset = (page-1)*recordToDisply;
      //console.log(offset);
      // call the helper function   
      helper.getDatas(component,parentId,offset,recordToDisply); 
    },
    viewAll : function (component, event, helper) {
      $A.get("e.force:navigateToURL").setParams({ 
        "url": "/lightning/r/"+component.get("v.recordId")+"/related/Risks__r/view" 
      }).fire();
    },
    newRecord:function(component, event, helper){
       var recordId = component.get("v.recordId");
       var createRecordEvent = $A.get("e.force:createRecord")           
       createRecordEvent.setParams({
        "entityApiName": 'ermt__Risk__c',
        "defaultFieldValues":{
          'ermt__Project__c': recordId
        }
      });
       createRecordEvent.fire(); 
    },
    viewDetail:function (component, event, helper) {
      var relatedListEvent = $A.get("e.force:navigateToRelatedList");
      relatedListEvent.setParams({
        "relatedListId": 'ermt__Risk__c',
        "parentRecordId": component.get("v.recordId")
      });
      relatedListEvent.fire();      
    }, 
    gotoDetail : function(component, event, helper) {
        var fieldName = event.currentTarget.dataset.fieldname;
        fieldName = fieldName.substr(0, fieldName.lastIndexOf("."));
        fieldName += '.Id';
        var record = component.get("v.records")[event.currentTarget.dataset.index];
        var value = fieldName.split('.').reduce(function(a, b) { return a[b];}, record);
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+value 
        }).fire();
    },
    edit:function(component, event, helper){
      var recordId = event.currentTarget.id;
      //window.location.href = "/"+recordId+"/e";
      var editRecordEvent = $A.get("e.force:editRecord");
      editRecordEvent.setParams({
        "recordId": recordId
      });
      editRecordEvent.fire();
    },
    delete:function(component, event, helper){
      // record to delete
      var recordId = event.currentTarget.id;
      // current page
      var page = component.get("v.page") || 1;
      // get selected fields
      var fields = component.get("v.fields");
      // get  selected object
      var parentId = component.get("v.recordId");
      // default pagesize
      var recordToDisply = component.get("v.pageSize");
      // offset
      var offset = (page-1)*recordToDisply;
      // confirm to delete
      if(confirm("Delete this record!")){
       helper.delete(component,parentId,fields,offset,recordToDisply,recordId);
     }
   },
   /*pagination*/
   nextPage: function(component, event, helper) {
       var parentId = component.get("v.recordId");
       var page = component.get("v.page") || 1;      
       // set the current page,(using ternary operator.)  "(page + 1)"
       page = page + 1;      
       var recordToDisply = component.get("v.pageSize");
       var offset = (page-1)*recordToDisply;
       helper.getDatas(component,parentId, offset, recordToDisply);
     },
     previousPage: function(component, event, helper) {
      var parentId = component.get("v.recordId"); 
      var page = component.get("v.page") || 1;      
      // set the current page,(using ternary operator.)  "(page + 1)"
      page = page - 1;      
      var recordToDisply = component.get("v.pageSize");
      var offset = (page-1)*recordToDisply;
      helper.getDatas(component,parentId, offset, recordToDisply); 
    },
    firstPage: function(component, event, helper) {
      var parentId = component.get("v.recordId");  
       var page = 1;   
       var recordToDisply = component.get("v.pageSize");
       var offset = (page-1)*recordToDisply;
       helper.getDatas(component,parentId, offset, recordToDisply); 
     },
     lastPage: function(component, event, helper) {
      var parentId = component.get("v.recordId");   
       var page = component.get("v.pages");   
       var recordToDisply = component.get("v.pageSize");
       var offset = (page-1)*recordToDisply;
       helper.getDatas(component,parentId, offset, recordToDisply); 
     },
     loadRightPanel: function(component, event, helper) {
      var evt = $A.get("e.c:PassVariable");
      evt.setParams({"Pass_Variable":event.currentTarget.getAttribute("id")});
      evt.fire();
     }
   })