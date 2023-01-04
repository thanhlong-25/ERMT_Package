({
	checkChecklistSubmitableHelper : function(component) {
		var action = component.get("c.checkChecklistSubmitable");
		action.setParams({ checklistId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				var obj = response.getReturnValue();
				component.set("v.submitable", obj.submitable);
				component.set("v.popupTextContent", obj.message);
				component.set("v.finished", true);
			}
		});
		$A.enqueueAction(action);
	},

	submitChecklistHelper : function(component) {
		var action = component.get("c.submitChecklist");
		action.setParams({ checklistId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
				alert($A.get("$Label.c.UpdateSuccess"));
				var refreshEvent = $A.get("e.c:RefreshChecklistEvent");
				refreshEvent.fire();
				$A.get("e.force:closeQuickAction").fire();
			} else {
				alert($A.get("$Label.c.UpdateFailed"));
				window.location.reload();
			}
		});
		$A.enqueueAction(action);
	}

})