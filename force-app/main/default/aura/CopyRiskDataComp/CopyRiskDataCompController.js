({
	doInit : function(component, event, helper) {
		
	},
	newClick : function(component, event, helper) {
		// var cmpTarget = component.find("projectForm");
		// $A.util.removeClass(cmpTarget, 'slds-hide');
		// $A.util.addClass(cmpTarget, 'slds-show');
		var modalBody;
		$A.createComponent("c:NewRecordComp", { "objType": "ermt__Project__c"},
			function(content, status) {
				if (status === "SUCCESS") {
					modalBody = content;
					component.find('overlayLib').showCustomModal({
						header: "New Project",
						body: modalBody, 
						showCloseButton: true,
						cssClass: "mymodal",
						closeCallback: function() {
						}
					})
				}                               
			});
	},
	copyClick : function(component, event, helper) {
		var projectId = component.find("projectField").get("v.value");
		var recordId = component.get("v.recordId")
		helper.copyData(component,recordId,projectId);
	},
})