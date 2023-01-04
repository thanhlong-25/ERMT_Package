({
	doInit : function(component, helper) {
        var checkedIds = component.get("v.checkedIds");
        var recordId = component.get("v.recordId");
        if(checkedIds == null){
          checkedIds = [];
        }
        if(checkedIds.indexOf(recordId) >= 0){
             component.set("v.isChecked", true);
        }
    },
    selectRecord : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        var isChecked = event.getSource().get("v.value");

        var myEvent = $A.get("e.c:CheckboxCheckedEvent");
        myEvent.setParams({"selectedId": recordId, "isChecked": isChecked});
        myEvent.fire();
	}
})