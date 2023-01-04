// リスク分類（プロジェクト内）コンボボックス
import { LightningElement, api } from 'lwc';
import label_inputError_required from '@salesforce/label/c.InputError_Required';
import {
    getErrorMessages
} from 'c/commonUtil';
import getClassGroups from '@salesforce/apex/RiskClassProjectComboboxCtlr.getClassGroups';

export default class RiskClassProjectCombobox extends LightningElement {
    // プロジェクトID
    @api
    get projectId() {
        return this._projectId;
    }
    set projectId(value) {
        this._projectId = value;

        // 分類グループリストの読込み
        this.loadClassGroups();
    }
    _projectId = null; // プロジェクトID
    @api label = null; // 表示ラベル
    // 値（分類IDリスト）
    @api
    get value() {
        return this.classIds.concat();
    }
    set value(value) {
        this.classIds = (value ?? []).concat();

        // 分類ラベルリストの取得
        const classLabels = this.getClassLabels(this.classTreeData, this.classIds);
        this.classLabel = classLabels.join();

        // 入力値のセット
        this.setInputValue(this.classLabel);
    }

    classIds = []; // 分類IDリスト
    classLabel = null; // 分類表示ラベル
    @api required = false; // 必須
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
    get classTreeColumns() {
        return [
            {
                type: 'text'
                , fieldName: 'label'
                , label: this.label
            }
        ];
    }
    classTreeData = []; // 分類ツリーデータ

    // 選択済
    get isSelected() {
        return (this.value.length > 0);
    }

    // 画面描画時
    renderedCallback() {
        if (!this.isInitialized) {
            this.isInitialized = true;
            // 入力値のセット
            this.setInputValue(this.classLabel);
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
    async handleClassTreeRowSelection() {
        const cmp = this.template.querySelector('[data-name="class-tree"]');
        const selectedRows = cmp.getSelectedRows();
        const selectedClassIds = selectedRows.map(cls => cls.id);
        const classIds = this.classIds.concat();

        // 子の分類IDを選択・解除
        this.selectChildClassId(classIds, this.classTreeData, selectedClassIds);

        // 分類IDリストのセット
        this.classIds = classIds;

        // 分類ラベルリストの取得
        const classLabels = this.getClassLabels(this.classTreeData, this.classIds);
        this.classLabel = classLabels.join();

        // 入力値のセット
        this.setInputValue(this.classLabel);

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
                , label: classLabels
            }
        }));
    }

    // 分類ツリーのトグル時
    handleClassTreeToggle(event) {
        const targetClassId = event.detail.name;
        this.classIds = this.classIds.concat(); // ツリーの選択を更新するため、再セット

        // 分類の検索
        const cls = this.searchClass(this.classTreeData, targetClassId);
        if (cls && cls._children) {
            cls._children.forEach(childClass => {
                childClass.isShow = event.detail.isExpanded;
            });
        }
    }

    // 分類ツリーデータの作成
    async createClassTreeData(classGroups) {
        const classTreeData = [];
        classGroups.forEach(classGroup => {
            const {
                Id = null,
                ermt__Label_Pick__c = null,
                ermt__Label__c = null,
            } = classGroup;

            const children = [];
            classTreeData.push({
                id: Id,
                label: ermt__Label_Pick__c ?? ermt__Label__c,
                level: 1,
                isShow: true,
                _children: children,
            });
            
            const classes = classGroup.ermt__MClassifications_del__r;
            if (classes) {
                classes.forEach(cls => {
                    const {
                        Id = null,
                        ermt__Label_Pick__c = null,
                        ermt__Label__c = null,
                    } = cls;
                    children.push({
                        id: Id,
                        label: ermt__Label_Pick__c ?? ermt__Label__c,
                        level: 2,
                        isShow: false,
                    });
                });
            }
        });

        return classTreeData;
    }

    // 分類ラベルリストの取得
    getClassLabels(classTreeData, classIds) {
        let labels = [];
        if (classIds.length > 0) {
            for (let i = 0, len = classTreeData.length; i < len; i++) {
                const cls = classTreeData[i];
                const index = classIds.indexOf(cls.id);
                if (index >= 0) {
                    labels.push(cls.label);
                    if (labels.length === classIds.length) break;
                }
                if (cls._children) {
                    // 分類ラベルリストの取得
                    labels = labels.concat(this.getClassLabels(cls._children, classIds))
                }
            }
        }
        return labels;
    }

    // 分類の検索
    searchClass(classTreeData, classId) {
        for (let i = 0, len = classTreeData.length; i < len; i++) {
            const cls = classTreeData[i];
            if (cls.id === classId) {
                return cls;
            }
            if (cls._children) {
                // 分類の検索
                const childClass = this.searchClass(cls._children, classId);
                if (childClass) return childClass;
            }
        }
        return null;
    }

    // 子の分類IDを選択・解除
    selectChildClassId(classIds, classTreeData, selectedClassIds) {
        for (let i = 0, len = classTreeData.length; i < len; i++) {
            const cls = classTreeData[i];
            if (cls.isShow) {
                const index = classIds.indexOf(cls.id);
                const newIndex = selectedClassIds.indexOf(cls.id);
                let isChanged = false;
                if (index < 0) {
                    // 行が選択された場合
                    if (newIndex >= 0) {
                        isChanged = true;
                        // 行の選択
                        classIds.push(cls.id);
                        if (cls._children) {
                            // 子の分類IDを含める
                            this.includeChildClassId(classIds, cls._children);
                        }
                    }
                } else {
                    // 行が選択解除された場合
                    if (newIndex < 0) {
                        isChanged = true;
                        // 行の選択解除
                        classIds.splice(index, 1);
                        if (cls._children) {
                            // 子の分類IDを除外
                            this.excludeChildClassId(classIds, cls._children);
                        }
                    }
                }
                if (!isChanged) {
                    if (cls._children) {
                        // 子の分類IDを選択・解除
                        this.selectChildClassId(classIds, cls._children, selectedClassIds);
                    }
                }
            }
        }
    }

    // 子の分類IDを含める
    includeChildClassId(classIds, childClass) {
        for (let i = 0, len = childClass.length; i < len; i++) {
            const cls = childClass[i];
            const index = classIds.indexOf(cls.id);
            if (index < 0) classIds.push(cls.id);
            if (cls._children) {
                this.includeChildClassId(classIds, cls._children);
            }
        }
    }

    // 子の分類IDを除外
    excludeChildClassId(classIds, childClass) {
        for (let i = 0, len = childClass.length; i < len; i++) {
            const cls = childClass[i];
            const index = classIds.indexOf(cls.id);
            if (index >= 0) classIds.splice(index, 1);
            if (cls._children) {
                this.excludeChildClassId(classIds, cls._children);
            }
        }
    }

    // 分類グループリストの読込み
    async loadClassGroups() {
        // ドロップダウンの非表示
        this.isDropdownShow = false;
        
        try {
            this.errorMessages = null;

            let classTreeData = [];
            if (this.projectId) {
                // 分類グループリストの取得
                const classGroups = await getClassGroups({
                    projectId: this.projectId
                });

                // 分類ツリーデータの作成
                classTreeData = await this.createClassTreeData(classGroups);
            }
            this.classTreeData = classTreeData;

            // 分類ラベルリストの取得
            const classLabels = this.getClassLabels(this.classTreeData, this.classIds);
            this.classLabel = classLabels.join();

            // 入力値のセット
            this.setInputValue(this.classLabel);
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