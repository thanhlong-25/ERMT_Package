/**
 * インシデントリスク登録
 */
 import { LightningElement, api, track, wire } from 'lwc';
 import { getObjectInfo } from 'lightning/uiObjectInfoApi';
 import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import INCIDENT_OBJECT from '@salesforce/schema/Incident__c';
 import RISK_OBJECT from '@salesforce/schema/Risk__c';
 import TIME_ZONE from '@salesforce/i18n/timeZone';
 import label_ok from '@salesforce/label/c.Action_Ok';
 import label_cancel from '@salesforce/label/c.Action_Cancel';
 import label_save from '@salesforce/label/c.Action_Save';
 import label_entry from '@salesforce/label/c.Action_Entry';
 import label_delete from '@salesforce/label/c.Action_Delete';
 import label_close from '@salesforce/label/c.Action_Close';
 import label_searchCond from '@salesforce/label/c.Action_SearchCond';
 import label_number from '@salesforce/label/c.List_Number';
 import label_page from '@salesforce/label/c.List_Page';
 import label_first from '@salesforce/label/c.List_First';
 import label_last from '@salesforce/label/c.List_Last';
 import label_next from '@salesforce/label/c.List_Next';
 import label_previous from '@salesforce/label/c.List_Previous';
 import label_all from '@salesforce/label/c.Label_All';
 import label_unregistered from '@salesforce/label/c.Label_Unregistered';
 import label_registered from '@salesforce/label/c.Label_Registered';
 import label_editable from '@salesforce/label/c.Label_Editable';
 import label_riskIncidentEntry from '@salesforce/label/c.RiskIncidentEntry_Entry';
 import label_entryConfirm from '@salesforce/label/c.RiskIncidentEntry_EntryConfirm';
 import label_entryComplete from '@salesforce/label/c.RiskIncidentEntry_EntryComplete';
 import label_deleteConfirm from '@salesforce/label/c.RiskIncidentEntry_DeleteConfirm';
 import label_deleteComplete from '@salesforce/label/c.RiskIncidentEntry_DeleteComplete';
 import label_incidentNewCreate from '@salesforce/label/c.RiskIncidentEntry_IncidentNewCreate';
 import label_incidentNewCreateComplete from '@salesforce/label/c.RiskIncidentEntry_IncidentNewCreateComplete';
 import label_incidentControlEntryComplete from '@salesforce/label/c.RiskIncidentEntry_IncidentControlEntryComplete';
 
 import {
    getErrorMessages,
    getFieldValue,
    TYPE_BOOLEAN,
    TYPE_DATE,
    TYPE_TIME,
    TYPE_DATETIME,
    TYPE_INTEGER,
    TYPE_LONG,
    TYPE_DOUBLE,
    TYPE_CURRENCY,
    TYPE_PERCENT,
    TYPE_PICKLIST,
    TYPE_MULTIPICKLIST,
    TYPE_REFERENCE,
 } from 'c/commonUtil';
 import getRiskIncidentEntrySetting from '@salesforce/apex/RiskIncidentEntryCtlr.getRiskIncidentEntrySetting';
 import getRisk from '@salesforce/apex/RiskIncidentEntryCtlr.getRisk';
 import getIncidentFieldDefines from '@salesforce/apex/RiskIncidentEntryCtlr.getIncidentFieldDefines';
 import getIncidents from '@salesforce/apex/RiskIncidentEntryCtlr.getIncidents';
 import registerRiskIncident from '@salesforce/apex/RiskIncidentEntryCtlr.registerRiskIncident';
 import deleteRiskIncident from '@salesforce/apex/RiskIncidentEntryCtlr.deleteRiskIncident';
 import registerIncidentControl from '@salesforce/apex/RiskIncidentEntryCtlr.registerIncidentControl';
 
 export default class RiskIncidentEntry extends LightningElement {
    timeZone = TIME_ZONE;
    // レコードID
    @api
    get recordId() {
        return this.riskId;
    }
    set recordId(value) {
        this.riskId = value;
        //init data async
        this.refreshRiskAsync();
    }
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中
    cacheMap = new Map(); // キャッシュマップ
    // ラベル情報
    labelInfo = {
        parentObj: this,
        ok: label_ok,
        cancel: label_cancel,
        save: label_save,
        entry: label_entry,
        delete: label_delete,
        close: label_close,
        searchCond: label_searchCond,
        number: label_number,
        page: label_page,
        first: label_first,
        last: label_last,
        next: label_next,
        previous: label_previous,
        riskIncidentEntry: label_riskIncidentEntry,
        incidentNewCreate: label_incidentNewCreate,
        riskNewCreateComplete: label_incidentNewCreateComplete,
        riskIncidentEntryConfirm: label_entryConfirm,
        riskIncidentEntryComplete: label_entryComplete,
        riskIncidentDeleteConfirm: label_deleteConfirm,
        riskIncidentDeleteComplete: label_deleteComplete,
        incidentControlEntryComplete: label_incidentControlEntryComplete
    };
    activeTabValue = 'riskIncidentEntry';
    riskLabel = '';
    riskNameLabel = '';
    incidentTitleLabel = '';
    riskId = null;
    risk = this.createRisk();
    incidentInfo = null;
    incidentSearchCondActiveSections = [];
    incidentObjectName = INCIDENT_OBJECT.objectApiName;
    incidentRecordTypeId = null;
    incidentDisplayFieldNames = [];
    incidentSearchFieldNames = [];
    incidentSelectLimit = 0;
    incidentSearchConds = [];
    incidentSearchCondLogic = null;
    registerType = label_all;
    // 登録種別選択リスト
    registerTypeOptions = [
        { label: label_all, value: label_all },
        { label: label_unregistered, value: label_unregistered },
        { label: label_registered, value: label_registered },
    ];
    incidentFieldDefs = [];
    incidentColumns = [];
    riskSortFieldNameMap = new Map();
    incidentDataRows = [];
    incidentDefaultSortDirection = 'asc'; 
    incidentSortDirection = 'asc'; 
    incidentSortedBy = ''; 
    incidents = []; 
    @track IncidentPageInfo = this.createPageInfo(); 
    entryIncidentIds = []; 
    deleteIncidentIds = []; 
    incidentCreateInfo = null;
    incidentCreateLayout = null;

    // get incident label
    get incidentLabel() {
        return this.incidentInfo?.label || '';
    }

    // リスク先頭ページ有効
    get isRiskFirstPageEnable() {
        return (this.IncidentPageInfo.pageNumber > 2);
    }
 
    // リスク最終ページ有効
    get isRiskLastPageEnable() {
        return (this.IncidentPageInfo.pageNumber < (this.IncidentPageInfo.lastPageNumber - 1));
    }
 
    // リスク次ページ有効
    get isRiskNextPageEnable() {
        return (this.IncidentPageInfo.pageNumber < this.IncidentPageInfo.lastPageNumber);
    }

    // リスク前ページ有効
    get isRiskPreviousPageEnable() {
        return (this.IncidentPageInfo.pageNumber > 1);
    }

    // 登録の無効化フラグ
    get isEntryDisabled() {
        return (this.entryIncidentIds.length === 0);
    }

    // 削除の無効化フラグ
    get isDeleteDisabled() {
        return (this.deleteIncidentIds.length === 0);
    }

    //get risk info
    @wire(getObjectInfo, { objectApiName: RISK_OBJECT })
    wiredRiskInfo({ data, error }) {
        if (data) {
            const { label, fields } = data;
            this.riskLabel = label;
            this.riskNameLabel = fields.Name.label;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }
 
    // get incident info
    @wire(getObjectInfo, { objectApiName: INCIDENT_OBJECT })
    wiredIncidentInfo({ data, error }) {
        if (data) {
            this.incidentInfo = data;

            // レコードタイプIDが変わった場合、リスク作成情報の取得処理が実行される
            const { defaultRecordTypeId = null } = data;
            if (defaultRecordTypeId !== this.incidentRecordTypeId) {
                this.incidentRecordTypeId = defaultRecordTypeId;
                this.incidentCreateInfo = null;
            }

            // リスク作成レイアウトの作成
            // this.incidentCreateLayout = this.createIncidentCreateLayout();
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }
 
    // リスク作成情報の取得
    @wire(getRecordCreateDefaults, {
        objectApiName: INCIDENT_OBJECT,
        recordTypeId: '$incidentRecordTypeId',
    })
    wiredIncidentCreateInfo({ error, data }) {
        if (data) {
            this.incidentCreateInfo = data;

            // リスク作成レイアウトの作成
            // this.incidentCreateLayout = this.createIncidentCreateLayout();
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }
 
    // // 初期化時
    // connectedCallback() {
    //     // データの初期化
    //     this.initDataAsync();
    // }
 
    // タブのアクティブ時
    handleTabActive(event) {
        this.activeTabValue = event.target.value;
    }
 
    // handle incident seach async
    async handleIncidentSearchAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.incidentSearchConds = event.detail.searchConditions;
            this.incidentSearchCondLogic = event.detail.searchConditionLogic;
            // リスクリストの読込み
            await this.loadIncidentsAsync();
            // 検索条件セクションを閉じる
            this.incidentSearchCondActiveSections = [];
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // handle incident search cancel
    handleIncidentSearchCancel() {
        // 検索条件セクションを閉じる
        this.incidentSearchCondActiveSections = [];
    }
 
    // 登録種別の変更時
    async handleRegisterTypeChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.registerType = event.detail.value;
            // リスクリストの読込み
            await this.loadIncidentsAsync();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // ページ移動クリック時
    handleRiskPageMoveClick(event) {
        event.preventDefault();
        const { name } = event.target.dataset;
        switch (name) {
            case 'risk-first-page':
                this.IncidentPageInfo.pageNumber = 1;
                break;
            case 'risk-last-page':
                this.IncidentPageInfo.pageNumber = this.IncidentPageInfo.lastPageNumber;
                break;
            case 'risk-next-page':
                this.IncidentPageInfo.pageNumber++;
                break;
            case 'risk-previous-page':
                this.IncidentPageInfo.pageNumber--;
                break;
        }
        // リスクデータ行リストの読込み
        this.loadIncidentDataRows();
    }
 
    // リスクのソート時
    handleIncidentSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.incidentSortDirection = sortDirection;
        this.incidentSortedBy = fieldName;
        // sort incident
        this.sortIncidents();
        // load incident data rows
        this.loadIncidentDataRows();
    }
 
    // handle incident row selection
    handleIncidentRowSelection(event) {
        // 選択リスクIDの読込み
        const selectedRows = event.detail.selectedRows;
        this.loadSelectIncidentId(selectedRows);
    }
 
    // 登録のクリック時
    handleEntryClick() {
        // 登録確認ダイアログを開く
        this.openEntryConfirmDialog();
    }
 
    // 登録キャンセルのクリック時
    handleEntryCancelClick() {
        // 登録確認ダイアログを閉じる
        this.closeEntryConfirmDialog();
    }
     
    // 登録OKのクリック時
    async handleEntryOkClickAsync() {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            
            // インシデントリスクの登録
            await registerRiskIncident({
                riskId: this.riskId,
                incidentIds: this.entryIncidentIds,
            });

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.riskIncidentEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 登録確認ダイアログを閉じる
            this.closeEntryConfirmDialog();
            
            // リスクリストの読込み
            await this.loadIncidentsAsync(this.IncidentPageInfo.pageNumber);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // 削除のクリック時
    handleDeleteClick() {
        // 削除確認ダイアログを開く
        this.openDeleteConfirmDialog();
    }
 
    // 削除キャンセルのクリック時
    handleDeleteCancelClick() {
        // 削除確認ダイアログを閉じる
        this.closeDeleteConfirmDialog();
    }
 
    // 削除OKのクリック時
    async handleDeleteOkClickAsync() {
        try {
            this.isProcessing = true;
            this.errorMessages = null;

            // インシデントリスクの削除
            await deleteRiskIncident({
                riskId: this.riskId,
                incidentIds: this.deleteIncidentIds,
            });
            
            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.riskIncidentDeleteComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 削除確認ダイアログを閉じる
            this.closeDeleteConfirmDialog();
            
            // リスクリストの読込み
            await this.loadIncidentsAsync(this.IncidentPageInfo.pageNumber);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // リスクの新規の送信時
    handleRiskNewSubmit() {
        this.isProcessing = true;
        this.errorMessages = null;
    }
 
    // リスクの新規の成功時
    async handleIncidentNewSuccessAsync(event) {
        try {
            // 完了メッセージの表示
            let evt = new ShowToastEvent({
                message:  this.labelInfo.riskNewCreateComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // インシデントリスクの登録
            const { id: incidentId } = event.detail;
            await registerRiskIncident({
                riskId: this.riskId,
                incidentIds: [ incidentId ],
            });

            // 完了メッセージの表示
            evt = new ShowToastEvent({
                message: this.labelInfo.riskIncidentEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // リスク対応策の登録
            const result = await registerIncidentControl({
                riskId: this.riskId,
                incidentId: incidentId,
            });

            if (result.registerCount > 0) {
                // 完了メッセージの表示
                evt = new ShowToastEvent({
                    message: this.labelInfo.incidentControlEntryComplete,
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }

            // アクティブタブ値のセット
            this.activeTabValue = 'riskIncidentEntry';
            
            // リスクリストの読込み
            await this.loadIncidentsAsync(this.IncidentPageInfo.pageNumber);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // リスクの新規のエラー時
    handleRiskNewError(event) {
        const { message } = event.detail;
        this.errorMessages = getErrorMessages(message);
        this.isProcessing = false;
    }
 
    // エラーアラートの閉じるのクリック時
    handleErrorAlertCloseClick() {
        this.errorMessages = null;
    }
 
    // 閉じるのクリック時
    handleCloseClick() {
        // クローズの実行
        this.execClose(true);
    }
 
    // データの初期化
    async initDataAsync() {
        try {
            this.errorMessages = null;
            // 設定の読込み
            await this.loadSettingAsync();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }
 
    // 設定の読込み
    async loadSettingAsync() {
        if (this.cacheMap.get('setting_isLoaded')) return;
        // get risk incident entry setting
        const data = await getRiskIncidentEntrySetting();
        const {
            ermt__IncidentSearchFieldNames__c = '',
            ermt__IncidentDisplayFieldNames__c = '',
            ermt__IncidentSelectLimit__c = 2000,
            ermt__IncidentPageSize__c = 30,
        } = data || {};
        this.incidentSearchFieldNames = ermt__IncidentSearchFieldNames__c.split(/\s*,\s*/);
        this.incidentDisplayFieldNames = ermt__IncidentDisplayFieldNames__c.split(/\s*,\s*/);
        this.incidentSelectLimit = ermt__IncidentSelectLimit__c;
        this.IncidentPageInfo.pageSize = ermt__IncidentPageSize__c;
        this.cacheMap.set('setting_isLoaded', true);
    }
 
    // インシデントの最新表示
    async refreshRiskAsync() {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            // load setting async
            await this.loadSettingAsync();
            // load risk async
            await this.loadRiskAsync();
            // load incident's fields define async
            await this.loadIncidentFieldDefinesAsync();
            // load incident async
            await this.loadIncidentsAsync();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }
 
    // load risk async
    async loadRiskAsync() {
        const data = await getRisk({
            riskId: this.riskId
        });
        // create risk
        this.risk = this.createRisk(data || {});

        // リスク作成レイアウトの作成
        this.incidentCreateLayout = this.createIncidentCreateLayout();
    }

    // create Risk
    createRisk ({
        Id = null,
        Name = null,
        ermt__Organization__c = null,
        UserRecordAccess: {
            HasEditAccess = false
        } = {},
    } = {}) {
        return {
            Id,
            Name,
            ermt__Organization__c,
            HasEditAccess
        };
    }
 
    // load incident field define async
    async loadIncidentFieldDefinesAsync() {
        if (this.cacheMap.get('riskFieldDefines_isLoaded')) return;
        // get incident field define
        const data = await getIncidentFieldDefines({
            displayFieldNames: this.incidentDisplayFieldNames
        });
        this.incidentFieldDefs = data;
        // リスク列リストの作成
        const incidentColumns = data.map(fieldDef => this.createColumn(fieldDef));
        incidentColumns.unshift({
            label: label_registered,
            fieldName: 'isRegistered',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        incidentColumns.push({
            label: label_editable,
            fieldName: 'hasEditAccess',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        this.incidentColumns = incidentColumns;
        // create incident sort field name map
        this.riskSortFieldNameMap = this.createIncidentSortFieldNameMap();
        this.cacheMap.set('riskFieldDefines_isLoaded', true);
    }
 
     // create incident sort field name map
    createIncidentSortFieldNameMap() {
        const fieldNameMap = new Map();
        this.incidentFieldDefs.forEach(fieldDef => {
            const {
                fieldName = null,
                parentNameFieldName = null,
                fieldType = null,
            } = fieldDef;
            if (fieldName === 'Name') {
                fieldNameMap.set('riskUrl', 'Name');
            } else {
                switch (fieldType) {
                    case TYPE_REFERENCE:
                        fieldNameMap.set(fieldName, parentNameFieldName);
                        break;
                    default:
                        fieldNameMap.set(fieldName, fieldName);
                        break;
                }
            }
        });
        return fieldNameMap;
    }
 
    // load incidents async
    async loadIncidentsAsync(pageNumber = 1) {
        // リスクリストの取得
        const data = await getIncidents({
            riskId: this.riskId
            , fieldDefs: this.incidentFieldDefs
            , registerType: this.registerType
            , searchConds: this.incidentSearchConds
            , searchCondLogic: this.incidentSearchCondLogic
            , selectLimit: this.incidentSelectLimit
        });
        this.incidents = data;
        this.IncidentPageInfo.resultSize = data.length;
        this.IncidentPageInfo.pageNumber = pageNumber;
        // sort incident
        this.sortIncidents();
        // load incident data rows
        this.loadIncidentDataRows();
        // 選択リスクIDの読込み
        setTimeout(() =>{
            const table = this.template.querySelector('[data-name="incidentTable"]');
            const selectedRows = (table ? table.getSelectedRows() : []);
            this.loadSelectIncidentId(selectedRows);
        }, 0);
    }
 
    // sort incidents
    sortIncidents() {
        // リスクソート項目が有る場合、ソートする
        if (this.incidentSortedBy) {
            const fieldName = this.riskSortFieldNameMap.get(this.incidentSortedBy);
            const reverse = (this.incidentSortDirection === 'asc' ? 1 : -1);
            const incidents = [...this.incidents];
            incidents.sort(this.compareIncident(fieldName, reverse));
            this.incidents = incidents;
        }
    }
 
    // compare incident
    compareIncident(fieldName, reverse) {
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
 
    // load incident data row
    loadIncidentDataRows() {
        const incidentDataRows = [];
        const startIndex = this.IncidentPageInfo.rowNumberOffset;
        let endIndex = startIndex + this.IncidentPageInfo.pageSize - 1;
        endIndex = (endIndex < this.IncidentPageInfo.resultSize ? endIndex : this.IncidentPageInfo.resultSize - 1);
        for (let i = startIndex; i <= endIndex; i++) {
            const incident = this.incidents[i];
            incidentDataRows.push(this.createIncidentDataRow(incident, this.incidentFieldDefs));
        }
        this.incidentDataRows = incidentDataRows;
    }
 
    // 列の作成
    createColumn(fieldDef) {
        const {
            fieldName = null,
            parentNameFieldName = null,
            fieldLabel = null,
            fieldType = null,
        } = fieldDef;
        let column;
        if (fieldName === 'Name') {
            column = {
                label: fieldLabel,
                fieldName: 'riskUrl',
                type: 'url',
                typeAttributes: {
                    label: {
                        fieldName: fieldName,
                    },
                    tooltip: {
                        fieldName: fieldName,
                    },
                    target: '_blank',
                },
                sortable: true,
            };
        } else {
            switch (fieldType) {
                case TYPE_BOOLEAN:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'boolean',
                        cellAttributes: {
                            alignment: 'center'
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_INTEGER:
                case TYPE_LONG:
                case TYPE_DOUBLE:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'number',
                        typeAttributes: {
                            maximumFractionDigits: '4',
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_CURRENCY:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'currency',
                        typeAttributes: {
                            maximumFractionDigits: '4',
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_PERCENT:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'percent',
                        typeAttributes: {
                            maximumFractionDigits: '4',
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_DATE:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'date',
                        typeAttributes: {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit',
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_TIME:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'date',
                        typeAttributes: {
                            hour: '2-digit',
                            minute: '2-digit',
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_DATETIME:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'date',
                        typeAttributes: {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit',
                            hour: '2-digit',
                            minute: '2-digit',
                            hour12: false,
                            timeZone: this.timeZone
                        },
                        sortable: true,
                    };
                    break;
                case TYPE_PICKLIST:
                case TYPE_MULTIPICKLIST:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        sortable: true,
                    };
                    break;
                case TYPE_REFERENCE:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        type: 'url',
                        typeAttributes: {
                            label: {
                                fieldName: parentNameFieldName,
                            },
                            tooltip: {
                                fieldName: parentNameFieldName,
                            },
                            target: '_blank',
                        },
                        sortable: true,
                    };
                    break;
                default:
                    column = {
                        label: fieldLabel,
                        fieldName: fieldName,
                        sortable: true,
                    };
                    break;
            }
        }
        return column;
    }
 
    //create incident data row
    createIncidentDataRow(record, fieldDefs) {
        const newRec = {
            key: record.Id,
            riskUrl: '/' + record.Id,
            hasEditAccess: this.risk.HasEditAccess && record.UserRecordAccess.HasEditAccess,
            isRegistered: !!(record.ermt__Incident_Risk_Juncs__r?.length),
        };
        fieldDefs.forEach(fieldDef => {
            const { fieldName, parentNameFieldName, fieldType } = fieldDef;
            let fieldValue = getFieldValue(record, fieldName);
            if (fieldValue !== null) {
                switch (fieldType) {
                    case TYPE_PERCENT:
                        fieldValue = fieldValue / 100;
                        break
                    case TYPE_REFERENCE:
                        fieldValue = '/' + fieldValue
                        break;
                }
            }
            newRec[fieldName] = fieldValue;
            if (parentNameFieldName) {
                const parentNameFieldValue = getFieldValue(record, parentNameFieldName);
                newRec[parentNameFieldName] = parentNameFieldValue;
            }
        });
        return newRec;
    }
 
    // ページ情報の作成
    createPageInfo(pageInfo = {}) {
        const newPageInfo = Object.assign({
            pageSize: 10,
            resultSize: 0,
            pageNumber: 1,
            get lastPageNumber() {
                return Math.ceil(this.resultSize / this.pageSize) || 1;
            },
            get rowNumberOffset() {
                return (this.pageNumber - 1) * this.pageSize;
            }
        }, pageInfo);
        return newPageInfo;
    }
 
    // load select incident id
    loadSelectIncidentId(selectedRows) {
        let entryIncidentIds = [];
        let deleteIncidentIds = [];
        for (let i = 0, len = selectedRows.length; i < len; i++) {
            const row = selectedRows[i];
            if (row.hasEditAccess) {
                if (row.isRegistered) {
                    deleteIncidentIds.push(row.key);
                } else {
                    entryIncidentIds.push(row.key);
                }
            }
        }
        // 登録分と削除分のリスクの選択が有る場合、登録、削除できないようにする
        if (entryIncidentIds.length > 0 && deleteIncidentIds.length > 0) {
            entryIncidentIds = [];
            deleteIncidentIds = [];
        }
        this.entryIncidentIds = entryIncidentIds;
        this.deleteIncidentIds = deleteIncidentIds;
    }
 
    // create incident create layout
    createIncidentCreateLayout() {
        let layout = null;
        if (this.incidentInfo && this.incidentCreateInfo && this.risk.Id) {
            const {
                record: {
                    fields = {}
                } = {}
            } = this.incidentCreateInfo;
            layout = [];
            this.incidentCreateInfo.layout.sections.forEach(s => {
                const section = {
                    heading: s.useHeading ? s.heading : '',
                    columnClass: 'slds-col slds-size_1-of-' + s.columns,
                    rows: [],
                };
                layout.push(section);
                s.layoutRows.forEach(lr => {
                    const row = {
                        items: [],
                    };
                    section.rows.push(row);
                    lr.layoutItems.forEach(li => {
                        li.layoutComponents.forEach(lc => {
                            const item = {
                                name: lc.apiName,
                                value: null,
                                required: li.required,
                                disabled: !li.editableForNew,
                                class: (s.columns === 1 ? 'slds-form-element_1-col' : ''),
                            };
                            
                            

                            // デフォルト値のセット
                            if (item.name) {
                                if (item.name === 'ermt__IssueDate__c') {
                                    item.class = 'slds-m-top_custom';
                                }
                                // レコードタイプID
                                if (item.name === 'RecordTypeId') {
                                    item.value = this.incidentRecordTypeId;
                                // 組織・部門
                                } else if (item.name === 'ermt__Organization__c') {
                                    item.value = this.risk.ermt__Organization__c;
                                } else {
                                    // 設定のデフォルト値
                                    if (item.name in fields) {
                                        item.value = fields[item.name].value;
                                    }
                                }
                            }
                            row.items.push(item);
                        });
                    });
                });
            });
        }
        return layout;
    }
 
    // 登録確認ダイアログを開く
    openEntryConfirmDialog() {
        const dialog = this.template.querySelector('[data-name="entry-confirm-dialog"]');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }
 
    // 登録確認ダイアログを閉じる
    closeEntryConfirmDialog() {
        const dialog = this.template.querySelector('[data-name="entry-confirm-dialog"]');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }
 
    // 削除確認ダイアログを開く
    openDeleteConfirmDialog() {
        const dialog = this.template.querySelector('[data-name="delete-confirm-dialog"]');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }
 
    // 削除確認ダイアログを閉じる
    closeDeleteConfirmDialog() {
        const dialog = this.template.querySelector('[data-name="delete-confirm-dialog"]');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }
 
    // クローズの実行
    execClose(isRefresh) {
        // クローズイベントの送信
        const event = new CustomEvent('close', {
            detail: { isRefresh: isRefresh }
        });
        this.dispatchEvent(event);
    }
 }