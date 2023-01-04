/**
 * レコード検索
 */
import { LightningElement, api } from 'lwc';
import GROUP_OBJECT from '@salesforce/schema/Group';
import RECORD_TYPE_OBJECT from '@salesforce/schema/RecordType';
import label_inputError_required from '@salesforce/label/c.InputError_Required';
import { getErrorMessages } from 'c/commonUtil';
import getRecord from '@salesforce/apex/RecordLookupCtlr.getRecord';
import getRecords from '@salesforce/apex/RecordLookupCtlr.getRecords';
import getGroupRecords from '@salesforce/apex/RecordLookupCtlr.getGroupRecords';
import getRecordTypeRecords from '@salesforce/apex/RecordLookupCtlr.getRecordTypeRecords';

export default class RecordLookup extends LightningElement {
    @api objectName = null; // オブジェクト名
    @api label = null; // 表示ラベル（コンポーネント）
    @api value = null; // 値（レコードID）
    @api required = false; // 必須
    @api groupTypes = null; // グループ種別リスト
    @api recordTypeObjectName = null; // レコードタイプのオブジェクト名
    backupObjectName = null; // バックアップオブジェクト名
    backupRecordId = null; // バックアップレコードID
    currentRecordId = null; // 現在のレコードID
    currentRecordName = null; // 現在のレコード名
    records = null; // レコードリスト
    errorMessages = null; // エラーメッセージリスト
    iconName = 'standard:record'; // アイコン
    isInitialized = false; // 初期化済
    isSearching = false; // 検索中
    hasInputFocus = false; // 入力フォーカス中
    hasDropdownMouseEnter = false; // ドロップダウンマウス領域対象中

    // 初期化処理
    get initializer() {
        if (this.isInitialized) {
            // 現在のレコードの初期化
            this.initCurrentRecord();
        }
        return '';
    }

    // 選択済
    get isSelected() {
        return !!this.currentRecordId;
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

    // 画面描画時
    renderedCallback() {
        if (!this.isInitialized) {
            this.isInitialized = true;
            // 現在のレコードの初期化
            this.initCurrentRecord();
        }
    }

    // 現在のレコードの初期化
    initCurrentRecord() {
        if (
            this.objectName !== this.backupObjectName ||
            this.value !== this.backupRecordId
        ) {
            this.backupObjectName = this.objectName;
            this.backupRecordId = this.value;
            this.errorMessages = null;
            // 現在のレコードの読込
            this.loadCurrentRecord();
        }
    }

    // 現在のレコードの読込
    async loadCurrentRecord() {
        try {
            this.currentRecordId = this.value || null;
            let rec = null;
            if (this.currentRecordId && this.objectName) {
                // レコードの取得
                rec = await getRecord({
                    objectName: this.objectName
                    , recordId: this.currentRecordId
                });
            }
            if (rec) {
                this.currentRecordName = rec.Name; 
            } else {
                this.currentRecordName = null;
            }
            // 入力の確定
            this.confirmInput();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // レコードリストの検索
    searchRecords() {
        if (this.isSearching) return;
        this.isSearching = true;
        if (this.objectName === GROUP_OBJECT.objectApiName) {
            // グループのレコードリストの取得
            getGroupRecords({
                objectName: this.objectName
                , recordName: this.currentRecordName
                , groupTypes: this.groupTypes
            }).then(data => {
                this.records = data || null;
                this.isSearching = false;
            }).catch(error => {
                this.errorMessages = getErrorMessages(error);
                this.isSearching = false;
            });
        } else if (this.objectName === RECORD_TYPE_OBJECT.objectApiName) {
            // レコードタイプのレコードリストの取得
            getRecordTypeRecords({
                objectName: this.objectName
                , recordName: this.currentRecordName
                , recordTypeObjectName: this.recordTypeObjectName
            }).then(data => {
                this.records = data || null;
                this.isSearching = false;
            }).catch(error => {
                this.errorMessages = getErrorMessages(error);
                this.isSearching = false;
            });
        } else {
            // レコードリストの取得
            getRecords({
                objectName: this.objectName
                , recordName: this.currentRecordName
            }).then(data => {
                this.records = data || null;
                this.isSearching = false;
            }).catch(error => {
                this.errorMessages = getErrorMessages(error);
                this.isSearching = false;
            });
        }
    }

    // 入力の確定
    confirmInput() {
        let elm = this.template.querySelector('[data-name="combobox-input"]');
        if (elm) {
            elm.value = this.currentRecordName || '';
            elm.title = elm.value;
        }
        elm = this.template.querySelector('[data-name="combobox-input-wrap"]');
        if (elm) {
            if (this.currentRecordId) {
                elm.classList.add('slds-input-has-icon_left-right');
                elm.classList.remove('slds-input-has-icon_right');
            } else {
                elm.classList.add('slds-input-has-icon_right');
                elm.classList.remove('slds-input-has-icon_left-right');
            }
        }
    }

    // ドロップダウンの表示
    showDropdown() {
        const elm = this.template.querySelector('[data-name="combobox"]');
        if (!elm.classList.contains('slds-is-open')) {
            elm.classList.add('slds-is-open');
            elm.setAttribute('aria-expanded', 'true');
        }
    }

    // ドロップダウンの非表示
    hideDropdown() {
        const elm = this.template.querySelector('[data-name="combobox"]');
        if (elm.classList.contains('slds-is-open')) {
            elm.classList.remove('slds-is-open');
            elm.setAttribute('aria-expanded', 'false');
        }
    }

    // 検証表示
    @api
    reportValidity() {
        this.errorMessages = null;
        if (this.required && !this.currentRecordId) {
            this.errorMessages = getErrorMessages(label_inputError_required);
        }
    }

    // 検証チェック
    @api
    checkValidity() {
        if (this.required && !this.currentRecordId) {
            return false;
        }
        return true;
    }

    // 選択クリアクリック
    handleSelectionClearClick() {
        this.currentRecordId = null;
        this.currentRecordName = null;
        this.records = null;

        // 入力の確定
        this.confirmInput();

        // ドロップダウンの非表示
        this.hideDropdown();

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.currentRecordId
                , label: this.currentRecordName
            }
        }));

        // 入力フォーカスセット
        const elm = this.template.querySelector('[data-name="combobox-input"]');
        elm.focus();
    }

    // 入力キー押上
    handleInputKeyup(event) {
        this.currentRecordName = event.target.value;

        if (!this.isSelected) {
            // レコードリストの検索
            this.searchRecords();

            // ドロップダウンの表示
            this.showDropdown();
        }
    }

    // 入力フォーカス
    handleInputFocus() {
        this.hasInputFocus = true;

        if (!this.isSelected) {
            // レコードリストの検索
            this.searchRecords();

            // ドロップダウンの表示
            this.showDropdown();
        }
    }

    // 入力フォーカス消失
    handleInputBlur() {
        this.hasInputFocus = false;

        if (!this.hasInputFocus && !this.hasDropdownMouseEnter) {
            // ドロップダウンの非表示
            this.hideDropdown();
        }
    }

    // ドロップダウンマウス領域対象
    handleDropdownMouseEnter() {
        this.hasDropdownMouseEnter = true;
    }

    // ドロップダウンマウス領域対象外
    handleDropdownMouseLeave() {
        this.hasDropdownMouseEnter = false;

        if (!this.hasInputFocus && !this.hasDropdownMouseEnter) {
            // ドロップダウンの非表示
            this.hideDropdown();
        }
    }

    // オプションクリック
    handleOptionClick(event) {
        this.currentRecordId = event.currentTarget.dataset.value;
        this.currentRecordName = event.currentTarget.dataset.text;
        this.records = null;
        this.hasDropdownMouseEnter = false;

        // 入力の確定
        this.confirmInput();

        // ドロップダウンの非表示
        this.hideDropdown();

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.currentRecordId
                , label: this.currentRecordName
            }
        }));
    }
}