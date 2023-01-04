({
	doInit : function(component, event, helper) {
		var child = component.get("v.record.ermt__MClassifications_del__r");
		var values = component.get("v.record.values");
		var listBadges = [];
		if(child != null){
			child.forEach(function(element) {
				for (var i in values){
					if (values[i] == element.Id){
						listBadges.push(element.ermt__Label__c?element.ermt__Label__c:element.Name);
					}
				}
				
			});
			component.set("v.listBadges", listBadges);
		}
	},
})