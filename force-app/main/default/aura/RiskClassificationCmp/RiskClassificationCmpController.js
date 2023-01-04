({
	doInit : function(component, event, helper) {
		
	},
	handleRecordChanged: function(component, event, helper) {
		switch(event.getParams().changeType) {
			case "ERROR":
			break;
			case "LOADED":
			helper.getDatas(component);
			break;
			case "REMOVED":
			break;
			case "CHANGED":
			break;
		}
	}
})