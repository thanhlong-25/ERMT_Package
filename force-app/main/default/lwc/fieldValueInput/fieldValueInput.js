import { LightningElement, api } from 'lwc';
import GROUP_OBJECT from '@salesforce/schema/Group';
import {
    getErrorMessages
    , undefineToNull
    , stringToNumber
    , TYPE_BOOLEAN
    , TYPE_DATE
    , TYPE_TIME
    , TYPE_DATETIME
    , TYPE_DOUBLE
    , TYPE_INTEGER
    , TYPE_LONG
    , TYPE_CURRENCY
    , TYPE_PERCENT
    , TYPE_PICKLIST
    , TYPE_MULTIPICKLIST
    , TYPE_TEXTAREA
    , TYPE_REFERENCE
} from 'c/commonUtil';
import getInputInfo from '@salesforce/apex/FieldValueInputCtlr.getInputInfo';

export default class FieldValueInput extends LightningElement {
    @api label = null; // 表示ラベル（コンポーネント）
    @api objectName = null; // オブジェクト名
    @api fieldName = null; // 項目名
    // 値
    @api
    get value() {
        switch (this.type) {
            case TYPE_BOOLEAN:
                return String(this._value);
        }
        return this._value;
    }
    set value(value) {
        this._value = value;

        // 親オブジェクト名の取得
        if (value) {
            this.parentObjectName = this.getParentObjectName();
        }
    }
    _value = null;
    @api required = false; // 必須
    errorMessages = null; // エラーメッセージリスト
    type = null; // データ型
    selectList = null; // 選択リスト
    parentObjectName = null; // 親オブジェクト名
    parentObjectNameSels = null; // 親オブジェクト名選択リスト
    // 親オブジェクトを選択するか
    get isParentObjectSelect() {
        return (this.parentObjectNameSels && this.parentObjectNameSels.length > 1)
    }
    // 初期化処理
    get initializer() {
        const key = (this.objectName || '') + ',' + (this.fieldName || '');
        if (key !== this.initializeKey) {
            this.initializeKey = key;
            // 初期化処理
            this.initialize();
        }
        return '';
    }
    initializeKey = null; // 初期化キー
    isInitialized = false; // 初期化済み
    // 親グループ種別リスト
    get parentGroupTypes() {
        let ret = null;
        if (this.parentObjectName === GROUP_OBJECT.objectApiName) {
            ret = [this.fieldName === 'OwnerId' ? 'Queue' : 'Regular'];
        }
        return ret;
    }
    get variant() { return (this.label ? 'standard' : 'label-hidden'); } // 入力フィールドの外観
    get isTypeBoolean() { return this.type === TYPE_BOOLEAN } // データ型が論理型か
    // データ型が十進型か
    get isTypeDecimal() {
        return (
            this.type === TYPE_INTEGER ||
            this.type === TYPE_LONG ||
            this.type === TYPE_DOUBLE
        );
    }
    get isTypeCurrency() { return this.type === TYPE_CURRENCY } // データ型が通貨型か
    get isTypePercent() { return this.type === TYPE_PERCENT } // データ型がパーセント型か
    get isTypeDate() { return this.type === TYPE_DATE } // データ型が日付型か
    get isTypeTime() { return this.type === TYPE_TIME } // データ型が時間型か
    get isTypeDatetime() { return this.type === TYPE_DATETIME } // データ型が日付時間型か
    get isTypePicklist() { return this.type === TYPE_PICKLIST } // データ型が択リスト型か
    get isTypeMultiPicklist() { return this.type === TYPE_MULTIPICKLIST } // データ型が複数選択リスト型か
    get isTypeTextarea() { return this.type === TYPE_TEXTAREA } // データ型がテキストエリア型か
    get isTypeReference() { return this.type === TYPE_REFERENCE } // データ型が参照型か
    // データ型がその他か
    get isTypeOther() {
        return (
            !this.isTypeBoolean &&
            !this.isTypeDecimal &&
            !this.isTypeCurrency &&
            !this.isTypePercent &&
            !this.isTypeDate &&
            !this.isTypeTime &&
            !this.isTypeDatetime &&
            !this.isTypePicklist &&
            !this.isTypeMultiPicklist &&
            !this.isTypeTextarea &&
            !this.isTypeReference
        );
    }

    // 初期化処理
    async initialize() {
        this.isInitialized = false;
        this.errorMessages = null;

        // 入力情報の読込み
        await this.loadInputInfo();

        this.isInitialized = true;
    }

    // 入力情報の読込み
    async loadInputInfo() {
        try {
            if (this.objectName && this.fieldName) {
                // 入力情報の取得
                const data = await getInputInfo({
                    objectName: this.objectName
                    , fieldName: this.fieldName
                });
                this.type = data.type;
                this.selectList = undefineToNull(data.selectList);
                this.parentObjectNameSels = undefineToNull(data.objectNameSels);

                // 親オブジェクト名の取得
                this.parentObjectName = this.getParentObjectName();
            } else {
                this.type = null;
                this.selectList = null;
                this.parentObjectName = null;
                this.parentObjectNameSels = null;
            }
        } catch (error) {
            this.type = null;
            this.selectList = null;
            this.parentObjectName = null;
            this.parentObjectNameSels = null;
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 親オブジェクト名の取得
    getParentObjectName() {
        let ret = null;
        if (this.parentObjectNameSels && this.parentObjectNameSels.length > 0) {
            ret = this.parentObjectNameSels[0].value;
            if (this.value && this.parentObjectNameSels.length > 1) {
                const value = this.value;
                for (let i = 0, len = this.parentObjectNameSels.length; i < len; i++) {
                    const sel = this.parentObjectNameSels[i];
                    if (value.startsWith(sel.keyPrefix)) {
                        ret = sel.value;
                        break;
                    }
                }
            }
        }
        return ret;
    }

    // 検証表示
    @api
    reportValidity() {
        [...this.template.querySelectorAll('[data-name="input"]')]
            .forEach(inputCmp => {
                inputCmp.reportValidity();
            });
    }

    // 検証チェック
    @api
    checkValidity() {
        let isValid = true;
        isValid = [...this.template.querySelectorAll('[data-name="input"]')]
            .reduce((isValidSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return isValidSoFar && inputCmp.checkValidity();
                }
                , isValid
            );
        return isValid;
    }

    // 変更
    handleChange(event) {
        this._value = event.detail.value;
        const label = undefineToNull(event.detail.label);

        // 入力変更イベント発行
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: {
                value: this.getValue(this.value, this.type)
                , label: this.getLabel(this.value, this.type, label, this.selectList)
            }
        }));
    }

    // 親オブジェクト名変更時
    handleParentObjectNameChange(event) {
        this.parentObjectName = event.detail.value;
        this._value = null;
        const label = null;

        // 入力変更イベント発行
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: {
                value: this.getValue(this.value, this.type)
                , label: this.getLabel(this.value, this.type, label, this.selectList)
            }
        }));
    }

    // 値の取得
    getValue(value, type) {
        switch (type) {
            case TYPE_BOOLEAN:
                return (value === String(true));
            case TYPE_DOUBLE:
            case TYPE_INTEGER:
            case TYPE_LONG:
            case TYPE_CURRENCY:
            case TYPE_PERCENT:
                return stringToNumber(value);
        }
        return value;
    }

    // ラベルの取得
    getLabel(value, type, label, selectList) {
        switch (type) {
            case TYPE_BOOLEAN:
            case TYPE_PICKLIST:
                if (value && selectList) {
                    for (let i = 0, len = selectList.length; i < len; i++) {
                        const item = selectList[i];
                        if (item.value === value) {
                            return item.label;
                        }
                    }
                }
                return null;
            case TYPE_MULTIPICKLIST:
                if (value && selectList) {
                    const labels = [];
                    value.forEach(v => {
                        for (let i = 0, len = selectList.length; i < len; i++) {
                            const item = selectList[i];
                            if (item.value === v) {
                                labels.push(item.label);
                                break;
                            }
                        }
                    });
                    return labels;
                }
                return null;
            case TYPE_REFERENCE:
                return label;
        }
        return null;
    }
}