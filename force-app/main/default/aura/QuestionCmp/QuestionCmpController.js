({

	doInit : function(component, event, helper) {
		var question = component.get("v.question");
		if (question != null && question != undefined){
			// init radio options for this question
			// default value of these options is in ['0','1','2','3','4','5']
			var map = [];
            if (question.ermt__Label_0__c != null && question.ermt__Label_0__c != undefined){
            	map.push({'label': question.ermt__Label_0__c, 'value': '0'});    
            }
            if (question.ermt__Label_1__c != null && question.ermt__Label_1__c != undefined){
            	map.push({'label': question.ermt__Label_1__c, 'value': '1'});    
            }
            if (question.ermt__Label_2__c != null && question.ermt__Label_2__c != undefined){
            	map.push({'label': question.ermt__Label_2__c, 'value': '2'});    
            }
            if (question.ermt__Label_3__c != null && question.ermt__Label_3__c != undefined){
            	map.push({'label': question.ermt__Label_3__c, 'value': '3'});    
            }
            if (question.ermt__Label_4__c != null && question.ermt__Label_4__c != undefined){
            	map.push({'label': question.ermt__Label_4__c, 'value': '4'});    
            }
            if (question.ermt__Label_5__c != null && question.ermt__Label_5__c != undefined){
            	map.push({'label': question.ermt__Label_5__c, 'value': '5'});    
            }

			component.set("v.answerOptions", map);
			
			// init answer value to field
			var answers = question.ermt__Answer__r;
			var answer = null;
			if (answers != null && answers != undefined){
				answer = answers[0];
			}
			if (answer != null){
				var radioValue = null;
				if (answer.ermt__Answer_0__c == true) {
					radioValue = '0';
				} else if (answer.ermt__Answer_1__c == true) {
					radioValue = '1';
				} else if (answer.ermt__Answer_2__c == true) {
					radioValue = '2';
				} else if (answer.ermt__Answer_3__c == true) {
					radioValue = '3';
				} else if (answer.ermt__Answer_4__c == true) {
					radioValue = '4';
				} else if (answer.ermt__Answer_5__c == true) {
					radioValue = '5';
				}
				if (radioValue != null) component.set("v.radioValue", radioValue);

				// set value for text field and date field
				if (answer.ermt__Answer_Textarea__c != null) component.set("v.textValue", answer.ermt__Answer_Textarea__c);
				if (answer.ermt__Answer_Datefield__c != null) component.set("v.dateValue", answer.ermt__Answer_Datefield__c);

				// enable date field
				var str = question.ermt__Value_to_display_date_field__c;
				if (str != null && str != undefined && str != ''){
					var array = str.split(";");
					if (array != undefined){
						for (var k in array){
							if (array[k] === radioValue) {
								component.set("v.disableDate", false);
								component.set("v.dateValueRequired", true);
								break;
							}
						}
					}
				}
			}

			// 補足画像のURLを抽出
			var pattern = /<img [^>]*src="([^\"]+)"[^>]*>/;
			if (question.ermt__Supplement_Image_1__c) {
				if (pattern.exec(question.ermt__Supplement_Image_1__c)) {
					var url = RegExp.$1;
					url = url.replace(/&amp;/gi, '&');
					component.set("v.supplementImageUrl1", url);
				}
			}
			if (question.ermt__Supplement_Image_2__c) {
				if (pattern.exec(question.ermt__Supplement_Image_2__c)) {
					var url = RegExp.$1;
					url = url.replace(/&amp;/gi, '&');
					component.set("v.supplementImageUrl2", url);
				}
			}
		}
	},

	handleRadioChange: function (component, event, helper) {
		var radioValue = component.get("v.radioValue");
		var question = component.get("v.question");

		// check condition to enable/disable date field
		var str = question.ermt__Value_to_display_date_field__c;
		var check = false;
		if (str != null && str != undefined && str != ''){
			var array = str.split(";");
			if (array != undefined){
				for (var k in array){
					if (array[k] === radioValue) {
						component.set("v.disableDate", false);
						component.set("v.dateValueRequired", true);
						check = true;
						break;
					}
				}
			}
		}
		if (!check){
			component.set("v.dateValue", null);
			component.set("v.disableDate", true);
			component.set("v.dateValueRequired", false);

			component.set("v.reRender", false); 
			component.set("v.reRender", true);
		}

		// add or update answers list
		var answers = component.get("v.answers");
		
		for (var i in answers){
			if (answers[i].ermt__Question__c == question.Id){
				
				answers[i].ermt__Answer_0__c = false;
				answers[i].ermt__Answer_1__c = false;
				answers[i].ermt__Answer_2__c = false;
				answers[i].ermt__Answer_3__c = false;
				answers[i].ermt__Answer_4__c = false;
				answers[i].ermt__Answer_5__c = false;

				switch (radioValue) {
					case '0': 
						answers[i].ermt__Answer_0__c = true;
						break;
					case '1':
						answers[i].ermt__Answer_1__c = true;
						break;
					case '2':
						answers[i].ermt__Answer_2__c = true;
						break;
					case '3':
						answers[i].ermt__Answer_3__c = true;
						break;
					case '4':
						answers[i].ermt__Answer_4__c = true;
						break;
					case '5':
						answers[i].ermt__Answer_5__c = true;
						break;
				}

				if (!check){
					answers[i].ermt__Answer_Datefield__c = null;
				}
				break;
			}
		}
		component.set("v.answers", answers);
	},

	handleDateChange: function (component, event, helper) {
		var answers = component.get("v.answers");
		var question = component.get("v.question");
		var dateValue = component.get("v.dateValue");

		var answers = component.get("v.answers");

		for (var i in answers){
			if (answers[i].ermt__Question__c == question.Id){
				answers[i].ermt__Answer_Datefield__c = dateValue;
				break;
			}
		}
		
		component.set("v.answers", answers);
	},

	handleTextChange: function (component, event, helper) {
		var answers = component.get("v.answers");
		var question = component.get("v.question");
		var textValue = component.get("v.textValue");

		var answers = component.get("v.answers");

		for (var i in answers){
			if (answers[i].ermt__Question__c == question.Id){
				answers[i].ermt__Answer_Textarea__c = textValue;
				break;
			}
		}
		
		component.set("v.answers", answers);
	},

	validate: function(component, event){
		var req = component.get("v.dateValueRequired");
		var val = component.get("v.dateValue");
		var textVal = component.get("v.textValue");
		var question = component.get("v.question");

		var listIds = event.getParam("listQuestionIds"); 
		if (listIds != undefined && listIds.length > 0){
			if (listIds.indexOf(question.Id) >= 0) {
				var _c = false;
				if (req && (val === null || val === undefined || val === '')){
					var input = component.find("ipDateId");
					if (input.constructor == Array){
						input = input[0];	
					} 
					input.reportValidity();
					if (listIds.indexOf(question.Id) == 0) {
						input.focus();
						_c = true;
					}
				}
				if (req && (textVal === null || textVal === undefined || textVal === '')){
					var input = component.find("textCommentId");
					if (input.constructor == Array){
						input = input[0];	
					} 
					input.reportValidity();
					if (listIds.indexOf(question.Id) == 0 && !_c) input.focus();
				}
			}
		}
	}
})