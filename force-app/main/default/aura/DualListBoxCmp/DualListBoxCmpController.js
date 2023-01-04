({
	doInit : function(component, event, helper) {
		helper.getDatas(component);
		helper.getSelectedClassification(component);
	},
	handleChange: function (component, event, helper) {
        helper.insertClassification(component);
    }
    ,
	onClick: function (component, event, helper) {
        var myDiv = event.currentTarget.id;
        console.log(myDiv);
    },
    handleRecordChanged: function(component, event, helper) {
        switch(event.getParams().changeType) {
            case "ERROR":
            break;
            case "LOADED":
            var rName = component.get('v.prjField');
            component.set('v.isDisable', rName.RecordType.DeveloperName == 'GoUnderway');
            var a = component.get('c.doInit');
            $A.enqueueAction(a);
            break;
            case "REMOVED":
            break;
            case "CHANGED":
            break;
        }
    }
})