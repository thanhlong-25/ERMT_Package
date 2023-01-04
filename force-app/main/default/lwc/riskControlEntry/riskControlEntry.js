import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { getErrorMessages } from 'c/commonUtil';
import getLabelMap from '@salesforce/apex/RiskControlEntryCtlr.getLabelMap';
import getRegisterTypeSels from '@salesforce/apex/RiskControlEntryCtlr.getRegisterTypeSels';
import getControlInfo from '@salesforce/apex/RiskControlEntryCtlr.getControlInfo';
import registerRiskControl from '@salesforce/apex/RiskControlEntryCtlr.registerRiskControl';
import deleteRiskControl from '@salesforce/apex/RiskControlEntryCtlr.deleteRiskControl';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RISK_NAME_FIELD from '@salesforce/schema/Risk__c.Name';
import RISK_ORG_FIELD from '@salesforce/schema/Risk__c.Organization__c';
import CONTROL_OBJECT from '@salesforce/schema/Control__c';
import CONTROL_ORG_FIELD from '@salesforce/schema/Control__c.AssignedOrg__c';
const RISK_FIELDS = [RISK_NAME_FIELD, RISK_ORG_FIELD];

export default class RiskControlEntry extends LightningElement {
    @api recordId; // レコードID
    label = null; // ラベル
    errorMessages = null; // エラーメッセージリスト
    processing = false; // 処理中
    risk = null; // リスク
    get controlObjName() { return CONTROL_OBJECT.objectApiName; } // 対応策オブジェクト名
    registerTypeSels  = []; // 登録種別選択リスト
    registerType = null; // 登録種別
    searchCondActiveSections = null; // 検索条件のアクティブセクション
    searchConds = []; // 検索条件リスト
    searchCondLogic = null; // 検索条件ロジック
    otherSearchCond = null; // その他の検索条件
    // 対応策リスト
    @track controlList = {
        pageNumber : 1 // ページ番号
        , sortFieldName : null // ソート項目名
        , sortDirection : 'asc' // ソート順
        , defaultSortDirection : 'asc' // デフォルトのソート順
        , info: null // 対応策情報
        , ctrlIds: null // 対応策IDリスト（選択したレコードのID）
    };
    controlNewCreateActiveSections = null; // 対応策の新規作成のアクティブセクション
    controlRecInfo = null; // 対応策レコード情報
    _controlNewCreateLayout = null // 対応策の新規作成レイアウト

    // 初期化済み
    get isInitialized() {
        return !!this.label;
    }

    // リスクの取得
    @wire(getRecord, { recordId: '$recordId', fields: RISK_FIELDS })
    wiredRisk({ error, data }) {
        if (data) {
            this.risk = {
                name: data.fields.Name.value
                , accountId: data.fields.ermt__Organization__c.value
            };
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 対応策レコード情報の取得
    @wire(getRecordCreateDefaults, { objectApiName: CONTROL_OBJECT })
    wiredControlRecInfo({ error, data }) {
        if (data) {
            this.controlRecInfo = data;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 初期化処理
    connectedCallback() {
        // ラベルの読込み
        this.loadLabel();

        // 登録種別選択リストの読込み
        this.loadRegisterTypeSels();

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // ラベルの読込み
    loadLabel() {
        // ラベルマップの取得
        getLabelMap()
        .then(data => {
            this.label = data;
        })
        .catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // 登録種別選択リストの読込み
    loadRegisterTypeSels() {
        // 登録種別選択リストの取得
        getRegisterTypeSels()
        .then(data => {
            this.registerTypeSels = data;
        })
        .catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // 対応策情報の読込み
    loadControlInfo() {
        // 対応策情報の取得
        getControlInfo({
            riskId: this.recordId
            , registerType: this.registerType
            , searchConds: this.searchConds
            , searchCondLogic: this.searchCondLogic
            , otherSearchCond: this.otherSearchCond
            , sortFieldName: this.controlList.sortFieldName
            , sortDirectionType: (this.controlList.sortDirection === 'asc' ? 0 : 1)
            , pageNumber: this.controlList.pageNumber
        })
        .then(data => {
            this.controlList.info = data;
        })
        .catch(error => {
            this.controlList.info = null;
            this.errorMessages = getErrorMessages(error);
        });  
    }

    // 検索条件セクションの開閉時
    handleSearchCondSectionToggle(event) {
        this.searchCondActiveSections = event.detail.openSections;
    }

    // 検索時
    handleSearch(event) {
        this.searchConds = event.detail.searchConditions;
        this.searchCondLogic = event.detail.searchConditionLogic;
        this.controlList.pageNumber = 1;
        
        // 対応策情報の読込み
        this.loadControlInfo();

        // 検索条件セクションを閉じる
        this.searchCondActiveSections = null;
    }

    // 検索キャンセル時
    handleSearchCancel() {
        // 検索条件セクションを閉じる
        this.searchCondActiveSections = null;
    }

    // 登録種別の変更時
    handleRegisterTypeChange(event) {
        this.registerType = event.detail.value;
        this.controlList.pageNumber = 1;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // その他の検索条件の変更時
    handleOtherSearchCondChange(event) {
        this.otherSearchCond = event.detail.value;
        this.controlList.pageNumber = 1;
  
        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // 対応策リストのソート時
    handleControlListSort(event) {
        const sortFieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        if (this.controlList.sortFieldName === sortFieldName) {
            this.controlList.sortDirection = (this.controlList.sortDirection === 'asc' ? 'desc' : 'asc');
        } else {
            this.controlList.sortFieldName = sortFieldName;
            this.controlList.sortDirection = sortDirection;
        }
        this.controlList.pageNumber = this.controlList.info.pageInfo.pageNumber;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // ページネーション表示
    get paginationVisible() {
        return (this.controlList.info.pageInfo.lastPageNumber > 1);
    }

    // 先頭へが無しの取得
    get notHasFirst() {
        return !(this.controlList.info.pageInfo.pageNumber > 2);
    }

    // 前へが無しの取得
    get notHasPrevious() {
        return !(this.controlList.info.pageInfo.pageNumber > 1);
    }

    // 次へが無しの取得
    get notHasNext() {
        return !(this.controlList.info.pageInfo.pageNumber < this.controlList.info.pageInfo.lastPageNumber);
    }

    // 最終へが無しの取得
    get notHasLast() {
        return !(this.controlList.info.pageInfo.pageNumber < (this.controlList.info.pageInfo.lastPageNumber - 1));
    }

    // ページ番号の変更時
    handlePageNumberChange(event) {
        if (event.detail.value) {
            this.controlList.pageNumber = event.detail.value;
 
            // 対応策情報の読込み
            this.loadControlInfo();
        }
    }

    // 先頭ページへの移動のクリック時
    handleFirstPageClick() {
        this.controlList.pageNumber = 1;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // 前ページへの移動のクリック時
    handlePreviousPageClick() {
        this.controlList.pageNumber = this.controlList.info.pageInfo.pageNumber;
        this.controlList.pageNumber--;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // 次ページへの移動のクリック時
    handleNextPageClick() {
        this.controlList.pageNumber = this.controlList.info.pageInfo.pageNumber;
        this.controlList.pageNumber++;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // 最終ページへの移動のクリック時
    handleLastPageClick() {
        this.controlList.pageNumber = this.controlList.info.pageInfo.lastPageNumber;

        // 対応策情報の読込み
        this.loadControlInfo();
    }

    // 登録のクリック時
    handleEntryClick() {
        // 対応策IDリストの取得
        const elm = this.template.querySelector('[data-name="controlList"]');
        this.controlList.ctrlIds = (!elm ? null : elm.selectedRows);

        // 入力チェック
        if (!this.checkInput()) return;

        // 登録確認ダイアログを開く
        this.openEntryConfirmDialog();

    }

    // 登録キャンセルのクリック時
    handleEntryCancelClick() {
        // 登録確認ダイアログを閉じる
        this.closeEntryConfirmDialog();
    }

    // 登録OKのクリック時
    handleEntryOkClick() {
        this.processing = true;

        // リスク対応策の登録
        registerRiskControl({
            riskId: this.recordId
            , ctrlIds: this.controlList.ctrlIds
        })
        .then(() => {
            this.processing = false;

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.label.entry_complete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 対応策情報の読込み
            this.loadControlInfo();
        })
        .catch(error => {
            this.processing = false;
            this.errorMessages = getErrorMessages(error);
        });

        // 登録確認ダイアログを閉じる
        this.closeEntryConfirmDialog();
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

    // 削除のクリック時
    handleDeleteClick() {
        // 対応策IDリストの取得
        const elm = this.template.querySelector('[data-name="controlList"]');
        this.controlList.ctrlIds = (!elm ? null : elm.selectedRows);

        // 入力チェック
        if (!this.checkInput()) return;

        // 削除確認ダイアログを開く
        this.openDeleteConfirmDialog();
    }

    // 削除キャンセルのクリック時
    handleDeleteCancelClick() {
        // 削除確認ダイアログを閉じる
        this.closeDeleteConfirmDialog();
    }

    // 削除OKのクリック時
    handleDeleteOkClick() {
        this.processing = true;

        // リスク対応策の削除
        deleteRiskControl({
            riskId: this.recordId
            , ctrlIds: this.controlList.ctrlIds
        })
        .then(() => {
            this.processing = false;

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.label.delete_complete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 対応策情報の読込み
            this.loadControlInfo();
        })
        .catch(error => {
            this.processing = false;
            this.errorMessages = getErrorMessages(error);
        });

        // 削除確認ダイアログを閉じる
        this.closeDeleteConfirmDialog();
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

    // 入力エラーOKのクリック時
    handleInputErrorOkClick() {
        // 入力エラーダイアログを閉じる
        this.closeInputErrorDialog();
    }

    // 入力チェック
    checkInput() {
        // 対応策の必須チェック
        if (!this.controlList.ctrlIds || this.controlList.ctrlIds.length === 0) {
            // 入力エラーダイアログを開く
            this.openInputErrorDialog(this.label.inputError_control_require);
            return false;
        }
        return true;
    }

    // 入力エラーダイアログを開く
    openInputErrorDialog(errorMessage) {
        const dialog = this.template.querySelector('[data-name="input-error-dialog"]');
        const msg = dialog.querySelector('[data-name="message"]');
        msg.textContent = errorMessage;
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }

    // 入力エラーダイアログを閉じる
    closeInputErrorDialog() {
        const dialog = this.template.querySelector('[data-name="input-error-dialog"]');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    // 閉じるのクリック時
    handleCloseClick() {
        // クローズの実行
        this.execClose(true);
    }

    // 対応策の新規作成セクションの開閉時
    handleControlNewCreateSectionToggle(event) {
        this.controlNewCreateActiveSections = event.detail.openSections;
    }

    // 対応策の新規作成レイアウト
    get controlNewCreateLayout() {
        let ret = null;
        if (this._controlNewCreateLayout) {
            ret = this._controlNewCreateLayout;
        } else {
            if (this.controlRecInfo && this.risk) {
                ret = [];
                const recInfo = this.controlRecInfo;
                recInfo.layout.sections.forEach(s => {
                    const section = {
                        heading: s.useHeading ? s.heading : '',
                        class: 'slds-col slds-size_1-of-' + s.columns,
                        rows: [],
                    };
                    ret.push(section);
                    s.layoutRows.forEach(lr => {
                        const row = {
                            items: [],
                        };
                        section.rows.push(row);
                        lr.layoutItems.forEach(li => {
                            li.layoutComponents.forEach(lc => {
                                const item = {
                                    name: lc.apiName
                                    , value: null
                                    , required: li.required
                                    , disabled: !li.editableForNew
                                };
                                if (item.name) {
                                    // デフォルト値のセット
                                    if (item.name in recInfo.record.fields) {
                                        item.value = recInfo.record.fields[item.name].value;
                                    }
                                    if (item.name === CONTROL_ORG_FIELD.fieldApiName) {
                                        item.value = this.risk.accountId;
                                    }
                                }
                                row.items.push(item);
                            });
                        });
                    });
                });
                this._controlNewCreateLayout = ret;
            }
        }
        return ret;
    }

    // 対応策の新規作成の保存のクリック時
    handleControlNewCreateSaveClick() {
        const btn = this.template.querySelector('[data-name="control-new-create-button"]');
        if (btn) {
            btn.click();
        }
    }

    // 対応策の新規作成の実行時
    handleControlNewCreateSubmit() {
        this.processing = true;
    }

    // 対応策の新規作成の成功時
    handleControlNewCreateSucess(event) {
        const ctrlIds = [ event.detail.id ];

        // リスク対応策の登録
        registerRiskControl({
            riskId: this.recordId
            , ctrlIds: ctrlIds
        })
        .then(() => {
            this.processing = false;

            // 完了メッセージの表示
            const evt = new ShowToastEvent({
                message: this.label.control_newCreate_complete,
                variant: 'success',
            });
            this.dispatchEvent(evt);

            // 対応策情報の読込み
            this.loadControlInfo();

            // 対応策の新規作成セクションを閉じる
            this.controlNewCreateActiveSections = null;
        })
        .catch(error => {
            this.processing = false;
            this.errorMessages = getErrorMessages(error);
        });
    }

    // 対応策の新規作成のエラー時
    handleControlNewCreateError(event) {
        this.processing = false;
        this.errorMessages = getErrorMessages(event.detail.message);
    }

    // エラーアラートの閉じるのクリック時
    handleErrorAlertCloseClick() {
        this.errorMessages = null;
    }

    // クローズの実行
    execClose(isSaved) {
        const event = new CustomEvent('close', {
            detail: { isSaved: isSaved }
        });
        this.dispatchEvent(event);
    }
}