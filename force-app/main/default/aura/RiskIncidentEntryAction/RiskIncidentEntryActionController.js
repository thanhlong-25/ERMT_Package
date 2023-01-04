({
    handleClose : function(component, event, helper) {
        var isRefresh = event.getParam('isRefresh');
        if (isRefresh) {
            $A.get('e.force:refreshView').fire();
        }
        $A.get("e.force:closeQuickAction").fire();
    },
})