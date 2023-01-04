({
	getAllQuestionByChecklistHelper : function(component) {
		var action = component.get("c.getAllQuestionByChecklist");
		action.setParams({ checklistId : component.get("v.recordId") });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (state === "SUCCESS") {
                
				var listQuestions = response.getReturnValue();
				
				// group by category, sort by order
				
				var categories = _(listQuestions).groupBy(function (item) {
					return item.ermt__Section__r.ermt__Category__r.Id;
				}).sortBy(function (group) {
					return group[0].ermt__Section__r.ermt__Category__r.ermt__Order__c;
				}).value();

				// get and set global answers variable
				var answers = [];
				for (var x in listQuestions){
					var item = listQuestions[x];
					if (item.ermt__Answer__r != null && item.ermt__Answer__r != undefined){
						answers.push(item.ermt__Answer__r[0]);
					} else {
						var answer = {'sobjectType': 'ermt__Answer__c'};
						answer.ermt__Question__c = item.Id;
						answers.push(answer);
					}
				} 
				
				component.set("v.answers", answers);
				component.set("v.categories", categories);
				
            } else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(action);
	},

	getChecklistAnswerPermissionHelper : function(component) {
		
		var action = component.get("c.getChecklistAnswerPermission");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				component.set("v.hasPermission", response.getReturnValue());
			}
		});
		$A.enqueueAction(action);
	},

	checkChecklistValidAnswer : function(component) {
		
		var action = component.get("c.checkChecklistValidAnswer");
		action.setParams({ checklistId : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				component.set("v.disable", !response.getReturnValue());
			}
		});
		$A.enqueueAction(action);
	},

})