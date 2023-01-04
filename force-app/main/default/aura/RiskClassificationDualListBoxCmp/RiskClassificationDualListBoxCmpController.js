({
	doInit : function(component, event, helper) {
		var child = component.get("v.record.ermt__MClassifications_del__r");
		var values = component.get("v.record.values");
		if(child != null){
			var selectArr = [];
			child.forEach(function(element) {
				selectArr.push({label:(element.ermt__Label__c?element.ermt__Label__c:element.Name),value:element.Id});
			});
			component.set("v.options", selectArr);
			if (values.length > 0){
				component.set("v.values", values);
			}
		}
	},
	handleChange: function (component, event, helper) {
        helper.insertClassification(component, event);
    }

})