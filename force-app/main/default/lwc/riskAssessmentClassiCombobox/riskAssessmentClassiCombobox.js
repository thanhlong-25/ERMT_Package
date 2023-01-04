// リスクアセスメント分類のコンボボックス
import { LightningElement, api } from 'lwc';
import { getErrorMessages } from 'c/commonUtil';
import getClassiSelsInfo from '@salesforce/apex/RiskAssessmentClassiComboboxCtlr.getClassiSelsInfo';

export default class RiskAssessmentClassiCombobox extends LightningElement {
    @api isLabelShow = false; // 表示ラベルを表示するか
    @api classiRecordTypeName = null; // 分類レコードタイプ名
    @api projectId = null; // プロジェクトID
    @api value = null; // 値
    @api required = false; // 必須
    errorMessages = null; // エラーメッセージリスト
    classiSelsInfo = null; // 分類選択リスト情報
    // 初期化処理
    get initializer() {
        const key = (this.projectId || '') + ',' + (this.classiRecordTypeName || '');
        if (key !== this.initializeKey) {
            this.initializeKey = key;
            // 初期化処理
            this.initialize();
        }
        return '';
    }
    initializeKey = null; // 初期化キー
    isInitialized = false; // 初期化済み
    get variant() { return (this.isLabelShow ? 'standard' : 'label-hidden'); } // 入力フィールドの外観
    
    // 初期化処理
    async initialize() {
        this.isInitialized = false;
        this.errorMessages = null;

        // 分類リスト情報の読込み
        await this.loadClassiSelsInfo();

        this.isInitialized = true;
    }

    // 分類リスト情報の読込み
    async loadClassiSelsInfo() {
        try {
            if (this.classiRecordTypeName) {
                // 分類リスト情報の取得
                const info = await getClassiSelsInfo({
                    classiGroupRecordTypeName: this.classiRecordTypeName
                    , projectId: this.projectId
                    , isOptionsBlankAdd: true
                });
                this.classiSelsInfo = info;
            } else {
                this.classiSelsInfo = null;
            }
        } catch (error) {
            this.classiSelsInfo = null;
            this.errorMessages = getErrorMessages(error);
        }
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
        this.value = event.detail.value;
        const options = (!this.classiSelsInfo ? null : this.classiSelsInfo.options);
        
        // 入力変更イベント発行
        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: {
                value: this.value
                , label: this.getLabel(this.value, options)
            }
        }));
    }

    // ラベルの取得
    getLabel(value, options) {
        if (value && options) {
            for (let i = 0, len = options.length; i < len; i++) {
                const item = options[i];
                if (item.value === value) {
                    return item.label;
                }
            }
        }
        return null;
    }
}