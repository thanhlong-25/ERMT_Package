import { LightningElement, api, track } from 'lwc';
import { getErrorMessages, getFieldValue } from 'c/commonUtil';
import getNormalObjectHistoryLog from '@salesforce/apex/ERMT_HistoryLogController.getNormalObjectHistoryLog';
import getJunctionObjectHistoryLog from '@salesforce/apex/ERMT_HistoryLogController.getJunctionObjectHistoryLog';
import getColumnLabel from '@salesforce/apex/ERMT_HistoryLogController.getColumnLabel';
import getHistoryTypeMap from '@salesforce/apex/ERMT_HistoryLogController.getHistoryTypeMap';
import getObjectLabel from '@salesforce/apex/ERMT_HistoryLogController.getObjectLabel';

/** OBJECT SCHEMA */
//import fields of History__c
import RECORD_ID from '@salesforce/schema/History__c.RecordId__c';
import RECORD_NAME_OBJECT_LOG from '@salesforce/schema/History__c.RecordNameObjectLog__c';
import PARENT_RECORD_ID_1 from '@salesforce/schema/History__c.ParentRecordId1__c';
import PARENT_RECORD_ID_2 from '@salesforce/schema/History__c.ParentRecordId2__c';
import PARENT_RECORD_NAME_1 from '@salesforce/schema/History__c.ParentRecordName1__c';
import PARENT_RECORD_NAME_2 from '@salesforce/schema/History__c.ParentRecordName2__c';
import Id from '@salesforce/schema/History__c.Id';

//import SObjects
import RISK_OBJECT from '@salesforce/schema/Risk__c';
import INCIDENT_OBJECT from '@salesforce/schema/Incident__c';
import CONTROL_OBJECT from '@salesforce/schema/Control__c';
import INCIDENT_RISK_JUNC_OBJECT from '@salesforce/schema/Incident_Risk_Junc__c';
import INCIDENT_CONTROL_JUNC_OBJECT from '@salesforce/schema/Incident_Control_Junc__c';
import RISK_CONTROL_JUNC_OBJECT from '@salesforce/schema/Risk_Control_Junc__c';

/** CUSTOM LABEL */
import history_log_title from '@salesforce/label/c.History_Log_Title';

// static variables
const historyLogType = {
    UPDATE_TYPE_LOG: '変更'
    , INSERT_TYPE_LOG: '追加'
    , DELETE_TYPE_LOG: '削除'
};
const objectsApiName = {
    riskObjectApiName: RISK_OBJECT.objectApiName,
    incidentObjectApiName: INCIDENT_OBJECT.objectApiName,
    controlObjectApiName: CONTROL_OBJECT.objectApiName,
    incRiskJuncObjectApiName: INCIDENT_RISK_JUNC_OBJECT.objectApiName,
    incControlJuncObjectApiName: INCIDENT_CONTROL_JUNC_OBJECT.objectApiName,
    riskConJuncObjectApiName: RISK_CONTROL_JUNC_OBJECT.objectApiName,
};
const apiFieldNamesOfHistory = {
    recordIdApiName: RECORD_ID.fieldApiName,
    recordNameObjectLogApiName: RECORD_NAME_OBJECT_LOG.fieldApiName,
    parentRecordId1ApiName: PARENT_RECORD_ID_1.fieldApiName,
    parentRecordId2ApiName: PARENT_RECORD_ID_2.fieldApiName,
    parentRecordName1ApiName: PARENT_RECORD_NAME_1.fieldApiName,
    parentRecordName2ApiName: PARENT_RECORD_NAME_2.fieldApiName,
    idApiName: Id.fieldApiName
};
const junctionObjectList = [
    objectsApiName.incRiskJuncObjectApiName,
    objectsApiName.incControlJuncObjectApiName,
    objectsApiName.riskConJuncObjectApiName
    //'ermt__Risk_Classification_Junc__c'
];

export default class HistoryLog extends LightningElement {
    // api variables
    @api recordId;
    @api objectApiName;
    @api objectHistoryLog;
    @api listview;

    // datatable variables
    @track data = [];
    columns = [
        { label: '種別', fieldName: 'ermt__Type__c', type: 'text', hideDefaultActions: true, initialWidth: 80 },
        { label: '項目名', fieldName: 'ermt__FieldName__c', type: 'text', hideDefaultActions: true },
        { label: '前の値', fieldName: 'ermt__OldValue__c', type: 'text', hideDefaultActions: true },
        { label: '後の値', fieldName: 'ermt__NewValue__c', type: 'text', hideDefaultActions: true },
        { label: 'ユーザ', fieldName: 'OwnerId', type: 'url', hideDefaultActions: true, initialWidth: 150
            , typeAttributes: {
                label: { fieldName: 'OwnerName' }
                , tooltip: { fieldName: 'OwnerName'}
                , target: '_blank'
            }
        },
        { label: '変更日時', fieldName: 'CreatedDate', type: 'date', hideDefaultActions: true, initialWidth: 150
            , typeAttributes:{
                day: '2-digit'
                , month: '2-digit'
                , year: 'numeric'
                , hour: '2-digit'
                , minute: '2-digit'
                , hour12: false
            }
        }
    ];

    // util variables
    errorMessages = null;
    remainingJuncObjectName = null;
    @track historyTypeMap = {};
    objectLabelName = null;

    // get - set method
    get historyLogTitle(){
        return this.objectLabelName + history_log_title;
    }

    async connectedCallback(){
        await this.getHistoryTypeMap();
        if(junctionObjectList.includes(this.objectHistoryLog)){
            this.getJunctionObjectHistoryLog();
        } else {
            this.getNormalObjectHistoryLog();
        }
    }

    /** APEX METHOD CALL */
    // Get history log when objectHistoryLog is Normal Object
    async getNormalObjectHistoryLog(){
        try {
            await this.getObjectLabel();
            let historyLogs = await getNormalObjectHistoryLog({
                    objectHistoryLog: this.objectHistoryLog
                    , recordId: this.recordId
                });

            this.data = historyLogs.map(element => {
                return {
                    ...element
                    , OwnerId: '/' + element.OwnerId
                    , OwnerName: element.Owner.Name,
                    ermt__RecordId__c: '/' + element.ermt__RecordId__c
                };
            })
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // Get history log when objectHistoryLog is Junction Object
    async getJunctionObjectHistoryLog(){
        try {
            let orderParent = this.getOrderParentFromJunctionObject();
            await this.getObjectLabel();
            let historyLogs = await getJunctionObjectHistoryLog({
                recordId: this.recordId
                , objectApiName: this.objectApiName
                , objectHistoryLog: this.objectHistoryLog
                , remainingJuncObjectName: this.remainingJuncObjectName
                , orderParent: orderParent
            });
            //map data
            let data = historyLogs.map(element => {
                let type = element.ermt__Type__c;
                let objectLog = element.ermt__ObjectLog__c;
                let parentName1 = element.ermt__ParentRecordName1__c;
                let parentName2 = element.ermt__ParentRecordName2__c;
                let recordId = element.ermt__RecordId__c;
                let recordNameObjectLog = element.ermt__RecordNameObjectLog__c;

                if(!junctionObjectList.includes(objectLog)){
                    //In record page Incident__c
                    if (this.objectApiName == objectsApiName.incidentObjectApiName) {
                        element.ermt__ParentRecordId2__c =  '/' + recordId;
                        element.ermt__ParentRecordName2__c = recordNameObjectLog;
                    } else if (this.objectApiName == objectsApiName.riskObjectApiName) {
                        //In record page Risk__c
                        if (this.objectHistoryLog == objectsApiName.incRiskJuncObjectApiName) {
                            element.ermt__ParentRecordId1__c =  '/' + recordId;
                            element.ermt__ParentRecordName1__c = recordNameObjectLog;
                        } else {
                            element.ermt__ParentRecordId2__c =  '/' + recordId;
                            element.ermt__ParentRecordName2__c = recordNameObjectLog;
                        }
                    } else {
                        element.ermt__ParentRecordId1__c =  '/' + recordId;
                        element.ermt__ParentRecordName1__c = recordNameObjectLog;
                    }
                    return {
                            ...element
                            , ermt__Type__c: this.historyTypeMap[type]
                            , OwnerId: '/' + element.OwnerId
                            , OwnerName: element.Owner.Name
                    };
                } else {
                    return {
                        ...element
                        , ermt__Type__c: this.historyTypeMap[type]
                        , ermt__FieldName__c: this.objectLabelName
                        , ermt__OldValue__c: (type == historyLogType.DELETE_TYPE_LOG) ? (orderParent == 1 ? parentName2 : parentName1) : null
                        , ermt__NewValue__c: (type == historyLogType.INSERT_TYPE_LOG) ? (orderParent == 1 ? parentName2 : parentName1) : null
                        , OwnerId: '/' + element.OwnerId
                        , OwnerName: element.Owner.Name
                        , ermt__ParentRecordId1__c: '/' + element.ermt__ParentRecordId1__c
                        , ermt__ParentRecordId2__c: '/' + element.ermt__ParentRecordId2__c
                    };
                }
            })
            //sort data order by created date desc
            // this.data = data;
            this.data = this.sortData(data);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    async getColumnLabel(){
        try {
            const columnLabel = await getColumnLabel();
            //Check record page name to add column
            this.checkRecordPageObjectName();
            this.columns = this.columns.map(element => {
                
                return {
                    ...element,
                    label: (element.fieldName == apiFieldNamesOfHistory.parentRecordId1ApiName || element.fieldName == apiFieldNamesOfHistory.parentRecordId2ApiName || element.fieldName == apiFieldNamesOfHistory.recordIdApiName) ? this.objectLabelName : columnLabel[element.fieldName]
                };
            })
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    async getHistoryTypeMap(){
        try {
            const historyType = await getHistoryTypeMap();
            this.historyTypeMap = historyType;
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    async getObjectLabel(){
        try {
            let objectName = (this.remainingJuncObjectName) ? this.remainingJuncObjectName : this.objectApiName
            const titleList = await getObjectLabel({objectApiName : objectName});
            this.objectLabelName = titleList;
            await this.getColumnLabel();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    /** UTIL METHOD */
    //Check record page Object name to add column. That will display link to record page detail
    checkRecordPageObjectName() {
        let objectApiName = this.objectApiName;
        if (objectApiName == this.objectHistoryLog) {
            this.columns = this.addColumn(apiFieldNamesOfHistory.recordIdApiName);
        } else {
            switch (objectApiName) {
                //In record page ermt__Incident__c
                case objectsApiName.incidentObjectApiName:
                    this.columns = this.addColumn(apiFieldNamesOfHistory.parentRecordId2ApiName); //display link to record page detail ermt__Risk__c or ermt__Control__c
                    break;
                //In record page ermt__Risk__c
                case objectsApiName.riskObjectApiName:
                    if (this.objectHistoryLog == objectsApiName.incRiskJuncObjectApiName) {
                        this.columns = this.addColumn(apiFieldNamesOfHistory.parentRecordId1ApiName); //display link to record page detail ermt__Incident__c
                    } else if (this.objectHistoryLog == objectsApiName.riskConJuncObjectApiName) {
                        this.columns = this.addColumn(apiFieldNamesOfHistory.parentRecordId2ApiName); //display link to record page detail ermt__Control__c
                    }
                    break;
                //In record page ermt__Control__c
                case objectsApiName.controlObjectApiName:
                    this.columns = this.addColumn(apiFieldNamesOfHistory.parentRecordId1ApiName); //display link to record page detail ermt__Risk__c or ermt__Incident__c
                    break;
                default:
                    break;
            }
        }
    }
    //Add column to display label link to record page detail
    addColumn(columnToAdd) {
        let columns = this.columns;
        let labelName = '';
        switch (columnToAdd) {
            case apiFieldNamesOfHistory.recordIdApiName:
                labelName = apiFieldNamesOfHistory.recordNameObjectLogApiName;
                break;
            case apiFieldNamesOfHistory.parentRecordId1ApiName:
                labelName = apiFieldNamesOfHistory.parentRecordName1ApiName;
                break;
            case apiFieldNamesOfHistory.parentRecordId2ApiName:
                labelName = apiFieldNamesOfHistory.parentRecordName2ApiName;
                break;
            default:
                break;
        }
        let column = { label: 'Record Name', fieldName: columnToAdd, type: 'url', hideDefaultActions: true, initialWidth: 150
            , typeAttributes: {
                label: { fieldName: labelName }
                , tooltip: { fieldName: labelName}
                , target: '_blank'
            }
        }
        columns.splice(5, 0, column); //add Column to column list
        return columns;
    }

    //sort data
    sortData(data) {
        const reverse = -1;
        const histories = [...data];
        histories.sort(this.compareData(apiFieldNamesOfHistory.idApiName, reverse));
        return histories;
    }

    //compare data
    compareData(fieldName, reverse) {
        return ((rec1, rec2) => {
            const value1 = getFieldValue(rec1, fieldName);
            const value2 = getFieldValue(rec2, fieldName);
            let result = 0;
            if (value1 === null) {
                if (value2 !== null) {
                    result = -1;
                }
            } else {
                if (value2 === null) {
                    result = 1;
                } else {
                    if (value1 < value2) {
                        result = -1;
                    } else if (value2 < value1) {
                        result = 1;
                    }
                }
            }
            result *= reverse;
            return result;
        });
    }

    getOrderParentFromJunctionObject(){
        let objectJuncList = this.objectHistoryLog.split("_").slice(2,4);
        let objectName = this.objectApiName.split("__").slice(1,2).toString();
        let objectNameIdx = objectJuncList.indexOf(objectName);
        this.remainingJuncObjectName = (objectNameIdx == 0) ? objectJuncList[1] : objectJuncList[0];
        this.remainingJuncObjectName = 'ermt__' + this.remainingJuncObjectName + '__c'; 

        // example this.objectHistoryLog = ermt__Incident_Risk_Junc__c and this.objectApiName = ermt__Risk__c
        // objectJuncList = ['Incident', 'Risk'];
        // objectName = 'Risk';
        // objectNameIdx = 1
        // remainingJuncObjectName = ermt__Incident__c

        return objectNameIdx + 1;
    }

    // Handle close alert error message
    handleErrorAlertCloseClick() {
        this.errorMessages = null;
    }
}