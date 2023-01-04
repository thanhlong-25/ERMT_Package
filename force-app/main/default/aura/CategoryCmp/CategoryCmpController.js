({
	doInit : function(component, event, helper) {
		var listQuestionBycategory = component.get("v.category");

		if (listQuestionBycategory != undefined && listQuestionBycategory.length > 0) {
			var sections = _(listQuestionBycategory).groupBy(function (item) {
				return item.ermt__Section__r.Id;
			}).sortBy(function (group) {
				return group[0].ermt__Section__r.ermt__Order__c;
			}).value();

			component.set("v.sections", sections);
			component.set("v.categoryTitle", listQuestionBycategory[0].ermt__Section__r.ermt__Category__r.ermt__Title__c);
		}
	},

	saveChecklist: function (component, event, helper){

		var answers = component.get("v.answers");
		var checklistId = component.get("v.checklistId");
		var action = component.get("c.upsertAnswers");

		// filter question - answer by category => save only current category
		var questions = component.get("v.category");
		var answersToUpdate = [];
		var qIds = [];
		for (var x in questions){
			qIds.push(questions[x].Id);
		}
		if (qIds.length <= 0) return;

		for(var x in qIds){
			for (var y in answers){
				if (qIds[x] == answers[y].ermt__Question__c) {
					answersToUpdate.push(answers[y]);
				}
			}
		}
		if (answersToUpdate.length <=0 ) return;

		// check required field (date field)
		var check = false;
		var listIds = []; // list all question Id need to fill data and warning all of them
		for (var i in answersToUpdate){
			for (var j in questions){
				var question = questions[j];
				if (answersToUpdate[i].ermt__Question__c === question.Id){
					var radioValue = null;

					if (answersToUpdate[i].ermt__Answer_0__c == true) {
						radioValue = '0';
					} else if (answersToUpdate[i].ermt__Answer_1__c == true) {
						radioValue = '1';
					} else if (answersToUpdate[i].ermt__Answer_2__c == true) {
						radioValue = '2';
					} else if (answersToUpdate[i].ermt__Answer_3__c == true) {
						radioValue = '3';
					} else if (answersToUpdate[i].ermt__Answer_4__c == true) {
						radioValue = '4';
					} else if (answersToUpdate[i].ermt__Answer_5__c == true) {
						radioValue = '5';
					}

					var dateFieldValue = answersToUpdate[i].ermt__Answer_Datefield__c;
					var textFieldValue = answersToUpdate[i].ermt__Answer_Textarea__c;
					var _c = false;
					var str = question.ermt__Value_to_display_date_field__c;
					if (str != null && str != undefined && str != ''){
						var array = str.split(";");
						if (array != undefined){
							if (array.length > 0){
								for (var k in array){
									if (array[k] === radioValue ) {
										_c = true;
									}
								}
							}
						}
					}
					if (_c && (dateFieldValue === null || dateFieldValue === undefined || dateFieldValue === '' || textFieldValue === null || textFieldValue === undefined || textFieldValue === '')){
						check = true;
						listIds.push(question.Id);
					}
				}
			}
		}
		if (check) {
			var categoryEvent = $A.get("e.c:SaveChecklistEvent");
			categoryEvent.setParams({ "listQuestionIds": listIds}); // listQuestionIds is the questions need to handle this event
			categoryEvent.fire();
			return;
		}

		action.setParams({
				"checklistId": checklistId,
				"listAnswers": answersToUpdate
		});
		action.setCallback(this, function(response){
				var state = response.getState();
				if (state === "SUCCESS") {
					var listAnswers = response.getReturnValue();

					for (var i in listAnswers) {
						if (!listAnswers[i].Id) {
							console.log(response);
							console.log(response.getReturnValue());
							alert(component.get("v.categoryTitle") + ": " + $A.get("$Label.c.UpdateFailed"));
							return;
						}
					}
					
					for (var i in listAnswers) {
						for (var j in answers){
							if (listAnswers[i].ermt__Question__c == answers[j].ermt__Question__c){
								answers[j].Id = listAnswers[i].Id;
							}
						}
					}
					component.set("v.answers", answers);
					
					alert(component.get("v.categoryTitle") + ": " + $A.get("$Label.c.UpdateSuccess"));
				} else {
					console.log(response);
					console.log(response.getReturnValue());
					alert(component.get("v.categoryTitle") + ": " + $A.get("$Label.c.UpdateFailed"));
				}
		});
		$A.enqueueAction(action);
	},
})