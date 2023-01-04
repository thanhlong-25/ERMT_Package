({
	doInit : function(component, event, helper) {
		// 設定の読込み
		helper.loadSetting(component);
	},
	editRecord : function(component, event, helper) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": component.get("v.assessId")
        });
        editRecordEvent.fire();
    },
	changeRecordType : function(component, event, helper) {
		var assessId = component.get("v.assessId");
		var action = component.get("c.changeRiskAssessmentRecordType");
      	action.setParams({
			'recordId': assessId,
			'recordTypeName': 'Evaluation'
		});
		var toastEvent = $A.get("e.force:showToast");
      	action.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				toastEvent.setParams({
					"type": "success",
					"message": name + " " +$A.get("{! $Label.c.UpdateSuccess }"),
					"duration" : 3000
				});
				toastEvent.fire();
				component.find('recordAssess').reloadRecord(true);
         	} else {
				toastEvent.setParams({
					"type": "error",
					"message": name + " " +$A.get("{! $Label.c.UpdateFailed }"),
					"duration" : 3000
				});
				toastEvent.fire();
				var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
			 }
      	});
      	$A.enqueueAction(action);
	},
	// コピーのクリック時
	handleCopyClick : function(component, event, helper) {
		component.set('v.isCopyDialogOpen', true);
	},
	// コピーの閉じるのクリック時
	handleCopyCloseClick : function(component, event, helper) {
		component.set('v.isCopyDialogOpen', false);
	}
})