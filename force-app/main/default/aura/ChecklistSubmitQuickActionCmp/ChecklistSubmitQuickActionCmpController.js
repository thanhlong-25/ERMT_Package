({
	doInit : function(component, event, helper) {
		// check user can answer this checklist  (can click button submit)
		// check checklist has done
		helper.checkChecklistSubmitableHelper(component);
	},

	hideSubmitPopup: function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}, 

	handleSave : function(component, event, helper) {
		helper.submitChecklistHelper(component);
	}
})