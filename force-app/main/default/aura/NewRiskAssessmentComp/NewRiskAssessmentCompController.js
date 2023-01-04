({
	onCancel: function(component, event, helper) {
		component.find("overlayLib").notifyClose();
	},
	onSuccess: function(component, event, helper) {
		// var payload = event.getParams().response;
		// console.log(JSON.stringify(payload));
		alert('レコードの新規作成に成功しました。');
		component.find("overlayLib").notifyClose();
	},
	onLoaded: function(component, event, helper) {
		component.set("v.isLoaded",true);
	},
})