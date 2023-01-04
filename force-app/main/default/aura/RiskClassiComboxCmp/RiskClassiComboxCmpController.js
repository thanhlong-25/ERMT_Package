({
	doInit: function (component, event, helper) {
		var child = component.get("v.record.ermt__MClassifications_del__r");
		if(child != null){
			var selectArr = [];
			selectArr.push({label:'選択しない',value:''});
			child.forEach(function(element) {
				selectArr.push({label:(element.ermt__Label__c?element.ermt__Label__c:element.Name),value:element.Id});
			});
			component.set("v.options", selectArr);
		}
	},
	handleChange: function (component, event, helper) {
        var selectedOptionValue = component.get("v.record.selected");
        if(selectedOptionValue != null){
        	helper.upsertSelected(component);
        }
    }

})