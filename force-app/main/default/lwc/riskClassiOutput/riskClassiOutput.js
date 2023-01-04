// リスク分類出力
import { LightningElement, api } from 'lwc';
import {
    getErrorMessages
} from 'c/commonUtil';
import getClassiGroupLabel from '@salesforce/apex/RiskClassiOutputCtlr.getClassiGroupLabel';
import getClassis from '@salesforce/apex/RiskClassiOutputCtlr.getClassis';

export default class RiskClassiOutput extends LightningElement {
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
        return this.classiIds;
    }
    set value(value) {
        this.classiIds = (value || []);
        
        // 値の初期化
        this.initValue();
    }
    classiIds = []; // 分類IDリスト
    classis = []; // 分類リスト
    @api isLabelHidden = false; // ラベル非表示
    label = null; // 表示ラベル
    errorMessages = null; // エラーメッセージリスト

    // 分類グループの初期化
    async initClassiGroup() {
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
            if (this.value.length === 0) {
                this.classis = [];
            } else {
                // 分類リストの取得
                this.classis = await this.getClassis();
            }
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 分類リストの取得
    async getClassis() {
        // 分類リストの取得
        const classis = await getClassis({
            classiIds: this.value
        });
        return classis.map(classi => {
            let label = '';
            let title = '';
            if (classi.ermt__Label_Pick__c) {
                label += classi.ermt__Label_Pick__c;
                title += classi.ermt__Label_Pick__c;
            } else if (classi.ermt__Label__c) {
                label += classi.ermt__Label__c;
                title += classi.ermt__Label__c;
            }
            if (classi.ermt__Kind__c) {
                title += '(' + classi.ermt__Kind__c + ')';
            }
            return {
                id: classi.Id
                , url: '/' + classi.Id
                , label: label
                , title: title
            };
        });
    }
}