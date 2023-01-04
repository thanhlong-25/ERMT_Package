import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getErrorMessages } from 'c/commonUtil';
import getLabelMap from '@salesforce/apex/RiskUnlockCtlr.getLabelMap';
import updateRisk from '@salesforce/apex/RiskUnlockCtlr.updateRisk';

export default class RiskUnlock extends LightningElement {
    @api recordId; // レコードID
    label = null; // ラベル
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中

    // 初期化済み
    get isInitialized() {
        return !!this.label;
    }

    // 初期化処理
    connectedCallback() {
        // ラベルの読込み
        this.loadLabel();
    }

    // 保存のクリック時
    handleSaveClick() {
        // リスクのロック解除
        this.unlockRisk();
    }

    // キャンセルのクリック時
    handleCancelClick() {
        // クローズの実行
        this.execClose(false);
    }

    // エラーの閉じるのクリック時
    handleErrorClose() {
        this.errorMessages = null;
    }

    // ラベルの読込み
    loadLabel() {
        // ラベルマップの取得
        getLabelMap().then(data => {
            this.label = data;
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // リスクのロック解除
    async unlockRisk() {
        try {
            this.isProcessing = true;
            let lastRiskId = null;
            let result;
            do {
                // リスクの更新
                result = await updateRisk({
                    projectId: this.recordId
                    , previousLastRiskId: lastRiskId
                });
                lastRiskId = result.lastRiskId || null;
            } while (!result.isDone);
            this.isProcessing = false;
            // トーストの表示
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.save_success_title
                    , message: this.label.save_success_content
                    , variant: 'success'
                })
            );
            // クローズの実行
            this.execClose(true);
        } catch (error) {
            this.isProcessing = false;
            this.errorMessages = getErrorMessages(error);
            // トーストの表示
            if (this.errorMessages && this.errorMessages.length) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.save_error_title
                        , message: this.errorMessages[0]
                        , variant: 'error'
                    })
                );
            }
        }
    }

    // クローズの実行
    execClose(isSaved) {
        const event = new CustomEvent('close', {
            detail: { isSaved: isSaved }
        });
        this.dispatchEvent(event);
    }
}