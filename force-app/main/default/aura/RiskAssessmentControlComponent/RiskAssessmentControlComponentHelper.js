({
	getEvaluations : function(cmp) {
		var action = cmp.get("c.getClassificationEvaluations");
		var riskId = cmp.get("v.recordId");
      	action.setParams({
			'riskId': riskId
      	});
      	action.setCallback(this, function(a) {
			var result = a.getReturnValue();
         	if(result){
				if (result.length > 0){
					var listEvaluations = [];
					var Ids = "";
					for (var i in result){
						if (Ids.indexOf(result[i].ermt__M_Classification__c) < 0){
							listEvaluations.push({
								'classId': result[i].ermt__M_Classification__c,
								'label': result[i].ermt__M_Classification__r.ermt__Label_Pick__c ? result[i].ermt__M_Classification__r.ermt__Label_Pick__c : result[i].ermt__M_Classification__r.ermt__Label__c,
							});
							Ids = Ids + ',' + result[i].ermt__M_Classification__c;
						}
					}
					for (var i in listEvaluations){
						var childs = [];
						var child1s = [];
						var child2s = [];
						var child3s = [];
						for (var j in result) {
							if (result[j].ermt__M_Classification__c === listEvaluations[i].classId) {
								if (result[j].ermt__RiskAssessment__r.ermt__Current_Valuation__c){
									child1s.push({
										'assessId': result[j].ermt__RiskAssessment__c,
										'currentValuation': result[j].ermt__RiskAssessment__r.ermt__Current_Valuation__c,
										'isActive': result[j].ermt__RiskAssessment__r.ermt__isActive__c,
									});
								} else if (result[j].ermt__RiskAssessment__r.ermt__isActive__c){
									child2s.push({
										'assessId': result[j].ermt__RiskAssessment__c,
										'currentValuation': result[j].ermt__RiskAssessment__r.ermt__Current_Valuation__c,
										'isActive': result[j].ermt__RiskAssessment__r.ermt__isActive__c,
									});
								} else {
									child3s.push({
										'assessId': result[j].ermt__RiskAssessment__c,
										'currentValuation': result[j].ermt__RiskAssessment__r.ermt__Current_Valuation__c,
										'isActive': result[j].ermt__RiskAssessment__r.ermt__isActive__c,
									});
								}
							}
						}
						if (child1s.length > 0) childs.push.apply(childs, child1s);
						if (child2s.length > 0) childs.push.apply(childs, child2s);
						if (child3s.length > 0) childs.push.apply(childs, child3s);
						listEvaluations[i].childs = childs;
					}
					// check permission
					var action = cmp.get("c.checkEditPermission");
					action.setCallback(this, function(a) {
						var result = a.getReturnValue();
						cmp.set("v.hasEditPermission", result);
						cmp.set("v.listEvaluations", listEvaluations);
						cmp.set("v.currentTab", listEvaluations[listEvaluations.length - 1].label);
					});
					$A.enqueueAction(action);
				}
         	}
      	});
      	$A.enqueueAction(action);
	},
	// 確定の使用可否の読込み
	loadCanConfirm : function(cmp) {
		var action = cmp.get("c.checkCanConfirm");
		action.setCallback(this, function(a) {
			var result = a.getReturnValue();
			cmp.set("v.canConfirm", result);
		});
		$A.enqueueAction(action);
	},
	// コピーの使用可否の読込み
	loadCanCopy : function(cmp) {
		var action = cmp.get("c.checkCanCopy");
		action.setCallback(this, function(a) {
			var result = a.getReturnValue();
			cmp.set("v.canCopy", result);
		});
		$A.enqueueAction(action);
	},
})