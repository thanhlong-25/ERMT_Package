import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord  } from 'lightning/uiRecordApi';
import { getErrorMessages } from 'c/commonUtil';
import ID_FIELD from '@salesforce/schema/Project__c.Id';
import ANALYSE_TIMING_DEFAULT_FIELD from '@salesforce/schema/Project__c.AnalyseTimingDefault__c';
import getLabelMap from '@salesforce/apex/ProjectClassiDefaultEntryCtlr.getLabelMap';
import getClassiSelsInfo from '@salesforce/apex/ProjectClassiDefaultEntryCtlr.getClassiSelsInfo';

const CLASSI_RECORD_TYPE_ANALYSE_TIMING = 'EvaluationPeriodGroup'; // 分類・評価軸設定の分析タイミングのレコードタイプ

export default class ProjectClassiDefaultEntry extends LightningElement {
    @api recordId; // レコードID
    @track label = {}; // ラベル
    errorMessages = null; // エラーメッセージリスト
    // 分析タイミングの初期値
    @track analyseTimingDefault = {
        id: null
        , label: null
        , helpText: null
        , value: null
        , oldValue: null
        , options: null
    };
    isSaveShow = false; // 保存を表示するか

    // プロジェクトの取得
    @wire(getRecord, { recordId: '$recordId', fields: ANALYSE_TIMING_DEFAULT_FIELD })
    wiredProject({ error, data }) {
        if (data) {
            this.analyseTimingDefault.value = data.fields.ermt__AnalyseTimingDefault__c.value;
            this.analyseTimingDefault.oldValue = data.fields.ermt__AnalyseTimingDefault__c.value;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 初期化処理
    connectedCallback() {
        // ラベルの読込み
        this.loadLabel();

        // 分類・評価軸の選択リスト情報の読込み
        this.loadClassiSelsInfo();
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

    // 分類・評価軸の選択リスト情報の読込み
    loadClassiSelsInfo() {
        // 分類・評価軸の選択リスト情報の取得
        getClassiSelsInfo({
            projectId: this.recordId
            , classiGroupRecordTypeName: CLASSI_RECORD_TYPE_ANALYSE_TIMING
            , isOptionsBlankAdd: true
        }).then(data => {
            if (data.length > 0) {
                const rec = data[0];
                this.analyseTimingDefault.id = rec.id;
                this.analyseTimingDefault.label = rec.label;
                this.analyseTimingDefault.helpText = rec.helpText;
                this.analyseTimingDefault.options = rec.options;
            }
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });  
    }

    // エラーの閉じるのクリック時
    handleErrorClose() {
        this.errorMessages = null;
    }

    // 分析タイミングの初期値の変更時
    handleAnalyseTimingDefaultChange(event) {
        this.analyseTimingDefault.value = event.target.value;
        this.isSaveShow = true;
    }

    // 保存のクリック時
    handleSaveClick() {
        // プロジェクトの更新
        this.updateProject();
    }

    // キャンセルのクリック時
    handleCancelClick() {
        // プロジェクトの最新化
        this.refreshProject();
    }

    // プロジェクトの更新
    updateProject() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[ANALYSE_TIMING_DEFAULT_FIELD.fieldApiName] = this.analyseTimingDefault.value;
        
        const recordInput = {fields};

        // レコードの更新
        updateRecord(recordInput)
        .then(() => {
            this.analyseTimingDefault.oldValue = this.analyseTimingDefault.value;
            this.isSaveShow = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.save_success_title
                    , message: this.label.save_success_content
                    , variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.save_error_title
                    , message: error.body.message
                    , variant: 'error'
                })
            );
        });
    }

    // プロジェクトの最新化
    refreshProject() {
        this.analyseTimingDefault.value = this.analyseTimingDefault.oldValue;
        this.isSaveShow = false;
    }
}