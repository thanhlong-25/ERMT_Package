/**
 * リスク分類チャート（リスクアセスメント分類軸）
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/chartJs_3_7_0';
import PROJECT_OBJECT from '@salesforce/schema/Project__c';
import RISK_OBJECT from '@salesforce/schema/Risk__c';
import RISK_ASSESSMENT_OBJECT from '@salesforce/schema/RiskAssessment__c';
import label_title from '@salesforce/label/c.RiskClassChartRac_Title';
import label_chartBackColorSetting from '@salesforce/label/c.RiskClassChartRac_ChartBackColorSetting';
import label_chartDataLabelVisible from '@salesforce/label/c.RiskClassChartRac_ChartDataLabelVisible';
import label_classType_riskClass from '@salesforce/label/c.RiskClassChartRac_ClassType_RiskClass';
import label_classType_account from '@salesforce/label/c.RiskClassChartRac_ClassType_Account';
import label_ok from '@salesforce/label/c.Action_Ok';
import label_cancel from '@salesforce/label/c.Action_Cancel';
import label_search from '@salesforce/label/c.Action_Search';
import label_searchCond from '@salesforce/label/c.Action_SearchCond';
import label_searchCond_inputError from '@salesforce/label/c.SearchCondition_InputError';
import label_rowDelete from '@salesforce/label/c.Action_RowDelete';
import label_rowAdd from '@salesforce/label/c.Action_RowAdd';
import label_allRowDelete from '@salesforce/label/c.Action_AllRowDelete';
import label_verticalAxis from '@salesforce/label/c.Label_VerticalAxis';
import label_horizontalAxis from '@salesforce/label/c.Label_HorizontalAxis';
import label_classType from '@salesforce/label/c.Label_ClassType';
import label_classGroup from '@salesforce/label/c.Label_ClassGroup';
import label_score from '@salesforce/label/c.Label_Score';
import label_greaterThanEqual from '@salesforce/label/c.Label_GreaterThanEqual';
import label_backgroundColor from '@salesforce/label/c.Label_BackgroundColor';
import label_transparency from '@salesforce/label/c.Label_Transparency';
import label_classRecordType_analyseTiming from '@salesforce/label/c.ClassiRecordType_AnalyseTiming';
import {
    getErrorMessages,
    stringToNumber,
    roundDownDecimal,
    roundUpDecimal,
    roundDecimal,
} from 'c/commonUtil';
import getRiskClassChartSetting from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskClassChartSetting';
import getRiskClassChartRacBackColorInfo from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskClassChartRacBackColorInfo';
import saveRiskClassChartRacBackColorInfo from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.saveRiskClassChartRacBackColorInfo';
import getClassGroups from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getClassGroups';
import getClasses from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getClasses';
import getRisks from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRisks';
import getRiskClasses from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskClasses';
import getRiskAccounts from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskAccounts';
import getRiskAssessments from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskAssessments';
import getRiskAssessmentClasses from '@salesforce/apex/RiskClassChartRiskAssessClassCtlr.getRiskAssessmentClasses';

const QUERY_LIMIT = 2000; // クエリーのリミット値
const CALSS_TYPE_RISK_CLASS = 'riskClass'; // 分類種別：リスク分類
const CALSS_TYPE_ACCOUNT = 'account'; // 分類種別：組織・部門

export default class RiskClassChartRiskAssessClass extends LightningElement {
    // レコードID（プロジェクトID）
    @api
    get recordId() {
        return this.projectId;
    }
    set recordId(value) {
        this.projectId = value || null;
        this.isProjectVisible = !value;
    }
    @api chartHeight = 400; // チャートの高さ
    @api chartLegendHeight = 100; // チャート凡例の高さ
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中フラグ
    // ラベル情報
    labelInfo = {
        title: label_title,
        chartBackColorSetting: label_chartBackColorSetting,
        chartDataLabelVisible: label_chartDataLabelVisible,
        classType_riskClass: label_classType_riskClass,
        classType_account: label_classType_account,
        ok: label_ok,
        cancel: label_cancel,
        search: label_search,
        searchCond: label_searchCond,
        searchCond_inputError: label_searchCond_inputError,
        rowDelete: label_rowDelete,
        rowAdd: label_rowAdd,
        allRowDelete: label_allRowDelete,
        verticalAxis: label_verticalAxis,
        horizontalAxis: label_horizontalAxis,
        classType: label_classType,
        classGroup1: `${label_classGroup}1`,
        classGroup2: `${label_classGroup}2`,
        score1: `${label_score}1`,
        score2: `${label_score}2`,
        greaterThanEqual: label_greaterThanEqual,
        backgroundColor: label_backgroundColor,
        transparency: label_transparency,
        classRecordType_analyseTiming: label_classRecordType_analyseTiming,
    };
    projectObjectLabel = null; // プロジェクトオブジェクト表示ラベル
    riskObjectLabel = null; // リスクオブジェクト表示ラベル
    riskAssessmentObjectLabel = null; // リスクアセスメントオブジェクト表示ラベル
    searchCondition = this.createSearchCondition(); // 検索条件
    @track searchCondTemp = this.createSearchCondition(); // 検索条件（一時保管用）
    riskSearchFieldNames = null; // リスク検索項目リスト
    riskAssessSearchFieldNames = null; // リスクアセスメント検索項目名リスト
    _isSearchCondVisible = false; // 検索条件表示フラグ
    searchCondErrorMessage = null; // 検索条件エラーメッセージ
    projectId = null; // プロジェクトID
    isProjectVisible = true; // プロジェクト表示フラグ
    analyseTimingClassId = null; // 分析タイミングの分類ID
    verticalAxisInfo = this.createAxisInfo(); // 縦軸情報
    horizontalAxisInfo = this.createAxisInfo(); // 横軸情報
    axisSels = []; // 軸選択リスト
    classType = null; // 分類種別
    classTypeSels = []; // 分類種別選択リスト
    classGroupIds = []; // 分類グループリスト
    classIds = []; // 分類IDリスト
    accountIds = []; // 組織・部門IDリスト
    classGroupSumMap = new Map(); // 分類グループ集計マップ
    isChartLoaded = false; // チャート読込済みフラグ
    chart = null; // チャート
    isChartDataLabelVisible = false; // チャートデータラベル表示フラグ
    chartDataBackColorMap = new Map(); // チャートデータ背景色マップ（プロットの背景色）
    chartBackColorInfos = []; // チャート背景色情報リスト（プロットエリアの背景色）
    @track chartBackColorInfosTemp = []; // チャート背景色情報リスト（一時保管用）

    // プロジェクトオブジェクト名
    get projectObjectName() {
        return PROJECT_OBJECT.objectApiName;
    }
    
    // リスクオブジェクト名
    get riskObjectName() {
        return RISK_OBJECT.objectApiName;
    }

    // リスクアセスメントオブジェクト名
    get riskAssessmentObjectName() {
        return RISK_ASSESSMENT_OBJECT.objectApiName;
    }

    // 検索条件表示フラグ
    get isSearchCondVisible() {
        return this._isSearchCondVisible;
    }
    set isSearchCondVisible(value) {
        this._isSearchCondVisible = value;
        if (value) {
            // 検索条件パネルを開く
            this.openSearchConditionPanel();
        } else {
            // 検索条件パネルを閉じる
            this.closeSearchConditionPanel();
        }
    }

    // リスク検索条件クラス
    get riskSearchCondClass() {
        return 'slds-section__content' + (this.searchCondTemp.risk.isEnabled ? '' : ' slds-hide');
    }

    // リスクアセスメント検索条件クラス
    get riskAssessmentSearchCondClass() {
        return 'slds-section__content' + (this.searchCondTemp.riskAssessment.isEnabled ? '' : ' slds-hide');
    }

    // リスク分類表示クラス
    get riskClassVisibleClass() {
        return (this.classType === CALSS_TYPE_RISK_CLASS ? '' : 'slds-hide');
    }

    // 組織・部門表示クラス
    get accountVisibleClass() {
        return (this.classType === CALSS_TYPE_ACCOUNT ? '' : 'slds-hide');
    }

    // チャート背景色設定無効フラグ
    get isChartBackColorSettingDisabled() {
        return !this.projectId;
    }

    // チャートコンテナスタイル
    get chartContainerStyle() {
        const height = this.chartHeight;
        return `height: ${height}px`;
    }

    // チャート凡例コンテナスタイル
    get chartLegendContainerStyle() {
        const height = this.chartLegendHeight;
        return `height: ${height}px`;
    }

    // プロジェクト情報の取得
    @wire(getObjectInfo, { objectApiName: PROJECT_OBJECT })
    wiredProjectInfo({ data, error }) {
        if (data) {
            const { label } = data;
            this.projectObjectLabel = label;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスク情報の取得
    @wire(getObjectInfo, { objectApiName: RISK_OBJECT })
    wiredRiskInfo({ data, error }) {
        if (data) {
            const { label } = data;
            this.riskObjectLabel = label;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスクアセスメント情報の取得
    @wire(getObjectInfo, { objectApiName: RISK_ASSESSMENT_OBJECT })
    wiredRiskAssessmentInfo({ data, error }) {
        if (data) {
            const { label } = data;
            this.riskAssessmentObjectLabel = label;
        } else if (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 現在のページ参照
    @wire(CurrentPageReference)
    wiredCurrentPageReference(pageRef) {
       if (pageRef) {
            const { c__id = null } = pageRef.state;
            if (!this.projectId && c__id) {
                this.projectId = c__id;

                // データの初期化
                this.initData();
            }
        }
    }

    // 初期化時処理
    connectedCallback() {
        // データの初期化
        this.initData();

        // チャートリサイズイベントの追加
        window.addEventListener('resize', this.resizeChart);
    }

    // 終了時処理
    disconnectedCallback() {
        window.removeEventListener('resize', this.resizeChart);

        // チャートの破棄
        this.destroyChart();
    }

    // 描画時処理
    renderedCallback() {
        // チャートの読込み
        this.loadChartAsync();
    }

    // 検索条件のクリック
    handleSearchConditionClick() {
        this.searchCondErrorMessage = null;

        // 検索条件が表示されている場合、検索条件を非表示
        if (this.isSearchCondVisible) {
            this.isSearchCondVisible = false;
            return;
        }

        try {
            this.errorMessages = null;

            // 検索条件のコピー
            this.copySearchCondition(this.searchCondition, this.searchCondTemp);

            // 検索条件を表示
            this.isSearchCondVisible = true;
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスク検索条件有効の変更
    handleRiskSearchCondEnableChange(event) {
        this.searchCondTemp.risk.isEnabled = event.detail.checked;
    }

    // リスク検索条件の編集
    handleRiskSearchCondEdit(event) {
        this.searchCondTemp.risk.searchConds = event.detail.searchConditions;
        this.searchCondTemp.risk.searchCondLogic = event.detail.searchConditionLogic;
    }

    // リスクアセスメント検索条件有効の変更
    handleRiskAssessSearchCondEnableChange(event) {
        this.searchCondTemp.riskAssessment.isEnabled = event.detail.checked;
    }

    // リスクアセスメント検索条件の編集
    handleRiskAssessSearchCondEdit(event) {
        this.searchCondTemp.riskAssessment.searchConds = event.detail.searchConditions;
        this.searchCondTemp.riskAssessment.searchCondLogic = event.detail.searchConditionLogic;
    }

    // 検索条件のキャンセルのクリック
    handleSearchConditionCancelClick() {
        // 検索条件を非表示
        this.isSearchCondVisible = false;
    }

    // 検索条件の検索のクリック
    async handleSearchConditionSearchClickAsync() {
        this.searchCondErrorMessage = null;
        const panel = this.getSearchConditionPanelElement();
        let isValid = true;
        
        // リスクの検索条件の入力チェック
        if (this.searchCondTemp.risk.isEnabled) {
            const cmp = panel.querySelector('[data-name="riskSerachCondition"]');
            if (cmp) {
                const result = await cmp.checkValidity();
                isValid = isValid && result;
            }
        }
        
        // リスクアセスメントの検索条件の入力チェック
        if (this.searchCondTemp.riskAssessment.isEnabled) {
            const cmp = panel.querySelector('[data-name="riskAssessmentSerachCondition"]');
            if (cmp) {
                const result = await cmp.checkValidity();
                isValid = isValid && result;
            }
        }

        if (!isValid) {
            this.searchCondErrorMessage = this.labelInfo.searchCond_inputError;
            return;
        }

        try {
            this.isProcessing = true;
            this.errorMessages = null;
            
            // リスクの検索条件の保存
            if (this.searchCondTemp.risk.isEnabled) {
                const cmp = panel.querySelector('[data-name="riskSerachCondition"]');
                if (cmp) {
                    const result = cmp.save();
                }
            }
            
            // リスクアセスメントの検索条件
            if (this.searchCondTemp.riskAssessment.isEnabled) {
                const cmp = panel.querySelector('[data-name="riskAssessmentSerachCondition"]');
                if (cmp) {
                    const result = cmp.save();
                }
            }

            // 検索条件のコピー
            this.copySearchCondition(this.searchCondTemp, this.searchCondition);

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // プロジェクトの変更
    async handleProjectChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.projectId = event.detail.value;

            await Promise.all([
                // チャート背景色情報リストの読込み
                this.loadChartBackColorInfosAsync(),
                // 軸選択リストの読込み
                this.loadAxisSelsAsync(),
            ]);

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 分類タイミングの変更
    async handleAnalyseTimingChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.analyseTimingClassId = event.detail.value || null;

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 縦軸の変更
    async handleVerticalAxisChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            const { value } = event.detail;
            this.verticalAxisInfo.classGroupId = value;

            // 軸の表示ラベルの取得
            const axis = this.axisSels.find(axis => axis.value === value);
            this.verticalAxisInfo.label = axis?.label ?? null;

            // 軸の値情報の取得
            const axisValueInfo = await this.getAxisValueInfoAsync(value);
            this.verticalAxisInfo.min = axisValueInfo.min;
            this.verticalAxisInfo.max = axisValueInfo.max;

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 横軸の変更
    async handleHorizontalAxisChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            const { value } = event.detail;
            this.horizontalAxisInfo.classGroupId = value;

            // 軸の表示ラベルの取得
            const axis = this.axisSels.find(axis => axis.value === value);
            this.horizontalAxisInfo.label = axis?.label ?? null;

            // 軸の値情報の取得
            const axisValueInfo = await this.getAxisValueInfoAsync(value);
            this.horizontalAxisInfo.min = axisValueInfo.min;
            this.horizontalAxisInfo.max = axisValueInfo.max;

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 分類種別の変更
    async handleClassTypeChangeAsync(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.classType = event.detail.value;

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // リスク分類の変更時
    async handleRiskClassChange(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.classIds = event.detail.value || [];

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 組織・部門の変更時
    async handleAccountChange(event) {
        try {
            this.isProcessing = true;
            this.errorMessages = null;
            this.accountIds = event.detail.value || [];

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // チャートデータラベル表示変更
    handleChartDataLabelVisibleChange(event) {
        this.isChartDataLabelVisible = event.target.checked;
        
        // チャートの描画
        this.chart?.render();
    }

    // チャート背景色設定クリック
    handleChartBackColorSettingClick() {
        // チャート背景色情報リストのコピー
        this.copyChartBackColorInfos(
            this.chartBackColorInfos,
            this.chartBackColorInfosTemp,
        );

        // チャート背景色設定ダイアログを開く
        this.openChartBackColorSettingDialog();
    }

    // チャート背景色の分類グループ1の変更
    handleChartBackColorClassGroup1Change(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.classGroupId1 = value;
    }

    // チャート背景色の最小スコア1の変更
    handleChartBackColorMinScore1Change(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.minScore1 = stringToNumber(value);
    }

    // チャート背景色の分類グループ2の変更
    handleChartBackColorClassGroup2Change(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.classGroupId2 = value;
    }

    // チャート背景色の最小スコア2の変更
    handleChartBackColorMinScore2Change(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.minScore2 = stringToNumber(value);
    }

    // チャート背景色の背景色の変更
    handleChartBackColorBackColorChange(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.backColor = value;
    }

    // チャート背景色の透明度の変更
    handleChartBackColorTransparencyChange(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const info = this.chartBackColorInfosTemp[index];
        info.transparency = value;
    }

    // チャート背景色情報の削除のクリック
    handleChartBackColorInfoDeleteClick(event) {
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        this.chartBackColorInfosTemp = this.deleteChartBackColorInfo(
            this.chartBackColorInfosTemp,
            index,
        );
    }

    // チャート背景色情報の追加のクリック
    handleChartBackColorInfoAddClick() {
        this.chartBackColorInfosTemp.push(
            this.createChartBackColorInfo(this.chartBackColorInfosTemp.length + 1)
        );
    }

    // チャート背景色情報の全削除のクリック
    handleChartBackColorInfoAllDeleteClick() {
        this.chartBackColorInfosTemp = [];
    }

    // チャート背景色設定のキャンセルのクリック
    handleChartBackColorSettingCancelClick() {
        this.chartBackColorInfosTemp = [];

        // チャート背景色設定ダイアログを閉じる
        this.closeChartBackColorSettingDialog();
    }

    // チャート背景色設定のOKのクリック
    async handleChartBackColorSettingOkClick() {
        // 入力チェック
        let isValid = true;
        const dialog = this.template.querySelector('[data-name="chartBackColorSettingDialog"]');
        isValid = [...dialog.querySelectorAll('lightning-input,lightning-combobox,lightning-slider')]
            .reduce((isValidSoFar, inputCmp) => {
                    //console.log('inputCmp.name=' + inputCmp.name);
                    inputCmp.reportValidity();
                    return isValidSoFar && inputCmp.checkValidity();
                }
                , isValid
            );
        if (!isValid) return;

        try {
            this.isProcessing = true;
            this.errorMessages = null;

            if (this.projectId) {
                let backColorInfo = null;
                if (this.chartBackColorInfosTemp.length > 0) {
                    backColorInfo = JSON.stringify(this.chartBackColorInfosTemp);
                }

                // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の保存
                await saveRiskClassChartRacBackColorInfo({
                    projectId: this.projectId,
                    backColorInfo: backColorInfo
                });
            }

            // チャート背景色情報リストのコピー
            this.copyChartBackColorInfos(
                this.chartBackColorInfosTemp,
                this.chartBackColorInfos,
            );

            // チャート背景色設定ダイアログを閉じる
            this.closeChartBackColorSettingDialog();

            // チャートの描画
            this.chart?.render();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // データの初期化
    async initData() {
        try {
            this.isProcessing = true;
            this.errorMessages = null;

            await Promise.all([
                // 設定の読込み
                this.loadSettingAsync(),
                // 分類種別選択リストの読込み
                this.loadClassTypeSels(),
                // チャート背景色情報リストの読込み
                this.loadChartBackColorInfosAsync(),
                // 軸選択リストの読込み
                this.loadAxisSelsAsync(),
            ]);

            // 分類グループ集計マップの読込み
            await this.loadClassGroupSumMapAsync();

            // チャートの更新
            this.updateChart();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // 設定の読込み
    async loadSettingAsync() {
        // リスクマトリックスの設定の取得
        const setting = await getRiskClassChartSetting();
        if (setting) {
            if (setting.ermt__RiskSearchFieldName__c) {
                this.riskSearchFieldNames = setting.ermt__RiskSearchFieldName__c.split(',');
            }
            if (setting.ermt__RiskAssessSearchFieldName__c) {
                this.riskAssessSearchFieldNames = setting.ermt__RiskAssessSearchFieldName__c.split(',');
            }
        }
    }

    // 検索条件の作成
    createSearchCondition() {
        return {
            risk: {
                isEnabled: false
                , searchConds: []
                , searchCondLogic: null
            },
            riskAssessment: {
                isEnabled: false
                , searchConds: []
                , searchCondLogic: null
            },
        };
    }

    // 検索条件のコピー
    copySearchCondition(srcSearchCond, dstSearchCond) {
        const { risk, riskAssessment } = srcSearchCond;

        dstSearchCond.risk.isEnabled = risk.isEnabled;
        dstSearchCond.risk.searchConds = [];
        dstSearchCond.risk.searchCondLogic = null;
        if (risk.isEnabled) {
            dstSearchCond.risk.searchConds =
                risk.searchConds.map(searchCond => {
                    return { ...searchCond };
                });
            dstSearchCond.risk.searchCondLogic = risk.searchCondLogic;
        }

        dstSearchCond.riskAssessment.isEnabled = riskAssessment.isEnabled;
        dstSearchCond.riskAssessment.searchConds = [];
        dstSearchCond.riskAssessment.searchCondLogic = null;
        if (riskAssessment.isEnabled) {
            dstSearchCond.riskAssessment.searchConds =
            riskAssessment.searchConds.map(searchCond => {
                    return { ...searchCond };
                });
            dstSearchCond.riskAssessment.searchCondLogic =
                riskAssessment.searchCondLogic;
        }
    }

    // 検索条件クラスの取得
    getSearchConditionClass(isEnabled) {
        return 'slds-section__content' + (isEnabled ? '' : ' slds-hide');
    }

    // 検索条件パネルラップ要素の取得
    getSearchConditionPanelWrapElement() {
        return this.template.querySelector('[data-name="searchConditionPanelWrap"]');
    }

    // 検索条件パネル要素の取得
    getSearchConditionPanelElement() {
        return this.template.querySelector('[data-name="searchConditionPanel"]');
    }

    // 検索条件パネルを開く
    openSearchConditionPanel() {
        const panelWrap = this.getSearchConditionPanelWrapElement();
        panelWrap.classList.remove('slds-hide');
        const panel = this.getSearchConditionPanelElement();
        panel.classList.add('slds-is-open');
    }

    // 検索条件パネルを閉じる
    closeSearchConditionPanel() {
        const panelWrap = this.getSearchConditionPanelWrapElement();
        panelWrap.classList.add('slds-hide');
        const panel = this.getSearchConditionPanelElement();
        panel.classList.remove('slds-is-open');
    }

    // チャート背景色情報リストの読込み
    async loadChartBackColorInfosAsync() {
        let chartBackColorInfos = [];
        if (this.projectId) {
            // リスク分類チャート（リスクアセスメント分類軸）の背景色情報の取得
            const info = await getRiskClassChartRacBackColorInfo({
                projectId: this.projectId
            });
            if (info) {
                chartBackColorInfos = JSON.parse(info);
            }
        }
        this.chartBackColorInfos = chartBackColorInfos;
    }

    // チャート背景色情報の検索
    findChartBackColorInfo(
        vaClassGroupId,
        vaScore,
        haClassGroupId,
        haScore,
    ) {
        const chartBackColorInfo = this.chartBackColorInfos.find(info => {
            const {
                classGroupId1,
                minScore1,
                classGroupId2,
                minScore2,
            } = info;

            if (classGroupId1 === vaClassGroupId &&
                minScore1 <= vaScore &&
                classGroupId2 === haClassGroupId &&
                minScore2 <= haScore
            ) {
                return true;
            }

            if (classGroupId1 === haClassGroupId &&
                minScore1 <= haScore &&
                classGroupId2 === vaClassGroupId &&
                minScore2 <= vaScore
            ) {
                return true;
            }

            return false;
        });
        
        return chartBackColorInfo ?? null;
    }

    // チャート背景色情報リストのコピー
    copyChartBackColorInfos(
        srcChartBackColorInfos,
        dstChartBackColorInfos,
    ) {
        const chartBackColorInfos = srcChartBackColorInfos.map(
            chartBackColorInfo => ({ ...chartBackColorInfo })
        );
        dstChartBackColorInfos.splice(0);
        Array.prototype.push.apply(
            dstChartBackColorInfos, chartBackColorInfos);
    }

    // チャート背景色情報の作成
    createChartBackColorInfo(no) {
        return {
            no,
            classGroupId1: null,
            minScore1: null,
            classGroupId2: null,
            minScore2: null,
            backColor: '#ff0000',
            transparency: 80,
            
        };
    }

    // チャート背景色情報の削除
    deleteChartBackColorInfo(chartBackColorInfos, deleteIndex) {
        let no = 0;
        return chartBackColorInfos.filter((info, index) => {
            let ret = (index !== deleteIndex);
            if (ret) {
                no++;
                info.no = no;
            }
            return ret;
        });
    }

    // チャート背景色設定ダイアログを開く
    openChartBackColorSettingDialog() {
        const dialog = this.template.querySelector('[data-name="chartBackColorSettingDialog"]');
        dialog.classList.remove('slds-hide');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialogBackdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }

    // チャート背景色設定ダイアログを閉じる
    closeChartBackColorSettingDialog() {
        const dialog = this.template.querySelector('[data-name="chartBackColorSettingDialog"]');
        dialog.classList.add('slds-hide');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialogBackdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    // 軸選択リストの読込み
    async loadAxisSelsAsync() {
        let options = [];
        if (this.projectId) {
            // 分類グループリストの取得
            const classGroups = await getClassGroups({
                projectId: this.projectId
            });
            options = classGroups.map(classGroup => {
                const {
                    Id = null,
                    ermt__Label_Pick__c = null,
                    ermt__Label__c = null,
                } = classGroup;
                return {
                    label: ermt__Label_Pick__c ? ermt__Label_Pick__c : ermt__Label__c,
                    value: Id,
                };
            });
        }

        this.axisSels = options;
    }

    // 軸の値情報の取得
    async getAxisValueInfoAsync(classGroupId) {
        let min = 0;
        let max = 0;

        if (classGroupId) {
            // 分類リストの取得
            const classis = await getClasses({
                classGroupId: classGroupId
            });

            classis.forEach((classItem, index) => {
                const {
                    ermt__ViewNo__c = 0,
                } = classItem;

                // 最小値（整数）の取得
                let num = roundDownDecimal(ermt__ViewNo__c, 0);
                if (index === 0 || num < min) min = num;

                // 最大値（整数）の取得
                num = roundUpDecimal(ermt__ViewNo__c, 0);
                if (index === 0 || num > max) max = num;
            });
        }

        return {
            min,
            max,
        }
    }

    // 軸情報の作成
    createAxisInfo() {
        return {
            classGroupId: null,
            label: null,
            min: 0,
            max: 0,
        };
    }

    // 分類種別選択リストの読込み
    loadClassTypeSels() {
        const {
            classType_riskClass: riskClassLabel,
            classType_account: accountLabel,
        } = this.labelInfo;
        const options = [];
        options.push({ label: riskClassLabel, value: CALSS_TYPE_RISK_CLASS });
        options.push({ label: accountLabel, value: CALSS_TYPE_ACCOUNT });
        this.classTypeSels = options;
    }

    // 分類グループ集計マップの読込み
    async loadClassGroupSumMapAsync() {
        const classGroupSumMap = new Map();

        if (this.projectId && this.classType &&
            this.verticalAxisInfo.classGroupId &&
            this.horizontalAxisInfo.classGroupId
        ) {
            const {
                risk,
                riskAssessment,
            } = this.searchCondition;

            // リスクリスト、リスクIDリストの作成
            // リスク分類リストマップの作成
            // リスク組織・部門リストマップの作成
            let risks = [];
            let riskIds = [];
            let riskClassesMap = new Map();
            let riskAccountsMap = new Map();
            if (this.classType === CALSS_TYPE_RISK_CLASS) {
                if (this.classIds.length > 0) {
                    // リスクリストの取得
                    risks = await this.getRisks({
                        projectId: this.projectId,
                        accountIds: [],
                        searchConds: risk.searchConds,
                        searchCondLogic: risk.searchCondLogic,
                    });
                    //console.log('risks=' + JSON.stringify(risks));

                    // リスクIDリストの作成
                    riskIds = risks.map(risk => risk.Id);

                    // リスク分類リストの取得
                    const riskClasses = await this.getRiskClasses({
                        riskIds: riskIds,
                        classIds: this.classIds,
                        classGroupIds: this.classGroupIds,
                    });
                    //console.log('riskClasses=' + JSON.stringify(riskClasses));

                    // リスク分類リストマップの作成
                    riskClasses.forEach(riskClass => {
                        const { ermt__Risk__c: riskId } = riskClass;
                        let riskClasses = riskClassesMap.get(riskId);
                        if (!riskClasses) {
                            riskClasses = [];
                            riskClassesMap.set(riskId, riskClasses);
                        }
                        riskClasses.push(riskClass);
                    });
                }
            } else if (this.classType === CALSS_TYPE_ACCOUNT) {
                if (this.accountIds.length > 0) {
                    // リスクリストの取得
                    risks = await this.getRisks({
                        projectId: this.projectId,
                        accountIds: this.accountIds,
                        searchConds: risk.searchConds,
                        searchCondLogic: risk.searchCondLogic,
                    });
                    //console.log('risks=' + JSON.stringify(risks));

                    // リスクIDリストの作成
                    riskIds = risks.map(risk => risk.Id);

                    // リスク組織・部門リストの取得
                    const riskAccounts = await this.getRiskAccounts({
                        riskIds: riskIds,
                        accountIds: this.accountIds,
                    });
                    //console.log('riskAccounts=' + JSON.stringify(riskAccounts));

                    // リスク組織・部門リストマップの作成
                    riskAccounts.forEach(riskAccount => {
                        const { ermt__Risk__c: riskId } = riskAccount;
                        let riskAccounts = riskAccountsMap.get(riskId);
                        if (!riskAccounts) {
                            riskAccounts = [];
                            riskAccountsMap.set(riskId, riskAccounts);
                        }
                        riskAccounts.push(riskAccount);
                    });
                }
            }

            // リスクIDリスト、リスクアセスメントIDリストの作成
            let tempRiskIds = [];
            let riskAssessmentIds = [];
            if (riskIds.length > 0) {
                if (this.analyseTimingClassId) {
                    // 分析タイミングの分類IDが有る場合
                    // リスクアセスメント分類リストの取得
                    const riskAssessmentClasses = await this.getRiskAssessmentClasses({
                        riskIds: riskIds,
                        classIds: [ this.analyseTimingClassId ],
                    });
                    //console.log('riskAssessmentClasses=' + JSON.stringify(riskAssessmentClasses));

                    if (riskAssessmentClasses.length > 0) {
                        // リスクアセスメントIDリストの作成
                        riskAssessmentIds = riskAssessmentClasses.map(riskAssessmentClass => {
                            return riskAssessmentClass.ermt__RiskAssessment__c;
                        });

                        // リスクアセスメントの検索条件が有る場合
                        if (riskAssessment.searchConds && riskAssessment.searchConds.length > 0) {
                            // リスクアセスメントリストの取得
                            const riskAssessments = await this.getRiskAssessments({
                                riskAssessmentIds: riskAssessmentIds,
                                searchConds: riskAssessment.searchConds,
                                searchCondLogic: riskAssessment.searchCondLogic,
                            });
                            //console.log('riskAssessments=' + JSON.stringify(riskAssessments));

                            // リスクアセスメントIDリストの作成
                            riskAssessmentIds = riskAssessments.map(riskAssessment => riskAssessment.Id);
                        }
                    }
                } else {
                    // 分析タイミングの分類IDが空の場合
                    // リスクアセスメントの検索条件が有る場合
                    if (riskAssessment.searchConds && riskAssessment.searchConds.length > 0) {
                        // リスクアセスメントリストの取得
                        const riskAssessments = await this.getRiskAssessments({
                            riskIds: riskIds,
                            searchConds: riskAssessment.searchConds,
                            searchCondLogic: riskAssessment.searchCondLogic,
                        });
                        //console.log('riskAssessments=' + JSON.stringify(riskAssessments));

                        // リスクアセスメントIDリストの作成
                        riskAssessmentIds = riskAssessments.map(riskAssessment => riskAssessment.Id);
                    } else {
                        tempRiskIds = riskIds;
                    }
                }
            }

            // 縦軸、横軸のリスクアセスメント分類リストマップの作成
            const vaRiskAssessmentClassesMap = new Map();
            const haRiskAssessmentClassesMap = new Map();
            if (tempRiskIds.length > 0 || riskAssessmentIds.length > 0) {
                await Promise.all([
                    (async () => {
                        // リスクアセスメント分類リストの取得
                        const riskAssessmentClasses = await this.getRiskAssessmentClasses({
                            riskAssessmentIds: riskAssessmentIds,
                            riskIds: tempRiskIds,
                            classGroupIds: [ this.verticalAxisInfo.classGroupId ],
                        });
                        //console.log('riskAssessmentClasses=' + JSON.stringify(riskAssessmentClasses));

                        // 縦軸のリスクアセスメント分類リストマップの作成
                        riskAssessmentClasses.forEach(riskAssessmentClass => {
                            const {
                                ermt__RiskAssessment__r: {
                                    ermt__Risk__c: riskId = null
                                } = {}
                            } = riskAssessmentClass;

                            let riskAssessmentClasses = vaRiskAssessmentClassesMap.get(riskId);
                            if (!riskAssessmentClasses) {
                                riskAssessmentClasses = [];
                                vaRiskAssessmentClassesMap.set(riskId, riskAssessmentClasses);
                            }
                            riskAssessmentClasses.push(riskAssessmentClass);
                        });
                    })(),
                    (async () => {
                        // リスクアセスメント分類リストの取得
                        const riskAssessmentClasses = await this.getRiskAssessmentClasses({
                            riskAssessmentIds: riskAssessmentIds,
                            riskIds: tempRiskIds,
                            classGroupIds: [ this.horizontalAxisInfo.classGroupId ],
                        });
                        //console.log('riskAssessmentClasses=' + JSON.stringify(riskAssessmentClasses));

                        // 横軸のリスクアセスメント分類リストマップの作成
                        riskAssessmentClasses.forEach(riskAssessmentClass => {
                            const {
                                ermt__RiskAssessment__r: {
                                    ermt__Risk__c: riskId = null
                                } = {}
                            } = riskAssessmentClass;
                            let riskAssessmentClasses = haRiskAssessmentClassesMap.get(riskId);
                            if (!riskAssessmentClasses) {
                                riskAssessmentClasses = [];
                                haRiskAssessmentClassesMap.set(riskId, riskAssessmentClasses);
                            }
                            riskAssessmentClasses.push(riskAssessmentClass);
                        });
                    })(),
                ]);
            }

            // 分類グループ集計マップの作成
            risks.forEach(risk => {
                const { Id: riskId } = risk;

                // 縦軸の集計
                let vaValue = 0;
                let vaCount = 0;
                const vaRiskAssessmentClasses = vaRiskAssessmentClassesMap.get(riskId);
                if (vaRiskAssessmentClasses) {
                    vaRiskAssessmentClasses.forEach(riskAssessmentClass => {
                        const {
                            ermt__M_Classification__r: {
                                ermt__ViewNo__c: viewNo = null
                            } = {}
                        } = riskAssessmentClass;
                        if (viewNo != null) {
                            vaValue += viewNo;
                            vaCount++;
                        }
                    });
                }
                
                // 横軸の集計
                let haValue = 0;
                let haCount = 0;
                const haRiskAssessmentClasses = haRiskAssessmentClassesMap.get(riskId);
                if (haRiskAssessmentClasses) {
                    haRiskAssessmentClasses.forEach(riskAssessmentClass => {
                        const {
                            ermt__M_Classification__r: {
                                ermt__ViewNo__c: viewNo = null
                            } = {}
                        } = riskAssessmentClass;
                        if (viewNo != null) {
                            haValue += viewNo;
                            haCount++;
                        }
                    });
                }

                if (vaCount > 0 && haCount > 0) {
                    if (this.classType === CALSS_TYPE_RISK_CLASS) {
                        const riskClasses = riskClassesMap.get(riskId);
                        if (riskClasses) {
                            riskClasses.forEach(riskClass => {
                                const {
                                    ermt__M_Classification__c: classId = null,
                                    ermt__M_Classification__r: {
                                        ermt__Label_Pick__c: classLabel = null,
                                        ermt__Label__c: classLabel2 = null,
                                        ermt__ParentMClassification_del__c: classGroupId = null,
                                        ermt__ParentMClassification_del__r: {
                                            ermt__Label_Pick__c: classGroupLabel = null,
                                            ermt__Label__c: classGroupLabel2 = null,
                                            ermt__RiskClassChartRacDataLabelBackColor__c: dataLabelBackColor = null,
                                        } = {},
                                    } = {},
                                } = riskClass;

                                // 分類グループ集計をマップへ追加
                                let classGroupSum = classGroupSumMap.get(classGroupId);
                                if (!classGroupSum) {
                                    let backColor = dataLabelBackColor;
                                    if (!backColor) {
                                        backColor = this.chartDataBackColorMap.get(classGroupId);
                                        if (!backColor) {
                                            backColor = this.createRandomColorCode();
                                            this.chartDataBackColorMap.set(classGroupId, backColor);
                                        }
                                    }
                                    classGroupSum = {
                                        classGroupLabel: classGroupLabel ?? classGroupLabel2,
                                        classSumMap: new Map(),
                                        backColor: backColor,
                                    };
                                    classGroupSumMap.set(classGroupId, classGroupSum);
                                }

                                // 分類集計をマップへ追加
                                const classSumMap = classGroupSum.classSumMap;
                                let classSum = classSumMap.get(classId);
                                if (!classSum) {
                                    classSum = {
                                        classLabel: classLabel ?? classLabel2,
                                        vaValue: 0,
                                        vaCount: 0,
                                        haValue: 0,
                                        haCount: 0,
                                    };
                                    classSumMap.set(classId, classSum);
                                }
                                classSum.vaValue += vaValue;
                                classSum.vaCount += vaCount;
                                classSum.haValue += haValue;
                                classSum.haCount += haCount;
                            });
                        }
                    } else if (this.classType === CALSS_TYPE_ACCOUNT) {
                        const sumedAccountIdSet = new Set();
                        const {
                            ermt__Organization__c: accountId = null,
                            ermt__Organization__r: {
                                Name: accountName = null,
                                ermt__RiskClassChartRacDataLabelBackColor__c: dataLabelBackColor = null,
                            } = {},
                        } = risk;

                        if (accountId) {
                            const classGroupId = accountId;
                            const classGroupLabel = accountName;

                            // 分類グループ集計をマップへ追加
                            let classGroupSum = classGroupSumMap.get(classGroupId);
                            if (!classGroupSum) {
                                let backColor = dataLabelBackColor;
                                if (!backColor) {
                                    backColor = this.chartDataBackColorMap.get(classGroupId);
                                    if (!backColor) {
                                        backColor = this.createRandomColorCode();
                                        this.chartDataBackColorMap.set(classGroupId, backColor);
                                    }
                                }
                                classGroupSum = {
                                    classGroupLabel: classGroupLabel,
                                    classSumMap: new Map(),
                                    backColor: backColor,
                                };
                                classGroupSumMap.set(classGroupId, classGroupSum);
                            }

                            // 分類集計をマップへ追加
                            const classSumMap = classGroupSum.classSumMap;
                            let classSum = classSumMap.get(classGroupId);
                            if (!classSum) {
                                classSum = {
                                    classLabel: null,
                                    vaValue: 0,
                                    vaCount: 0,
                                    haValue: 0,
                                    haCount: 0,
                                };
                                classSumMap.set(classGroupId, classSum);
                            }
                            classSum.vaValue += vaValue;
                            classSum.vaCount += vaCount;
                            classSum.haValue += haValue;
                            classSum.haCount += haCount;
                            
                            sumedAccountIdSet.add(classGroupId);
                        }

                        const riskAccounts = riskAccountsMap.get(riskId);
                        if (riskAccounts) {
                            riskAccounts.forEach(riskAccount => {
                                const {
                                    ermt__Department__c: classGroupId = null,  
                                    ermt__Department__r: {
                                        Name: classGroupLabel = null,
                                        ermt__RiskClassChartRacDataLabelBackColor__c: dataLabelBackColor = null,
                                    } = {},
                                } = riskAccount;

                                // 未集計チェック
                                if (!sumedAccountIdSet.has(classGroupId)) {
                                    // 分類グループ集計をマップへ追加
                                    let classGroupSum = classGroupSumMap.get(classGroupId);
                                    if (!classGroupSum) {
                                        let backColor = dataLabelBackColor;
                                        if (!backColor) {
                                            backColor = this.chartDataBackColorMap.get(classGroupId);
                                            if (!backColor) {
                                                backColor = this.createRandomColorCode();
                                                this.chartDataBackColorMap.set(classGroupId, backColor);
                                            }
                                        }
                                        classGroupSum = {
                                            classGroupLabel: classGroupLabel,
                                            classSumMap: new Map(),
                                            backColor: backColor,
                                        };
                                        classGroupSumMap.set(classGroupId, classGroupSum);
                                    }

                                    // 分類集計をマップへ追加
                                    const classSumMap = classGroupSum.classSumMap;
                                    let classSum = classSumMap.get(classGroupId);
                                    if (!classSum) {
                                        classSum = {
                                            classLabel: null,
                                            vaValue: 0,
                                            vaCount: 0,
                                            haValue: 0,
                                            haCount: 0,
                                        };
                                        classSumMap.set(classGroupId, classSum);
                                    }
                                    classSum.vaValue += vaValue;
                                    classSum.vaCount += vaCount;
                                    classSum.haValue += haValue;
                                    classSum.haCount += haCount;

                                    sumedAccountIdSet.add(classGroupId);
                                }
                            });
                        }
                    }
                }
            });

            // for (let classGroupSum of classGroupSumMap.values()) {
            //     console.log('classGroupSum=' + JSON.stringify(classGroupSum));
            //     for (let classSum of classGroupSum.classSumMap.values()) {
            //         console.log('classSum=' + JSON.stringify(classSum));
            //     }
            // }
        }

        this.classGroupSumMap = classGroupSumMap;
    }

    // リスクリストの取得
    async getRisks(params) {
        const {
            projectId,
            accountIds,
            searchConds,
            searchCondLogic,
        } = params;
        
        let risks = [];
        let previousLastId = null;
        do {
            // リスクリストの取得
            const data = await getRisks({
                projectId: projectId,
                accountIds: accountIds,
                searchConds: searchConds,
                searchCondLogic: searchCondLogic,
                previousLastId: previousLastId,
                queryLimit: QUERY_LIMIT,
            });
            risks = risks.concat(data);
            if (data.length === QUERY_LIMIT) {
                const risk = data[data.length - 1];
                previousLastId = risk.Id;
            } else {
                previousLastId = null;
            }
        } while (previousLastId);

        return risks;
    }

    // リスク分類リストの取得
    async getRiskClasses(params) {
        const {
            riskIds,
            classIds,
            classGroupIds,
        } = params;
        
        let riskClasses = [];
        let previousLastId = null;
        do {
            // リスク分類リストの取得
            const data = await getRiskClasses({
                riskIds: riskIds,
                classIds: classIds,
                classGroupIds: classGroupIds,
                previousLastId: previousLastId,
                queryLimit: QUERY_LIMIT,
            });
            riskClasses = riskClasses.concat(data);
            if (data.length === QUERY_LIMIT) {
                const riskClass = data[data.length - 1];
                previousLastId = riskClass.Id;
            } else {
                previousLastId = null;
            }
        } while (previousLastId);

        return riskClasses;
    }

    // リスク組織・部門リストの取得
    async getRiskAccounts(params) {
        const {
            riskIds,
            accountIds,
        } = params;
        
        let riskAccounts = [];
        let previousLastId = null;
        do {
            // リスク組織・部門リストの取得
            const data = await getRiskAccounts({
                riskIds: riskIds,
                accountIds: accountIds,
                previousLastId: previousLastId,
                queryLimit: QUERY_LIMIT,
            });
            riskAccounts = riskAccounts.concat(data);
            if (data.length === QUERY_LIMIT) {
                const riskAccount = data[data.length - 1];
                previousLastId = riskAccount.Id;
            } else {
                previousLastId = null;
            }
        } while (previousLastId);

        return riskAccounts;
    }

    // リスクアセスメントリストの取得
    async getRiskAssessments(params) {
        const {
            riskAssessmentIds = [],
            riskIds = [],
            searchConds,
            searchCondLogic,
        } = params;
        
        let riskAssessments = [];
        let previousLastId = null;
        do {
            // リスクアセスメントリストの取得
            const data = await getRiskAssessments({
                riskAssessmentIds: riskAssessmentIds,
                riskIds: riskIds,
                searchConds: searchConds,
                searchCondLogic: searchCondLogic,
                previousLastId: previousLastId,
                queryLimit: QUERY_LIMIT,
            });
            riskAssessments = riskAssessments.concat(data);
            if (data.length === QUERY_LIMIT) {
                const riskAssessment = data[data.length - 1];
                previousLastId = riskAssessment.Id;
            } else {
                previousLastId = null;
            }
        } while (previousLastId);

        return riskAssessments;
    }

    // リスクアセスメント分類リストの取得
    async getRiskAssessmentClasses(params) {
        const {
            riskAssessmentIds = [],
            riskIds = [],
            classIds = [],
            classGroupIds = [],
        } = params;
        
        let riskAssessmentClasses = [];
        let previousLastId = null;
        do {
            // リスクアセスメント分類リストの取得
            const data = await getRiskAssessmentClasses({
                riskAssessmentIds: riskAssessmentIds,
                riskIds: riskIds,
                classIds: classIds,
                classGroupIds: classGroupIds,
                previousLastId: previousLastId,
                queryLimit: QUERY_LIMIT,
            });
            riskAssessmentClasses = riskAssessmentClasses.concat(data);
            if (data.length === QUERY_LIMIT) {
                const riskAssessmentClass = data[data.length - 1];
                previousLastId = riskAssessmentClass.Id;
            } else {
                previousLastId = null;
            }
        } while (previousLastId);

        return riskAssessmentClasses;
    }




    // チャートの読込み
    async loadChartAsync() {
        if (this.isChartLoaded) return;
        this.isChartLoaded = true;

        try {
            this.isProcessing = true;

            if (!window.Chart) {
                //チャートJSの読込み
                await loadScript(this, chartJs);
            }

            // チャートの作成
            this.createChart();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        } finally {
            this.isProcessing = false;
        }
    }

    // チャートの作成
    createChart() {
        if (!window.Chart) return;

        const container = this.template.querySelector('[data-name="chartContainer"]');
        if (!container) return;

        // 作成済みのチャートを破棄する
        this.destroyChart();

        const canvas = document.createElement('canvas');
        canvas.setAttribute('width', container.clientWidth);
        canvas.setAttribute('height', container.clientHeight);
        container.appendChild(canvas);
        const ctx = canvas.getContext('2d');
        const chartConfig = this.createChartConfig();
        this.chart = new window.Chart(ctx, chartConfig);
    }

    // チャートの更新
    updateChart() {
        if (!this.chart) return;

        // チャートデータセットの作成
        const datasets = this.createChartDatasets();

        this.chart.data.datasets = datasets;

        // チャートスケールの作成
        const scales = this.createChartScales();

        this.chart.options.scales = scales;

        this.chart.update();
    }

    // チャートのリサイズ
    resizeChart = () => {
        if (!this.chart) return;

        const container = this.template.querySelector('[data-name="chartContainer"]');
        if (!container) return;
        
        const canvas = container.querySelector('canvas');
        if (!canvas) return;
            
        canvas.setAttribute('width', container.clientWidth);
        canvas.setAttribute('height', container.clientHeight);
        this.chart.resize();
    }

    // チャートの破棄
    destroyChart() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
    }

    // チャート設定の作成
    createChartConfig() {
        // データ
        const data = {
            datasets: this.createChartDatasets()
        };
    
        // オプション
        const options = {
            responsive: false,
            maintainAspectRatio: false,
            plugins: {
                // title: {
                //     display: true,
                //     text: 'チャートテスト'
                //   },
                htmlLegend: {
                    containerID: 'chartLegend',
                },
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: tooltipItem => {
                            const {
                                dataset: {
                                    label: classGroupLabel,
                                    data,
                                },
                                dataIndex,
                            } = tooltipItem;
                            const {classLabel, x, y} = data[dataIndex];

                            return `${classGroupLabel}${classLabel ? ': ' + classLabel : ''} (${x}, ${y})`;
                        }
                    }
                }
            },
            scales: this.createChartScales(),
        };

        return {
            type: 'scatter',
            data: data,
            options: options,
            plugins: [
                this.createChartDataLabelPlugin(),
                this.createChartBackgroundPlugin(),
                this.createChartHtmlLegendPlugin(),
            ],
        };
    }

    // チャートデータセットの作成
    createChartDatasets() {
        const datasets = [];
        for (const classGroupSum of this.classGroupSumMap.values()) {
            const dataset = {
                label: classGroupSum.classGroupLabel,
                data: [],
                backgroundColor: this.addAlphaColorCode(classGroupSum.backColor, 0.5),
                borderColor: this.addAlphaColorCode(classGroupSum.backColor, 0),
                borderWidth: 1,
                pointStyle: 'circle',
                pointRadius: 10, //5,
                hoverRadius: 11, //6,
            };
            for (const classSum of classGroupSum.classSumMap.values()) {
                dataset.data.push({
                    classLabel: classSum.classLabel,
                    x: (classSum.haCount === 0 ? 0 : roundDecimal(classSum.haValue / classSum.haCount, 2)),
                    y: (classSum.vaCount === 0 ? 0 : roundDecimal(classSum.vaValue / classSum.vaCount, 2)),
                });
            }
            datasets.push(dataset);
        }
        return datasets;
    }

    // チャートスケールの作成
    createChartScales() {
        const vaInfo = this.verticalAxisInfo;
        const haInfo = this.horizontalAxisInfo;
        return {
            y: {
                title: {
                    display: !!vaInfo.classGroupId,
                    text: vaInfo.label,
                },
                min: vaInfo.min - 1,
                max: vaInfo.max + 1,
                ticks: {
                    stepSize: 1,
                    callback: value => (vaInfo.min <= value && value <= vaInfo.max ? value : null),
                },
                pointLabels: { display: true }
            },
            x: {
                title: {
                    display: !!haInfo.classGroupId,
                    text: haInfo.label,
                },
                min: haInfo.min - 1,
                max: haInfo.max + 1,
                ticks: {
                    stepSize: 1,
                    callback: value => (haInfo.min <= value && value <= haInfo.max ? value : null),
                },
                pointLabels: { display: true }
            },
        };
    }

    // チャートデータラベルプラグインの作成
    createChartDataLabelPlugin() {
        const self = this;
        return {
            id: 'chartDataLabel',
            afterDatasetsDraw(chart) {
                if (!self.isChartDataLabelVisible) return;

                const {
                    ctx,
                    data: {
                        datasets
                    },
                } = chart;

                ctx.save();

                datasets.forEach((dataset, dIndex) => {
                    const meta = chart.getDatasetMeta(dIndex);
                    if (!meta.hidden) {
                        meta.data.forEach((element, eIndex) => {
                            const fontSize = 10;
                            ctx.fillStyle = 'dimgray';
                            ctx.font = Chart.helpers.fontString(fontSize, 'normal', 'Helvetica Neue');
                            ctx.textAlign = 'center';
                            ctx.textBaseline = 'middle';
                            const {label} = dataset;
                            const {classLabel} = dataset.data[eIndex];
                            const labelText = (classLabel ?? label);
                            const padding = 6; //1;
                            const position = element.tooltipPosition();
                            ctx.fillText(labelText, position.x, position.y - fontSize - padding);
                        });
                    }
                });

                ctx.restore();
            }
        };
    }

    // チャート背景色プラグインの作成
    createChartBackgroundPlugin() {
        const self = this;
        return {
            id: 'chartBackground',
            beforeDraw(chart) {
                const {
                    ctx,
                    scales: {
                        x,
                        y,
                    },
                } = chart;
                const vaInfo = self.verticalAxisInfo;
                const haInfo = self.horizontalAxisInfo;

                ctx.save();

                for (let i = vaInfo.min; i < vaInfo.max; i++) {
                    const top = y.getPixelForValue(i + 1);
                    const height = y.getPixelForValue(i) - top;
                    for (let j = haInfo.min; j < haInfo.max; j++) {
                        // チャート背景色情報の検索
                        const backColorInfo = self.findChartBackColorInfo(
                            haInfo.classGroupId,
                            j,
                            vaInfo.classGroupId,
                            i,
                        );
                        if (backColorInfo) {
                            const {
                                backColor,
                                transparency,
                            } = backColorInfo
                            ctx.fillStyle = self.addAlphaColorCode(backColor, (transparency / 100));
                            const left = x.getPixelForValue(j);
                            const width = x.getPixelForValue(j + 1) - left;
                            //console.log(`${left}, ${top}, ${width}, ${height}`);
                            ctx.fillRect(left, top, width, height);
                        }
                    }
                }
                
                ctx.restore();
            }
        };
    }

    // チャートHTML凡例プラグインの作成
    createChartHtmlLegendPlugin() {
        const self = this;
        return {
            id: 'chartHtmlLegend',
            afterUpdate(chart) {
                const legendContainer = self.template.querySelector(
                    '[data-name="chartLegendContainer"]'
                );
                if (!legendContainer) return;

                // リストの取得・生成
                let ul = legendContainer.querySelector('ul');
                if (!ul) {
                    ul = document.createElement('ul');
                    ul.className = 'slds-grid slds-wrap';
                    legendContainer.appendChild(ul);
                }
            
                // リストアイテムをクリア
                while (ul.firstChild) { ul.firstChild.remove(); }
            
                // リストアイテムを生成
                const items = chart.options.plugins.legend.labels.generateLabels(chart);
                items.forEach(item => {
                    const { datasetIndex } = item;
                    const li = document.createElement('li');
                    li.className = 'slds-grid slds-grid_vertical-align-center slds-m-horizontal_x-small slds-m-vertical_xxx-small';
                    li.onclick = () => {
                        chart.setDatasetVisibility(datasetIndex, !chart.isDatasetVisible(datasetIndex));
                        chart.update();
                    };
            
                    // 色ボックス
                    const colorBox = document.createElement('span');
                    colorBox.style.background = item.fillStyle;
                    colorBox.style.borderColor = item.strokeStyle;
                    colorBox.style.borderWidth = item.lineWidth + 'px';
                    colorBox.style.borderStyle = 'solid';
                    colorBox.style.display = 'inline-block';
                    colorBox.style.height = '1rem';
                    colorBox.style.marginRight = '0.25rem';
                    colorBox.style.width = '1rem';
                    colorBox.style.minWidth = '1rem';
                
                    // テキストコンテナ
                    const textContainer = document.createElement('div');
                    textContainer.style.color = item.fontColor;
                    textContainer.style.margin = 0;
                    textContainer.style.padding = 0;
                    textContainer.style.textDecoration = item.hidden ? 'solid line-through dimgray 3px' : '';
                
                    const text = document.createTextNode(item.text);
                    textContainer.appendChild(text);
                
                    li.appendChild(colorBox);
                    li.appendChild(textContainer);
                    ul.appendChild(li);
                });
            }
        };
    }

    // ランダムカラーコードの作成
    createRandomColorCode() {
        const h = Math.floor(Math.random() * 360);
        const s = 0.75;
        const l = 0.5;
        const c = (1 - Math.abs(2 * l - 1)) * s;
        const m = l - 0.5 * c;
        const hp = h / 60;
        const x = c * (1 - Math.abs((hp % 2) - 1));
        let r = m;
        let g = m;
        let b = m;
        if (hp >= 0 && hp <= 1) {
            r += c;
            g += x;
        } else if (hp >= 1 && hp <= 2) {
            r += x;
            g += c;
        } else if (hp >= 2 && hp <= 3) {
            g += c;
            b += x;
        } else if (hp >= 3 && hp <= 4) {
            g += x;
            b += c;
        } else if (hp >= 4 && hp <= 5) {
            r += x;
            b += c;
        } else if (hp >= 5 && hp < 6) {
            r += c;
            b += x;
        }
        r = Math.floor(r * 255).toString(16).padStart(2, '0');
        g = Math.floor(g * 255).toString(16).padStart(2, '0');
        b = Math.floor(b * 255).toString(16).padStart(2, '0');
        return `#${r}${g}${b}`;
    }

    /**
     * カラーコードに透明度を追加
     * 
     * @param {String} colorCode カラーコード
     * @param {Float} alpha 透明度:0～1
     * @returns 透明度追加後のカラーコード
     */
    addAlphaColorCode(colorCode, alpha) {
        return colorCode + (parseInt((1 - alpha) * 255)).toString(16).padStart(2, '0');
    }
}