// リスク分類（階層）コンボボックス
import { LightningElement, api } from 'lwc';
import label_inputError_required from '@salesforce/label/c.InputError_Required';
import label_inputError_selectMaxOver from '@salesforce/label/c.InputError_SelectMaxOver';
import {
    getErrorMessages
} from 'c/commonUtil';
import getClassiGroupLabel from '@salesforce/apex/RiskClassiOutputCtlr.getClassiGroupLabel';
import getKindSels from '@salesforce/apex/RiskClassiComboboxCtlr.getKindSels';
import getClassis from '@salesforce/apex/RiskClassiComboboxCtlr.getClassis';

const KIND_ID_PREFIX = 'kind_'; // 種別IDの接頭辞

export default class RiskClassiLevelCombobox extends LightningElement {
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
        // 種別IDを除去
        return this.removeKindId(this.classiIds);
    }
    set value(value) {
        // value(配列)の参照に要素を追加すると、
        // 外のコンポーネントに影響が有るため、valueをコピーして保持すること。
        // 種別IDを追加
        this.classiIds = this.appendKindId(this.classiTreeData, (value || []));

        // 分類ラベルリストの取得
        const classiLabels = this.getClassiLabels(this.classiTreeData, this.classiIds);
        this.classiLabel = classiLabels.join();

        // 入力値のセット
        this.setInputValue(this.classiLabel);
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
    hasInputFocus = false; // 入力フォーカス中
    hasDropdownMouseEnter = false; // ドロップダウンマウス領域対象中

    // 分類ツリー列リスト
    get classiTreeColumns() {
        return [
            {
                type: 'text'
                , fieldName: 'label'
                , label: this.label
            }
        ];
    }
    classiTreeData = null; // 分類ツリーデータ

    // 選択済
    get isSelected() {
        return (this.value.length > 0);
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

    // 入力フォーカス時
    handleInputFocus() {
        this.hasInputFocus = true;
    }

    // 入力フォーカス消失時
    handleInputBlur() {
        this.hasInputFocus = false;
        if (!this.hasInputFocus && !this.hasDropdownMouseEnter) {
            // ドロップダウンの非表示
            this.isDropdownShow = false;
        }
    }

    // 入力クリック時
    handleInputClick() {
        this.isDropdownShow = !this.isDropdownShow;
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
            this.isDropdownShow = false;
        }
    }

    // 分類ツリーの行選択時
    async handleClassiTreeRowSelection() {
        const cmp = this.template.querySelector('[data-name="classi-tree"]');
        const selectedRows = cmp.getSelectedRows();
        const selectedClassiIds = selectedRows.map(classi => classi.id);
        const classiIds = [...this.classiIds];
        // 子の分類IDを選択・解除
        this.selectChildClassiId(classiIds, this.classiTreeData, selectedClassiIds);
        // 分類IDリストのセット
        this.classiIds = classiIds;
        // 分類ラベルリストの取得
        const classiLabels = this.getClassiLabels(this.classiTreeData, this.classiIds);
        this.classiLabel = classiLabels.join();
        // 入力値のセット
        this.setInputValue(this.classiLabel);
        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
                , label: classiLabels
            }
        }));
    }

    // 分類ツリーのトグル時
    handleClassiTreeToggle(event) {
        const targetClassiId = event.detail.name;
        this.classiIds = [...this.classiIds]; // ツリーの選択を更新するため、再セット

        // 分類の検索
        const classi = this.searchClassi(this.classiTreeData, targetClassiId);
        if (classi && classi._children) {
            classi._children.forEach(childClassi => {
                childClassi.isShow = event.detail.isExpanded;
            });
        }
    }

    // 分類ツリーデータの取得
    async getClassiTreeData() {
        const ret = [];
        if (!this.classiGroupId) return ret;

        // 種別選択リストの取得
        const kindSels = await getKindSels({
            classiGroupId: this.classiGroupId
            , isOptionsBlankAdd: false
        });

        // 分類ツリーの第1階層に種別を追加
        kindSels.forEach(kindSel => {
            ret.push({
                id: KIND_ID_PREFIX + kindSel.value
                , label: kindSel.label
                , isKind: true
                , isShow: true
                , _children: []
            });
        });

        // 分類リストの取得
        const classis = await getClassis({
            classiGroupId: this.classiGroupId
        });

        // 分類ツリーの第1階層または第2階層に分類を追加
        classis.forEach(classi => {
            // 親（種別）を検索
            let parent = null;
            if (classi.ermt__Kind__c) {
                for (let i = 0, len = ret.length; i < len; i++) {
                    const item = ret[i];
                    if (item.isKind) {
                        const kindId = KIND_ID_PREFIX + classi.ermt__Kind__c;
                        if (item.id === kindId) {
                            parent = item;
                            break;
                        }
                    }
                }
            }
            let label = '';
            if (classi.ermt__Label_Pick__c) {
                label = classi.ermt__Label_Pick__c;
            } else if (classi.ermt__Label__c) {
                label = classi.ermt__Label__c;
            }
            if (parent) {
                parent._children.push({
                    id: classi.Id
                    , label: label
                    , isKind: false
                    , isShow: false
                });
            } else {
                ret.push({
                    id: classi.Id
                    , label: label
                    , isKind: false
                    , isShow: true
                });
            }
        });
        return ret;
    }

    // 種別IDの除去
    removeKindId(classiIds) {
        return classiIds.filter(classiId => classiId.substr(0, KIND_ID_PREFIX.length) !== KIND_ID_PREFIX);
    }

    // 種別IDの追加
    appendKindId(classiTree, classiIds) {
        let ret = [...classiIds];
        if (classiTree && classiTree.length > 0 && classiIds.length > 0) {
            for (let i = 0, len = classiTree.length; i < len; i++) {
                const classi = classiTree[i];
                if (classi.isKind) {
                    let isAllSelected = true;
                    if (classi._children) {
                        for (let j = 0, len2 = classi._children.length; j < len2; j++) {
                            const classi2 = classi._children[j];
                            const index = classiIds.indexOf(classi2.id);
                            if (index < 0) {
                                isAllSelected = false;
                                break;
                            }
                        }
                    }
                    if (isAllSelected) {
                        ret.push(classi.id);
                    }
                }
            }
        }
        return ret;
    }

    // 分類ラベルリストの取得
    getClassiLabels(classiTree, classiIds) {
        let ret = [];
        if (classiTree && classiTree.length > 0 && classiIds.length > 0) {
            for (let i = 0, len = classiTree.length; i < len; i++) {
                const classi = classiTree[i];
                if (!classi.isKind) {
                    const index = classiIds.indexOf(classi.id);
                    if (index >= 0) {
                        ret.push(classi.label);
                        if (ret.length === classiIds.length) break;
                    }
                }
                if (classi._children) {
                    // 分類ラベルリストの取得
                    ret = ret.concat(this.getClassiLabels(classi._children, classiIds))
                }
            }
        }
        return ret;
    }

    // 分類の検索
    searchClassi(classiTree, classiId) {
        for (let i = 0, len = classiTree.length; i < len; i++) {
            const classi = classiTree[i];
            if (classi.id === classiId) {
                return classi;
            }
            if (classi._children) {
                // 分類の検索
                const childClassi = this.searchClassi(classi._children, classiId);
                if (childClassi) return childClassi;
            }
        }
        return null;
    }

    // 子の分類IDを選択・解除
    selectChildClassiId(classiIds, classiTree, selectedClassiIds) {
        for (let i = 0, len = classiTree.length; i < len; i++) {
            const classi = classiTree[i];
            if (classi.isShow) {
                const index = classiIds.indexOf(classi.id);
                const newIndex = selectedClassiIds.indexOf(classi.id);
                let isChanged = false;
                if (index < 0) {
                    // 行が選択された場合
                    if (newIndex >= 0) {
                        isChanged = true;
                        // 行の選択
                        classiIds.push(classi.id);
                        if (classi._children) {
                            // 子の分類IDを含める
                            this.includeChildClassiId(classiIds, classi._children);
                        }
                    }
                } else {
                    // 行が選択解除された場合
                    if (newIndex < 0) {
                        isChanged = true;
                        // 行の選択解除
                        classiIds.splice(index, 1);
                        if (classi._children) {
                            // 子の分類IDを除外
                            this.excludeChildClassiId(classiIds, classi._children);
                        }
                    }
                }
                if (!isChanged) {
                    if (classi._children) {
                        // 子の分類IDを選択・解除
                        this.selectChildClassiId(classiIds, classi._children, selectedClassiIds);
                    }
                }
            }
        }
    }

    // 子の分類IDを含める
    includeChildClassiId(classiIds, childClassi) {
        for (let i = 0, len = childClassi.length; i < len; i++) {
            const classi = childClassi[i];
            const index = classiIds.indexOf(classi.id);
            if (index < 0) classiIds.push(classi.id);
            if (classi._children) {
                this.includeChildClassiId(classiIds, classi._children);
            }
        }
    }

    // 子の分類IDを除外
    excludeChildClassiId(classiIds, childClassi) {
        for (let i = 0, len = childClassi.length; i < len; i++) {
            const classi = childClassi[i];
            const index = classiIds.indexOf(classi.id);
            if (index >= 0) classiIds.splice(index, 1);
            if (classi._children) {
                this.excludeChildClassiId(classiIds, classi._children);
            }
        }
    }

    // 分類グループの初期化
    async initClassiGroup() {
        // ドロップダウンの非表示
        this.isDropdownShow = false;
        this.label = null;
        this.classiTreeData = null;
        this.errorMessages = null;
        try {
            if (this.classiGroupId) {
                // 分類・評価軸のグループラベルの取得
                this.label = await getClassiGroupLabel({
                    classiGroupId: this.classiGroupId
                });
            }

            // 分類ツリーデータの取得
            this.classiTreeData = await this.getClassiTreeData();

            // 種別IDを除去
            const classiIds = this.removeKindId(this.classiIds);
    
            // 種別IDを追加
            this.classiIds = this.appendKindId(this.classiTreeData, classiIds);

            // 分類ラベルリストの取得
            const classiLabels = this.getClassiLabels(this.classiTreeData, this.classiIds);
            this.classiLabel = classiLabels.join();

            // 入力値のセット
            this.setInputValue(this.classiLabel);
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
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
        const elm = this.template.querySelector('[data-name="combobox"]');
        if (elm) {
            if (!elm.classList.contains('is-open')) {
                elm.classList.add('is-open');
                elm.setAttribute('aria-expanded', 'true');
            }
        }
    }

    // ドロップダウンの非表示
    hideDropdown() {
        const elm = this.template.querySelector('[data-name="combobox"]');
        if (elm) {
            if (elm.classList.contains('is-open')) {
                elm.classList.remove('is-open');
                elm.setAttribute('aria-expanded', 'false');
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