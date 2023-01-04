/**
 * インシデント対応策登録
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import INCIDENT_OBJECT from '@salesforce/schema/Incident__c';
import CONTROL_OBJECT from '@salesforce/schema/Control__c';
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
import label_incidentControlEntry from '@salesforce/label/c.IncidentControlEntry_Entry';
import label_entryConfirm from '@salesforce/label/c.IncidentControlEntry_EntryConfirm';
import label_entryComplete from '@salesforce/label/c.IncidentControlEntry_EntryComplete';
import label_deleteConfirm from '@salesforce/label/c.IncidentControlEntry_DeleteConfirm';
import label_deleteComplete from '@salesforce/label/c.IncidentControlEntry_DeleteComplete';
import label_controlNewCreate from '@salesforce/label/c.IncidentControlEntry_ControlNewCreate';
import label_controlNewCreateComplete from '@salesforce/label/c.IncidentControlEntry_ControlNewCreateComplete';

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
import getIncidentControlEntrySetting from '@salesforce/apex/IncidentControlEntryCtlr.getIncidentControlEntrySetting';
import getIncident from '@salesforce/apex/IncidentControlEntryCtlr.getIncident';
import getControlFieldDefines from '@salesforce/apex/IncidentControlEntryCtlr.getControlFieldDefines';
import getControls from '@salesforce/apex/IncidentControlEntryCtlr.getControls';
import registerIncidentControl from '@salesforce/apex/IncidentControlEntryCtlr.registerIncidentControl';
import deleteIncidentControl from '@salesforce/apex/IncidentControlEntryCtlr.deleteIncidentControl';

export default class IncidentControlEntry extends LightningElement {
    // レコードID
    @api
    get recordId() {
        return this.incidentId;
    }
    set recordId(value) {
        this.incidentId = value;
        // インシデントの最新表示
        this.refreshIncidentAsync();
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
        incidentControlEntry: label_incidentControlEntry,
        controlNewCreate: label_controlNewCreate,
        controlNewCreateComplete: label_controlNewCreateComplete,
        incidentControlEntryConfirm: label_entryConfirm,
        incidentControlEntryComplete: label_entryComplete,
        incidentControlDeleteConfirm: label_deleteConfirm,
        incidentControlDeleteComplete: label_deleteComplete,
    };
    activeTabValue = 'incidentControlEntry'; // アクティブタブ値
    incidentLabel = ''; // インシデント表示ラベル
    incidentNameLabel = ''; // インシデント名表示ラベル
    incidentTitleLabel = ''; // インシデントタイトル表示ラベル
    incidentId = null; // インシデントID
    incident = this.createIncident(); // インシデントレコード
    @track controlInfo = null; // 対応策情報
    // 対応策表示ラベル
    get controlLabel() {
        return this.controlInfo?.label || '';
    }
    controlSearchCondActiveSections = []; // 対応策検索条件アクティブセクションリスト
    controlObjectName = CONTROL_OBJECT.objectApiName; // 対応策オブジェクト名
    controlRecordTypeId = null; // 対応策レコードタイプID
    controlDisplayFieldNames = []; // 対応策表示項目名リスト
    controlSearchFieldNames = []; // 対応策検索項目名リスト
    controlSelectLimit = 0; // 対応策レコード取得限度数
    controlSearchConds = []; // 対応策検索条件リスト
    controlSearchCondLogic = null; // 対応策検索条件ロジック
    registerType = label_all; // 登録種別
    // 登録種別選択リスト
    registerTypeOptions = [
        { label: label_all, value: label_all },
        { label: label_unregistered, value: label_unregistered },
        { label: label_registered, value: label_registered },
    ];
    controlFieldDefs = []; // 対応策項目定義リスト
    controlColumns = []; // 対応策列リスト
    controlSortFieldNameMap = new Map(); // 対応策ソート項目名マップ
    controlDataRows = []; // 対応策データ行リスト
    controlDefaultSortDirection = 'asc'; // 対応策デフォルトソート方向
    controlSortDirection = 'asc'; // 対応策ソート方向
    controlSortedBy = ''; // 対応策ソート項目
    controls = []; // 対応策リスト
    @track controlPageInfo = this.createPageInfo(); // 対応策ページ情報
    entryControlIds = []; // 登録対応策IDリスト
    deleteControlIds = []; // 削除対応策IDリスト
    controlCreateInfo = null; // 対応策作成情報
    controlCreateLayout = null; // 対応策作成レイアウト

    // 対応策先頭ページ有効
    get isControlFirstPageEnable() {
        return (this.controlPageInfo.pageNumber > 2);
    }

    // 対応策最終ページ有効
    get isControlLastPageEnable() {
        return (this.controlPageInfo.pageNumber < (this.controlPageInfo.lastPageNumber - 1));
    }

    // 対応策次ページ有効
    get isControlNextPageEnable() {
        return (this.controlPageInfo.pageNumber < this.controlPageInfo.lastPageNumber);
    }

    // 対応策前ページ有効
    get isControlPreviousPageEnable() {
        return (this.controlPageInfo.pageNumber > 1);
    }

    // 登録の無効化フラグ
    get isEntryDisabled() {
        return (this.entryControlIds.length === 0);
    }

    // 削除の無効化フラグ
    get isDeleteDisabled() {
        return (this.deleteControlIds.length === 0);
    }

    // インシデント情報の取得
    @wire(getObjectInfo, { objectApiName: INCIDENT_OBJECT })
    wiredIncidentInfo({ data, error }) {
        if (data) {
            //console.log('incidentInfo=' + JSON.stringify(data));
            const { label, fields } = data;
            this.incidentLabel = label;
            this.incidentNameLabel = fields.Name.label;
            this.incidentTitleLabel = fields.ermt__Title__c.label;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 対応策情報の取得
    @wire(getObjectInfo, { objectApiName: CONTROL_OBJECT })
    wiredControlInfo({ data, error }) {
        if (data) {
            //console.log('controlInfo=' + JSON.stringify(data));
            this.controlInfo = data;

            // レコードタイプIDが変わった場合、対応策作成情報の取得処理が実行される
            const { defaultRecordTypeId = null } = data;
            if (defaultRecordTypeId !== this.controlRecordTypeId) {
                this.controlRecordTypeId = defaultRecordTypeId;
                this.controlCreateInfo = null;
            }

            // 対応策作成レイアウトの作成
            this.controlCreateLayout = this.createControlCreateLayout();
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 対応策作成情報の取得
    @wire(getRecordCreateDefaults, {
        objectApiName: CONTROL_OBJECT,
        recordTypeId: '$controlRecordTypeId',
    })
    wiredControlCreateInfo({ error, data }) {
        if (data) {
            this.controlCreateInfo = data;
            // 対応策作成レイアウトの作成
            this.controlCreateLayout = this.createControlCreateLayout();
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 初期化時
    connectedCallback() {
        // データの初期化
        this.initDataAsync();
    }

    // タブのアクティブ時
    handleTabActive(event) {
        this.activeTabValue = event.target.value;
    }

    // 対応策検索条件セクションの開閉時
    handleControlSearchCondSectionToggle(event) {
        this.controlSearchCondActiveSections = event.detail.openSections;
    }

    // 対応策の検索時
    async handleControlSearchAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.controlSearchConds = event.detail.searchConditions;
            this.controlSearchCondLogic = event.detail.searchConditionLogic;
            // 対応策リストの読込み
            await this.loadControlsAsync();
            // 検索条件セクションを閉じる
            this.controlSearchCondActiveSections = [];
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 対応策の検索キャンセル時
    handleControlSearchCancel() {
        // 検索条件セクションを閉じる
        this.controlSearchCondActiveSections = [];
    }

    // 登録種別の変更時
    async handleRegisterTypeChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.registerType = event.detail.value;
            // 対応策リストの読込み
            await this.loadControlsAsync();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // ページ移動クリック時
    handleControlPageMoveClick(event) {
        event.preventDefault();
        const { name } = event.target.dataset;
        switch (name) {
            case 'control-first-page':
                this.controlPageInfo.pageNumber = 1;
                break;
            case 'control-last-page':
                this.controlPageInfo.pageNumber = this.controlPageInfo.lastPageNumber;
                break;
            case 'control-next-page':
                this.controlPageInfo.pageNumber++;
                break;
            case 'control-previous-page':
                this.controlPageInfo.pageNumber--;
                break;
        }
        // 対応策データ行リストの読込み
        this.loadControlDataRows();
    }

    // 対応策のソート時
    handleControlSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.controlSortDirection = sortDirection;
        this.controlSortedBy = fieldName;
        // 対応策リストのソート
        this.sortControls();
        // 対応策データ行リストの読込み
        this.loadControlDataRows();
    }

    // 対応策の行選択時
    handleControlRowSelection(event) {
        // 選択対応策IDの読込み
        const selectedRows = event.detail.selectedRows;
        this.loadSelectControlId(selectedRows);
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
            
            // インシデント対応策の登録
            await registerIncidentControl({
                incidentId: this.incidentId,
                controlIds: this.entryControlIds,
            });

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.incidentControlEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 登録確認ダイアログを閉じる
            this.closeEntryConfirmDialog();
            
            // 対応策リストの読込み
            await this.loadControlsAsync(this.controlPageInfo.pageNumber);
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

            // インシデント対応策の削除
            await deleteIncidentControl({
                incidentId: this.incidentId,
                controlIds: this.deleteControlIds,
            });
            
            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.incidentControlDeleteComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 削除確認ダイアログを閉じる
            this.closeDeleteConfirmDialog();
            
            // 対応策リストの読込み
            await this.loadControlsAsync(this.controlPageInfo.pageNumber);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 対応策の新規の送信時
    handleControlNewSubmit() {
        this.isProcessing = true;
        this.errorMessages = null;
    }

    // 対応策の新規の成功時
    async handleControlNewSuccessAsync(event) {
        try {
            // 完了メッセージの表示
            let evt = new ShowToastEvent({
                message:  this.labelInfo.controlNewCreateComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // インシデント対応策の登録
            const { id: controlId } = event.detail;
            await registerIncidentControl({
                incidentId: this.incidentId,
                controlIds: [ controlId ],
            });

            // 完了メッセージの表示
            evt = new ShowToastEvent({
                message: this.labelInfo.incidentControlEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // アクティブタブ値のセット
            this.activeTabValue = 'incidentControlEntry';
            
            // 対応策リストの読込み
            await this.loadControlsAsync(this.controlPageInfo.pageNumber);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 対応策の新規のエラー時
    handleControlNewError(event) {
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
        // インシデント対応策登録設定の取得
        const data = await getIncidentControlEntrySetting();
        //console.log('incidentControlEntrySetting=' + JSON.stringify(data));
        const {
            ermt__ControlSearchFieldNames__c = '',
            ermt__ControlDisplayFieldNames__c = '',
            ermt__ControlSelectLimit__c = 2000,
            ermt__ControlPageSize__c = 30,
        } = data || {};
        this.controlSearchFieldNames = ermt__ControlSearchFieldNames__c.split(/\s*,\s*/);
        this.controlDisplayFieldNames = ermt__ControlDisplayFieldNames__c.split(/\s*,\s*/);
        this.controlSelectLimit = ermt__ControlSelectLimit__c;
        this.controlPageInfo.pageSize = ermt__ControlPageSize__c;
        this.cacheMap.set('setting_isLoaded', true);
    }

    // インシデントの最新表示
    async refreshIncidentAsync() {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            // 設定の読込み
            await this.loadSettingAsync();
            // インシデントの読込み
            await this.loadIncidentAsync();
            // 対応策項目定義リストの読込み
            await this.loadControlFieldDefinesAsync();
            // 対応策リストの読込み
            await this.loadControlsAsync();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // インシデントの読込み
    async loadIncidentAsync() {
        const data = await getIncident({
            incidentId: this.incidentId
        });
        // インシデントの作成
        this.incident = this.createIncident(data || {});
        // 対応策作成レイアウトの作成
        this.controlCreateLayout = this.createControlCreateLayout();
    }

    // インシデントの作成
    createIncident({
        Id = null,
        Name = null,
        ermt__Title__c = null,
        ermt__Organization__c = null,
        UserRecordAccess: {
            HasEditAccess = false
        } = {},
    } = {}) {
        return {
            Id,
            Name,
            ermt__Title__c,
            ermt__Organization__c,
            HasEditAccess
        };
    }

    // 対応策項目定義リストの読込み
    async loadControlFieldDefinesAsync() {
        if (this.cacheMap.get('controlFieldDefines_isLoaded')) return;
        // 対応策項目定義リストの取得
        const data = await getControlFieldDefines({
            displayFieldNames: this.controlDisplayFieldNames
        });
        //console.log('controlFieldDefines=' + JSON.stringify(data));
        this.controlFieldDefs = data;
        // 対応策列リストの作成
        const controlColumns = data.map(fieldDef => this.createColumn(fieldDef));
        controlColumns.unshift({
            label: label_registered,
            fieldName: 'isRegistered',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        controlColumns.push({
            label: label_editable,
            fieldName: 'hasEditAccess',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        this.controlColumns = controlColumns;
        // 対応策ソート項目名マップの作成
        this.controlSortFieldNameMap = this.createControlSortFieldNameMap();
        this.cacheMap.set('controlFieldDefines_isLoaded', true);
    }

    // 対応策ソート項目名マップの作成
    createControlSortFieldNameMap() {
        const fieldNameMap = new Map();
        this.controlFieldDefs.forEach(fieldDef => {
            const {
                fieldName = null,
                parentNameFieldName = null,
                fieldType = null,
            } = fieldDef;
            if (fieldName === 'Name') {
                fieldNameMap.set('controlUrl', 'Name');
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

    // 対応策リストの読込み
    async loadControlsAsync(pageNumber = 1) {
        // console.log('incidentId=' + this.incidentId);
        // console.log('controlFieldDefs=' + JSON.stringify(this.controlFieldDefs));
        // console.log('registerType=' + this.registerType);
        // console.log('controlSearchConds=' + JSON.stringify(this.controlSearchConds));
        // console.log('controlSearchCondLogic=' + this.controlSearchCondLogic);
        // console.log('controlSelectLimit=' + this.controlSelectLimit);
        // 対応策リストの取得
        const data = await getControls({
            incidentId: this.incidentId
            , fieldDefs: this.controlFieldDefs
            , registerType: this.registerType
            , searchConds: this.controlSearchConds
            , searchCondLogic: this.controlSearchCondLogic
            , selectLimit: this.controlSelectLimit
        });
        //console.log('controls=' + JSON.stringify(data));
        this.controls = data;
        this.controlPageInfo.resultSize = data.length;
        this.controlPageInfo.pageNumber = pageNumber;
        // 対応策リストのソート
        this.sortControls();
        // 対応策データ行リストの読込み
        this.loadControlDataRows();
        // 選択対応策IDの読込み
        setTimeout(() =>{
            const table = this.template.querySelector('[data-name="controlTable"]');
            const selectedRows = (table ? table.getSelectedRows() : []);
            this.loadSelectControlId(selectedRows);
        }, 0);
    }

    // 対応策リストのソート
    sortControls() {
        // 対応策ソート項目が有る場合、ソートする
        if (this.controlSortedBy) {
            const fieldName = this.controlSortFieldNameMap.get(this.controlSortedBy);
            const reverse = (this.controlSortDirection === 'asc' ? 1 : -1);
            const controls = [...this.controls];
            controls.sort(this.compareControl(fieldName, reverse));
            this.controls = controls;
        }
    }

    // 対応策のソート比較関数
    compareControl(fieldName, reverse) {
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

    // 対応策データ行リストの読込み
    loadControlDataRows() {
        const controlDataRows = [];
        const startIndex = this.controlPageInfo.rowNumberOffset;
        let endIndex = startIndex + this.controlPageInfo.pageSize - 1;
        endIndex = (endIndex < this.controlPageInfo.resultSize ? endIndex : this.controlPageInfo.resultSize - 1);
        for (let i = startIndex; i <= endIndex; i++) {
            const control = this.controls[i];
            controlDataRows.push(this.createControlDataRow(control, this.controlFieldDefs));
        }
        this.controlDataRows = controlDataRows;
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
                fieldName: 'controlUrl',
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

    //対応策データ行の作成
    createControlDataRow(record, fieldDefs) {
        const newRec = {
            key: record.Id,
            controlUrl: '/' + record.Id,
            hasEditAccess: this.incident.HasEditAccess && record.UserRecordAccess.HasEditAccess,
            isRegistered: !!(record.ermt__Incident_Control_Juncs__r?.length),
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

    // 選択対応策IDの読込み
    loadSelectControlId(selectedRows) {
        let entryControlIds = [];
        let deleteControlIds = [];
        for (let i = 0, len = selectedRows.length; i < len; i++) {
            const row = selectedRows[i];
            if (row.hasEditAccess) {
                if (row.isRegistered) {
                    deleteControlIds.push(row.key);
                } else {
                    entryControlIds.push(row.key);
                }
            }
        }
        // 登録分と削除分の対応策の選択が有る場合、登録、削除できないようにする
        if (entryControlIds.length > 0 && deleteControlIds.length > 0) {
            entryControlIds = [];
            deleteControlIds = [];
        }
        this.entryControlIds = entryControlIds;
        this.deleteControlIds = deleteControlIds;
    }

    // 対応策作成レイアウトの作成
    createControlCreateLayout() {
        let layout = null;
        if (this.controlInfo && this.controlCreateInfo && this.incident.Id) {
            const {
                record: {
                    fields = {}
                } = {}
            } = this.controlCreateInfo;
            layout = [];
            this.controlCreateInfo.layout.sections.forEach(s => {
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
                                // レコードタイプID
                                if (item.name === 'RecordTypeId') {
                                    item.value = this.controlRecordTypeId;
                                // 組織・部門
                                } else if (item.name === 'ermt__AssignedOrg__c') {
                                    item.value = this.incident.ermt__Organization__c;
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