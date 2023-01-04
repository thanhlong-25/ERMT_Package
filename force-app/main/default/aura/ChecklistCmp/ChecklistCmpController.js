({
	doInit : function(component, event, helper) {
		helper.getChecklistAnswerPermissionHelper(component);
		helper.checkChecklistValidAnswer(component);
		helper.getAllQuestionByChecklistHelper(component);
	},

	refreshChecklist: function(component){
		component.set("v.disable", true);
	}
		
})