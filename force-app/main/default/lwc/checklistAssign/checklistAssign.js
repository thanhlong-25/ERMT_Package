import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLabelMap from '@salesforce/apex/ChecklistAssignController.getLabelMap';
import getAssignSourceObjectNameSels from '@salesforce/apex/ChecklistAssignController.getAssignSourceObjectNameSels';
import getAssignDestinationObjectNameSels from '@salesforce/apex/ChecklistAssignController.getAssignDestinationObjectNameSels';
import getAssignedSels from '@salesforce/apex/ChecklistAssignController.getAssignedSels';
import getAssignSourceInfo from '@salesforce/apex/ChecklistAssignController.getAssignSourceInfo';
import getAssignDestinationInfo from '@salesforce/apex/ChecklistAssignController.getAssignDestinationInfo';
import createAnswerSheet from '@salesforce/apex/ChecklistAssignController.createAnswerSheet';
import deleteAnswerSheet from '@salesforce/apex/ChecklistAssignController.deleteAnswerSheet';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CHECKLIST_OBJECT from '@salesforce/schema/Checklist__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_USER_OBJECT from '@salesforce/schema/Account_User__c';
import USER_OBJECT from '@salesforce/schema/User';
import ANSWER_SHEET_OBJECT from '@salesforce/schema/Checklist_User__c';

export default class ChecklistAssign extends LightningElement {
    @api recordId = null;
    @api objectApiName = null;
    @track errorMsgs = null;
    @track label = {};
    @track assignSrcObjNameSels  = [];
    @track assignDstObjNameSels  = [];
    @track assignedSels = [];
    @track assignSrcInfo = null;
    @track assignDstInfo = null;
    @track assignSrcObjName = null;
    @track assignDstObjName = null;
    @track assignSrcObjNameVisible = false;
    @track assignDstObjNameVisible = false;
    accountUserObject = ACCOUNT_USER_OBJECT;
    answerSheetObject = ANSWER_SHEET_OBJECT;
    checklistId = null;
    accountId = null;
    userId = null;
    assignSrcList = {
        otherSearchCond : null
        , selectedRows : []
        , pageNumber : 1
        , sortFieldName : null
        , sortDirection : 'asc'
        , defaultSortDirection : 'asc'
    };
    assignDstList = {
        assigned : ''
        , otherSearchCond : null
        , pageNumber : 1
        , sortFieldName : null
        , sortDirection : 'asc'
        , defaultSortDirection : 'asc'
    };

    @track isAccountUserCreate = false;
    @wire(getObjectInfo, { objectApiName: ACCOUNT_USER_OBJECT })
    wiredAccountUserObjectInfo({ error, data }) {
        if (data) {
            this.isAccountUserCreate = data.createable;
        } else if (error) {
            //this.isAccountUserCreate = false;
            //this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
        }
    }

    @track isAnswerSheetEdit = false;
    @wire(getObjectInfo, { objectApiName: ANSWER_SHEET_OBJECT })
    wiredAnswerSheetObjectInfo({ error, data }) {
        if (data) {
            this.isAnswerSheetEdit = (data.createable && data.updateable && data.deletable);
        } else if (error) {
            //this.isAnswerSheetEdit = false;
            //this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
        }
    }

    assignDstRecordIds = null;
    @track inputErrorDialogVisible = false;
    @track inputErrorContent = null;
    @track assignDialogVisible = false;
    @track unassignDialogVisible = false;

    // 初期化処理
    connectedCallback() {
        // console.log('recordId=' + this.recordId);
        // console.log('objectApiName=' + this.objectApiName);

        // ラベルの読込み
        this.loadLabel();

        // オブジェクトIDの初期設定
        if (this.objectApiName === CHECKLIST_OBJECT.objectApiName) {
            this.checklistId = this.recordId;
        } else if (this.objectApiName === ACCOUNT_OBJECT.objectApiName) {
            this.accountId = this.recordId;
        }

        // 割当元オブジェクト名選択リストの読込み
        this.loadAssignSourceObjectNameSels();

        // 割当元オブジェクト名のセット
        if (this.objectApiName === ACCOUNT_OBJECT.objectApiName) {
            this.assignSrcObjName = USER_OBJECT.objectApiName;
        } else {
            this.assignSrcObjName = this.objectApiName;
        }

        // 割当元オブジェクト名表示のセット
        this.assignSrcObjNameVisible = this.isAssignSrcNone;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();

        // 割当先オブジェクト名選択リストの読込み
        this.loadAssignDestinationObjectNameSels();

        // 割当先オブジェクト名のセット
        this.assignDstObjName = this.getAssignDstObjName();

        // 割当先オブジェクト名表示のセット
        this.assignDstObjNameVisible = this.getAssignDstObjNameVisible();

        // 割当済選択リストの読込み
        this.loadAssignedSels();

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // ラベルの読込み
    loadLabel() {
        // ラベルマップの取得
        getLabelMap()
            .then(data => {
                this.label = data;
            })
            .catch(error => {
                this.label = {};
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });
    }

    // 割当元オブジェクト名選択リストの読込み
    loadAssignSourceObjectNameSels() {
        // 割当元オブジェクト名選択リストの取得
        getAssignSourceObjectNameSels()
            .then(data => {
                this.assignSrcObjNameSels = data;
            })
            .catch(error => {
                this.assignSrcObjNameSels = {};
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });
    }

    // 割当先オブジェクト名選択リストの読込み
    loadAssignDestinationObjectNameSels() {
        // 割当先オブジェクト名選択リストの取得
        getAssignDestinationObjectNameSels({
            assignSourceObjectName: this.assignSrcObjName
        })
            .then(data => {
                this.assignDstObjNameSels = data;
            })
            .catch(error => {
                this.assignDstObjNameSels = {};
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });
    }

    // 割当済選択リストの読込み
    loadAssignedSels() {
        // 割当済選択リストの取得
        getAssignedSels()
            .then(data => {
                this.assignedSels = data;
            })
            .catch(error => {
                this.assignedSels = {};
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });
    }

    // 割当元情報の読込み
    loadAssignSourceInfo() {
        let assSrcObjName = this.assignSrcObjName;
        let assSrcRecId = this.assignSrcRecordId;
        if (this.assignSrcObjName === USER_OBJECT.objectApiName) {
            assSrcObjName = ACCOUNT_OBJECT.objectApiName;
            assSrcRecId = this.accountId;
        }
        
        // 割当元情報の取得
        getAssignSourceInfo({
            assignSourceObjectName: assSrcObjName
            , assignSourceRecordId: assSrcRecId
            , otherSearchCond: this.assignSrcList.otherSearchCond
            , sortFieldName: this.assignSrcList.sortFieldName
            , sortDirectionType: (this.assignSrcList.sortDirection === 'asc' ? 0 : 1)
            , pageNumber: this.assignSrcList.pageNumber
        })
            .then(data => {
                this.assignSrcInfo = data;
            })
            .catch(error => {
                this.assignSrcInfo = null;
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });  
    }

    // 割当先情報の読込み
    loadAssignDestinationInfo() {
        let assDstObjName = this.assignDstObjName;
        let assDstRecId = null;
        if (this.assignDstObjName === USER_OBJECT.objectApiName) {
            assDstObjName = ACCOUNT_OBJECT.objectApiName;
            assDstRecId = this.accountId;
        }

        // 割当先情報の取得
        getAssignDestinationInfo({
            assignSourceObjectName: this.assignSrcObjName
            , assignSourceRecordId: this.assignSrcRecordId
            , assignDestinationObjectName: assDstObjName
            , assignDestinationRecordId: assDstRecId
            , assignedStr: this.assignDstList.assigned
            , otherSearchCond: this.assignDstList.otherSearchCond
            , sortFieldName: this.assignDstList.sortFieldName
            , sortDirectionType: (this.assignDstList.sortDirection === 'asc' ? 0 : 1)
            , pageNumber: this.assignDstList.pageNumber
        })
            .then(data => {
                this.assignDstInfo = data;
            })
            .catch(error => {
                this.assignDstInfo = null;
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });  
    }

    // 割当元レコードID
    get assignSrcRecordId() {
        let ret = null;
        if (this.assignSrcObjName === CHECKLIST_OBJECT.objectApiName) {
            ret = this.checklistId;
        } else if (this.assignSrcObjName === USER_OBJECT.objectApiName) {
            ret = this.userId;
        }
        return ret;
    }

    // 割当元が無しか？
    get isAssignSrcNone() {
        return !Boolean(this.assignSrcObjName);
    }

    // 割当元がチェックリストか？
    get isAssignSrcChecklist() {
        return this.assignSrcObjName === CHECKLIST_OBJECT.objectApiName;
    }

    // 割当元がユーザか？
    get isAssignSrcUser() {
        return this.assignSrcObjName === USER_OBJECT.objectApiName;
    }

    // 割当元オブジェクト変更時
    handleAssignSrcObjChange(event) {
        // 割当元オブジェクト名のセット
        this.assignSrcObjName = event.detail.value;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元リストのプロパティの初期化
        if (this.assignSrcObjName === USER_OBJECT.objectApiName) {
            this.userId = null;
            this.assignSrcList.otherSearchCond = null;
            this.assignSrcList.selectedRows = [];
            this.assignSrcList.pageNumber = 1;
            this.assignSrcList.sortFieldName = null;
            this.assignSrcList.sortDirection = 'asc';
        }

        // 割当元情報の読込み
        this.loadAssignSourceInfo();

        // 割当先オブジェクト名選択リストの読込み
        this.loadAssignDestinationObjectNameSels();

        // 割当先オブジェクト名のセット
        this.assignDstObjName = this.getAssignDstObjName();

        // 割当先オブジェクト名表示のセット
        this.assignDstObjNameVisible = this.getAssignDstObjNameVisible();

        // 割当先リストのプロパティの初期化
        this.assignDstList.assigned = '';
        this.assignDstList.otherSearchCond = null;
        this.assignDstList.pageNumber = 1;
        this.assignDstList.sortFieldName = null;
        this.assignDstList.sortDirection = 'asc';

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当元チェックリスト変更時
    handleAssignSrcChecklistChange(event) {
        const vals = event.detail.value;
        this.checklistId = (!vals || vals.length === 0 ? null : vals[0]);

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();

        // 割当先リストのプロパティの初期化
        this.assignDstList.pageNumber = 1;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当元組織・部門変更時
    handleAssignSrcAccountChange(event) {
        const vals = event.detail.value;
        this.accountId = (!vals || vals.length === 0 ? null : vals[0]);

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元リストのプロパティの初期化
        this.assignSrcList.pageNumber = 1;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストのその他の検索条件の変更時
    handleAssignSrcListOtherSearchCondChange(event) {
        this.assignSrcList.otherSearchCond = event.detail.value;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元リストのプロパティの初期化
        this.assignSrcList.pageNumber = 1;
  
        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストの行選択時
    handleAssignSrcListRowSelect(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.userId = selectedRows[0].id;
        } else {
            this.userId = null;
        }

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先リストのプロパティの初期化
        //this.assignDstList.pageNumber = 1;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当元リストのソート時
    handleAssignSrcListSort(event) {
        const sortFieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        if (this.assignSrcList.sortFieldName === sortFieldName) {
            this.assignSrcList.sortDirection = (this.assignSrcList.sortDirection === 'asc' ? 'desc' : 'asc');
        } else {
            this.assignSrcList.sortFieldName = sortFieldName;
            this.assignSrcList.sortDirection = sortDirection;
        }
        this.assignSrcList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストのページネーション表示
    get assignSrcListPaginationVisible() {
        return (this.assignDstInfo.pageInfo.lastPageNumber > 1);
    }

    // 割当元リストの先頭へが無しの取得
    get assignSrcListNotHasFirst() {
        return !(this.assignDstInfo.pageInfo.pageNumber > 2);
    }

    // 割当元リストの前へが無しの取得
    get assignSrcListNotHasPrevious() {
        return !(this.assignDstInfo.pageInfo.pageNumber > 1);
    }

    // 割当元リストの次へが無しの取得
    get assignSrcListNotHasNext() {
        return !(this.assignDstInfo.pageInfo.pageNumber < this.assignDstInfo.pageInfo.lastPageNumber);
    }

    // 割当元リストの最終へが無しの取得
    get assignSrcListNotHasLast() {
        return !(this.assignDstInfo.pageInfo.pageNumber < (this.assignDstInfo.pageInfo.lastPageNumber - 1));
    }

    // 割当元リストのページ番号の変更時
    handleAssignSrcListPageNumberChange(event) {
        if (event.detail.value) {
            this.assignDstList.pageNumber = event.detail.value;
 
            // エラーメッセージクリア
            this.errorMsgs = null;

            // 割当元情報の読込み
            this.loadAssignSourceInfo();
        }
    }

    // 割当元リストの先頭ページへの移動のクリック時
    handleAssignSrcListFirstPageClick() {
        this.assignDstList.pageNumber = 1;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストの前ページへの移動のクリック時
    handleAssignSrcListPreviousPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;
        this.assignDstList.pageNumber--;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストの次ページへの移動のクリック時
    handleAssignSrcListNextPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;
        this.assignDstList.pageNumber++;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当元リストの最終ページへの移動のクリック時
    handleAssignSrcListLastPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.lastPageNumber;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当元情報の読込み
        this.loadAssignSourceInfo();
    }

    // 割当先オブジェクト名の取得
    getAssignDstObjName() {
        let ret = null;
        if (this.assignSrcObjName === CHECKLIST_OBJECT.objectApiName) {
            ret = USER_OBJECT.objectApiName;
        } else if (this.assignSrcObjName === USER_OBJECT.objectApiName) {
            ret = CHECKLIST_OBJECT.objectApiName;
        }
        return ret;
    }

    // 割当先オブジェクト名表示の取得
    getAssignDstObjNameVisible() {
        return false;
    }

    // 割当先が無しか？
    get isAssignDstNone() {
        return !Boolean(this.assignDstObjName);
    }

    // 割当先がチェックリストか？
    get isAssignDstChecklist() {
        return this.assignDstObjName === CHECKLIST_OBJECT.objectApiName;
    }

    // 割当先がユーザか？
    get isAssignDstUser() {
        return this.assignDstObjName === USER_OBJECT.objectApiName;
    }

    // 割当先オブジェクト変更時
    handleAssignDstObjChange(event) {
        this.assignDstObjName = event.detail.value;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先リストのプロパティの初期化
        this.assignDstList.assigned = '';
        this.assignDstList.otherSearchCond = null;
        this.assignDstList.pageNumber = 1;
        this.assignDstList.sortFieldName = null;
        this.assignDstList.sortDirection = 'asc';

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先組織・部門変更時
    handleAssignDstAccountChange(event) {
        const vals = event.detail.value;
        this.accountId = (!vals || vals.length === 0 ? null : vals[0]);

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先リストのプロパティの初期化
        this.assignDstList.pageNumber = 1;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストの割当済の変更時
    handleAssignDstListAssignedChange(event) {
        this.assignDstList.assigned = event.detail.value;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先リストのプロパティの初期化
        this.assignDstList.pageNumber = 1;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストのその他の検索条件の変更時
    handleAssignDstListOtherSearchCondChange(event) {
        this.assignDstList.otherSearchCond = event.detail.value;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先リストのプロパティの初期化
        this.assignDstList.pageNumber = 1;
  
        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストのソート時
    handleAssignDstListSort(event) {
        const sortFieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        if (this.assignDstList.sortFieldName === sortFieldName) {
            this.assignDstList.sortDirection = (this.assignDstList.sortDirection === 'asc' ? 'desc' : 'asc');
        } else {
            this.assignDstList.sortFieldName = sortFieldName;
            this.assignDstList.sortDirection = sortDirection;
        }
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストのページネーション表示
    get assignDstListPaginationVisible() {
        return (this.assignDstInfo.pageInfo.lastPageNumber > 1);
    }

    // 割当先リストの先頭へが無しの取得
    get assignDstListNotHasFirst() {
        return !(this.assignDstInfo.pageInfo.pageNumber > 2);
    }

    // 割当先リストの前へが無しの取得
    get assignDstListNotHasPrevious() {
        return !(this.assignDstInfo.pageInfo.pageNumber > 1);
    }

    // 割当先リストの次へが無しの取得
    get assignDstListNotHasNext() {
        return !(this.assignDstInfo.pageInfo.pageNumber < this.assignDstInfo.pageInfo.lastPageNumber);
    }

    // 割当先リストの最終へが無しの取得
    get assignDstListNotHasLast() {
        return !(this.assignDstInfo.pageInfo.pageNumber < (this.assignDstInfo.pageInfo.lastPageNumber - 1));
    }

    // 割当先リストのページ番号の変更時
    handleAssignDstListPageNumberChange(event) {
        if (event.detail.value) {
            this.assignDstList.pageNumber = event.detail.value;
 
            // エラーメッセージクリア
            this.errorMsgs = null;

            // 割当先情報の読込み
            this.loadAssignDestinationInfo();
        }
    }

    // 割当先リストの先頭ページへの移動のクリック時
    handleAssignDstListFirstPageClick() {
        this.assignDstList.pageNumber = 1;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストの前ページへの移動のクリック時
    handleAssignDstListPreviousPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;
        this.assignDstList.pageNumber--;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストの次ページへの移動のクリック時
    handleAssignDstListNextPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.pageNumber;
        this.assignDstList.pageNumber++;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当先リストの最終ページへの移動のクリック時
    handleAssignDstListLastPageClick() {
        this.assignDstList.pageNumber = this.assignDstInfo.pageInfo.lastPageNumber;

        // エラーメッセージクリア
        this.errorMsgs = null;

        // 割当先情報の読込み
        this.loadAssignDestinationInfo();
    }

    // 割当のクリック時
    handleAssignClick() {
        // 割当先レコードIDリストの取得
        const elm = this.template.querySelector('lightning-datatable.assignDstList');
        this.assignDstRecordIds = (!elm ? null : elm.selectedRows);
                
        // 入力チェック
        if (!this.checkInput()) return;

        this.assignDialogVisible = true;
    }

    // 割当キャンセルのクリック時
    handleAssignCancelClick() {
        this.assignDialogVisible = false;
    }

    // 割当OKのクリック時
    handleAssignOkClick() {
        // エラーメッセージクリア
        this.errorMsgs = null;
        
        // 回答票の作成
        createAnswerSheet({
            assignSourceObjectName: this.assignSrcObjName
            , assignSourceRecordId: this.assignSrcRecordId
            , assignDestinationObjectName: this.assignDstObjName
            , assignDestinationRecordIds: this.assignDstRecordIds
        })
            .then(() => {
                // 完了メッセージの表示
                const evt = new ShowToastEvent({
                    message: this.label.assign_complete,
                    variant: 'success',
                });
                this.dispatchEvent(evt);

                // 割当先情報の読込み
                this.loadAssignDestinationInfo();
            })
            .catch(error => {
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });

        this.assignDialogVisible = false;
    }

    // 割当解除のクリック時
    handleUnassignClick() {
        // 割当先レコードIDリストの取得
        const elm = this.template.querySelector('lightning-datatable.assignDstList');
        this.assignDstRecordIds = (!elm ? null : elm.selectedRows);

        // 入力チェック
        if (!this.checkInput()) return;

        this.unassignDialogVisible = true;
    }

    // 割当解除キャンセルのクリック時
    handleUnassignCancelClick() {
        this.unassignDialogVisible = false;
    }

    // 割当解除OKのクリック時
    handleUnassignOkClick() {
        // エラーメッセージクリア
        this.errorMsgs = null;

        // 回答票の削除
        deleteAnswerSheet({
            assignSourceObjectName: this.assignSrcObjName
            , assignSourceRecordId: this.assignSrcRecordId
            , assignDestinationObjectName: this.assignDstObjName
            , assignDestinationRecordIds: this.assignDstRecordIds
        })
            .then(() => {
                // 完了メッセージの表示
                const evt = new ShowToastEvent({
                    message: this.label.unassign_complete,
                    variant: 'success',
                });
                this.dispatchEvent(evt);

                // 割当先情報の読込み
                this.loadAssignDestinationInfo();
            })
            .catch(error => {
                this.errorMsgs = (this.errorMsgs || []).concat(this.getErrorMessages(error));
            });

        this.unassignDialogVisible = false;
    }

    // 入力チェック
    checkInput() {
        this.inputErrorContent = null;

        // 割当元レコードIDの必須チェック
        if(!this.assignSrcRecordId) {
            this.inputErrorContent = this.label.input_error_assignSoruce_require;
            this.inputErrorDialogVisible = true;
            return false;
        }

        // 割当先レコードIDリストの必須チェック
        if(!this.assignDstRecordIds || this.assignDstRecordIds.length === 0) {
            this.inputErrorContent = this.label.input_error_assignDestination_require;
            this.inputErrorDialogVisible = true;
            return false;
        }
        
        return true;
    }

    // 入力エラーOKのクリック時
    handleInputErrorOkClick() {
        this.inputErrorDialogVisible = false;
    }

    // エラーメッセージリストの取得
    getErrorMessages(error) {
        let ret = null;
        if (error) {
            ret = [];
            if (error.body) {
                if (Array.isArray(error.body)) {
                    ret = ret.concat(error.body.map(e => e.message));
                } else if (typeof error.body.message === 'string') {
                    ret.push(error.body.message);
                } else {
                    ret.push('Unknown error');
                }
            } else if (typeof error.message === 'string') {
                ret.push(error.message);
            } else if (typeof error.statusText === 'string') {
                ret.push(error.statusText);
            } else {
                ret.push('Unknown error');
            }
        }
        return ret;
    }
}