import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { getErrorMessages } from 'c/commonUtil';
import PROJECT_ANALYSE_TIMING_DEFAULT_FIELD from '@salesforce/schema/Project__c.AnalyseTimingDefault__c';
import RISK_PROJECT_FIELD from '@salesforce/schema/Risk__c.Project__c';
import RISK_ASSESSMENT_OBJECT from '@salesforce/schema/RiskAssessment__c';
import RISK_ASSESSMENT_OWNER_FIELD from '@salesforce/schema/RiskAssessment__c.OwnerId';
import RISK_ASSESSMENT_RECORD_TYPE_FIELD from '@salesforce/schema/RiskAssessment__c.RecordTypeId';
import RISK_ASSESSMENT_RISK_FIELD from '@salesforce/schema/RiskAssessment__c.Risk__c';
import getLabelMap from '@salesforce/apex/RiskAnalysisNewCreateCtlr.getLabelMap';
import getSetting from '@salesforce/apex/RiskAnalysisNewCreateCtlr.getSetting';
import getRiskAssessRecTypeId from '@salesforce/apex/RiskAnalysisNewCreateCtlr.getRiskAssessRecTypeId';
import getRiskAssess from '@salesforce/apex/RiskAnalysisNewCreateCtlr.getRiskAssess';
import getClassiId from '@salesforce/apex/RiskAnalysisNewCreateCtlr.getClassiId';
import updateRiskAssessClassi from '@salesforce/apex/RiskAnalysisNewCreateCtlr.updateRiskAssessClassi';
import deleteRiskAssess from '@salesforce/apex/RiskAnalysisNewCreateCtlr.deleteRiskAssess';
import getClassiSelsInfo from '@salesforce/apex/RiskAssessmentClassiComboboxCtlr.getClassiSelsInfo';

const RISK_ASSESS_RECORD_TYPE_ANALYSE = 'Analysis'; // リスクアセスメントの分析のレコードタイプ
const CLASSI_RECORD_TYPE_ANALYSE_TIMING = 'EvaluationPeriodGroup'; // 分類・評価軸設定の分析タイミング軸のレコードタイプ
const CLASSI_RECORD_TYPE_PROBABILITY = 'LikelihoodGroup'; // 分類・評価軸設定の発生可能性軸のレコードタイプ
const CLASSI_RECORD_TYPE_RESULT_IMPACT = 'ConsequenceGroup'; // 分類・評価軸設定の結果の影響度軸のレコードタイプ
const CLASSI_RECORD_TYPE_THIRD_EVALUATION = 'SeverityRiskLevelGroup'; // 分類・評価軸設定の第三評価軸のレコードタイプ

export default class RiskAnalysisNewCreate extends NavigationMixin(LightningElement) {
    @api recordId; // レコードID
    @api copySourceRiskAssessId = null; // コピー元のリスクアセスメントID
    label = null; // ラベル
    errorMessages = null; // エラーメッセージリスト
    get riskAssessObjName() { return RISK_ASSESSMENT_OBJECT; } // リスクアセスメントオブジェクト名
    projectId = null; // プロジェクトID
    riskAssessRecTypeId = null; // リスクアセスメントのレコードタイプID
    riskAssess = null; // リスクアセスメント
    riskAssessRecInfo = null; // リスクアセスメントのレコード情報
    _riskAssessNewCreateLayout = null // リスクアセスメントの新規作成レイアウト
    processing = false; // 処理中

    // 分析タイミング
    @track analyseTiming = {
        id: null
        , label: null
        , helpText: null
        , value: null
        , options: null
        , orderNo: 1
    };
    // 発生可能性
    @track probability = {
        id: null
        , label: null
        , helpText: null
        , value: null
        , options: null
        , orderNo: 2
    };
    // 結果の影響度
    @track resultImpact = {
        id: null
        , label: null
        , helpText: null
        , value: null
        , options: null
        , orderNo: 3
    };
    // 第三評価
    @track thirdEvaluation = {
        id: null
        , label: null
        , helpText: null
        , value: null
        , options: null
        , orderNo: 4
    };

    // 初期化済み
    get isInitialized() {
        return !!(this.label && this.riskAssessNewCreateLayout);
    }

    // リスクアセスメントレコード情報の取得
    @wire(getRecordCreateDefaults, { objectApiName: RISK_ASSESSMENT_OBJECT, recordTypeId: '$riskAssessRecTypeId' })
    wiredRiskAssessRecInfo({ error, data }) {
        if (data) {
            if (this.riskAssessRecTypeId === data.record.recordTypeId) {
                this.riskAssessRecInfo = data;
            }
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // プロジェクトの取得
    @wire(getRecord, { recordId: '$projectId', fields: PROJECT_ANALYSE_TIMING_DEFAULT_FIELD })
    wiredProject({ error, data }) {
        if (data) {
            const value = data.fields.ermt__AnalyseTimingDefault__c.value;
            if (value) {
                this.analyseTiming.value = value;
            }
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスクの取得
    @wire(getRecord, { recordId: '$recordId', fields: RISK_PROJECT_FIELD })
    wiredRisk({ error, data }) {
        if (data) {
            this.projectId = data.fields.ermt__Project__c.value;

            // 分類・評価軸の選択リスト情報の読込み
            this.loadClassiSelsInfo(this.projectId, CLASSI_RECORD_TYPE_ANALYSE_TIMING, this.analyseTiming);
            this.loadClassiSelsInfo(this.projectId, CLASSI_RECORD_TYPE_PROBABILITY, this.probability);
            this.loadClassiSelsInfo(this.projectId, CLASSI_RECORD_TYPE_RESULT_IMPACT, this.resultImpact);
            this.loadClassiSelsInfo(this.projectId, CLASSI_RECORD_TYPE_THIRD_EVALUATION, this.thirdEvaluation);
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 初期化処理
    connectedCallback() {
        // ラベルの読込み
        this.loadLabel();

        // 設定の読込み
        this.loadSetting();

        // リスクアセスメントのレコードタイプの読込み
        this.loadRiskAssessRecTypeId();

        // コピーする場合
        if (this.copySourceRiskAssessId) {
            // リスクアセスメントの読込み
            this.loadRiskAssess();
        }
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

    // 設定の読込み
    loadSetting() {
        // 設定の取得
        getSetting().then(data => {
            this.analyseTiming.orderNo = data.analyseTimingDispOrder;
            this.probability.orderNo = data.probabilityDispOrder;
            this.resultImpact.orderNo = data.resultImpactDispOrder;
            this.thirdEvaluation.orderNo = data.thirdEvaluationDispOrder;
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // リスクアセスメントのレコードタイプの読込み
    loadRiskAssessRecTypeId() {
        // リスクアセスメントのレコードタイプの取得
        getRiskAssessRecTypeId({
            recTypeName: RISK_ASSESS_RECORD_TYPE_ANALYSE
        }).then(data => {
            this.riskAssessRecTypeId = data;
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // リスクアセスメントの読込み
    loadRiskAssess() {
        // リスクアセスメントの取得
        getRiskAssess({
            riskAssessId: this.copySourceRiskAssessId
        }).then(data => {
            this.riskAssess = data || {};
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // 分類・評価軸の選択リスト情報の読込み
    loadClassiSelsInfo(projectId, classiRecType, info) {
        // 分類・評価軸の選択リスト情報の取得
        getClassiSelsInfo({
            classiGroupRecordTypeName: classiRecType
            , projectId: projectId
            , isOptionsBlankAdd: true
        }).then(data => {
            if (data) {
                const rec = data;
                info.id = rec.classiGroupId
                info.label = rec.label || null;
                info.helpText = rec.helpText || null;
                info.options = rec.options;

                // コピーする場合
                if (this.copySourceRiskAssessId) {
                    // 分析タイミング軸以外
                    if (classiRecType !== CLASSI_RECORD_TYPE_ANALYSE_TIMING) {
                        // 分類・評価軸IDの読込み
                        this.loadClassiId(this.copySourceRiskAssessId, info.id, info);
                    }
                }
            }
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });  
    }

    // 分類・評価軸IDの読込み
    loadClassiId(riskAssessId, parentClassiId, info) {
        // 分類・評価軸IDの取得
        getClassiId({
            riskAssessId: riskAssessId
            , parentClassiId: parentClassiId
        }).then(data => {
            if (data) {
                info.value = data;
            }
        }).catch(error => {
            this.errorMessages = getErrorMessages(error);
        });
    }

    // 分析タイミングの並び順のクラス
    get analyseTimingOrderClass() {
        return 'slds-col slds-order_' + this.analyseTiming.orderNo;
    }

    // 発生可能性の並び順のクラス
    get probabilityOrderClass() {
        return 'slds-col slds-order_' + this.probability.orderNo;
    }

    // 結果の影響度の並び順のクラス
    get resultImpactOrderClass() {
        return 'slds-col slds-order_' + this.resultImpact.orderNo;
    }

    // 第三評価の並び順のクラス
    get thirdEvaluationOrderClass() {
        return 'slds-col slds-order_' + this.thirdEvaluation.orderNo;
    }

    // エラーの閉じるのクリック時
    handleErrorClose() {
        this.errorMessages = null;
    }

    // 分析タイミングの変更時
    handleAnalyseTimingChange(event) {
        this.analyseTiming.value = event.target.value || null;
    }

    // 発生可能性の変更時
    handleProbabilityChange(event) {
        this.probability.value = event.target.value || null;
    }

    // 結果の影響度の変更時
    handleResultImpactChange(event) {
        this.resultImpact.value = event.target.value || null;
    }

    // 第三評価の変更時
    handleThirdEvaluationChange(event) {
        this.thirdEvaluation.value = event.target.value || null;
    }

    // 保存のクリック時
    handleSaveClick() {
        // 入力チェック
        if (!this.checkInput()) return;

        // リスクアセスメントの新規作成の実行
        const btn = this.template.querySelector('[data-name="risk-assess-new-create-button"]');
        if (btn) {
            btn.click();
        }
    }

    // キャンセルのクリック時
    handleCancelClick() {
        // クローズの実行
        this.execClose(false);
    }

    // 入力チェック
    checkInput() {
        // 分析タイミングの入力チェック
        let elm = this.template.querySelector('[data-name="analyse-timing"]');
        if (elm) {
            elm.reportValidity();
            if (!elm.checkValidity()) {
                elm.focus();
                return false;
            }
        }
        return true;
    }
    
    // リスクアセスメントの新規作成レイアウト
    get riskAssessNewCreateLayout() {
        let ret = null;
        if (this._riskAssessNewCreateLayout) {
            ret = this._riskAssessNewCreateLayout;
        } else {
            if (this.riskAssessRecInfo && (!this.copySourceRiskAssessId || this.riskAssess)) {
                ret = [];
                const recInfo = this.riskAssessRecInfo;
                recInfo.layout.sections.forEach(s => {
                    const section = {
                        heading: s.useHeading ? s.heading : '',
                        class: 'slds-col slds-size_1-of-' + s.columns,
                        rows: [],
                    };
                    ret.push(section);
                    s.layoutRows.forEach(lr => {
                        const row = {
                            items: [],
                        };
                        section.rows.push(row);
                        lr.layoutItems.forEach(li => {
                            li.layoutComponents.forEach(lc => {
                                const item = {
                                    name: lc.apiName
                                    , value: null
                                    , required: li.required
                                    , disabled: !li.editableForNew
                                };
                                if (item.name) {
                                    // デフォルト値のセット
                                    if (item.name in recInfo.record.fields) {
                                        item.value = recInfo.record.fields[item.name].value;
                                    }
                                    if (item.name === RISK_ASSESSMENT_RISK_FIELD.fieldApiName) {
                                        item.value = this.recordId;
                                        item.required = true;
                                    }
                                    if (this.riskAssess) {
                                        if (
                                            item.name !== RISK_ASSESSMENT_OWNER_FIELD.fieldApiName
                                            && item.name !== RISK_ASSESSMENT_RECORD_TYPE_FIELD.fieldApiName
                                            && item.name !== RISK_ASSESSMENT_RISK_FIELD.fieldApiName
                                        ) {
                                            if (item.name in this.riskAssess) {
                                                item.value = this.riskAssess[item.name];
                                            }
                                        }
                                    }
                                }
                                row.items.push(item);
                            });
                        });
                    });
                });
                this._riskAssessNewCreateLayout = ret;
            }
        }
        return ret;
    }

    // 新規作成の実行時
    handleRiskAssessNewCreateSubmit() {
        this.processing = true;
    }

    // 新規作成の成功時
    handleRiskAssessNewCreateSucess(event) {
        // 関連データの保存
        this.saveRelatedData(event.detail.id);
    }

    // 新規作成のエラー時
    handleRiskAssessNewCreateError(event) {
        //console.log(event.detail.message);
        this.processing = false;
    }

    // 関連データの保存
    saveRelatedData(riskAssessId) {
        // 更新処理リストの作成
        const updateProcs = [];
        updateProcs.push(this.getRiskAssessClassiUpdate(riskAssessId, this.analyseTiming.value, this.analyseTiming.id));
        updateProcs.push(this.getRiskAssessClassiUpdate(riskAssessId, this.probability.value, this.probability.id));
        updateProcs.push(this.getRiskAssessClassiUpdate(riskAssessId, this.resultImpact.value, this.resultImpact.id));
        updateProcs.push(this.getRiskAssessClassiUpdate(riskAssessId, this.thirdEvaluation.value, this.thirdEvaluation.id));

        // 更新処理を直列で実行
        const res = updateProcs.reduce((prev, curr) => {
            return prev.then(curr); // thenでcurrを実行
        }, Promise.resolve());

        // 更新処理の結果確認
        res.then(() => {
            this.processing = false

            // トーストの表示
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.save_success_title
                    , message: this.label.save_success_content
                    , variant: 'success'
                })
            );

            // クローズの実行
            // this.execClose(true);

            // リスクのレコードページを表示（最新化）
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage'
                , attributes: {
                    recordId: this.recordId
                    , actionName: 'view'
                }
            });
        }).catch(error => {
            this.processing = false
            //console.log('error=' + error.body.message);

            // トーストの表示
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.save_error_title
                    , message: error.body.message
                    , variant: 'error'
                })
            );

            // リスクアセスメントの削除
            deleteRiskAssess({
                riskAssessId: riskAssessId
            }).then(() => {
            }).catch(error => {
                this.errorMessages = getErrorMessages(error);
            });
        });
    }

    // リスクアセスメント分類・評価軸連携の更新処理の取得
    getRiskAssessClassiUpdate(riskAssessId, classiId, parentClassiId) {
        return () => {
            // リスクアセスメント分類・評価軸連携の更新
            return updateRiskAssessClassi({
                riskAssessId: riskAssessId
                , classiId: classiId
                , parentClassiId: parentClassiId
            });
        };
    }

    // クローズの実行
    execClose(isSaved) {
        const event = new CustomEvent('close', {
            detail: { isSaved: isSaved }
        });
        this.dispatchEvent(event);
    }
}