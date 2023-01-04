({
	doInit: function (component, event, helper) {
        component.set('v.gridColumns', [
            {label: 'Account Name', fieldName: 'Name', type: 'text'},
            {label: 'Type', fieldName: 'Type', type: 'text'},
            ]);
        helper.getAcctChilds(component);
        helper.getSelectedProjectAccount(component);
    },
    handleSelect: function (component, event, helper) {
        if(!component.get('v.isDisable')){
            var selectedRows = event.getParam('selectedRows');
            var selectedIds = [];
            for (var i = 0; i < selectedRows.length; i++){
                selectedIds.push(selectedRows[i].Id);
            } 
            component.set('v.gridSelectedRows', selectedIds);
            helper.insertProjectAccount(component,selectedIds);
        }
        else{
            component.set('v.gridSelectedRows', component.get('v.gridSelectedRows'));
        }
    },
    handleRowToggle: function(component, event, helper) {
        //Fix bug when toggle, selected row become unselected row
        // console.log(component.find('mytree').get('v.selectedRows'));
        // component.set('v.gridSelectedRows', component.get('v.gridSelectedRows'));
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