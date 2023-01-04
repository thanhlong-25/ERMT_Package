({
    doInit : function(component, helper) {
        var record = component.get('v.record');
        var field = component.get('v.field');
        // console.log(record);
        // console.log(field);
        var outputText = component.find("outputTextId");
        // if (field.indexOf(".") >= 0) {
        //     var ParentSobject = record[field.split(".")[0]];
        //     if(ParentSobject != undefined){
        //         outputText.set("v.value",ParentSobject[field.split(".")[1]]);
        //     }
        // }
        // else{
        //     outputText.set("v.value",record[field]);
        // }
        outputText.set("v.value",field.split('.').reduce(function(a, b) {return a[b];}, record));
    }
})