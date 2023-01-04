/**
 * プロジェクト用のリスクマトリックス
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
// import jQuery from '@salesforce/resourceUrl/jQuery_3_6_0';
// import jQueryUI from '@salesforce/resourceUrl/jQueryUI_1_12_1';
import hasCellColorEditPermission from '@salesforce/customPermission/ProjectRiskMatrixCellColorEditPermission';
import label_title from '@salesforce/label/c.ProjectRiskMatrix_Title';
import label_newWindowOpen from '@salesforce/label/c.Action_NewWindowOpen';
import label_verticalAxis from '@salesforce/label/c.ProjectRiskMatrix_VerticalAxis';
import label_horizontalAxis from '@salesforce/label/c.ProjectRiskMatrix_HorizontalAxis';
import label_type from '@salesforce/label/c.ProjectRiskMatrix_Type';
import label_riskName from '@salesforce/label/c.ProjectRiskMatrix_RiskName';
import label_riskNum from '@salesforce/label/c.ProjectRiskMatrix_RiskNum';
import label_searchCondition from '@salesforce/label/c.ProjectRiskMatrix_SearchCondition';
import label_searchCondition_inputError from '@salesforce/label/c.SearchCondition_InputError';
import label_cellValueFullDisplay from '@salesforce/label/c.Action_CellValueFullDisplay';
import label_riskNumCellColorSetting from '@salesforce/label/c.ProjectRiskMatrix_RiskNumCellColorSetting';
import label_riskNum_greaterThanEqual from '@salesforce/label/c.ProjectRiskMatrix_RiskNum_GreaterThanEqual';
import label_cellColor from '@salesforce/label/c.ProjectRiskMatrix_CellColor';
import label_rowAdd from '@salesforce/label/c.ProjectRiskMatrix_RowAdd';
import label_rowDelete from '@salesforce/label/c.ProjectRiskMatrix_RowDelete';
import label_allRowDelete from '@salesforce/label/c.ProjectRiskMatrix_AllRowDelete';
import label_account from '@salesforce/label/c.ObjectLabel_Account';
import label_project from '@salesforce/label/c.ObjectLabel_Project';
import label_risk from '@salesforce/label/c.ObjectLabel_Risk';
import label_riskAssessment from '@salesforce/label/c.ObjectLabel_RiskAssessment';
import label_ok from '@salesforce/label/c.Action_Ok';
import label_search from '@salesforce/label/c.Action_Search';
import label_cancel from '@salesforce/label/c.Action_Cancel';
import label_notSet from '@salesforce/label/c.Select_NotSet';
import label_classiRecordType_riskClassiGroup from '@salesforce/label/c.ClassiRecordType_RiskClassiGroup';
import label_classiRecordType_analyseTiming from '@salesforce/label/c.ClassiRecordType_AnalyseTiming';
import label_functionType_riskMatrixRiskClassi from '@salesforce/label/c.FunctionType_RiskMatrixRiskClassi';
import label_settingType_searchCond from '@salesforce/label/c.SettingType_SearchCond';
import PROJECT_OBJECT from '@salesforce/schema/Project__c';
import PROJECT_NAME_FIELD from '@salesforce/schema/Project__c.Name';
import RISK_OBJECT from '@salesforce/schema/Risk__c';
import RISK_ASSESSMENT_OBJECT from '@salesforce/schema/RiskAssessment__c';
import {
    getErrorMessages
    , undefineToNull
    , formatNumber
    , stringToNumber
    , getTextColorBlackOrWhite
} from 'c/commonUtil';
import getRiskMatrixSetting from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getRiskMatrixSetting';
import getGroupClassiSels from '@salesforce/apex/ProjectRiskMatrixCtlr.getGroupClassiSels';
import getClassis from '@salesforce/apex/ProjectRiskMatrixCtlr.getClassis';
import getRiskMatrixCellColor from '@salesforce/apex/ProjectRiskMatrixCtlr.getRiskMatrixCellColor';
import saveRiskMatrixCellColor from '@salesforce/apex/ProjectRiskMatrixCtlr.saveRiskMatrixCellColor';
import getRisks from '@salesforce/apex/ProjectRiskMatrixCtlr.getRisks';
import getRiskAssessmentsByRiskId from '@salesforce/apex/ProjectRiskMatrixCtlr.getRiskAssessmentsByRiskId';
import getCustomFunctionSettingValue from '@salesforce/apex/CustomFunctionSettingCtlr.getCustomFunctionSettingValue';
import setCustomFunctionSettingValue from '@salesforce/apex/CustomFunctionSettingCtlr.setCustomFunctionSettingValue';

// デフォルトの色
const DEFAULT_COLORS = [
    '#ff0000'
    , '#ff2b2b'
    , '#ff5555'
    , '#ff8080'
    , '#ffaaaa'
    , '#ffd5d5'
    , '#ffeaea'
    , '#fff4f4'
];

export default class ProjectRiskMatrix extends LightningElement {
    @api recordId; // レコードID
    @api isNewWindowOpenButtonHide = false; // 別ウィンドウで開くボタン非表示か（未使用）
    @api isFullWindowMode = false; // フルウィンドウモードか
    // ラベル
    label = {
        title: label_title
        , newWindowOpen: label_newWindowOpen
        , project: label_project
        , verticalAxis: label_verticalAxis
        , horizontalAxis: label_horizontalAxis
        , type: label_type
        , riskName: label_riskName
        , riskNum: label_riskNum
        , account: label_account
        , searchCondition: label_searchCondition
        , risk: label_risk
        , riskAssessment: label_riskAssessment
        , cellValueFullDisplay: label_cellValueFullDisplay
        , riskNumCellColorSetting: label_riskNumCellColorSetting
        , riskNum_greaterThanEqual: label_riskNum_greaterThanEqual
        , cellColor: label_cellColor
        , rowAdd: label_rowAdd
        , rowDelete: label_rowDelete
        , allRowDelete: label_allRowDelete
        , ok: label_ok
        , search: label_search
        , cancel: label_cancel
        , classiRecordType_analyseTiming: label_classiRecordType_analyseTiming
    };
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中
    projectId = null; // プロジェクトID
    accountIds = []; // 組織・部門IDリスト
    analyseTimingClassiId = null; // 分析タイミングの分類・評価軸ID
    riskClassiGroupSels = null; // リスク分類グループ選択リスト
    vrAxisClassiGroupId = null; // 縦軸の分類グループID
    hrAxisClassiGroupId = null; // 横軸の分類グループID
    type = label_riskName; // 種別
    searchCondition = this.defaultSearchCondition; // 検索条件
    @track searchCondTemp = this.defaultSearchCondition; // 検索条件（一時保管）
    _isSearchCondVisible = false; // 検索条件表示フラグ
    searchCondErrorMessage = null; // 検索条件エラーメッセージ
    riskSearchFieldNames = null; // リスク検索項目リスト
    riskAssessSearchFieldNames = null; // リスクアセスメント検索項目名リスト
    //isCellValueFullDisplay = false; // セル値全表示フラグ
    cellColors = null; // セル色リスト
    @track cellColorsTemp = null; // セル色リスト（一時保管）
    windowHeight = window.innerHeight; // ウィンドウの高さ
    detailItems = null; // 明細項目リスト
    vrAxisClassis = null; // 縦軸の分類・評価軸リスト
    hrAxisClassis = null; // 横軸の分類・評価軸リスト
    @track header = null; // ヘッダー
    @track detail = null; // 明細
    // isItemResizableInit = false; // 項目サイズ変更の初期化
    get projectObjectName() { return PROJECT_OBJECT.objectApiName; } // プロジェクトオブジェクト名
    get riskObjectName() { return RISK_OBJECT.objectApiName; } // リスクオブジェクト名
    get riskAssessmentObjectName() { return RISK_ASSESSMENT_OBJECT.objectApiName; } // リスクアセスメントオブジェクト名
    get riskSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.risk.isEnabled ? '' : ' slds-hide'); } // リスク検索条件クラス
    get riskAssessmentSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.riskAssessment.isEnabled ? '' : ' slds-hide'); } // リスクアセスメント検索条件クラス
    //get itemWrapClass() { return (this.isCellValueFullDisplay ? '' : 'itemWrap'); } // 項目ラッパークラス

    // リスクマトリックスラップスタイル
    get riskMatrixWrapStyle() {
        const minHeight = 50;
        const marginHeight = (this.recordId ? 230 : 180);
        let maxHeight = this.windowHeight - marginHeight;
        if (maxHeight < minHeight) maxHeight = minHeight;
        return 'min-height:' + minHeight + 'px;max-height:' + maxHeight + 'px;';
    }

    // 種別選択リスト
    get typeSels() {
        return [
            { label: label_riskName, value: label_riskName }
            , { label: label_riskNum, value: label_riskNum }
        ];
    }

    // デフォルトの検索条件
    get defaultSearchCondition() {
        return {
            risk: {
                isEnabled: false
                , searchConds: null
                , searchCondLogic: null
            }
            , riskAssessment: {
                isEnabled: false
                , searchConds: null
                , searchCondLogic: null
            }
        };
    }

    // 検索条件（一時保管）：リスク
    get searchCondTempRisk() {
        return {
            searchConds: this.searchCondTemp.risk.searchConds
            , searchCondLogic: this.searchCondTemp.risk.searchCondLogic
        };
    }

    // 検索条件（一時保管）：リスクアセスメント
    get searchCondTempRiskAssessment() {
        return {
            searchConds: this.searchCondTemp.riskAssessment.searchConds
            , searchCondLogic: this.searchCondTemp.riskAssessment.searchCondLogic
        };
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

    // デフォルトのセル色リスト
    get defaultCellColors() {
        const ret = [];
        for (let i = 0, len = DEFAULT_COLORS.length; i < len; i++) {
            const no = i + 1;
            let cellColor = this.createCellColor(no);
            cellColor.riskNum = len - i;
            cellColor.color = DEFAULT_COLORS[i];
            ret.push(cellColor);
        }
        return ret;
    }

    // プロジェクトレコードの取得
    @wire(getRecord, { recordId: '$recordId', fields: PROJECT_NAME_FIELD })
    project;

    // プロジェクト名
    get projectName() {
        return getFieldValue(this.project.data, PROJECT_NAME_FIELD);
    }

    // プロジェクト参照URL
    get projectViewUrl() {
        return (!this.recordId ? null : '/' + this.recordId);
    }

    // セル色の設定の表示
    get isCellColorSettingVisible() {
        return hasCellColorEditPermission && this.cellColors;
    }

    // 初期化時
    connectedCallback() {
        // 初期化処理
        this.initialize();
    }

    // 描画時
    renderedCallback() {
        // 項目サイズ変更の初期化
        //this.initItemResizeable();
    }

    // プロジェクトの変更時
    async handleProjectChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.projectId = event.detail.value || null;
            this.analyseTimingClassiId = null;
            this.vrAxisClassiGroupId = null;
            this.hrAxisClassiGroupId = null;
            this.hrAxisClassis = null;
            this.vrAxisClassis = null;
            this.riskClassiGroupSels = null;
            this.cellColors = null;

            // データの読込み
            await this.loadData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        //this.isProcessing = false;
    }

    // 組織・部門の変更時
    async handleAccountChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.accountIds = event.detail.value || [];

            // リスクデータの読込み
            await this.loadRiskData();
                
            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        //this.isProcessing = false;
    }

    // 分析タイミングの変更時
    async handleAnalyseTimingChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.analyseTimingClassiId = event.detail.value || null;

            // リスクデータの読込み
            await this.loadRiskData();
                
            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        //this.isProcessing = false;
    }

    // 縦軸の変更時
    async handleVrAxisClassiGroupChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.vrAxisClassiGroupId = event.detail.value || null;

            // 縦軸の分類・評価軸リストの取得
            this.vrAxisClassis = await getClassis({
                classiGroupId: this.vrAxisClassiGroupId
            });
            
            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        //this.isProcessing = false;
    }

    // 横軸の変更時
    async handleHrAxisClassiGroupChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.hrAxisClassiGroupId = event.detail.value || null;

            // 横軸の分類・評価軸リストの取得
            this.hrAxisClassis = await getClassis({
                classiGroupId: this.hrAxisClassiGroupId
            });
            
            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        //this.isProcessing = false;
    }

    // 種別の変更時
    async handleTypeChange(event) {
        this.errorMessages = null;
        try {
            this.type = event.detail.value || null;

            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
    }

    // 検索条件のクリック時
    async handleSearchConditionClick() {
        this.searchCondErrorMessage = null;

        // 検索条件が表示されている場合、検索条件を非表示
        if (this.isSearchCondVisible) {
            this.isSearchCondVisible = false;
            return;
        }

        this.errorMessages = null;
        try {
            const panel = this.template.querySelector('[data-name="search-condition-panel"]');

            // 検索条件の復元
            // 検索条件有効
            this.searchCondTemp.risk.isEnabled = this.searchCondition.risk.isEnabled;
            this.searchCondTemp.riskAssessment.isEnabled = this.searchCondition.riskAssessment.isEnabled;

            // リスクの検索条件
            if (this.searchCondition.risk.searchConds) {
                this.searchCondTemp.risk.searchConds = this.searchCondition.risk.searchConds.map(searchCond => { return {...searchCond}; });
            } else {
                this.searchCondTemp.risk.searchConds = null;
            }
            this.searchCondTemp.risk.searchCondLogic = this.searchCondition.risk.searchCondLogic;
            // if (this.searchCondTemp.risk.isEnabled) {
            //     const cmp = panel.querySelector('[data-name="risk-serach-condition"]');
            //     if (cmp) {
            //         cmp.restore();
            //     }
            // }
            // リスクアセスメントの検索条件
            if (this.searchCondition.riskAssessment.searchConds) {
                this.searchCondTemp.riskAssessment.searchConds = this.searchCondition.riskAssessment.searchConds.map(searchCond => { return {...searchCond}; });
            } else {
                this.searchCondTemp.riskAssessment.searchConds = null;
            }
            this.searchCondTemp.riskAssessment.searchCondLogic = this.searchCondition.riskAssessment.searchCondLogic;
            // if (this.searchCondTemp.riskAssessment.isEnabled) {
            //     const cmp = panel.querySelector('[data-name="riskAssessment-serach-condition"]');
            //     if (cmp) {
            //         cmp.restore();
            //     }
            // }

            // 検索条件を表示
            this.isSearchCondVisible = true;
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // リスク検索条件有効の変更時
    handleRiskSearchCondEnableChange(event) {
        this.searchCondTemp.risk.isEnabled = event.detail.checked;
    }

    // リスク検索条件の編集時
    handleRiskSearchCondEdit(event) {
        this.searchCondTemp.risk.searchConds = event.detail.searchConditions;
        this.searchCondTemp.risk.searchCondLogic = event.detail.searchConditionLogic;
    }

    // リスクアセスメント検索条件有効の変更時
    handleRiskAssessSearchCondEnableChange(event) {
        this.searchCondTemp.riskAssessment.isEnabled = event.detail.checked;
    }

    // リスクアセスメント検索条件の編集時
    handleRiskAssessSearchCondEdit(event) {
        this.searchCondTemp.riskAssessment.searchConds = event.detail.searchConditions;
        this.searchCondTemp.riskAssessment.searchCondLogic = event.detail.searchConditionLogic;
    }

    // 検索条件のキャンセルのクリック時
    handleSearchConditionCancelClick() {
        // 検索条件を非表示
        this.isSearchCondVisible = false;
    }

    // 検索条件の検索のクリック時
    async handleSearchConditionSearchClick() {
        this.searchCondErrorMessage = null;
        const panel = this.template.querySelector('[data-name="search-condition-panel"]');
        // 入力チェック
        let isValid = true;
        // リスクの検索条件
        if (this.searchCondTemp.risk.isEnabled) {
            const cmp = panel.querySelector('[data-name="risk-serach-condition"]');
            if (cmp) {
                const result = await cmp.checkValidity();
                isValid = isValid && result;
            }
        }
        // リスクアセスメントの検索条件
        if (this.searchCondTemp.riskAssessment.isEnabled) {
            const cmp = panel.querySelector('[data-name="riskAssessment-serach-condition"]');
            if (cmp) {
                const result = await cmp.checkValidity();
                isValid = isValid && result;
            }
        }
        if (!isValid) {
            this.searchCondErrorMessage = label_searchCondition_inputError;
            return;
        }

        this.errorMessages = null;
        try {
            // 検索条件の保存
            // リスクの検索条件
            let searchConds = null;
            let searchCondLogic = null;
            if (this.searchCondTemp.risk.isEnabled) {
                const cmp = panel.querySelector('[data-name="risk-serach-condition"]');
                if (cmp) {
                    const result = cmp.save();
                    searchConds = result.data.searchConditions;
                    searchCondLogic = result.data.searchConditionLogic;
                }
            }
            this.searchCondition.risk.searchConds = searchConds;
            this.searchCondition.risk.searchCondLogic = searchCondLogic;
            
            // リスクアセスメントの検索条件
            searchConds = null;
            searchCondLogic = null;
            if (this.searchCondTemp.riskAssessment.isEnabled) {
                const cmp = panel.querySelector('[data-name="riskAssessment-serach-condition"]');
                if (cmp) {
                    const result = cmp.save();
                    searchConds = result.data.searchConditions;
                    searchCondLogic = result.data.searchConditionLogic;
                }
            }
            this.searchCondition.riskAssessment.searchConds = searchConds;
            this.searchCondition.riskAssessment.searchCondLogic = searchCondLogic;

            // 検索条件有効
            this.searchCondition.risk.isEnabled = this.searchCondTemp.risk.isEnabled;
            this.searchCondition.riskAssessment.isEnabled = this.searchCondTemp.riskAssessment.isEnabled;

            // リスクデータの読込み
            await this.loadRiskData();
                
            // マトリックスデータの作成
            this.createMatrixData();

            // 検索条件の保存
            await this.saveSearchCondition();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // // セル値全表示クリック時
    // handleCellValueFullDisplayClick() {
    //     this.isCellValueFullDisplay = !this.isCellValueFullDisplay;
    // }

    // 別ウィンドウで開くクリック時
    handleNewWindowOpenClick() {
        let url = '/lightning/cmp/ermt__projectRiskMatrixFull';
        let params = '';
        if (this.recordId) {
            params += (params ? '&' : '?');
            params += 'c__id=' + encodeURIComponent(this.recordId);
        }
        url += params;
        window.open(url, '_blank');
    }

    // リスク数セル色設定クリック時
    async handleRiskNumCellColorSettingClick() {
        // セル色リストのコピー
        this.cellColorsTemp = this.cellColors.map(cellColor => ({...cellColor}));

        // リスク数セル色設定ダイアログを開く
        this.openRiskNumCellColorSettingDialog();
    }

    // セル色のリスク数の変更時
    handleCellColorRiskNumChange(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const cellColor = this.cellColorsTemp[index];
        cellColor.riskNum = stringToNumber(value);
    }

    // セル色の色の変更時
    handleCellColorColorChange(event) {
        const value = event.detail.value;
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        const cellColor = this.cellColorsTemp[index];
        cellColor.color = value;
    }

    // セル色の削除のクリック時
    handleCellColorDeleteClick(event) {
        const no = event.target.dataset.no;
        const index = parseInt(no) - 1;
        this.cellColorsTemp = this.deleteCellColor(this.cellColorsTemp, index);
    }

    // セル色の追加のクリック時
    handleCellColorAddClick() {
        this.cellColorsTemp.push(this.createCellColor(this.cellColorsTemp.length + 1));
    }

    // セル色の全削除のクリック時
    handleCellColorAllDeleteClick() {
        this.cellColorsTemp = [];
    }

    // リスク数セル色設定のキャンセルのクリック時
    handleRiskNumCellColorSettingCancelClick() {
        // リスク数セル色設定ダイアログを閉じる
        this.closeRiskNumCellColorSettingDialog();
    }

    // リスク数セル色設定のOKのクリック時
    async handleRiskNumCellColorSettingOkClick() {
        // 入力チェック
        let isValid = true;
        const dialog = this.template.querySelector('[data-name="risk-num-cell-color-setting-dialog"]');
        isValid = [...dialog.querySelectorAll('lightning-input')]
            .reduce((isValidSoFar, inputCmp) => {
                    //console.log('inputCmp.name=' + inputCmp.name);
                    inputCmp.reportValidity();
                    return isValidSoFar && inputCmp.checkValidity();
                }
                , isValid
            );
        if (!isValid) return;

        this.errorMessages = null;
        try {
            // リスクマトリックスのセル色の保存
            await saveRiskMatrixCellColor({
                projectId: this.projectId
                , cellColor : (this.cellColorsTemp.length === 0 ? null : JSON.stringify(this.cellColorsTemp))
            });

            // リスク数セル色設定ダイアログを閉じる
            this.closeRiskNumCellColorSettingDialog();

            // セル色リストのセット
            this.cellColors = this.cellColorsTemp;

            // マトリックスデータの作成
            this.createMatrixData();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // エラーアラートの閉じるのクリック時
    handleErrorAlertCloseClick() {
        this.errorMessages = null;
    }

    // 初期化処理
    async initialize() {
        this.isProcessing = true;
        this.errorMessages = null;
        try {
            // // 外部ファイルの読込み
            // await loadStyle(this, jQueryUI + '/jquery-ui-1.12.1.custom/jquery-ui.min.css');
            // await loadScript(this, jQuery);
            // await loadScript(this, jQueryUI + '/jquery-ui-1.12.1.custom/jquery-ui.min.js');

            // ウィンドウサイズ変更イベントの登録
            window.addEventListener('resize', () => {
                this.windowHeight = window.innerHeight;
            }, false);

            this.projectId = this.recordId;

            // 設定の読込み
            await this.loadSetting();

            // 検索条件の読込み
            await this.loadSearchCondition();

            // 縦軸の分類・評価軸リストの取得
            if (this.vrAxisClassiGroupId) {
                this.vrAxisClassis = await getClassis({
                    classiGroupId: this.vrAxisClassiGroupId
                });
            }
            
            // 横軸の分類・評価軸リストの取得
            if (this.hrAxisClassiGroupId) {
                this.hrAxisClassis = await getClassis({
                    classiGroupId: this.hrAxisClassiGroupId
                });
            }

            // データの読込み
            await this.loadData();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        this.isProcessing = false;
    }

    // // 項目サイズ変更の更新
    // initItemResizeable() {
    //     if (!this.isItemResizableInit) return;
    //     this.isItemResizableInit = false;

    //     // 処理に時間がかかるため、非同期
    //     setTimeout(() => {
    //         // ヘッダー項目（上）のサイズ変更
    //         let items = this.template.querySelectorAll('.headerItemTop');
    //         $(items).resizable({
    //             autoHide: true
    //             , handles: 'e'
    //         });
    //     }, 0);

    //     // 処理に時間がかかるため、非同期
    //     setTimeout(() => {
    //         // ヘッダー項目（左）のサイズ変更
    //         let items = this.template.querySelectorAll('.headerItemLeft');
    //         $(items).resizable({
    //             autoHide: true
    //             , handles: 'e'
    //             // , resize: (event, ui) => {
    //             //     const target = event.target;
    //             //     const row = parseInt(target.dataset.row);
    //             //     const headerCellTop = this.header[0];
    //             //     const detailRecord = this.detail[row - 1];
    //             //     const headerCellLeft = detailRecord[0];

    //             //     // ヘッダセル（左）にサイズをセット
    //             //     headerCellLeft.width = ui.size.width;

    //             //     // 明細のヘッダ列内で最大の幅を取得
    //             //     let maxWidth = 130;
    //             //     this.detail.forEach(record => {
    //             //         const cell = record[0];
    //             //         if (cell.width && cell.width > maxWidth) {
    //             //             maxWidth = cell.width;
    //             //         }
    //             //     });

    //             //     // ヘッダセル（上）のサイズをセット
    //             //     headerCellTop.width = maxWidth;
    //             //     let headerItemTopStyle = null;
    //             //     if (headerCellTop.width) {
    //             //         headerItemTopStyle = headerItemTopStyle || '';
    //             //         headerItemTopStyle += 'width:' + headerCellTop.width + 'px;';
    //             //     }
    //             //     if (headerCellTop.height) {
    //             //         headerItemTopStyle = headerItemTopStyle || '';
    //             //         headerItemTopStyle += 'height:' + headerCellTop.height + 'px;';
    //             //     }
    //             //     headerCellTop.itemStyle = headerItemTopStyle;
    //             // }
    //         });
    //     }, 0);

    //     // 処理に時間がかかるため、非同期
    //     setTimeout(() => {
    //         // 明細項目のサイズ変更
    //         let items = this.template.querySelectorAll('.detailItem.type1');
    //         $(items).resizable({
    //             autoHide: true
    //             // , resize: (event, ui) => {
    //             //     const target = event.target;
    //             //     const row = parseInt(target.dataset.row);
    //             //     const col = parseInt(target.dataset.col);
    //             //     const headerCellTop = this.header[col];
    //             //     const detailRecord = this.detail[row - 1];
    //             //     const headerCellLeft = detailRecord[0];
    //             //     const detailCell = detailRecord[col];
                    
    //             //     // 明細セルにサイズをセット
    //             //     detailCell.width = ui.size.width;
    //             //     detailCell.height = ui.size.height;

    //             //     // 明細の対象列内で最大の幅を取得
    //             //     let maxWidth = 130;
    //             //     this.detail.forEach(record => {
    //             //         const cell = record[col];
    //             //         if (cell.width && cell.width > maxWidth) {
    //             //             maxWidth = cell.width;
    //             //         }
    //             //     });

    //             //     // 明細の対象行内で最大の高さを取得
    //             //     let maxHeight = 65;
    //             //     for (let i = 1, len = detailRecord.length; i < len; i++) {
    //             //         const cell = detailRecord[i];
    //             //         if (cell.height && cell.height > maxHeight) {
    //             //             maxHeight = cell.height;
    //             //         }
    //             //     }

    //             //     // ヘッダセル（上）のサイズをセット
    //             //     headerCellTop.width = maxWidth;
    //             //     let headerItemTopStyle = null;
    //             //     if (headerCellTop.width) {
    //             //         headerItemTopStyle = headerItemTopStyle || '';
    //             //         headerItemTopStyle += 'width:' + headerCellTop.width + 'px;';
    //             //     }
    //             //     if (headerCellTop.height) {
    //             //         headerItemTopStyle = headerItemTopStyle || '';
    //             //         headerItemTopStyle += 'height:' + headerCellTop.height + 'px;';
    //             //     }
    //             //     headerCellTop.itemStyle = headerItemTopStyle;

    //             //     // ヘッダセル（左）のサイズをセット
    //             //     headerCellLeft.height = maxHeight;
    //             //     let headerItemLeftStyle = null;
    //             //     if (headerCellLeft.width) {
    //             //         headerItemLeftStyle = headerItemLeftStyle || '';
    //             //         headerItemLeftStyle += 'width:' + headerCellLeft.width + 'px;';
    //             //     }
    //             //     if (headerCellLeft.height) {
    //             //         headerItemLeftStyle = headerItemLeftStyle || '';
    //             //         headerItemLeftStyle += 'height:' + headerCellLeft.height + 'px;';
    //             //     }
    //             //     headerCellLeft.itemStyle = headerItemLeftStyle;
    //             // }
    //         });
    //     }, 0);
    // }

    // 設定の読込み
    async loadSetting() {
        // リスクマトリックスの設定の取得
        const setting = await getRiskMatrixSetting();
        if (setting) {
            if (setting.ermt__RiskSearchFieldName__c) {
                this.riskSearchFieldNames = setting.ermt__RiskSearchFieldName__c.split(',');
            }
            if (setting.ermt__RiskAssessSearchFieldName__c) {
                this.riskAssessSearchFieldNames = setting.ermt__RiskAssessSearchFieldName__c.split(',');
            }
        }
    }

    // データの読込み
    async loadData() {
        if (this.projectId) {
            // 分類・評価軸のグループ選択リストの取得
            this.riskClassiGroupSels = await getGroupClassiSels({
                projectId: this.projectId
                , classiGroupRecordTypeName: label_classiRecordType_riskClassiGroup
                , isOptionsBlankAdd: true
            });
            //console.log('riskClassiGroupSels=' + JSON.stringify(this.riskClassiGroupSels));

            // リスクマトリックスのセル色の取得
            let cellColor = await getRiskMatrixCellColor({
                projectId: this.projectId
            });
            if (cellColor) {
                this.cellColors = JSON.parse(cellColor);
            } else {
                this.cellColors = this.defaultCellColors;
            }
            //console.log('cellColors=' + JSON.stringify(this.cellColors));
        }

        // リスクデータの読込み
        await this.loadRiskData();
        
        // マトリックスデータの作成
        this.createMatrixData();
    }

    // リスクデータの読込み
    async loadRiskData() {
        let detailItems = null;
        if (this.projectId) {
            // リスクリストの取得
            let risks = await this.getRisks({
                projectId: this.projectId
                , accountIds: this.accountIds
                , searchConds: this.searchCondition.risk.searchConds
                , searchCondLogic: this.searchCondition.risk.searchCondLogic
            });
            //console.log('risks=' + JSON.stringify(risks));

            // リスクアセスメントの検索条件が有り？
            if (
                this.analyseTimingClassiId ||
                (this.searchCondition.riskAssessment.searchConds &&
                this.searchCondition.riskAssessment.searchConds.length > 0)
            ) {
                // リスクアセスメントリストマップの取得
                const riskAssessmentsByRiskId = await this.getRiskAssessmentsByRiskId({
                    projectId: this.projectId
                    , analyseTimingClassiId: this.analyseTimingClassiId
                    , searchConds: this.searchCondition.riskAssessment.searchConds
                    , searchCondLogic: this.searchCondition.riskAssessment.searchCondLogic
                });
                //console.log('riskAssessmentsByRiskId=' + JSON.stringify(riskAssessmentsByRiskId));

                // リスクの絞り込み
                risks = risks.filter(risk => risk.Id in riskAssessmentsByRiskId);
            }

            // 明細項目リスト作成
            detailItems = risks.map(risk => this.createDetailItem(risk));
        }
        this.detailItems = detailItems;
    }

    // リスクリストの取得（ガバナ制限対応のため、分割して取得）
    async getRisks(param) {
        let ret = [];
        let lastId = null;
        let lastName = null;
        let result;
        do {
            // リスクリストの取得
            result = await getRisks({
                projectId: param.projectId
                , accountIds: param.accountIds
                , searchConds: param.searchConds
                , searchCondLogic: param.searchCondLogic
                , previousLastId: lastId
                , previousLastName: lastName
            });
            ret = ret.concat(result.data);
            lastId = result.lastId;
            lastName = result.lastName;
        } while (result.isContinue);
        return ret;
    }

    // リスクアセスメントリストマップの取得（ガバナ制限対応のため、分割して取得）
    async getRiskAssessmentsByRiskId(param) {
        const ret = {};
        let lastId = null;
        let result;
        do {
            // リスクアセスメントリストマップの取得
            result = await getRiskAssessmentsByRiskId({
                projectId: param.projectId
                , analyseTimingClassiId: param.analyseTimingClassiId
                , searchConds: param.searchConds
                , searchCondLogic: param.searchCondLogic
                , previousLastId: lastId
            });
            for (let riskId in result.data) {
                let riskAssessments = ret[riskId];
                if (!riskAssessments) riskAssessments = [];
                ret[riskId] = riskAssessments.concat(result.data[riskId]);
            }
            lastId = result.lastId;
        } while (result.isContinue);
        return ret;
    }

    // マトリックスデータの作成
    createMatrixData() {
        let header = null;
        let detail = null;
        if (
            this.hrAxisClassis && this.hrAxisClassis.length > 0 &&
            this.vrAxisClassis && this.vrAxisClassis.length > 0 &&
            this.detailItems
        ) {
            // ヘッダーの作成
            header = [];
            header.push(this.createHeaderCell(null));
            this.hrAxisClassis.forEach(classi => {
                header.push(this.createHeaderCell(classi));
            });

            // 明細の作成
            detail = [];
            this.vrAxisClassis.forEach(vrAxisClassi => {
                const record = [];
                record.push(this.createHeaderCell(vrAxisClassi));
                this.hrAxisClassis.forEach(hrAxisClassi => {
                    const items = [];
                    this.detailItems.forEach(item => {
                        if (item.classiIds.indexOf(vrAxisClassi.Id) >= 0) {
                            if (item.classiIds.indexOf(hrAxisClassi.Id) >= 0) {
                                items.push(item);
                            }
                        }
                    });
                    record.push(this.createDetailCell(vrAxisClassi, hrAxisClassi, items));
                });
                detail.push(record);
            });
        }
        this.header = header;
        //console.log('header=' + JSON.stringify(this.header));
        this.detail = detail;
        //console.log('detail=' + JSON.stringify(this.detail));

        // // 項目サイズ変更の初期化を実行する
        // this.isItemResizableInit = true;
    }

    // ヘッダーセルの作成
    createHeaderCell(classi) {
        const isType1 = (this.type === label_riskName);
        const isType2 = (this.type === label_riskNum);
        let text = null;
        if (classi) {
            text = undefineToNull(classi.ermt__Label_Pick__c);
            text = (text ? text : undefineToNull(classi.ermt__Label__c));
            text = (text ? text : label_notSet);
        }
        const cell = {
            text: text
            , isType1: isType1
            , isType2: isType2
            , class: 'headerCell'
        };
        return cell;
    }

    // 明細セルの作成
    createDetailCell(vrAxisClassi, hrAxisClassi, detailItems) {
        const isType1 = (this.type === label_riskName);
        const isType2 = (this.type === label_riskNum);
        let vrAxisText = (!vrAxisClassi ? null : undefineToNull(vrAxisClassi.ermt__Label_Pick__c));
        vrAxisText = (vrAxisText ? vrAxisText : undefineToNull(vrAxisClassi.ermt__Label__c));
        vrAxisText = (vrAxisText ? vrAxisText : label_notSet);
        let hrAxisText = (!hrAxisClassi ? null : undefineToNull(hrAxisClassi.ermt__Label_Pick__c));
        hrAxisText = (hrAxisText ? hrAxisText : undefineToNull(hrAxisClassi.ermt__Label__c));
        hrAxisText = (hrAxisText ? hrAxisText : label_notSet);
        let items = null;
        let itemNum = null;
        let style = '';
        if (isType1) {
            items = detailItems;
        }
        if (isType2) {
            itemNum = (detailItems === null ? 0 : detailItems.length);
            const backgroundColor = this.findCellColor(itemNum);
            if (backgroundColor) {
                style += 'background-color:' + backgroundColor + ';';
            }
            const textColor = getTextColorBlackOrWhite(backgroundColor);
            style += 'color:' + textColor + ';';
        }
        const cell = {
            isType1: isType1
            , isType2: isType2
            , items: items
            , itemNum: (itemNum === null ? null : formatNumber(itemNum))
            , class: 'detailCell'
            , style: style
            , title: vrAxisText + ', ' + hrAxisText
        };
        return cell;
    }

    // 明細項目の作成
    createDetailItem(risk) {
        const item = {
            text: risk.Name
            , url: '/' + risk.Id
            , classiIds: []
        };
        if (risk.ermt__Risk_Classification_Junc__r) {
            risk.ermt__Risk_Classification_Junc__r.forEach(riskClassi => {
                item.classiIds.push(riskClassi.ermt__M_Classification__c);
            });
        }
        return item;
    }

    // セル色の検索
    findCellColor(riskNum) {
        let ret = null;
        if (this.cellColors && riskNum !== null) {
            for (let i = 0, len = this.cellColors.length; i < len; i++) {
                const cellColor = this.cellColors[i];
                if (cellColor.riskNum !== null && cellColor.riskNum <= riskNum) {
                    ret = cellColor.color;
                    break;
                }
            }
        }
        return ret;
    }

    // 検索条件パネルを開く
    openSearchConditionPanel() {
        const panelWrap = this.template.querySelector('[data-name="search-condition-panel-wrap"]');
        panelWrap.classList.remove('slds-hide');
        const panel = this.template.querySelector('[data-name="search-condition-panel"]');
        panel.classList.add('slds-is-open');
    }

    // 検索条件パネルを閉じる
    closeSearchConditionPanel() {
        const panelWrap = this.template.querySelector('[data-name="search-condition-panel-wrap"]');
        panelWrap.classList.add('slds-hide');
        const panel = this.template.querySelector('[data-name="search-condition-panel"]');
        panel.classList.remove('slds-is-open');
    }

    // リスク数セル色設定ダイアログを開く
    openRiskNumCellColorSettingDialog() {
        const dialog = this.template.querySelector('[data-name="risk-num-cell-color-setting-dialog"]');
        dialog.classList.remove('slds-hide');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }

    // リスク数セル色設定ダイアログを閉じる
    closeRiskNumCellColorSettingDialog() {
        const dialog = this.template.querySelector('[data-name="risk-num-cell-color-setting-dialog"]');
        dialog.classList.add('slds-hide');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    // セル色の作成
    createCellColor(no) {
        return {
            no: no
            , riskNum: null
            , color: null
        };
    }

    // セル色の削除
    deleteCellColor(cellColors, targetIndex) {
        let no = 0;
        return cellColors.filter((cellColor, index) => {
            let ret = (index !== targetIndex);
            if (ret) {
                no++;
                cellColor.no = no;
            }
            return ret;
        });
    }

    // 検索条件の読込み
    async loadSearchCondition() {
        // カスタム機能設定の取得
        const value = await getCustomFunctionSettingValue({
            functionType: label_functionType_riskMatrixRiskClassi
            , settingType: label_settingType_searchCond
            , projectId: this.recordId
        });
        if (value) {
            const data = JSON.parse(value);
            const searchCond = data.searchCondition;
            if (searchCond) {
                if (searchCond.risk) {
                    const risk = searchCond.risk;
                    this.searchCondition.risk.isEnabled = risk.isEnabled || false;
                    this.searchCondition.risk.searchConds = risk.searchConds || null;
                    this.searchCondition.risk.searchCondLogic = risk.searchCondLogic || null;
                }
                if (searchCond.riskAssessment) {
                    const riskAss = searchCond.riskAssessment;
                    this.searchCondition.riskAssessment.isEnabled = riskAss.isEnabled || false;
                    this.searchCondition.riskAssessment.searchConds = riskAss.searchConds || null;
                    this.searchCondition.riskAssessment.searchCondLogic = riskAss.searchCondLogic || null;
                }
            }
            const projectId = data.projectId;
            if (projectId) {
                this.projectId = projectId;
            }
            const accountIds = data.accountIds;
            if (accountIds) {
                this.accountIds = accountIds;
            }
            const analyseTimingClassiId = data.analyseTimingClassiId;
            if (analyseTimingClassiId) {
                this.analyseTimingClassiId = analyseTimingClassiId;
            }
            const vrAxisClassiGroupId = data.vrAxisClassiGroupId;
            if (vrAxisClassiGroupId) {
                this.vrAxisClassiGroupId = vrAxisClassiGroupId;
            }
            const hrAxisClassiGroupId = data.hrAxisClassiGroupId;
            if (hrAxisClassiGroupId) {
                this.hrAxisClassiGroupId = hrAxisClassiGroupId;
            }
            const type = data.type;
            if (type) {
                this.type = type;
            }
        }
    }

    // 検索条件の保存
    async saveSearchCondition() {
        const data = {
            searchCondition: this.searchCondition
            , projectId: this.projectId
            , accountIds: this.accountIds
            , analyseTimingClassiId: this.analyseTimingClassiId
            , vrAxisClassiGroupId: this.vrAxisClassiGroupId
            , hrAxisClassiGroupId: this.hrAxisClassiGroupId
            , type: this.type
        };
        const value = JSON.stringify(data);

        // カスタム機能設定のセット
        await setCustomFunctionSettingValue({
            functionType: label_functionType_riskMatrixRiskClassi
            , settingType: label_settingType_searchCond
            , projectId: this.recordId
            , settingValue: value
        });
    }
}