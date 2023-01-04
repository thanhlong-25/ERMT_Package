/**
 * リスクマトリックス（リスクアセスメント分類軸）
 */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import label_title from '@salesforce/label/c.RiskMatrixRiskAssessClassi_Title';
import label_verticalAxis from '@salesforce/label/c.RiskMatrixRiskAssessClassi_VerticalAxis';
import label_horizontalAxis from '@salesforce/label/c.RiskMatrixRiskAssessClassi_HorizontalAxis';
import label_type from '@salesforce/label/c.RiskMatrixRiskAssessClassi_Type';
import label_riskName from '@salesforce/label/c.RiskMatrixRiskAssessClassi_RiskName';
import label_riskNum from '@salesforce/label/c.RiskMatrixRiskAssessClassi_RiskNum';
import label_newWindowOpen from '@salesforce/label/c.RiskMatrixRiskAssessClassi_NewWindowOpen';
import label_searchCondition from '@salesforce/label/c.RiskMatrixRiskAssessClassi_SearchCondition';
import label_searchCondition_inputError from '@salesforce/label/c.SearchCondition_InputError';
import label_cellValueFullDisplay from '@salesforce/label/c.Action_CellValueFullDisplay';
import label_account from '@salesforce/label/c.ObjectLabel_Account';
import label_project from '@salesforce/label/c.ObjectLabel_Project';
import label_risk from '@salesforce/label/c.ObjectLabel_Risk';
import label_riskClassi from '@salesforce/label/c.ObjectLabel_RiskClassi';
import label_riskAssessment from '@salesforce/label/c.ObjectLabel_RiskAssessment';
import label_riskAssessmentClassi from '@salesforce/label/c.ObjectLabel_RiskAssessmentClassi';
import label_input_selectable from '@salesforce/label/c.Input_Selectable';
import label_input_selected from '@salesforce/label/c.Input_Selected';
import label_search from '@salesforce/label/c.Action_Search';
import label_classiRecordType_analyseTiming from '@salesforce/label/c.ClassiRecordType_AnalyseTiming';
import label_classiRecordType_probability from '@salesforce/label/c.ClassiRecordType_Probability';
import label_classiRecordType_resultImpact from '@salesforce/label/c.ClassiRecordType_ResultImpact';
import label_functionType_riskMatrixRiskAssessClassi from '@salesforce/label/c.FunctionType_RiskMatrixRiskAssessClassi';
import label_settingType_searchCond from '@salesforce/label/c.SettingType_SearchCond';
import PROJECT_NAME_FIELD from '@salesforce/schema/Project__c.Name';
import RISK_OBJECT from '@salesforce/schema/Risk__c';
import RISK_ASSESSMENT_OBJECT from '@salesforce/schema/RiskAssessment__c';
import {
    getErrorMessages
    , undefineToNull
    , formatNumber
    , roundDecimal
    , getTextColorBlackOrWhite
} from 'c/commonUtil';
import getRiskMatrixSetting from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getRiskMatrixSetting';
import getRiskMatrixCellColor from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getRiskMatrixCellColor';
import getProjectSels from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getProjectSels';
import getClassiSelsGroups from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getClassiSelsGroups';
import getAxisSels from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getAxisSels';
import getClassis from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getClassis';
//import getAccounts from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getAccounts';
import getRisks from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getRisks';
import getRiskAssessments from '@salesforce/apex/RiskMatrixRiskAssessClassiCtlr.getRiskAssessments';
import getCustomFunctionSettingValue from '@salesforce/apex/CustomFunctionSettingCtlr.getCustomFunctionSettingValue';
import setCustomFunctionSettingValue from '@salesforce/apex/CustomFunctionSettingCtlr.setCustomFunctionSettingValue';

export default class RiskMatrixRiskAssessClassi extends LightningElement {
    @api recordId = null; // レコードID
    @api isNewWindowOpenButtonHide = false; // 別ウィンドウで開くボタン非表示か（未使用）
    @api isFullWindowMode = false; // フルウィンドウモードか
    // ラベル
    label = {
        title: label_title
        , verticalAxis: label_verticalAxis
        , horizontalAxis: label_horizontalAxis
        , type: label_type
        , riskName: label_riskName
        , riskNum: label_riskNum
        , newWindowOpen: label_newWindowOpen
        , searchCondition: label_searchCondition
        , cellValueFullDisplay: label_cellValueFullDisplay
        , account: label_account
        , project: label_project
        , risk: label_risk
        , riskClassi: label_riskClassi
        , riskAssessment: label_riskAssessment
        , riskAssessmentClassi: label_riskAssessmentClassi
        , selectable: label_input_selectable
        , selected: label_input_selected
        , search: label_search
        , classiRecordType_analyseTiming: label_classiRecordType_analyseTiming
    };
    errorMessages = null; // エラーメッセージリスト
    isProcessing = false; // 処理中
    projectId = null; // プロジェクトID
    accountIds = []; // 組織・部門IDリスト
    analyseTimingClassiId = null; // 分析タイミングの分類・評価軸ID
    vrAxisClassiRecordType = label_classiRecordType_resultImpact; // 縦軸の分類レコードタイプ名
    hrAxisClassiRecordType = label_classiRecordType_probability; // 横軸の分類レコードタイプ名
    axisSels = null; // 軸選択リスト
    type = label_riskName; // 種別
    searchCondition = this.defaultSearchCondition; // 検索条件
    @track searchCondTemp = this.defaultSearchCondition; // 検索条件（一時保管）
    _isSearchCondVisible = false; // 検索条件表示フラグ
    searchCondErrorMessage = null; // 検索条件エラーメッセージ
    projectSels = null; // プロジェクト選択リスト
    riskSearchFieldNames = null; // リスク検索項目リスト
    riskAssessSearchFieldNames = null; // リスクアセスメント検索項目名リスト
    isCellValueFullDisplay = false; // セル値全表示フラグ
    cellColorByKey = null; // セル色マップ
    windowHeight = window.innerHeight; // ウィンドウの高さ
    detailItems = null; // 明細項目リスト
    vrAxisClassis = null; // 縦軸の分類・評価軸リスト
    hrAxisClassis = null; // 横軸の分類・評価軸リスト
    @track header = null; // ヘッダー
    @track detail = null; // 明細
    get riskObjectName() { return RISK_OBJECT.objectApiName; } // リスクオブジェクト名
    get riskAssessmentObjectName() { return RISK_ASSESSMENT_OBJECT.objectApiName; } // リスクアセスメントオブジェクト名
    get projectSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.project.isEnabled ? '' : ' slds-hide'); } // プロジェクト検索条件クラス
    get riskSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.risk.isEnabled ? '' : ' slds-hide'); } // リスク検索条件クラス
    get riskClassiSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.riskClassi.isEnabled ? '' : ' slds-hide'); } // リスク分類検索条件クラス
    get riskAssessmentSearchCondClass() { return 'slds-section__content' + (this.searchCondTemp.riskAssessment.isEnabled ? '' : ' slds-hide'); } // リスクアセスメント検索条件クラス
    get itemWrapClass() { return (this.isCellValueFullDisplay ? '' : 'itemWrap'); } // 項目ラッパークラス

    // リスクマトリックスラップスタイル
    get riskMatrixWrapStyle() {
        const minHeight = 50;
        const marginHeight = (this.projectId ? 230 : 180);
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

    // プロジェクトIDリスト
    get projectIds() {
        const ret = [];
        if (this.projectId) {
            ret.push(this.projectId);
        }
        if (
            this.searchCondition.project.isEnabled &&
            this.searchCondition.project.value
        ) {
            ret.push(...this.searchCondition.project.value);
        }
        return ret;
    }

    // リスク分類の分類・評価軸IDリスト
    get riskClassiIds() {
        const ret = [];
        if (this.searchCondition.riskClassi.isEnabled) {
            if (this.searchCondition.riskClassi.riskClassis) {
                const riskClassis = this.searchCondition.riskClassi.riskClassis;
                riskClassis.forEach(riskClassi => {
                    if (riskClassi.isEnabled && riskClassi.value) {
                        ret.push(...riskClassi.value);
                    }
                });
            }
        }
        return ret;
    }

    // デフォルトの検索条件
    get defaultSearchCondition() {
        return {
            project: {
                isEnabled: false
                , value: null
            }
            , risk: {
                isEnabled: false
                , searchConds: null
                , searchCondLogic: null
            }
            , riskClassi: {
                isEnabled: false
                , riskClassis: null
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

    // プロジェクトレコードの取得
    @wire(getRecord, { recordId: '$recordId', fields: PROJECT_NAME_FIELD })
    project;

    // プロジェクト名
    get projectName() {
        return (!this.project ? null : getFieldValue(this.project.data, PROJECT_NAME_FIELD));
    }

    // プロジェクト参照URL
    get projectViewUrl() {
        return (!this.recordId ? null : '/' + this.recordId);
    }

    // 初期化時
    connectedCallback() {
        // 初期化処理
        this.initialize();
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
    async handleVrAxisClassiRecordTypeChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.vrAxisClassiRecordType = event.detail.value || null;

            // 縦軸の分類・評価軸リストの取得
            this.vrAxisClassis = await this.getAxisClassis({
                classiGroupRecordTypeName: this.vrAxisClassiRecordType
                , projectIds: this.projectIds
            });

            // 横軸の分類レコードタイプを自動セット
            if (this.vrAxisClassiRecordType === label_classiRecordType_probability) {
                this.hrAxisClassiRecordType = label_classiRecordType_resultImpact;
            } else {
                this.hrAxisClassiRecordType = label_classiRecordType_probability;
            }

            // 横軸の分類・評価軸リストの取得
            this.hrAxisClassis = await this.getAxisClassis({
                classiGroupRecordTypeName: this.hrAxisClassiRecordType
                , projectIds: this.projectIds
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
    async handleHrAxisClassiRecordTypeChange(event) {
        //this.isProcessing = true;
        this.errorMessages = null;
        try {
            this.hrAxisClassiRecordType = event.detail.value || null;

            // 横軸の分類・評価軸リストの取得
            this.hrAxisClassis = await this.getAxisClassis({
                classiGroupRecordTypeName: this.hrAxisClassiRecordType
                , projectIds: this.projectIds
            });

            // 縦軸の分類レコードタイプを自動セット
            if (this.hrAxisClassiRecordType === label_classiRecordType_probability) {
                this.vrAxisClassiRecordType = label_classiRecordType_resultImpact;
            } else {
                this.vrAxisClassiRecordType = label_classiRecordType_probability;
            }

            // 縦軸の分類・評価軸リストの取得
            this.vrAxisClassis = await this.getAxisClassis({
                classiGroupRecordTypeName: this.vrAxisClassiRecordType
                , projectIds: this.projectIds
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
            this.searchCondTemp.project.isEnabled = this.searchCondition.project.isEnabled;
            this.searchCondTemp.risk.isEnabled = this.searchCondition.risk.isEnabled;
            this.searchCondTemp.riskClassi.isEnabled = this.searchCondition.riskClassi.isEnabled;
            this.searchCondTemp.riskAssessment.isEnabled = this.searchCondition.riskAssessment.isEnabled;

            // プロジェクトの検索条件
            if (this.searchCondTemp.project.isEnabled) {
                this.searchCondTemp.project.value = (
                    !this.searchCondition.project.value ? null : [...this.searchCondition.project.value]
                );
            }
            
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

            // リスク分類の検索条件
            let riskClassisTemp = this.searchCondTemp.riskClassi.riskClassis;
            if (!riskClassisTemp) {
                // 分類・評価軸選択リストグループリストの取得
                let classiSelsGroups = await getClassiSelsGroups({
                    projectId: this.projectId
                });
                //console.log('classiSelsGroups=' + JSON.stringify(classiSelsGroups));
                riskClassisTemp = classiSelsGroups.map((classiSelsGroup, index) => {
                    return {
                        index: index
                        , groupId: classiSelsGroup.classiGroupId
                        , label: classiSelsGroup.label
                        , options: classiSelsGroup.options
                        , isEnabled: false
                        , searchCondClass: null
                        , value: null
                    };
                });
                this.searchCondTemp.riskClassi.riskClassis = riskClassisTemp;
            }
            const riskClassiByGroupId = {};
            if (this.searchCondition.riskClassi.riskClassis) {
                const riskClassis = this.searchCondition.riskClassi.riskClassis;
                riskClassis.forEach(riskClassi => {
                    const groupId = riskClassi.groupId || '';
                    riskClassiByGroupId[groupId] = riskClassi;
                });
            }
            riskClassisTemp.forEach(riskClassiTemp => {
                const riskClassi = riskClassiByGroupId[riskClassiTemp.groupId];
                let isEnabled = false;
                let value = null;
                if (riskClassi) {
                    isEnabled = !!riskClassi.isEnabled;
                    value = (!riskClassi.value ? null : [...riskClassi.value]);
                }
                const searchCondClass = this.getSearchCondClass(isEnabled);
                riskClassiTemp.isEnabled = isEnabled;
                riskClassiTemp.searchCondClass = searchCondClass;
                riskClassiTemp.value = value;
            });

            // 検索条件を表示
            this.isSearchCondVisible = true;
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    // プロジェクト検索条件有効の変更時
    handleProjectSearchCondEnableChange(event) {
        this.searchCondTemp.project.isEnabled = event.detail.checked;
    }

    // プロジェクト検索条件の変更時
    handleProjectSearchCondChange(event) {
        this.searchCondTemp.project.value = event.detail.value;
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

    // リスク分類検索条件有効の変更時
    handleRiskClassiSearchCondEnableChange(event) {
        this.searchCondTemp.riskClassi.isEnabled = event.detail.checked;
    }

    // リスク分類リスト検索条件有効の変更時
    handleRiskClassisSearchCondEnableChange(event) {
        const index = parseInt(event.target.dataset.index);
        const riskClassi = this.searchCondTemp.riskClassi.riskClassis[index];
        riskClassi.isEnabled = event.detail.checked;
        riskClassi.searchCondClass = this.getSearchCondClass(riskClassi.isEnabled);
    }

    // リスク分類リスト検索条件の変更時
    handleRiskClassisSearchCondChange(event) {
        const index = parseInt(event.target.dataset.index);
        const riskClassi = this.searchCondTemp.riskClassi.riskClassis[index];
        riskClassi.value = event.detail.value;
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
        // プロジェクトの検索条件
        if (this.searchCondTemp.project.isEnabled) {
            const cmp = panel.querySelector('[data-name="project-serach-condition"]');
            if (cmp) {
                cmp.reportValidity();
                isValid = isValid && cmp.checkValidity();
            }
        }
        // リスクの検索条件
        if (this.searchCondTemp.risk.isEnabled) {
            const cmp = panel.querySelector('[data-name="risk-serach-condition"]');
            if (cmp) {
                const result = await cmp.checkValidity();
                isValid = isValid && result;
            }
        }
        // リスク分類の検索条件
        if (this.searchCondTemp.riskClassi.isEnabled) {
            isValid = [...panel.querySelectorAll('[data-name="riskClassi-serach-condition"]')]
                .reduce((isValidSoFar, inputCmp) => {
                    let ret = isValidSoFar;
                    //console.log('inputCmp.dataset.index=' + inputCmp.dataset.index);
                    const index = parseInt(inputCmp.dataset.index);
                    const riskClassi = this.searchCondTemp.riskClassi.riskClassis[index];
                    if (riskClassi.isEnabled) {
                        inputCmp.reportValidity();
                        ret = ret && inputCmp.checkValidity();
                    }
                    return ret;
                }
                , isValid
            );
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
            // プロジェクトの検索条件
            let searchConds = null;
            if (this.searchCondTemp.project.isEnabled) {
                searchConds = this.searchCondTemp.project.value
            }
            this.searchCondition.project.value = searchConds;

            // リスクの検索条件
            searchConds = null;
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

            // リスク分類の検索条件
            let riskClassis = null;
            if (this.searchCondTemp.riskClassi.isEnabled) {
                const riskClassisTemp = this.searchCondTemp.riskClassi.riskClassis;
                riskClassis = riskClassisTemp.filter(riskClassiTemp => riskClassiTemp.isEnabled)
                    .map(riskClassiTemp => {
                        return {
                            groupId: riskClassiTemp.groupId
                            , isEnabled: riskClassiTemp.isEnabled
                            , value: riskClassiTemp.value
                        };
                });
            }
            this.searchCondition.riskClassi.riskClassis = riskClassis;
            
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
            this.searchCondition.project.isEnabled = this.searchCondTemp.project.isEnabled;
            this.searchCondition.risk.isEnabled = this.searchCondTemp.risk.isEnabled;
            this.searchCondition.riskClassi.isEnabled = this.searchCondTemp.riskClassi.isEnabled;
            this.searchCondition.riskAssessment.isEnabled = this.searchCondTemp.riskAssessment.isEnabled;

            if (!this.projectId) {
                // 縦軸の分類・評価軸リストの取得
                this.vrAxisClassis = await this.getAxisClassis({
                    classiGroupRecordTypeName: this.vrAxisClassiRecordType
                    , projectIds: this.projectIds
                });
                
                // 横軸の分類・評価軸リストの取得
                this.hrAxisClassis = await this.getAxisClassis({
                    classiGroupRecordTypeName: this.hrAxisClassiRecordType
                    , projectIds: this.projectIds
                });
            }

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

    // セル値全表示クリック時
    handleCellValueFullDisplayClick() {
        this.isCellValueFullDisplay = !this.isCellValueFullDisplay;
    }

    // 別ウィンドウで開くクリック時
    handleNewWindowOpenClick() {
        let url = '/lightning/cmp/ermt__riskMatrixRiskAssessClassiFull';
        let params = '';
        if (this.recordId) {
            params += (params ? '&' : '?');
            params += 'c__id=' + encodeURIComponent(this.recordId);
        }
        url += params;
        window.open(url, '_blank');
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
            // ウィンドウサイズ変更イベントの登録
            window.addEventListener('resize', () => {
                this.windowHeight = window.innerHeight;
            }, false);

            this.projectId = this.recordId;

            // 検索条件の読込み
            await this.loadSearchCondition();

            // データの読込み
            await this.loadData();
        } catch (error) {
            //console.log('error=' + JSON.stringify(error));
            this.errorMessages = getErrorMessages(error);
        }
        this.isProcessing = false;
    }

    // データの読込み
    async loadData() {
        // 設定の読込み
        await this.loadSetting();

        // 軸選択リストの取得
        this.axisSels = await getAxisSels({
            projectId: this.projectId
        });
        //console.log('axisSels=' + JSON.stringify(this.axisSels));

        if (this.projectId) {
            // セル色マップの取得
            this.cellColorByKey = await this.getCellColorByKey({
                projectId: this.projectId
            });
            //console.log('cellColorByKey=' + JSON.stringify(this.cellColorByKey));
        } else {
            // プロジェクト選択リストの取得
            this.projectSels = await getProjectSels();
        }

        // 縦軸の分類・評価軸リストの取得
        this.vrAxisClassis = await this.getAxisClassis({
            classiGroupRecordTypeName: this.vrAxisClassiRecordType
            , projectIds: this.projectIds
        });
        //console.log('vrAxisClassis=' + JSON.stringify(this.vrAxisClassis));

        // 横軸の分類・評価軸リストの取得
        this.hrAxisClassis = await this.getAxisClassis({
            classiGroupRecordTypeName: this.hrAxisClassiRecordType
            , projectIds: this.projectIds
        });
        //console.log('hrAxisClassis=' + JSON.stringify(this.hrAxisClassis));

        // リスクデータの読込み
        await this.loadRiskData();
        
        // マトリックスデータの作成
        this.createMatrixData();
    }

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

    // セル色マップの取得
    async getCellColorByKey(param) {
        // リスクマトリックスのセル色の取得
        const cellColors = await getRiskMatrixCellColor({
            projectId: param.projectId
        });

        // セル色マップの作成
        const ret = {};
        cellColors.forEach(cellColor => {
            let key = cellColor.ermt__XCordinate__c + '\t' + cellColor.ermt__YCordinate__c;
            ret[key] = cellColor;
            key = cellColor.ermt__YCordinate__c + '\t' + cellColor.ermt__XCordinate__c;
            ret[key] = cellColor;
        });
        return ret;
    }

    // 軸の分類・評価軸リストの取得
    async getAxisClassis(param) {
        // 分類・評価軸リストの取得
        let classis = await getClassis({
            classiGroupRecordTypeName: param.classiGroupRecordTypeName
            , projectIds: param.projectIds
        });

        // スコアでグループ化
        const ret = [];
        classis.forEach(classi => {
            const index = ret.findIndex(element => 
                element.score === classi.ermt__ViewNo__c
            );
            if (index < 0) {
                ret.push({
                    score: classi.ermt__ViewNo__c
                    , classis: [ classi ]
                });
            } else {
                const axisClassi = ret[index];

                // 表示ラベルの重複は追加しない
                let label = classi.ermt__Label_Pick__c;
                label = (label ? label : classi.ermt__Label__c);
                label = undefineToNull(label);
                const index2 = axisClassi.classis.findIndex(element2 => {
                    let label2 = element2.ermt__Label_Pick__c;
                    label2 = (label2 ? label2 : element2.ermt__Label__c);
                    label2 = undefineToNull(label2);
                    return (label === label2);
                });
                if (index2 < 0) {
                    axisClassi.classis.push(classi);
                }
            }
        });
        return ret;
    }

    // リスクデータの読込み
    async loadRiskData() {
        let detailItems = null;

        // リスクリストの取得
        const risks = await this.getRisks({
            projectIds: this.projectIds
            , accountIds: this.accountIds
            , classiIds: this.riskClassiIds
            , searchConds: this.searchCondition.risk.searchConds
            , searchCondLogic: this.searchCondition.risk.searchCondLogic
        });
        //console.log('risks=' + JSON.stringify(risks));

        // リスクアセスメントリストの取得
        const riskAssessments = await this.getRiskAssessments({
            projectIds: this.projectIds
            , analyseTimingClassiId: this.analyseTimingClassiId
            , searchConds: this.searchCondition.riskAssessment.searchConds
            , searchCondLogic: this.searchCondition.riskAssessment.searchCondLogic
        });
        //console.log('riskAssessments=' + JSON.stringify(riskAssessments));

        // 発生可能性の分類グループ表示ラベルの取得
        const probabilityLabel = this.getCassiGroupLabel(label_classiRecordType_probability);
        //console.log('probabilityLabel=' + probabilityLabel);

        // 発生可能性のスコアマップの作成
        const probabilityScoreByRiskId = this.createScoreByRiskId(
            label_classiRecordType_probability
            , riskAssessments
        );
        //console.log('probabilityScoreByRiskId=' + JSON.stringify(probabilityScoreByRiskId));

        // 結果の重大度の分類グループ表示ラベルの取得
        const resultImpactLabel = this.getCassiGroupLabel(label_classiRecordType_resultImpact);
        //console.log('resultImpactLabel=' + resultImpactLabel);

        // 結果の重大度のスコアマップの作成
        const resultImpactScoreByRiskId = this.createScoreByRiskId(
            label_classiRecordType_resultImpact
            , riskAssessments
        );
        //console.log('resultImpactScoreByRiskId=' + JSON.stringify(resultImpactScoreByRiskId));

        // 明細項目リスト作成
        detailItems = risks.map(risk => this.createDetailItem(
            risk
            , probabilityLabel
            , probabilityScoreByRiskId
            , resultImpactLabel
            , resultImpactScoreByRiskId
        ));
        
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
                projectIds: param.projectIds
                , accountIds: param.accountIds
                , classiIds: param.classiIds
                , dispFieldNames: param.dispFieldNames
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

    // リスクアセスメントリストの取得（ガバナ制限対応のため、分割して取得）
    async getRiskAssessments(param) {
        let ret = [];
        let lastId = null;
        let result;
        do {
            // リスクアセスメントリストの取得
            result = await getRiskAssessments({
                projectIds: param.projectIds
                , searchConds: param.searchConds
                , searchCondLogic: param.searchCondLogic
                , previousLastId: lastId
            });
            let data = result.data;
            if (param.analyseTimingClassiId) {
                data = data.filter(riskAss => {
                    let isExist = false;
                    if (riskAss.ermt__RiskAssessment_Classification_Junc__r) {
                        for (let i = 0, len = riskAss.ermt__RiskAssessment_Classification_Junc__r.length; i < len; i++) {
                            const riskAssCls = riskAss.ermt__RiskAssessment_Classification_Junc__r[i];
                            if (riskAssCls.ermt__M_Classification__c === param.analyseTimingClassiId) {
                                isExist = true;
                                break;
                            }
                        }
                    }
                    return isExist;
                });
            }
            ret = ret.concat(data);
            lastId = result.lastId;
        } while (result.isContinue);
        return ret;
    }

    // スコアマップの作成
    createScoreByRiskId(classiGroupRecordTypeName, riskAssessments) {
        // リスクIDごとのリスクアセスメントリストの作成
        const riskAsssByRiskId = {};
        riskAssessments.forEach(riskAss => {
            const riskId = riskAss.ermt__Risk__c;
            let riskAsss = riskAsssByRiskId[riskId];
            if (!riskAsss) {
                riskAsss = [];
                riskAsssByRiskId[riskId] = riskAsss;
            }
            riskAsss.push(riskAss);
        });

        // リスクIDごとのスコアの作成
        const scoreByRiskId = {};
        for (let riskId in riskAsssByRiskId) {
            const riskAsss = riskAsssByRiskId[riskId];
            let classiNum = 0;
            let totalScore = 0;
            riskAsss.forEach(riskAss => {
                if (riskAss.ermt__RiskAssessment_Classification_Junc__r) {
                    for (let i = 0, len = riskAss.ermt__RiskAssessment_Classification_Junc__r.length; i < len; i++) {
                        const riskAssCls = riskAss.ermt__RiskAssessment_Classification_Junc__r[i];
                        const classi = riskAssCls.ermt__M_Classification__r;
                        if (classi) {
                            const groupClassi = classi.ermt__ParentMClassification_del__r;
                            if (groupClassi) {
                                if (groupClassi.RecordType.DeveloperName === classiGroupRecordTypeName) {
                                    classiNum++;
                                    totalScore += (classi.ermt__ViewNo__c || 0);
                                }
                            }
                        }

                    }
                }
            });
            let score = 0;
            if (classiNum > 0) {
                score = roundDecimal(totalScore / classiNum, 2);
            }
            scoreByRiskId[riskId] = score;
        }
        return scoreByRiskId;
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
            // 縦軸の分類グループ表示ラベルの取得
            const vrAxisClassiLabel = this.getCassiGroupLabel(this.vrAxisClassiRecordType);

            // 横軸の分類グループ表示ラベルの取得
            const hrAxisClassiLabel = this.getCassiGroupLabel(this.hrAxisClassiRecordType);

            // ヘッダーの作成
            header = [];
            header.push(this.createHeaderCell(null));
            this.hrAxisClassis.forEach(classi => {
                header.push(this.createHeaderCell(classi));
            });
            header.push(this.createHeaderCell(null));

            // 明細の作成
            detail = [];
            this.vrAxisClassis.forEach((vrAxisClassi, vrIndex, vrAxisClassis) => {
                const record = [];
                record.push(this.createHeaderCell(vrAxisClassi));
                const vrAxisClassiPrev = (vrIndex === 0 ? null : vrAxisClassis[vrIndex - 1]);
                this.hrAxisClassis.forEach((hrAxisClassi, hrIndex, hrAxisClassis) => {
                    const hrAxisClassiPrev = (hrIndex === 0 ? null : hrAxisClassis[hrIndex - 1]);
                    const items = [];
                    this.detailItems.forEach(item => {
                        do {
                            let score = undefineToNull(item.scoreByType[this.vrAxisClassiRecordType]);
                            if (score === null) break;
                            if (score > vrAxisClassi.score) break;
                            if (vrAxisClassiPrev) {
                                if (score <= vrAxisClassiPrev.score) break;
                            }
                            score = undefineToNull(item.scoreByType[this.hrAxisClassiRecordType]);
                            if (score === null) break;
                            if (score > hrAxisClassi.score) break;
                            if (hrAxisClassiPrev) {
                                if (score <= hrAxisClassiPrev.score) break;
                            }
                            items.push(item);
                        } while (false);
                    });
                    record.push(this.createDetailCell(
                        this.vrAxisClassiRecordType
                        , vrAxisClassiLabel
                        , vrAxisClassi
                        , this.hrAxisClassiRecordType
                        , hrAxisClassiLabel
                        , hrAxisClassi
                        , items
                    ));
                });
                record.push(this.createHeaderCell(vrAxisClassi));
                detail.push(record);
            });
            detail = detail.reverse();
        }

        this.header = header;
        //console.log('header=' + JSON.stringify(this.header));
        this.detail = detail;
        //console.log('detail=' + JSON.stringify(this.detail));
    }

    // ヘッダーセルの作成
    createHeaderCell(classi) {
        const items = [];
        let title = null;
        if (classi) {
            const score = undefineToNull(classi.score);
            const labels = classi.classis.map(element => {
                let label = element.ermt__Label_Pick__c;
                label = (label ? label : element.ermt__Label__c);
                label = undefineToNull(label);
                return label;
            });
            if (this.projectId) {
                items.push({
                    text: score
                    , title: null
                });
                labels.forEach(label => {
                    items.push({
                        text: label
                        , title: label
                    });
                });
            } else {
                title = labels.join('\n');
                items.push({
                    text: score
                    , title: null
                });
            }
        }
        const cell = {
            items: items
            , class: null
            , title: title
        };
        return cell;
    }

    // 明細セルの作成
    createDetailCell(
        vrAxisClassiRecordType
        , vrAxisClassiLabel
        , vrAxisClassi
        , hrAxisClassiRecordType
        , hrAxisClassiLabel
        , hrAxisClassi
        , detailItems
    ) {
        const isType1 = (this.type === label_riskName);
        const isType2 = (this.type === label_riskNum);
        let vrAxisText = vrAxisClassiLabel || '';
        vrAxisText += ':';
        vrAxisText += vrAxisClassi.score || '';
        let hrAxisText = hrAxisClassiLabel || '';
        hrAxisText += ':';
        hrAxisText += hrAxisClassi.score || '';

        // 明細項目のタイトルの作成
        detailItems.forEach(item => {
            item.title = item.riskName;
            item.title += '\n';
            if (vrAxisClassiRecordType === label_classiRecordType_probability) {
                item.title += item.probability;
            } else if (vrAxisClassiRecordType === label_classiRecordType_resultImpact) {
                item.title += item.resultImpact;
            }
            item.title += '\n';
            if (hrAxisClassiRecordType === label_classiRecordType_probability) {
                item.title += item.probability;
            } else if (hrAxisClassiRecordType === label_classiRecordType_resultImpact) {
                item.title += item.resultImpact;
            }
        });

        // 項目リスト、項目数、セル色スタイルの作成
        let items = null;
        let itemNum = null;
        let style = null;
        let linkStyle = null;
        if (isType1) {
            items = detailItems;
        } else if (isType2) {
            itemNum = (detailItems === null ? 0 : detailItems.length);
        }
        const cellColor = this.findCellColor(vrAxisClassi, hrAxisClassi);
        if (cellColor) {
            style = '';
            style += 'background-color:' + cellColor.ermt__ColorCode__c + ';';
            linkStyle = '';
            linkStyle += 'background-color:' + cellColor.ermt__ColorLinkCode__c + ';';
            const textColor = getTextColorBlackOrWhite(cellColor.ermt__ColorLinkCode__c);
            linkStyle += 'color:' + textColor + ';';
        }
        const cell = {
            isType1: isType1
            , isType2: isType2
            , items: items
            , itemNum: (itemNum === null ? null : formatNumber(itemNum))
            , class: 'detailCell'
            , style: style
            , linkStyle: linkStyle
            , title: vrAxisText + '\n' + hrAxisText
        };
        return cell;
    }

    // 明細項目の作成
    createDetailItem(
        risk
        , probabilityLabel
        , probabilityScoreByRiskId
        , resultImpactLabel
        , resultImpactScoreByRiskId
    ) {
        const item = {
            text: risk.Name
            , url: '/' + risk.Id
            , title: null
            , riskName: risk.Name
            , probability: ''
            , resultImpact: ''
            , scoreByType: {}
        };
        let score;
        item.probability += probabilityLabel || '';
        item.probability += ':';
        score = undefineToNull(probabilityScoreByRiskId[risk.Id]);
        if (score !== null) {
            item.scoreByType[label_classiRecordType_probability] = score;
            item.probability += score;
        }
        item.resultImpact += resultImpactLabel || '';
        item.resultImpact += ':';
        score = undefineToNull(resultImpactScoreByRiskId[risk.Id]);
        if (score !== null) {
            item.scoreByType[label_classiRecordType_resultImpact] = score;
            item.resultImpact += score;
        }
        return item;
    }

    // 分類グループの表示ラベルの取得
    getCassiGroupLabel(classiRecordType) {
        let ret = null;
        if (this.axisSels) {
            for (let i = 0, len = this.axisSels.length; i < len; i++) {
                const axisSel = this.axisSels[i];
                if (axisSel.value === classiRecordType) {
                    ret = axisSel.label;
                    break;
                }
            }
        }
        return ret;
    }

    // セル色の検索
    findCellColor(vrAxisClassi, hrAxisClassi) {
        let ret = null;
        if (this.cellColorByKey) {
            if (
                vrAxisClassi.classis.length > 0 &&
                hrAxisClassi.classis.length > 0
            ) {
                const vrAxisClassiId = vrAxisClassi.classis[0].Id;
                const hrAxisClassiId = hrAxisClassi.classis[0].Id;
                const key = vrAxisClassiId + '\t' + hrAxisClassiId;
                const cellColor = this.cellColorByKey[key];
                if (cellColor) ret = cellColor;
            }
        }
        return ret;
    }

    // 検索条件クラスの取得
    getSearchCondClass(isEnabled) {
        return 'slds-section__content' + (isEnabled ? '' : ' slds-hide');
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

    // 検索条件の読込み
    async loadSearchCondition() {
        // カスタム機能設定の取得
        const value = await getCustomFunctionSettingValue({
            functionType: label_functionType_riskMatrixRiskAssessClassi
            , settingType: label_settingType_searchCond
            , projectId: this.recordId
        });
        if (value) {
            const data = JSON.parse(value);
            const searchCond = data.searchCondition;
            if (searchCond) {
                if (searchCond.project) {
                    const project = searchCond.project;
                    this.searchCondition.project.isEnabled = project.isEnabled || false;
                    this.searchCondition.project.value = project.value || null;
                }
                if (searchCond.risk) {
                    const risk = searchCond.risk;
                    this.searchCondition.risk.isEnabled = risk.isEnabled || false;
                    this.searchCondition.risk.searchConds = risk.searchConds || null;
                    this.searchCondition.risk.searchCondLogic = risk.searchCondLogic || null;
                }
                if (searchCond.riskClassi) {
                    const riskClassi = searchCond.riskClassi;
                    this.searchCondition.riskClassi.isEnabled = riskClassi.isEnabled || false;
                    this.searchCondition.riskClassi.riskClassis = riskClassi.riskClassis || null;
                }
                if (searchCond.riskAssessment) {
                    const riskAss = searchCond.riskAssessment;
                    this.searchCondition.riskAssessment.isEnabled = riskAss.isEnabled || false;
                    this.searchCondition.riskAssessment.searchConds = riskAss.searchConds || null;
                    this.searchCondition.riskAssessment.searchCondLogic = riskAss.searchCondLogic || null;
                }
            }
            const accountIds = data.accountIds;
            if (accountIds) {
                this.accountIds = accountIds;
            }
            const analyseTimingClassiId = data.analyseTimingClassiId;
            if (analyseTimingClassiId) {
                this.analyseTimingClassiId = analyseTimingClassiId;
            }
            const vrAxisClassiRecordType = data.vrAxisClassiRecordType;
            if (vrAxisClassiRecordType) {
                this.vrAxisClassiRecordType = vrAxisClassiRecordType;
            }
            const hrAxisClassiRecordType = data.hrAxisClassiRecordType;
            if (hrAxisClassiRecordType) {
                this.hrAxisClassiRecordType = hrAxisClassiRecordType;
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
            , accountIds: this.accountIds
            , analyseTimingClassiId: this.analyseTimingClassiId
            , vrAxisClassiRecordType: this.vrAxisClassiRecordType
            , hrAxisClassiRecordType: this.hrAxisClassiRecordType
            , type: this.type
        };
        const value = JSON.stringify(data);

        // カスタム機能設定のセット
        await setCustomFunctionSettingValue({
            functionType: label_functionType_riskMatrixRiskAssessClassi
            , settingType: label_settingType_searchCond
            , projectId: this.recordId
            , settingValue: value
        });
    }
}