import { LightningElement, api, track } from 'lwc';
import label_title from '@salesforce/label/c.RecordSearchCondition_Title';
import label_expression_field from '@salesforce/label/c.RecordSearchCondition_Expression_Field';
import label_expression_operator from '@salesforce/label/c.RecordSearchCondition_Expression_Operator';
import label_expression_value from '@salesforce/label/c.RecordSearchCondition_Expression_Value';
import label_expression_delete from '@salesforce/label/c.RecordSearchCondition_Expression_Delete';
import label_expression_add from '@salesforce/label/c.RecordSearchCondition_Expression_Add';
import label_expression_allDelete from '@salesforce/label/c.RecordSearchCondition_Expression_AllDelete';
import label_logic from '@salesforce/label/c.RecordSearchCondition_Logic';
import label_logic_help from '@salesforce/label/c.RecordSearchCondition_Logic_Help';
import label_search from '@salesforce/label/c.RecordSearchCondition_Search';
import label_cancel from '@salesforce/label/c.RecordSearchCondition_Cancel';
import { getErrorMessages } from 'c/commonUtil';
import checkSearchCondition from '@salesforce/apex/RecordSearchConditionCtlr.checkSearchCondition';

export default class RecordSearchCondition extends LightningElement {
    // オブジェクト名
    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        this._objectName = value;
    }
    _objectName = null;
    @api label = null; // 表示ラベル
    // 値
    @api
    get value() {
        return {
            searchConds: this.searchConditionsSaved
            , searchCondLogic: this.searchConditionLogicSaved
        };
    }
    set value(value) {
        // 検索条件の設定
        this.setSearchCondition(value);
    }
    @api selectFieldNames = null; // 選択項目名リスト
    @api maxLevel = 2; // 検索親オブジェクト項目の最大階層
    @api isSearchHide = false; // 検索非表示

    // ラベルマップ
    labels = {
        title: label_title
        , expression_field: label_expression_field
        , expression_operator: label_expression_operator
        , expression_value: label_expression_value
        , expression_delete: label_expression_delete
        , expression_add: label_expression_add
        , expression_allDelete: label_expression_allDelete
        , logic: label_logic
        , logic_help: label_logic_help
        , search: label_search
        , cancel: label_cancel
    };
    errorMessages = null; // エラーメッセージリスト
    @track searchConditions = [this.createSearchCondition(1)]; // 検索条件リスト
    searchConditionsSaved = []; // 保存済の検索条件リスト
    searchConditionLogic = null; // 検索条件ロジック
    searchConditionLogicSaved = null; // 保存済の検索条件ロジック
    searchConditionLogicErrMsg = null; // 検索条件ロジックエラーメッセージ

    // クリア
    @api
    clear() {
        this.searchConditions = [this.createSearchCondition(1)];
        this.searchConditionsSaved = [];
        this.searchConditionLogic = null;
        this.searchConditionLogicSaved = null;
        this.searchConditionLogicErrMsg = null;

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検証チェック
    @api
    async checkValidity() {
        let ret = false;
        this.errorMessages = null;
        try {
            // 検索条件のチェック
            const data = await checkSearchCondition({
                objectName: this.objectName
                , searchConditions: this.searchConditions
                , searchConditionLogic: this.searchConditionLogic
            });
            ret = data.result;
            this.searchConditions = data.searchConditions;
            this.searchConditionLogic = data.searchConditionLogic || null;
            this.searchConditionLogicErrMsg = data.searchConditionLogicErrMsg || null;

            // 編集イベントの発行
            this.issueEditEvent();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
        return ret;
    }

    // 保存する
    @api
    save() {
        // 検索条件の保存
        this.saveSearchCondition();
        return {
            data: {
                searchConditions: this.searchConditionsSaved
                , searchConditionLogic: this.searchConditionLogicSaved
            }
        };
    }

    // 復元する
    @api
    restore() {
        // 検索条件の復元
        this.restoreSearchCondition();

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 項目変更
    handleFieldChange(event) {
        const fieldName = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const searchCond = this.searchConditions[index];
        searchCond.fieldName = fieldName;
        searchCond.operator = null;
        searchCond.value = null;

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 演算子変更
    handleOperatorChange(event) {
        const operator = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const searchCond = this.searchConditions[index];
        searchCond.operator = operator;

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 値変更
    handleValueChange(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const searchCond = this.searchConditions[index];
        searchCond.value = value;

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検索条件削除クリック
    handleSearchConditionDeleteClick(event) {
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        this.searchConditions = this.deleteSearchCondition(this.searchConditions, index);

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検索条件追加クリック
    handleSearchConditionAddClick() {
        this.searchConditions.push(this.createSearchCondition(this.searchConditions.length + 1));

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検索条件全削除クリック
    handleSearchConditionAllDeleteClick() {
        this.searchConditions = [];

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検索条件ロジック変更
    handleSearchConditionLogicChange(event) {
        this.searchConditionLogic = event.target.value;

        // 編集イベントの発行
        this.issueEditEvent();
    }

    // 検索クリック
    async handleSearchClick() {
        // 検証チェック
        const result = await this.checkValidity();
        if (result) {
            // 検索条件の保存
            this.saveSearchCondition();

            // 検索イベント発行
            this.dispatchEvent(new CustomEvent('search', {
                detail: {
                    searchConditions: this.searchConditionsSaved
                    , searchConditionLogic: this.searchConditionLogicSaved
                }
            }));
        }
    }

    // キャンセルクリック
    handleCancelClick() {
        // 検索条件の復元
        this.restoreSearchCondition();

        // 編集イベントの発行
        this.issueEditEvent();

        // キャンセルイベント発行
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // 検索条件の設定
    setSearchCondition(data) {
        let searchConds = null;
        let searchCondLogic = null;
        if (data) {
            if(data.searchConds) {
                searchConds = data.searchConds;
            }
            if(data.searchCondLogic) {
                searchCondLogic = data.searchCondLogic;
            }
        }
        if (searchConds && searchConds.length > 0) {
            this.searchConditions = this.copySearchConditions(searchConds);
            this.searchConditionsSaved = this.copySearchConditions(searchConds);
            
        } else {
            this.searchConditions = [this.createSearchCondition(1)];
            this.searchConditionsSaved = [];
        }
        this.searchConditionLogic = searchCondLogic;
        this.searchConditionLogicSaved = searchCondLogic;
        this.searchConditionLogicErrMsg = null;
    }

    // 検索条件の保存
    saveSearchCondition() {
        if (this.searchConditions.length > 0) {
            this.searchConditionsSaved = this.copySearchConditions(this.searchConditions);
        } else {
            this.searchConditionsSaved = [];
            this.searchConditions = [this.createSearchCondition(1)];
        }
        this.searchConditionLogicSaved = this.searchConditionLogic;
        this.searchConditionLogicErrMsg = null;
    }

    // 検索条件の復元
    restoreSearchCondition() {
        if (this.searchConditionsSaved.length > 0) {
            this.searchConditions = this.copySearchConditions(this.searchConditionsSaved);
        } else {
            this.searchConditions = [this.createSearchCondition(1)];
        }
        this.searchConditionLogic = this.searchConditionLogicSaved;
        this.searchConditionLogicErrMsg = null;
    }

    // 検索条件の作成
    createSearchCondition(no) {
        return {
            no: no
            , fieldName: null
            , operator: null
            , value: null
            , errMsg: null
        };
    }

    // 検索条件リストのコピー
    copySearchConditions(searchConditions) {
        return searchConditions.map(sc => {
            return {
                no: sc.no
                , fieldName: sc.fieldName
                , operator: sc.operator
                , value: sc.value
                , errMsg: sc.errMsg
            };
        });
    }

    // 検索条件の削除
    deleteSearchCondition(searchConditions, index) {
        let cnt = 0;
        let no = 0;
        return searchConditions.filter(sc => {
            let ret = (cnt !== index);
            if (ret) {
                no++;
                sc.no = no;
            }
            cnt++;
            return ret;
        });
    }

    // 編集イベントの発行
    issueEditEvent() {
        // 編集イベント発行
        this.dispatchEvent(new CustomEvent('edit', {
            detail: {
                searchConditions: this.searchConditions
                , searchConditionLogic: this.searchConditionLogic
            }
        }));
    }
}