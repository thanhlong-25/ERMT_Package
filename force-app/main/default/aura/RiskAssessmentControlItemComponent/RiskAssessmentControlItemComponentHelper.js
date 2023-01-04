({
    loadSetting : function(component) {
        var action = component.get('c.getRiskAnalysisNewCreateSetting');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var setting = response.getReturnValue();
                component.set('v.probabilityOrderNo', setting.probabilityDispOrder);
                component.set('v.resultImpactOrderNo', setting.resultImpactDispOrder);
                component.set('v.thirdEvaluationOrderNo', setting.thirdEvaluationDispOrder);
            }
        });
		$A.enqueueAction(action);
    }
})