({
	getAcctChilds : function (component) {
        var action = component.get("c.getAccountChilds");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            	var accounts = response.getReturnValue();
            	var data = this.getNestedChildren(accounts,null);
              component.set('v.gridData', data);
              component.set('v.gridDataOrigin', accounts);
            	// console.log(data);
            }
            // error handling when state is "INCOMPLETE" or "ERROR"
         });
         $A.enqueueAction(action);
    },
    getSelectedProjectAccount: function(component) { 	
      var action = component.get("c.getSelectedPrjPart");
      action.setParams({
      	"projectId": component.get("v.recordId")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
         	var selectedArr = [];
         	result.forEach(function(element) {
         		selectedArr.push(element.ermt__Account__c);
         	});
         	if(selectedArr.length > 0){
              var expandedRows = this.getParentIds(component,selectedArr);
              component.set('v.gridExpandedRows', expandedRows);
              component.set('v.gridSelectedRows', selectedArr);
              component.set('v.gridSelectedRowsOrigin', selectedArr);
         	}

            
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
    insertProjectAccount : function(component, selectedIds) { 	
      var action = component.get("c.insertProjectParticipant");
      action.setParams({
      	"accountIds": selectedIds,
      	"projectId": component.get("v.recordId")
      });
      action.setCallback(this, function(a) {
         var result = a.getReturnValue();    
         if(result && a.getState() === "SUCCESS"){
         	
         }

      });
      // enqueue the action 
      $A.enqueueAction(action);
   },
   getNestedChildren :  function (models, parentId) {
   	var nestedTreeStructure = [];
   	var length = models.length;

   	for (var i = 0; i < length; i++) {
   		var model = models[i];

   		if (model.ParentId == parentId) {
   			var _children = this.getNestedChildren(models, model.Id);

   			if (_children.length > 0) {
   				model._children = _children;
   			}

   			nestedTreeStructure.push(model);
   		}
   	}

   	return nestedTreeStructure;
   },
   getParentIds : function (component,inputSort){
      component.set('v.resultsExpanded', []);
      var arr = component.get('v.gridDataOrigin');
      for(var i = 0 ; i< inputSort.length ; i++){
         this.findParents(component,inputSort[i],arr);
      }
      var results = component.get('v.resultsExpanded');
      results = this.deduplicate(results);
      component.set('v.resultsExpanded', results);
      // console.log(results);
      return results;
   },
   findParents : function (component,input, arr) {
      var self = this;
      var results = component.get('v.resultsExpanded');
      arr.filter(function(item){
         return item.Id == input;
      }).forEach(function(item){
         if(item.ParentId != null){
            results.push(item.ParentId);
            component.set('v.resultsExpanded', results);
         }
         self.findParents(component,item.ParentId,arr);
      });
   },
   deduplicate : function (arr) {
      var isExist = function isExist(arr,x){
        return arr.includes(x);
      }
      var ans = [];
      arr.forEach(function(element){
          if(!isExist(ans,element)) ans.push(element);
      });
      return ans;
   }
})