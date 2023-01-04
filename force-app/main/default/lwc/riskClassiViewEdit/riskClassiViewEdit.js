// リスク分類の参照・編集
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getErrorMessages, undefineToNull } from 'c/commonUtil';
import label_title from '@salesforce/label/c.RiskClassiViewEdit_Title';
import label_edit from '@salesforce/label/c.RiskClassiViewEdit_Edit';
import label_save from '@salesforce/label/c.Action_Save';
import label_cancel from '@salesforce/label/c.Action_Cancel';
import label_save_Success_title from '@salesforce/label/c.RiskClassiViewEdit_Save_Success_Title';
import label_save_Success_content from '@salesforce/label/c.RiskClassiViewEdit_Save_Success_Content';
import getProjectId from '@salesforce/apex/RiskClassiViewEditCtlr.getProjectId';
import getClassiGroupInfos from '@salesforce/apex/RiskClassiViewEditCtlr.getClassiGroupInfos';
import getClassiIds from '@salesforce/apex/RiskClassiViewEditCtlr.getClassiIds';
import updateRiskClassi from '@salesforce/apex/RiskClassiViewEditCtlr.updateRiskClassi';

export default class RiskClassiViewEdit extends LightningElement {
    @api recordId; // レコードID（リスクID）
    @api isReadOnly = false; // 参照のみ
    @api isTitleVisible = false; // タイトルの表示
    @api columnsNumber = 1; // レイアウトの列数

    // ラベル情報
    labelInfo = {
        title: label_title
        , edit: label_edit
        , save: label_save
        , cancel: label_cancel
    };
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中
    isEditing = false; // 編集中
    projectId = null; // プロジェクトID
    classiGroups = []; // 分類グループリスト
    // 分類ラップクラス
    get classiWrapClass() {
        return 'slds-col slds-size_1-of-' + this.columnsNumber;
    }

    // 初期化処理
    async connectedCallback() {
        this.isProcessing = true;
        try {
            // プロジェクトIDの取得
            this.projectId = await getProjectId({
                riskId: this.recordId
            });

            // 分類グループリストの取得
            this.classiGroups = await this.getClassiGroups();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
        this.isProcessing = false;
    }

    // エラーの閉じるのクリック時
    handleErrorClose() {
        this.errorMessages = null;
    }

    // 編集クリック時
    handleEditClick() {
        const isEditing = !this.isEditing;
        if (!isEditing) {
            // リスク分類IDを戻す
            this.restoreClassiId();
        }
        this.isEditing = isEditing;
    }

    // リスク分類の変更時
    handleRiskClassiChange(event) {
        const index = parseInt(event.target.dataset.index);
        const classiGroup = this.classiGroups[index];
        classiGroup.classiIds = event.detail.value;
    }

    // 保存のクリック時
    async handleSaveClick() {
        // 入力チェック
        if (!this.checkInput()) return;

        this.errorMessages = null;
        this.isProcessing = true;
        try {
            // リスク分類の保存
            await this.saveRiskClassi();

            // 編集中の解除
            this.isEditing = false;

            // トーストの表示
            this.dispatchEvent(
                new ShowToastEvent({
                    title: label_save_Success_title
                    , message: label_save_Success_content
                    , variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
        this.isProcessing = false;
    }

    // キャンセルのクリック時
    handleCancelClick() {
        // リスク分類IDを戻す
        this.restoreClassiId();
        this.isEditing = false;
    }

    // 分類グループリストの取得
    async getClassiGroups() {
        // 分類グループIDリストの取得
        const infos = await getClassiGroupInfos({
            projectId: this.projectId
        });
        // 分類グループリストの作成
        const ret = [];
        for (let i = 0, len = infos.length; i < len; i++) {
            const info = infos[i];

            // 分類IDリストの取得
            const classiIds = await getClassiIds({
                riskId: this.recordId
                , classiGroupId: info.classiGroupId
            });
            const inputType = undefineToNull(info.inputType);
            ret.push({
                index: i
                , classiGroupId: info.classiGroupId
                , isEditable: info.isEditable
                , selectMax: undefineToNull(info.selectMax)
                , isInputType1: (inputType === 1)
                , isInputType2: (inputType === 2)
                , classiIds: classiIds
                , oldClassiIds: classiIds
            });
        }
        return ret;
    }

    // 入力チェック
    checkInput() {
        let ret = true;
        let inputErrCmp = null;
        // リスク分類の検証
        ret = [...this.template.querySelectorAll('c-risk-classi-combobox,c-risk-classi-level-combobox')]
            .reduce((isValidSoFar, inputCmp) => {
                inputCmp.reportValidity();
                const isValid = inputCmp.checkValidity();
                if (!isValid && !inputErrCmp) inputErrCmp = inputCmp;
                return isValidSoFar && isValid;
            }
            , ret
        );
        if (inputErrCmp) inputErrCmp.focus();
        return ret;
    }

    // リスク分類の保存
    async saveRiskClassi() {
        // リスク分類グループリストのループ
        for (let i = 0, len = this.classiGroups.length; i < len; i++) {
            const classiGroup = this.classiGroups[i];
            // 変更が有る場合のみ、更新
            if (JSON.stringify(classiGroup.classiIds) !== JSON.stringify(classiGroup.oldClassiIds)) {
                // リスク分類の更新
                await updateRiskClassi({
                    riskId: this.recordId
                    , classiGroupId: classiGroup.classiGroupId
                    , classiIds: classiGroup.classiIds
                });
            }
        }

        // リスク分類IDの保存
        this.storeClassiId();
    }

    // リスク分類IDの保存
    storeClassiId() {
        this.classiGroups.forEach(classiGroup => {
            classiGroup.oldClassiIds = classiGroup.classiIds;
        });
    }

    // リスク分類IDを戻す
    restoreClassiId() {
        this.classiGroups.forEach(classiGroup => {
            classiGroup.classiIds = classiGroup.oldClassiIds;
        });
    }
}