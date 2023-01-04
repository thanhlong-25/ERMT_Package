({
	onCancel: function(component, event, helper) {
		component.find("overlayLib").notifyClose();
	},
	onSuccess: function(component, event, helper) {
		// var payload = event.getParams().response;
		// console.log(JSON.stringify(payload));
		component.find("overlayLib").notifyClose();
	}
})