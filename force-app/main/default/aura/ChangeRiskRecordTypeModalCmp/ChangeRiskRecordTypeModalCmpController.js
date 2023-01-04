({
	hideSubmitPopup: function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}, 

	handleSave : function(component, event, helper) {
		helper.changeRecordTypeHelper(component);
	}
})