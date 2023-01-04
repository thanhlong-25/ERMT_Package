// リスク分類コンボボックス
import { LightningElement, api } from 'lwc';
import label_kind_placeholder from '@salesforce/label/c.RiskClassiCombobox_Kind_Placeholder';
import label_inputError_required from '@salesforce/label/c.InputError_Required';
import label_inputError_selectMaxOver from '@salesforce/label/c.InputError_SelectMaxOver';
import {
    getErrorMessages
    , undefineToNull
} from 'c/commonUtil';
import getClassiGroupLabel from '@salesforce/apex/RiskClassiOutputCtlr.getClassiGroupLabel';
import getKindSels from '@salesforce/apex/RiskClassiComboboxCtlr.getKindSels';
import getClassis from '@salesforce/apex/RiskClassiComboboxCtlr.getClassis';

export default class RiskClassiCombobox extends LightningElement {
    // 分類グループID
    @api
    get classiGroupId() {
        return this._classiGroupId;
    }
    set classiGroupId(value) {
        this._classiGroupId = (value || []);

        // 分類グループの初期化
        this.initClassiGroup();
    }
    _classiGroupId = null; // 分類グループID

    // 値（分類IDリスト）
    @api
    get value() {
        return [...this.classiIds];
    }
    set value(value) {
        this.classiIds = [...(value || [])];
        
        // 値の初期化
        this.initValue();
    }
    classiIds = []; // 分類IDリスト
    classiLabel = null; // 分類表示ラベル
    @api isLabelHidden = false; // ラベル非表示
    label = null; // 表示ラベル
    @api isInitInputCheck = false; // 初期化時入力チェック
    @api required = false; // 必須
    @api max = null // 選択最大数
    errorMessages = null; // エラーメッセージリスト
    inputErrorMessages = null; // 入力エラーメッセージリスト
    isInitialized = false; // 初期化済
    isSearching = false; // 検索中
    
    // ラベル情報
    labelInfo = {
        kind_placeholder: label_kind_placeholder
    };

    // ドロップダウン表示
    get isDropdownShow() {
        return this._isDropdownShow;
    }
    set isDropdownShow(value) {
        this._isDropdownShow = value;
        if (this._isDropdownShow) {
            // ドロップダウンの表示
            this.showDropdown();
        } else {
            // ドロップダウンの非表示
            this.hideDropdown();
        }
    }
    _isDropdownShow = false; // ドロップダウン表示
    kindSels = null; // 種別選択リスト
    kind = null; // 種別

    // 分類列リスト
    get classiColumns() {
        return [
            {
                type: 'url'
                , fieldName: 'url'
                , label: this.label
                , typeAttributes: {
                    label: {
                        fieldName: 'label'
                    }
                    , tooltip: {
                        fieldName: 'tooltip'
                    }
                    , target: '_blank'
                }
            }
        ];
    }
    classiData = null; // 分類データ
    classiFilterData = null; // 分類絞込データ

    // 選択済
    get isSelected() {
        return (this.value.length > 0);
    }

    // 種別表示
    get isKindVisible() {
        return (this.kindSels && this.kindSels.length > 1);
    }

    // 分類リストボックススタイル
    get classiListboxStyle() {
        return (this.isKindVisible ? 'margin-top:2rem;' : 'margin-top:0;');
    }

    // 初期化時
    connectedCallback() {
        // 初期化時入力チェック
        if (this.isInitInputCheck) {
            // 検証表示
            this.reportValidity();
        }
    }

    // 画面描画時
    renderedCallback() {
        if (!this.isInitialized) {
            this.isInitialized = true;
            // 入力値のセット
            this.setInputValue(this.classiLabel);
        }
    }

    // 入力クリック時
    async handleInputClick() {
        this.errorMessages = null;
        try {
            if (this.isDropdownShow) {
                // ドロップダウンの非表示
                this.isDropdownShow = false;
            } else {
                this.isSearching = true;
                if (!this.kindSels) {
                    // 種別選択リストの取得
                    this.kindSels = await getKindSels({
                        classiGroupId: this.classiGroupId
                        , isOptionsBlankAdd: true
                    });
                }
                if (!this.classiFilterData) {
                    // 分類絞込データの取得
                    this.classiFilterData = await this.getClassiFilterData();
                    // 選択状態を更新するために、値を再セット
                    this.value = [...this.value];
                }
                this.isSearching = false;

                // ドロップダウンの表示
                this.isDropdownShow = true;
            }
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
            this.isSearching = false;
        }
    }

    // 種別変更時
    async handleKindChange(event) {
        this.kind = event.detail.value;
        this.errorMessages = null;
        try {
            // 分類絞込データの取得
            this.classiFilterData = await this.getClassiFilterData();
            // 選択状態を更新するために、値を再セット
            this.value = [...this.value];
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 分類データテーブルの行選択時
    async handleClassiRowSelection() {
        this.errorMessages = null;
        try {
            const cmp = this.template.querySelector('[data-name="classi-datatable"]');
            const selectedRows = cmp.getSelectedRows();
            const classiFilterIds = selectedRows.map(classi => classi.id);
            // 分類IDリストのマージ
            this.value = this.mergeClassiIds(this.value, classiFilterIds, this.classiFilterData);
            // 分類ラベルリストの取得
            const classiLabels = await this.getClassiLabels();
            // 選択変更イベント発行
            this.dispatchEvent(new CustomEvent('selectionchange', {
                detail: {
                    value: this.value
                    , label: classiLabels
                }
            }));
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 分類グループの初期化
    async initClassiGroup() {
        // ドロップダウンの非表示
        this.isDropdownShow = false;
        this.kind = null;
        this.kindSels = null;
        this.classiData = null;
        this.classiFilterData = null; 
        this.errorMessages = null;
        try {
            if (this.classiGroupId) {
                // 分類・評価軸のグループラベルの取得
                this.label = await getClassiGroupLabel({
                    classiGroupId: this.classiGroupId
                });
            } else {
                this.label = null;
            }
            // 値の初期化
            await this.initValue();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 値の初期化
    async initValue() {
        this.errorMessages = null;
        try {
            if (this.value.length > 0) {
                // 分類ラベルリストの取得
                const classiLabels = await this.getClassiLabels();
                this.classiLabel = classiLabels.join();
            } else {
                this.classiLabel = null;
            }
            // 入力値のセット
            this.setInputValue(this.classiLabel);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 分類データの取得
    async getClassiData() {
        if (!this.classiGroupId) return [];

        // 分類リストの取得
        let classis = await getClassis({
            classiGroupId: this.classiGroupId
        });
        return classis.map(classi => {
            let label = '';
            let tooltip = '';
            if (classi.ermt__Label_Pick__c) {
                label += classi.ermt__Label_Pick__c;
                tooltip += classi.ermt__Label_Pick__c;
            } else if (classi.ermt__Label__c) {
                label += classi.ermt__Label__c;
                tooltip += classi.ermt__Label__c;
            }
            if (classi.KindLabel) {
                tooltip += '(' + classi.KindLabel + ')';
            }
            return {
                id: classi.Id
                , url: '/' + classi.Id
                , label: label
                , tooltip: tooltip
                , kind: undefineToNull(classi.ermt__Kind__c)
            };
        });
    }

    // 分類絞込データの取得
    async getClassiFilterData() {
        if (!this.classiData) {
            // 分類データの取得
            this.classiData = await this.getClassiData();
        }
        return this.classiData.filter(classi => {
            return !this.kind || (this.kind && classi.kind === this.kind);
        });
    }

    // 分類IDリストのマージ
    mergeClassiIds(classiIds, classiFilterIds, classiFilterData) {
        const ret = classiIds;
        if (ret.length > 0 || classiFilterIds.length > 0) {
            for (let i = 0, len = classiFilterData.length; i < len; i++) {
                const classi = classiFilterData[i];
                let index = classiFilterIds.indexOf(classi.id);
                if (index < 0) {
                    index = ret.indexOf(classi.id);
                    if (index >= 0) {
                        ret.splice(index, 1);
                    }
                } else {
                    index = ret.indexOf(classi.id);
                    if (index < 0) {
                        ret.push(classi.id);
                    }
                }
            }
        }
        return ret;
    }

    // 分類表示ラベルリストの取得
    async getClassiLabels() {
        if (!this.classiData) {
            // 分類データの取得
            this.classiData = await this.getClassiData();
        }
        let ret = [];
        let cnt = this.value.length;
        if (cnt > 0) {
            for (let i = 0, len = this.classiData.length; i < len; i++) {
                const classi = this.classiData[i];
                const index = this.value.indexOf(classi.id);
                if (index >= 0) {
                    ret.push(classi.label);
                    cnt--;
                    if (cnt <= 0) break;
                }
            }
        }
        return ret;
    }

    // 入力値セット
    setInputValue(value) {
        const elm = this.template.querySelector('[data-name="combobox-input"]');
        if (elm) {
            elm.value = value || '';
            elm.title = value || '';
        }
    }

    // ドロップダウンの表示
    showDropdown() {
        let elm = this.template.querySelector('[data-name="combobox"]');
        if (elm) {
            if (!elm.classList.contains('is-open')) {
                elm.classList.add('is-open');
                elm.setAttribute('aria-expanded', 'true');
            }
        }
        elm = this.template.querySelector('[data-name="search-condition"]');
        if (elm) {
            if (elm.classList.contains('slds-hide')) {
                elm.classList.remove('slds-hide');
            }
        }
    }

    // ドロップダウンの非表示
    hideDropdown() {
        let elm = this.template.querySelector('[data-name="combobox"]');
        if (elm) {
            if (elm.classList.contains('is-open')) {
                elm.classList.remove('is-open');
                elm.setAttribute('aria-expanded', 'false');
            }
        }
        elm = this.template.querySelector('[data-name="search-condition"]');
        if (elm) {
            if (!elm.classList.contains('slds-hide')) {
                elm.classList.add('slds-hide');
            }
        }
    }

    // 検証表示
    @api
    reportValidity() {
        switch (this.checkInput()) {
            case 0:
                this.inputErrorMessages = null;
                break;
            case 1:
                this.inputErrorMessages = getErrorMessages(label_inputError_required);
                break;
            case 2:
                let msg = label_inputError_selectMaxOver;
                msg = msg.replace(/\{0\}/g, String(this.max));
                this.inputErrorMessages = getErrorMessages(msg);
                break;
        }
    }

    // 検証チェック
    @api
    checkValidity() {
        return (this.checkInput() === 0);
    }

    // 入力チェック
    checkInput() {
        if (this.required && !this.isSelected) {
            return 1;
        }
        if (this.max && this.max > 0 && this.max < this.value.length) {
            return 2;
        }
        return 0;
    }

    // フォーカスセット
    @api
    focus() {
        const elm = this.template.querySelector('[data-name="combobox-input"]');
        if (elm) {
            elm.focus();
        }
    }
}