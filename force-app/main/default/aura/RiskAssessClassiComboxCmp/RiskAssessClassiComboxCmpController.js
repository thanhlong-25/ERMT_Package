({
	doInit: function (component, event, helper) {
		var child = component.get("v.record.ermt__MClassifications_del__r");
		if(child != null){
			var selectArr = [];
			selectArr.push({label:$A.get("$Label.c.Input_NotSelected"),value:''});
			child.forEach(function(element) {
				selectArr.push({label:(element.ermt__Label_Pick__c?element.ermt__Label_Pick__c:element.ermt__Label__c),value:element.Id});
			});
			component.set("v.options", selectArr);
		}
	},
	handleChange: function (component, event, helper) {
		if(!component.get("v.isNewRecord")){
			var selectedOptionValue = component.get("v.record.selected");
			if(selectedOptionValue != null){
				helper.upsertSelected(component,component.get("v.riskAssessId"));
			}
		}
    },
    doAction : function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var riskAssessIdFromNew = params.riskAssessIdFromNew;
            var selectedOptionValue = component.get("v.record.selected");
            if(selectedOptionValue != null){
            	helper.upsertSelected(component,riskAssessIdFromNew);
            }
        }
    }
})