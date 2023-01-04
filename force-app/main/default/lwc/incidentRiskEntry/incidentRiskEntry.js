/**
 * インシデントリスク登録
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import INCIDENT_OBJECT from '@salesforce/schema/Incident__c';
import RISK_OBJECT from '@salesforce/schema/Risk__c';
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
import label_incidentRiskEntry from '@salesforce/label/c.IncidentRiskEntry_Entry';
import label_entryConfirm from '@salesforce/label/c.IncidentRiskEntry_EntryConfirm';
import label_entryComplete from '@salesforce/label/c.IncidentRiskEntry_EntryComplete';
import label_deleteConfirm from '@salesforce/label/c.IncidentRiskEntry_DeleteConfirm';
import label_deleteComplete from '@salesforce/label/c.IncidentRiskEntry_DeleteComplete';
import label_riskNewCreate from '@salesforce/label/c.IncidentRiskEntry_RiskNewCreate';
import label_riskNewCreateComplete from '@salesforce/label/c.IncidentRiskEntry_RiskNewCreateComplete';
import label_riskControlEntryComplete from '@salesforce/label/c.IncidentRiskEntry_RiskControlEntryComplete';

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
import getIncidentRiskEntrySetting from '@salesforce/apex/IncidentRiskEntryCtlr.getIncidentRiskEntrySetting';
import getIncident from '@salesforce/apex/IncidentRiskEntryCtlr.getIncident';
import getRiskFieldDefines from '@salesforce/apex/IncidentRiskEntryCtlr.getRiskFieldDefines';
import getRisks from '@salesforce/apex/IncidentRiskEntryCtlr.getRisks';
import registerIncidentRisk from '@salesforce/apex/IncidentRiskEntryCtlr.registerIncidentRisk';
import deleteIncidentRisk from '@salesforce/apex/IncidentRiskEntryCtlr.deleteIncidentRisk';
import registerRiskControl from '@salesforce/apex/IncidentRiskEntryCtlr.registerRiskControl';

export default class IncidentRiskEntry extends LightningElement {
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
        incidentRiskEntry: label_incidentRiskEntry,
        riskNewCreate: label_riskNewCreate,
        riskNewCreateComplete: label_riskNewCreateComplete,
        incidentRiskEntryConfirm: label_entryConfirm,
        incidentRiskEntryComplete: label_entryComplete,
        incidentRiskDeleteConfirm: label_deleteConfirm,
        incidentRiskDeleteComplete: label_deleteComplete,
        riskControlEntryComplete: label_riskControlEntryComplete,
    };
    activeTabValue = 'incidentRiskEntry'; // アクティブタブ値
    incidentLabel = ''; // インシデント表示ラベル
    incidentNameLabel = ''; // インシデント名表示ラベル
    incidentTitleLabel = ''; // インシデントタイトル表示ラベル
    incidentId = null; // インシデントID
    incident = this.createIncident(); // インシデントレコード
    riskInfo = null; // リスク情報
    // リスク表示ラベル
    get riskLabel() {
        return this.riskInfo?.label || '';
    }
    riskSearchCondActiveSections = []; // リスク検索条件アクティブセクションリスト
    riskObjectName = RISK_OBJECT.objectApiName; // リスクオブジェクト名
    riskRecordTypeId = null; // リスクレコードタイプID
    riskDisplayFieldNames = []; // リスク表示項目名リスト
    riskSearchFieldNames = []; // リスク検索項目名リスト
    riskSelectLimit = 0; // リスクレコード取得限度数
    riskSearchConds = []; // リスク検索条件リスト
    riskSearchCondLogic = null; // リスク検索条件ロジック
    registerType = label_all; // 登録種別
    // 登録種別選択リスト
    registerTypeOptions = [
        { label: label_all, value: label_all },
        { label: label_unregistered, value: label_unregistered },
        { label: label_registered, value: label_registered },
    ];
    riskFieldDefs = []; // リスク項目定義リスト
    riskColumns = []; // リスク列リスト
    riskSortFieldNameMap = new Map(); // リスクソート項目名マップ
    riskDataRows = []; // リスクデータ行リスト
    riskDefaultSortDirection = 'asc'; // リスクデフォルトソート方向
    riskSortDirection = 'asc'; // リスクソート方向
    riskSortedBy = ''; // リスクソート項目
    risks = []; // リスクリスト
    @track riskPageInfo = this.createPageInfo(); // リスクページ情報
    entryRiskIds = []; // 登録リスクIDリスト
    deleteRiskIds = []; // 削除リスクIDリスト
    riskCreateInfo = null; // リスク作成情報
    riskCreateLayout = null; // リスク作成レイアウト

    // リスク先頭ページ有効
    get isRiskFirstPageEnable() {
        return (this.riskPageInfo.pageNumber > 2);
    }

    // リスク最終ページ有効
    get isRiskLastPageEnable() {
        return (this.riskPageInfo.pageNumber < (this.riskPageInfo.lastPageNumber - 1));
    }

    // リスク次ページ有効
    get isRiskNextPageEnable() {
        return (this.riskPageInfo.pageNumber < this.riskPageInfo.lastPageNumber);
    }

    // リスク前ページ有効
    get isRiskPreviousPageEnable() {
        return (this.riskPageInfo.pageNumber > 1);
    }

    // 登録の無効化フラグ
    get isEntryDisabled() {
        return (this.entryRiskIds.length === 0);
    }

    // 削除の無効化フラグ
    get isDeleteDisabled() {
        return (this.deleteRiskIds.length === 0);
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

    // リスク情報の取得
    @wire(getObjectInfo, { objectApiName: RISK_OBJECT })
    wiredRiskInfo({ data, error }) {
        if (data) {
            //console.log('riskInfo=' + JSON.stringify(data));
            this.riskInfo = data;

            // レコードタイプIDが変わった場合、リスク作成情報の取得処理が実行される
            const { defaultRecordTypeId = null } = data;
            if (defaultRecordTypeId !== this.riskRecordTypeId) {
                this.riskRecordTypeId = defaultRecordTypeId;
                this.riskCreateInfo = null;
            }

            // リスク作成レイアウトの作成
            this.riskCreateLayout = this.createRiskCreateLayout();
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスク作成情報の取得
    @wire(getRecordCreateDefaults, {
        objectApiName: RISK_OBJECT,
        recordTypeId: '$riskRecordTypeId',
    })
    wiredRiskCreateInfo({ error, data }) {
        if (data) {
            this.riskCreateInfo = data;

            // リスク作成レイアウトの作成
            this.riskCreateLayout = this.createRiskCreateLayout();
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

    // リスク検索条件セクションの開閉時
    handleRiskSearchCondSectionToggle(event) {
        this.riskSearchCondActiveSections = event.detail.openSections;
    }

    // リスクの検索時
    async handleRiskSearchAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.riskSearchConds = event.detail.searchConditions;
            this.riskSearchCondLogic = event.detail.searchConditionLogic;
            // リスクリストの読込み
            await this.loadRisksAsync();
            // 検索条件セクションを閉じる
            this.riskSearchCondActiveSections = [];
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // リスクの検索キャンセル時
    handleRiskSearchCancel() {
        // 検索条件セクションを閉じる
        this.riskSearchCondActiveSections = [];
    }

    // 登録種別の変更時
    async handleRegisterTypeChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.registerType = event.detail.value;
            // リスクリストの読込み
            await this.loadRisksAsync();
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
                this.riskPageInfo.pageNumber = 1;
                break;
            case 'risk-last-page':
                this.riskPageInfo.pageNumber = this.riskPageInfo.lastPageNumber;
                break;
            case 'risk-next-page':
                this.riskPageInfo.pageNumber++;
                break;
            case 'risk-previous-page':
                this.riskPageInfo.pageNumber--;
                break;
        }
        // リスクデータ行リストの読込み
        this.loadRiskDataRows();
    }

    // リスクのソート時
    handleRiskSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.riskSortDirection = sortDirection;
        this.riskSortedBy = fieldName;
        // リスクリストのソート
        this.sortRisks();
        // リスクデータ行リストの読込み
        this.loadRiskDataRows();
    }

    // リスクの行選択時
    handleRiskRowSelection(event) {
        // 選択リスクIDの読込み
        const selectedRows = event.detail.selectedRows;
        this.loadSelectRiskId(selectedRows);
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
            await registerIncidentRisk({
                incidentId: this.incidentId,
                riskIds: this.entryRiskIds,
            });

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.incidentRiskEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 登録確認ダイアログを閉じる
            this.closeEntryConfirmDialog();
            
            // リスクリストの読込み
            await this.loadRisksAsync(this.riskPageInfo.pageNumber);
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
            await deleteIncidentRisk({
                incidentId: this.incidentId,
                riskIds: this.deleteRiskIds,
            });
            
            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.labelInfo.incidentRiskDeleteComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 削除確認ダイアログを閉じる
            this.closeDeleteConfirmDialog();
            
            // リスクリストの読込み
            await this.loadRisksAsync(this.riskPageInfo.pageNumber);
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
    async handleRiskNewSuccessAsync(event) {
        try {
            // 完了メッセージの表示
            let evt = new ShowToastEvent({
                message:  this.labelInfo.riskNewCreateComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // インシデントリスクの登録
            const { id: riskId } = event.detail;
            await registerIncidentRisk({
                incidentId: this.incidentId,
                riskIds: [ riskId ],
            });

            console.log(1);

            // 完了メッセージの表示
            evt = new ShowToastEvent({
                message: this.labelInfo.incidentRiskEntryComplete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // リスク対応策の登録
            const result = await registerRiskControl({
                incidentId: this.incidentId,
                riskId: riskId,
            });

            console.log(result);

            if (result.registerCount > 0) {
                // 完了メッセージの表示
                evt = new ShowToastEvent({
                    message: this.labelInfo.riskControlEntryComplete,
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }

            // アクティブタブ値のセット
            this.activeTabValue = 'incidentRiskEntry';
            
            // リスクリストの読込み
            await this.loadRisksAsync(this.riskPageInfo.pageNumber);
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
        // インシデントリスク登録設定の取得
        const data = await getIncidentRiskEntrySetting();
        //console.log('incidentRiskEntrySetting=' + JSON.stringify(data));
        const {
            ermt__RiskSearchFieldNames__c = '',
            ermt__RiskDisplayFieldNames__c = '',
            ermt__RiskSelectLimit__c = 2000,
            ermt__RiskPageSize__c = 30,
        } = data || {};
        this.riskSearchFieldNames = ermt__RiskSearchFieldNames__c.split(/\s*,\s*/);
        this.riskDisplayFieldNames = ermt__RiskDisplayFieldNames__c.split(/\s*,\s*/);
        this.riskSelectLimit = ermt__RiskSelectLimit__c;
        this.riskPageInfo.pageSize = ermt__RiskPageSize__c;
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
            // リスク項目定義リストの読込み
            await this.loadRiskFieldDefinesAsync();
            // リスクリストの読込み
            await this.loadRisksAsync();
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

        // リスク作成レイアウトの作成
        this.riskCreateLayout = this.createRiskCreateLayout();
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

    // リスク項目定義リストの読込み
    async loadRiskFieldDefinesAsync() {
        if (this.cacheMap.get('riskFieldDefines_isLoaded')) return;
        // リスク項目定義リストの取得
        const data = await getRiskFieldDefines({
            displayFieldNames: this.riskDisplayFieldNames
        });
        //console.log('riskFieldDefines=' + JSON.stringify(data));
        this.riskFieldDefs = data;
        // リスク列リストの作成
        const riskColumns = data.map(fieldDef => this.createColumn(fieldDef));
        riskColumns.unshift({
            label: label_registered,
            fieldName: 'isRegistered',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        riskColumns.push({
            label: label_editable,
            fieldName: 'hasEditAccess',
            type: 'boolean',
            initialWidth: 60,
            cellAttributes: { alignment: 'center' },
        });
        this.riskColumns = riskColumns;
        // リスクソート項目名マップの作成
        this.riskSortFieldNameMap = this.createRiskSortFieldNameMap();
        this.cacheMap.set('riskFieldDefines_isLoaded', true);
    }

    // リスクソート項目名マップの作成
    createRiskSortFieldNameMap() {
        const fieldNameMap = new Map();
        this.riskFieldDefs.forEach(fieldDef => {
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

    // リスクリストの読込み
    async loadRisksAsync(pageNumber = 1) {
        // console.log('incidentId=' + this.incidentId);
        // console.log('riskFieldDefs=' + JSON.stringify(this.riskFieldDefs));
        // console.log('registerType=' + this.registerType);
        // console.log('riskSearchConds=' + JSON.stringify(this.riskSearchConds));
        // console.log('riskSearchCondLogic=' + this.riskSearchCondLogic);
        // console.log('riskSelectLimit=' + this.riskSelectLimit);
        // リスクリストの取得
        const data = await getRisks({
            incidentId: this.incidentId
            , fieldDefs: this.riskFieldDefs
            , registerType: this.registerType
            , searchConds: this.riskSearchConds
            , searchCondLogic: this.riskSearchCondLogic
            , selectLimit: this.riskSelectLimit
        });
        //console.log('risks=' + JSON.stringify(data));
        this.risks = data;
        this.riskPageInfo.resultSize = data.length;
        this.riskPageInfo.pageNumber = pageNumber;
        // リスクリストのソート
        this.sortRisks();
        // リスクデータ行リストの読込み
        this.loadRiskDataRows();
        // 選択リスクIDの読込み
        setTimeout(() =>{
            const table = this.template.querySelector('[data-name="riskTable"]');
            const selectedRows = (table ? table.getSelectedRows() : []);
            this.loadSelectRiskId(selectedRows);
        }, 0);
    }

    // リスクリストのソート
    sortRisks() {
        // リスクソート項目が有る場合、ソートする
        if (this.riskSortedBy) {
            const fieldName = this.riskSortFieldNameMap.get(this.riskSortedBy);
            const reverse = (this.riskSortDirection === 'asc' ? 1 : -1);
            const risks = [...this.risks];
            risks.sort(this.compareRisk(fieldName, reverse));
            this.risks = risks;
        }
    }

    // リスクのソート比較関数
    compareRisk(fieldName, reverse) {
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

    // リスクデータ行リストの読込み
    loadRiskDataRows() {
        const riskDataRows = [];
        const startIndex = this.riskPageInfo.rowNumberOffset;
        let endIndex = startIndex + this.riskPageInfo.pageSize - 1;
        endIndex = (endIndex < this.riskPageInfo.resultSize ? endIndex : this.riskPageInfo.resultSize - 1);
        for (let i = startIndex; i <= endIndex; i++) {
            const risk = this.risks[i];
            riskDataRows.push(this.createRiskDataRow(risk, this.riskFieldDefs));
        }
        this.riskDataRows = riskDataRows;
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

    //リスクデータ行の作成
    createRiskDataRow(record, fieldDefs) {
        const newRec = {
            key: record.Id,
            riskUrl: '/' + record.Id,
            hasEditAccess: this.incident.HasEditAccess && record.UserRecordAccess.HasEditAccess,
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

    // 選択リスクIDの読込み
    loadSelectRiskId(selectedRows) {
        let entryRiskIds = [];
        let deleteRiskIds = [];
        for (let i = 0, len = selectedRows.length; i < len; i++) {
            const row = selectedRows[i];
            if (row.hasEditAccess) {
                if (row.isRegistered) {
                    deleteRiskIds.push(row.key);
                } else {
                    entryRiskIds.push(row.key);
                }
            }
        }
        // 登録分と削除分のリスクの選択が有る場合、登録、削除できないようにする
        if (entryRiskIds.length > 0 && deleteRiskIds.length > 0) {
            entryRiskIds = [];
            deleteRiskIds = [];
        }
        this.entryRiskIds = entryRiskIds;
        this.deleteRiskIds = deleteRiskIds;
    }

    // リスク作成レイアウトの作成
    createRiskCreateLayout() {
        let layout = null;
        if (this.riskInfo && this.riskCreateInfo && this.incident.Id) {
            const {
                record: {
                    fields = {}
                } = {}
            } = this.riskCreateInfo;
            layout = [];
            this.riskCreateInfo.layout.sections.forEach(s => {
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
                                    item.value = this.riskRecordTypeId;
                                // 組織・部門
                                } else if (item.name === 'ermt__Organization__c') {
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