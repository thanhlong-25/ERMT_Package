({
	changeRecordTypeHelper : function(component) {
		var action = component.get("c.changeRiskRecordType");
		action.setParams({ riskId : component.get("v.recordId"),recordTypeName : 'ClassifiedRisk' });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				//alert($A.get("$Label.c.UpdateSuccess"));
				//window.location.reload();
				var toastEvent = $A.get('e.force:showToast');
				var title = $A.get("$Label.c.Confirm_risk_classification");
				var message = $A.get("$Label.c.RiskClassificationConfirm_Save_Complete");
				toastEvent.setParams({
					'type': 'success'
					, 'title': title
					, 'message': message
				});
				toastEvent.fire();
				$A.get('e.force:refreshView').fire();
			}
		});
		$A.enqueueAction(action);
	}
})