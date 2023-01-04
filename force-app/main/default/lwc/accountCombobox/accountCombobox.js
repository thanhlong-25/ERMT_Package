// 組織・部門コンボボックス
import { LightningElement, api } from 'lwc';
import label_account from '@salesforce/label/c.ObjectLabel_Account';
import label_inputError_required from '@salesforce/label/c.InputError_Required';
import {
    getErrorMessages
    , undefineToNull
} from 'c/commonUtil';
import getAccounts from '@salesforce/apex/AccountComboboxCtlr.getAccounts';

export default class AccountCombobox extends LightningElement {
    @api label = null; // 表示ラベル

    // 値（組織・部門IDリスト）
    @api
    get value() {
        return this.accountIds;
    }
    set value(value) {
        this.accountIds = (!value ? [] : [...value]);

        // 組織・部門名リストの取得
        const accountNames = this.getAccountNames(this.accountTreeData, this.accountIds)
        this.accountName = accountNames.join();

        // 入力値のセット
        this.setInputValue(this.accountName);
    }
    accountIds = []; // 組織・部門IDリスト
    accountName = null; // 組織・部門名
    @api required = false; // 必須
    @api isInitInputCheck = false; // 初期化時入力チェック
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

    // 組織・部門ツリー列リスト
    get accountTreeColumns() {
        return [
            {
                type: 'text'
                , fieldName: 'name'
                , label: label_account
            }
        ];
    }
    accountTreeData = null; // 組織・部門ツリーデータ
    
    // 選択済
    get isSelected() {
        return (this.value.length > 0);
    }

    // 初期化時
    connectedCallback() {
        // 初期化処理
        this.initialize();

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
            this.setInputValue(this.accountName);
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

    // 組織・部門ツリーの行選択時
    handleAccountTreeRowSelection() {
        const cmp = this.template.querySelector('[data-name="account-tree"]');
        const selectedRows = cmp.getSelectedRows();
        const selectedAccountIds = selectedRows.map(account => account.id);
        const accountIds = [...this.accountIds];

        // 子の組織・部門IDを選択・解除
        this.selectChildAccountId(accountIds, this.accountTreeData, selectedAccountIds);

        // 組織・部門IDリストのセット
        this.accountIds = accountIds;

        // 組織・部門名リストの取得
        const accountNames = this.getAccountNames(this.accountTreeData, this.accountIds);
        this.accountName = accountNames.join();

        // 選択変更イベント発行
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                value: this.value
                , label: accountNames
            }
        }));
    }

    // 組織・部門ツリーのトグル時
    handleAccountTreeToggle(event) {
        const accountId = event.detail.name;
        this.accountIds = [...this.accountIds]; // ツリーグリッドの選択を更新するため、再セット

        // 組織・部門の検索
        const account = this.searchAccount(this.accountTreeData, accountId);
        if (account && account._children) {
            account._children.forEach(childAccount => {
                childAccount.isShow = event.detail.isExpanded;
            });
        }
    }

    // 組織・部門ツリーデータの取得
    async getAccountTreeData() {
        // 組織・部門リストの取得
        let accounts = await getAccounts();

        // 組織・部門ツリーの作成
        accounts = accounts.map(account => {
            return {
                id: account.Id
                , name: account.Name
                , parentId: undefineToNull(account.ParentId)
                , isShow: !account.ParentId
            };
        });

        // 組織・部門リストの階層化
        if (accounts.length > 0) {
            let index = 0;
            while (index < accounts.length) {
                const account = accounts[index];
                if (account.parentId) {
                    accounts.splice(index, 1);

                    // 組織・部門の親の子供に追加
                    this.addAccountParentChild(accounts, account);
                } else {
                    index++;
                }
            }
        }
        return accounts;
    }

    // 組織・部門の親の子供に追加
    addAccountParentChild(accounts, childAccount) {
        for (let i = 0, len = accounts.length; i < len; i++) {
            const account = accounts[i];
            if (account.id === childAccount.parentId) {
                account._children = account._children || [];
                account._children.push(childAccount);
                return true;
            }
            if (account._children) {
                if (this.addAccountParentChild(account._children, childAccount)) {
                    return true;
                }
            }
        }
        return false;
    }

    // 組織・部門名リストの取得
    getAccountNames(accounts, accountIds) {
        let ret = [];
        if (accounts && accounts.length > 0 && accountIds.length > 0) {
            for (let i = 0, len = accounts.length; i < len; i++) {
                const account = accounts[i];
                const index = accountIds.indexOf(account.id);
                if (index >= 0) {
                    ret.push(account.name);
                    if (ret.length === accountIds.length) break;
                }
                if (account._children) {
                    // 組織・部門名リストの取得
                    ret = ret.concat(this.getAccountNames(account._children, accountIds))
                }
            }
        }
        return ret;
    }

    // 組織・部門の検索
    searchAccount(accounts, accountId) {
        for (let i = 0, len = accounts.length; i < len; i++) {
            const account = accounts[i];
            if (account.id === accountId) {
                return account;
            }
            if (account._children) {
                // 組織・部門の検索
                const childAccount = this.searchAccount(account._children, accountId);
                if (childAccount) return childAccount;
            }
        }
        return null;
    }

    // 子の組織・部門IDを選択・解除
    selectChildAccountId(accountIds, accounts, selectedAccountIds) {
        for (let i = 0, len = accounts.length; i < len; i++) {
            const account = accounts[i];
            if (account.isShow) {
                const index = accountIds.indexOf(account.id);
                const newIndex = selectedAccountIds.indexOf(account.id);
                let isChanged = false;
                if (index < 0) {
                    // 行が選択された場合
                    if (newIndex >= 0) {
                        isChanged = true;
                        // 行の選択
                        accountIds.push(account.id);
                        if (account._children) {
                            // 子の組織・部門IDを含める
                            this.includeChildAccountId(accountIds, account._children);
                        }
                    }
                } else {
                    // 行が選択解除された場合
                    if (newIndex < 0) {
                        isChanged = true;
                        // 行の選択解除
                        accountIds.splice(index, 1);
                        if (account._children) {
                            // 子の組織・部門IDを除外
                            this.excludeChildAccountId(accountIds, account._children);
                        }
                    }
                }
                if (!isChanged) {
                    if (account._children) {
                        // 子の組織・部門IDを選択・解除
                        this.selectChildAccountId(accountIds, account._children, selectedAccountIds);
                    }
                }
            }
        }
    }

    // 子の組織・部門IDを含める
    includeChildAccountId(accountIds, childAccounts) {
        for (let i = 0, len = childAccounts.length; i < len; i++) {
            const account = childAccounts[i];
            const index = accountIds.indexOf(account.id);
            if (index < 0) accountIds.push(account.id);
            if (account._children) {
                this.includeChildAccountId(accountIds, account._children);
            }
        }
    }

    // 子の組織・部門IDを除外
    excludeChildAccountId(accountIds, childAccounts) {
        for (let i = 0, len = childAccounts.length; i < len; i++) {
            const account = childAccounts[i];
            const index = accountIds.indexOf(account.id);
            if (index >= 0) accountIds.splice(index, 1);
            if (account._children) {
                this.excludeChildAccountId(accountIds, account._children);
            }
        }
    }

    // 初期化処理
    async initialize() {
        // ドロップダウンの非表示
        this.isDropdownShow = false;
        this.accountTreeData = null;
        this.errorMessages = null;
        try {
            // 組織・部門ツリーデータの取得
            this.accountTreeData = await this.getAccountTreeData();

            // 組織・部門名リストの取得
            const accountNames = this.getAccountNames(this.accountTreeData, this.accountIds)
            this.accountName = accountNames.join();

            // 入力値のセット
            this.setInputValue(this.accountName);
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
        this.inputErrorMessages = null;
        if (this.required && !this.isSelected) {
            this.inputErrorMessages = getErrorMessages(label_inputError_required);
        }
    }

    // 検証チェック
    @api
    checkValidity() {
        if (this.required && !this.isSelected) {
            return false;
        }
        return true;
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