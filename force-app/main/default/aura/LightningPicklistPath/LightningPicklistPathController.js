({
	handleSelect : function (component, event, helper) {     
    	var stepName = event.getParam("detail").value;
    	component.set("v.picklistField.ermt__AssessmentStatus__c",stepName);
        
     	component.find("record").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                component.find('notifLib').showToast({
            		"variant": "success",
            		"message": "Record was updated sucessfully",
                    "mode" : "sticky"
        		});
            } else {
                component.find('notifLib').showToast({
            		"variant": "error",
            		"message": "Unfortunately, there was a problem updating the record.",
                    "mode" : "sticky"
        		});
            }
        }));
   
    }
})