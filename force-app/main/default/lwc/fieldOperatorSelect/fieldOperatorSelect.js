import { LightningElement, api, track } from 'lwc';
import { getErrorMessages } from 'c/commonUtil';
import getOperatorSels from '@salesforce/apex/FieldOperatorSelectCtlr.getOperatorSels';

export default class FieldOperatorSelect extends LightningElement {
    @api label = null; // 表示ラベル（コンポーネント）
    @api objectName = null; // オブジェクト名
    @api fieldName = null; // 項目名
    // オブジェクト項目名
    get objectFieldName() {
        const objectFieldName = (this.objectName || '') + ',' + (this.fieldName || '');
        if (objectFieldName !== this._objectFieldName) {
            this._objectFieldName = objectFieldName;
            this.errorMessages = null;

            // 演算子選択リストの読込み
            this.loadOperatorSels();
        }
        return this._objectFieldName;
    }
    _objectFieldName = null;
    @api value = null; // 値（演算子の値）
    @track errorMessages = null; // エラーメッセージリスト
    @track operatorSels = []; // 演算子選択リスト

    // 演算子選択リストの読込み
    loadOperatorSels() {
        if (this.objectName && this.fieldName) {
            // 演算子選択リストの取得
            getOperatorSels({
                objectName: this.objectName
                , fieldName: this.fieldName
            }).then(data => {
                this.operatorSels = data;
            }).catch(error => {
                this.operatorSels = [];
                this.errorMessages = getErrorMessages(error);
            });
        } else {
            this.operatorSels = [];
        }
    }

    // 変更
    handleChange(event) {
        this.value = event.detail.value;

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
            }
        }));
    }
}