({
	doInit : function(component, event, helper) {
		var listQuestionBySection = component.get("v.section");
        listQuestionBySection = JSON.parse(JSON.stringify(listQuestionBySection));

        var questions = _.orderBy(listQuestionBySection, 'ermt__Order__c', 'asc');

        component.set("v.questions", questions);
        component.set("v.sectionTitle", listQuestionBySection[0].ermt__Section__r.ermt__Title__c);
	},
})