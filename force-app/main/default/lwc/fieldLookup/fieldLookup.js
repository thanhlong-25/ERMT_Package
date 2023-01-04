import { LightningElement, api, track } from 'lwc';
import { getErrorMessages } from 'c/commonUtil';
import getFieldLabel from '@salesforce/apex/FieldLookupCtlr.getFieldLabel';
import getFieldSels from '@salesforce/apex/FieldLookupCtlr.getFieldSels';

const OPTION_MAX_SIZE = 100; // 選択リストの最大数

export default class FieldLookup extends LightningElement {
    @api label = null; // 表示ラベル（コンポーネント）
    // オブジェクト名
    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        this._objectName = value;
        this.errorMessages = null;
        
        // 項目選択リストの初期化
        this.initFieldSels();
    }
    _objectName = null;
    @api value = null; // 値（項目名）
    @api selectFieldNames = null; // 選択項目名リスト
    @api maxLevel = 2; // 検索親オブジェクト項目の最大階層
    @api isQuery = false; // クエリ用か
    @track fieldLabel = null; // 項目ラベル
    fieldLabelUpdated = false; // 項目ラベル更新済
    // オブジェクト項目名
    get objectFieldName() {
        const objectFieldName = (this.objectName || '') + ',' + (this.value || '');
        if (objectFieldName !== this._objectFieldName) {
            this._objectFieldName = objectFieldName;
            if (!this.fieldLabelUpdated) {
                // 項目ラベルの読込み
                this.loadFieldLabel();
            }
            this.fieldLabelUpdated = false;
        }
        return this._objectFieldName;
    }
    _objectFieldName = null;
    @track errorMessages = null; // エラーメッセージリスト
    fieldSels = null; // 項目選択リスト
    @track filterFieldSels = null; // 絞込み項目選択リスト
    fieldSelsLoading = false; // 項目選択リストのロード中
    @track hasInputFocus = false; // 入力フォーカス中
    @track hasDropdownMouseEnter = false; // ドロップダウンマウス領域対象中

    // 初期化処理
    connectedCallback() {
        // 項目選択リストの初期化
        this.initFieldSels();
    }

    // 項目選択リストの初期化
    initFieldSels() {
        this.fieldSels = null;
        this.filterFieldSels = [{label: '', value: ''}];
    }

    // 項目ラベルの読込み
    loadFieldLabel() {
        if (this.objectName && this.value) {
            // 項目ラベルの取得
            getFieldLabel({
                objectName: this.objectName
                , fieldName: this.value
            }).then(data => {
                this.fieldLabel = data;
            }).catch(error => {
                this.fieldLabel = null;
                this.errorMessages = getErrorMessages(error);
            });
        } else {
            this.fieldLabel = null;
        }
    }

    // 項目選択リストの読込み
    loadFieldSels(fieldLabel) {
        if (this.fieldSelsLoading) return;

        if (this.fieldSels) {
            // 絞込み項目リストの作成
            this.filterFieldSels = this.createFilterFieldSels(fieldLabel);
        } else {
            this.fieldSelsLoading = true;

            // 項目選択リストの取得
            getFieldSels({
                objectName: this.objectName
                , fieldNames: this.selectFieldNames
                , maxLevel: this.maxLevel
                , isQuery: this.isQuery
            }).then(data => {
                this.fieldSels = data;

                // 絞込み項目リストの作成
                this.filterFieldSels = this.createFilterFieldSels(fieldLabel);
                this.fieldSelsLoading = false;
            }).catch(error => {
                // 項目選択リストの初期化
                this.initFieldSels();
                this.errorMessages = getErrorMessages(error);
                this.fieldSelsLoading = false;
            });
        }
    }

    // 絞込み項目リストの作成
    createFilterFieldSels(fieldLabel) {
        let ret = [];
        if (this.fieldSels) {
            let cnt = 0;
            ret = this.fieldSels.filter(sel => {
                let ret = false;
                if (cnt <= OPTION_MAX_SIZE) {
                    if (sel.label) {
                        if (fieldLabel) {
                            if (sel.label.indexOf(fieldLabel) >= 0) {
                                ret = true;
                                cnt++;
                            }
                        } else {
                            ret = true;
                            cnt++;
                        }
                    }
                }
                return ret;
            });
        }
        return ret;
    }

    // 選択済
    get isSelected() {
        return !!this.value;
    }

    // 検索アイコンクラス
    get searchIconClass() {
        let ret = 'slds-input__icon slds-input__icon_right';
        if (this.isSelected) {
            ret += ' slds-hide';
        }
        return ret;
    }

    // 選択クリアボタンクラス
    get selectionClearButtonClass() {
        let ret = 'slds-button slds-button_icon slds-input__icon slds-input__icon_right';
        if (!this.isSelected) {
            ret += ' slds-hide';
        }
        return ret;
    }

    // ドロップダウン表示
    get isDropdownShow() {
        let ret = false;
        if (!this.isSelected) {
            ret = this.hasInputFocus || this.hasDropdownMouseEnter;
        }
        return ret;
    }

    // ドロップダウンクラス
    get dropdownClass() {
        let ret = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        if (this.isDropdownShow) {
            ret += ' slds-is-open';
        }
        return ret;
    }

    // 選択クリアクリック
    handleSelectionClearClick() {
        this.fieldLabel = null;
        this.fieldLabelUpdated = (this.value !== null);
        this.value = null;

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
            }
        }));

        // 入力フォーカスセット
        const elm = this.template.querySelector('input.fieldLabel');
        elm.focus();
    }

    // 入力キー押上
    handleInputKeyup(event) {
        this.fieldLabel = event.target.value;

        if (this.isDropdownShow) {
            // 項目選択リストの読込み
            this.loadFieldSels(this.fieldLabel);
        }
    }

    // 入力フォーカス
    handleInputFocus() {
        this.hasInputFocus = true;

        if (this.isDropdownShow) {
            // 項目選択リストの読込み
            this.loadFieldSels(this.fieldLabel);
        }
    }

    // 入力フォーカス消失
    handleInputBlur() {
        this.hasInputFocus = false;
    }

    // ドロップダウンマウス領域対象
    handleDropdownMouseEnter() {
        this.hasDropdownMouseEnter = true;
    }

    // ドロップダウンマウス領域対象外
    handleDropdownMouseLeave() {
        this.hasDropdownMouseEnter = false;
    }

    // オプションクリック
    handleOptionClick(event) {
        this.fieldLabel = event.currentTarget.dataset.label;
        this.fieldLabelUpdated = (this.value !== event.currentTarget.dataset.value);
        this.value = event.currentTarget.dataset.value;
        this.hasDropdownMouseEnter = false;

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
            }
        }));
    }
}