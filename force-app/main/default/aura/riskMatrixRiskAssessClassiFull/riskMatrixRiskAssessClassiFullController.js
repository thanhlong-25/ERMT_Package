({
	init : function(component, event, helper) {
		var pageRef = component.get("v.pageReference");
        var id = pageRef.state.c__id;
        if (id) {
            component.set("v.id", id);
        }
	}
})