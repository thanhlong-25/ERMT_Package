({
	doInit : function(component, event, helper) {
		var assessId = component.get('v.riskAssessId');
		if(component.get("v.isNewRecord") && component.get("v.projectId")){
			helper.getDatas(component,component.get("v.isNewRecord"));
		} else {
			var checkPermission = component.get("v.checkPermission");
			if (checkPermission){
				helper.checkPermission(component);
			}
		}
	},
	handleRecordChanged: function(component, event, helper) {
		switch(event.getParams().changeType) {
			case "ERROR":
			break;
			case "LOADED":
			if(!component.set("v.projectId")){
				component.set("v.projectId",component.get("v.riskAssessField.ermt__Risk__r.ermt__Project__c"));
			}
			helper.getDatas(component,component.get("v.isNewRecord"));
			break;
			case "REMOVED":
			break;
			case "CHANGED":
			break;
		}
	},
	doAction : function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var riskAssessIdFromNew = params.riskAssessIdFromNew;
            var cmp = component.find("riskComboId");
            if(cmp){
            	if(cmp.constructor == Array){
            		for(var i = 0;i<component.find("riskComboId").length;i++){
            			var item = component.find("riskComboId")[i];
            			item.sampleMethod(riskAssessIdFromNew);
            		}
            	}
            	else{
            		cmp.sampleMethod(riskAssessIdFromNew);
            	}
            }
            
        }
    }
})