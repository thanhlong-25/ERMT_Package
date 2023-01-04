({
    doInit : function(component, event, helper) {
        //Clone quantity and set to displaySize to prevent change quantity will affect all instance of RiskAssessmentPanelComponentController
        var quantity = component.get("v.quantity");
        component.set("v.displaySize",quantity);
        var displaySize = component.get("v.displaySize");
        var showFields = component.get("v.showFields");
        component.set("v.isShowViewAll",showFields.length > displaySize);
        component.set("v.isShowHide", displaySize > showFields.length);
        helper.getFieldsFromLayout(component);
    },
    showAllField : function(component, event, helper) {
        var showFields = component.get("v.showFields");

        component.set("v.displaySize",showFields.length);
        component.set("v.isShowViewAll",showFields.length > component.get("v.displaySize"));
        component.set("v.isShowHide", !component.get("v.isShowViewAll"));
    },
    gotoDetail : function(component, event, helper) {
        var fieldName = event.currentTarget.dataset.fieldname;
        fieldName = fieldName.substr(0, fieldName.lastIndexOf("."));
        fieldName += '.Id';
        var record = component.get("v.record");
        var value = fieldName.split('.').reduce(function(a, b) { return a[b];}, record);
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+value 
        }).fire();
    },
    hideField : function(component, event, helper) {
        var quantity = component.get("v.quantity");
        var showFields = component.get("v.showFields");

        component.set("v.displaySize",quantity);
        component.set("v.isShowViewAll",showFields.length > component.get("v.displaySize"));
        component.set("v.isShowHide", !component.get("v.isShowViewAll"));
    },
    editRecord : function(component, event, helper) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": component.get("v.record.Id")
        });
        editRecordEvent.fire();
    },
    newRecord : function(component, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord")           
        createRecordEvent.setParams({
            "entityApiName": "ermt__RiskAssessment__c",
            "defaultFieldValues":{
              "ermt__Risk__c": component.get("v.record.ermt__Risk__c"),
              "RecordTypeId": component.get("v.newRecordRecordTypeId"),
              "ermt__beforeAssessment__c": component.get("v.record.Id"),
              "ermt__SeverityRiskLevel__c": component.get("v.record.ermt__SeverityRiskLevel__c"),
              "ermt__RiskClassification__c": component.get("v.record.ermt__RiskClassification__c"),
              "ermt__Likelihood__c": component.get("v.record.ermt__Likelihood__c"),
              "ermt__AssumedCost__c": component.get("v.record.ermt__AssumedCost__c"),
              "ermt__Consequence__c": component.get("v.record.ermt__Consequence__c"),
              "ermt__RemainingRisk_DerivativeRisk__c": component.get("v.record.ermt__RemainingRisk_DerivativeRisk__c"),
              "ermt__AnalysisCurrentAnalysis__c": component.get("v.record.ermt__AnalysisCurrentAnalysis__c"),
              "ermt__RiskAnalysis__c": component.get("v.record.ermt__RiskAnalysis__c")
          }
      });
        createRecordEvent.fire();
          // var modalBody;
          // $A.createComponent("c:NewRiskAssessmentComp", { "recordTypeId": "0126F000001BukEQAS","recordViewId":component.get("v.record.Id")},
          //   function(content, status) {
          //       if (status === "SUCCESS") {
          //           modalBody = content;
          //           component.find('overlayLib').showCustomModal({
          //               header: "New ３．評価",
          //               body: modalBody, 
          //               showCloseButton: true,
          //               cssClass: "mymodal",
          //               closeCallback: function() {
          //               }
          //           })
          //       }                               
          //   });
    },
    enableRecord: function(component, event, helper) {
        component.set("v.riskAssess.ermt__isActive__c", true);
        component.find("recordUpdater").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                component.set("v.isActive", true);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + 
                 JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    waiting: function(component, event, helper) {
        component.set("v.hideSpinner", true);
    },
    doneWaiting: function(component, event, helper) {
        component.set("v.hideSpinner", false);
    },
    recordUpdated : function(component, event, helper) {
        var changeType = event.getParams().changeType;
        if (changeType === "LOADED"){
            component.set("v.isActive", component.get("v.riskAssess.ermt__isActive__c"));
        }
    },
    hideNewPopup: function(component, event, helper) {
      component.set("v.showModule", false);
    },
    showNewPopup: function(component, event, helper) {
      component.set("v.showModule", true);
    },
    handleLoad: function(component, event, helper) {
      component.find('rTypeField').set('v.value', component.get("v.newRecordRecordTypeId"));
      for(var i = 0;i<component.find("preField").length;i++){
        var item = component.find("preField")[i];
        var str="";
        if(item.get("v.fieldName") == "ermt__beforeAssessment__c"){
          str = "v.record.Id";
        }else{
          str = "v.record."+item.get("v.fieldName");
        }
        component.find("preField")[i].set("v.value",component.get(str));
      }
    },
    handleSave: function(component, event, helper) {
      if(!component.get("v.newRAssessIdAfterSuccess"))
           component.find('newRiskForm').submit();
    },
    handleSuccess: function(component, event, helper) {
      var payload = event.getParams().response;
      console.log(payload.id);
      component.set("v.newRAssessIdAfterSuccess",payload.id);
      var objCompA = component.find('cmpEva');
      if(objCompA)
        objCompA.sampleMethod(payload.id);

      var objCompB = component.find('cmpLike');
      if(objCompB)
        objCompB.sampleMethod(payload.id);
      
      var objCompC = component.find('cmpCons');
      if(objCompC)
        objCompC.sampleMethod(payload.id);
      
      var objCompD = component.find('cmpSever');
      if(objCompD)
        objCompD.sampleMethod(payload.id);

      var p = component.get("v.parent");
      p.reloadParentId();
    }
})