({
	handleClose : function(component, event, helper) {
        var isSaved = event.getParam('isSaved');
        if (isSaved) {
            $A.get('e.force:refreshView').fire();
        }
		$A.get("e.force:closeQuickAction").fire();
	},
})