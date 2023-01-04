/**
 * プロジェクト用のリスク一覧
 */
 import { LightningElement, api, track } from 'lwc';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import label_searchCondition from '@salesforce/label/c.ProjectRisklist_SearchCondition';
 import LOCALE from '@salesforce/i18n/locale';
 import CURRENCY from '@salesforce/i18n/currency';
 import TIME_ZONE from '@salesforce/i18n/timeZone';
 import label_title from '@salesforce/label/c.ProjectRisklistApproval_Title';
 import label_displayFieldsSetting from '@salesforce/label/c.ProjectRisklist_DisplayFieldsSetting';
 import label_risk from '@salesforce/label/c.ObjectLabel_Risk';
 import label_riskAssessment from '@salesforce/label/c.ObjectLabel_RiskAssessment';
 import label_riskAssessmentClassi from '@salesforce/label/c.ObjectLabel_RiskAssessmentClassi';
 import label_RiskClassi from '@salesforce/label/c.ObjectLabel_RiskClassi';
 import label_control from '@salesforce/label/c.ObjectLabel_Control';
 import label_editWarning from '@salesforce/label/c.ProjectRisklist_EditWarning';
 import label_classiRecordType_analyseTiming from '@salesforce/label/c.ClassiRecordType_AnalyseTiming';
 import label_classiRecordType_probability from '@salesforce/label/c.ClassiRecordType_Probability';
 import label_classiRecordType_resultImpact from '@salesforce/label/c.ClassiRecordType_ResultImpact';
 import label_classiRecordType_thirdEvaluation from '@salesforce/label/c.ClassiRecordType_ThirdEvaluation';
 import label_list_number from '@salesforce/label/c.List_Number';
 import label_list_page from '@salesforce/label/c.List_Page';
 import label_list_first from '@salesforce/label/c.List_First';
 import label_list_last from '@salesforce/label/c.List_Last';
 import label_list_next from '@salesforce/label/c.List_Next';
 import label_list_previous from '@salesforce/label/c.List_Previous';
 import label_input_selectable from '@salesforce/label/c.Input_Selectable';
 import label_input_selected from '@salesforce/label/c.Input_Selected';
 import label_true from '@salesforce/label/c.Value_True';
 import label_false from '@salesforce/label/c.Value_False';
 import label_save from '@salesforce/label/c.Action_Save';
 import label_ok from '@salesforce/label/c.Action_Ok';
 import label_cancel from '@salesforce/label/c.Action_Cancel';
 import label_approvalSubmit_title from '@salesforce/label/c.ApprovalSubmit_Title';
 import label_approvalSubmit_submit_confirm_1 from '@salesforce/label/c.ApprovalSubmit_Submit_Confirm_1';
 import label_approvalSubmit_submit_list_count from '@salesforce/label/c.ApprovalSubmit_Submit_List_Count';
 import label_approvalSubmit_complete from '@salesforce/label/c.ApprovalSubmit_Complete';
 import label_approvalSubmit_complete_detail from '@salesforce/label/c.ApprovalSubmit_Complete_Detail';
 import label_approvalSubmit_complete_count from '@salesforce/label/c.ApprovalSubmit_Complete_count';
 import label_approvalSubmit_incomplete_count from '@salesforce/label/c.ApprovalSubmit_Incomplete_count';
 import RISK_OBJECT from '@salesforce/schema/Risk__c';
 import RISK_ASSESSMENT_OBJECT from '@salesforce/schema/RiskAssessment__c';
 import CONTROL_OBJECT from '@salesforce/schema/Control__c';
 import {
     getErrorMessages
     , isNumber
     , isArray
     , undefineToNull
     , stringToNumber
     , TYPE_BOOLEAN
     , TYPE_DATE
     , TYPE_TIME
     , TYPE_DATETIME
     , TYPE_INTEGER
     , TYPE_LONG
     , TYPE_DOUBLE
     , TYPE_CURRENCY
     , TYPE_PERCENT
     , TYPE_PICKLIST
     , TYPE_MULTIPICKLIST
     , TYPE_STRING
     , TYPE_ID
     , TYPE_REFERENCE
 } from 'c/commonUtil';
 import checkRiskAssessmentEditPermission from '@salesforce/apex/ERMT_RiskAssessControlCC.checkEditPermission';
 import getRisklistDisplayFieldName from '@salesforce/apex/ProjectRisklistApprovalCtrl.getRisklistDisplayFieldName';
 import getRiskFieldDescByName from '@salesforce/apex/ProjectRisklistApprovalCtrl.getRiskFieldDescByName';
 import getRiskAssessmentFieldDescByName from '@salesforce/apex/ProjectRisklistApprovalCtrl.getRiskAssessmentFieldDescByName';
 import getClassificationFieldDescByName from '@salesforce/apex/ProjectRisklistApprovalCtrl.getClassificationFieldDescByName';
 import getRisks from '@salesforce/apex/ProjectRisklistApprovalCtrl.getRisks';
 import getRiskAssessmentsByRiskId from '@salesforce/apex/ProjectRisklistApprovalCtrl.getRiskAssessmentsByRiskId';
 import getClassificationsByRiskId from '@salesforce/apex/ProjectRisklistApprovalCtrl.getClassificationsByRiskId';
 import applyApproval from '@salesforce/apex/ProjectRisklistApprovalCtrl.applyApproval';
 import getGroupClassiSels from '@salesforce/apex/ProjectRisklistApprovalCtrl.getGroupClassiSels';
 import saveRisklistDisplayFieldName from '@salesforce/apex/ProjectRisklistApprovalCtrl.saveRisklistDisplayFieldName';
 import label_classiRecordType_riskClassiGroup from '@salesforce/label/c.ClassiRecordType_RiskClassiGroup';
 import getRiskDisplayFieldNameSels from '@salesforce/apex/ProjectRisklistCtlr.getRiskDisplayFieldNameSels';
import getRiskAssessmentDisplayFieldNameSels from '@salesforce/apex/ProjectRisklistCtlr.getRiskAssessmentDisplayFieldNameSels';
 export default class ProjectRisklistApproval extends LightningElement {
     @api recordId; // レコードID
     // ラベル
     label = {
         title: label_title
         , displayFieldsSetting: label_displayFieldsSetting
         , searchCondition: label_searchCondition
         , risk: label_risk
         , riskAssessment: label_riskAssessment
         , riskAssessmentClassi: label_riskAssessmentClassi
         , riskClassi : label_RiskClassi
         , control: label_control
         , editWarning: label_editWarning
         , list_number: label_list_number
         , list_page: label_list_page
         , list_first: label_list_first
         , list_last: label_list_last
         , list_next: label_list_next
         , list_previous: label_list_previous
         , selectable: label_input_selectable
         , selected: label_input_selected
         , save: label_save
         , ok: label_ok
         , cancel: label_cancel
         , approvalSubmit_title: label_approvalSubmit_title
         , approvalSubmit_submit_confirm_1: label_approvalSubmit_submit_confirm_1
         , approvalSubmit_submit_list_count: label_approvalSubmit_submit_list_count
         , approvalSubmit_complete: label_approvalSubmit_complete
         , approvalSubmit_complete_detail: label_approvalSubmit_complete_detail
         , approvalSubmit_complete_count: label_approvalSubmit_complete_count
         , approvalSubmit_incomplete_count: label_approvalSubmit_incomplete_count
     };
     errorMessages = null; // エラーメッセージリスト
     isProcessing = false; // 処理中
     isOriginalStyleRendered = false; // 独自スタイル描画済
     displayFieldName = this.defaultDisplayFieldName; // 表示項目名
     @track dispFieldNameTemp = this.defaultDisplayFieldName; // 表示項目名（一時保管）
     riskDisplayFieldNameSels = null; // リスク表示項目名選択リスト
     riskAssessmentDisplayFieldNameSels = null; // リスクアセスメント表示項目名選択リスト
     controlDisplayFieldNameSels = null; // 対応策表示項目名選択リスト
     analyseTimingSelsInfo = null; // 分析タイミング選択リスト情報
     probabilitySelsInfo = null; // 発生可能性選択リスト情報
     resultImpactSelsInfo = null; // 結果影響度選択リスト情報
     thirdEvaluationSelsInfo = null; // 第三評価選択リスト情報
     windowHeight = window.innerHeight; // ウィンドウの高さ
     header1 = null; // ヘッダー1
     @track header2 = null; // ヘッダー2
     @track detail = null; // 明細
     @track detailRaw = null; // 明細（元データ）
     @track fixedHeaderTop = this.createFixedHeaderTop(); // 固定ヘッダ（上）
     isEditing = false; // 編集中
     editingCell = null; // 編集中のセル
     get riskObjectName() { return RISK_OBJECT.objectApiName; } // リスクオブジェクト名
     get riskAssessmentObjectName() { return RISK_ASSESSMENT_OBJECT.objectApiName; } // リスクアセスメントオブジェクト名
     get controlObjectName() { return CONTROL_OBJECT.objectApiName; } // 対応策オブジェクト名
     isExecuteDisabled = true;
     comment = null; 
     riskClassiGroupSels = null;
     riskClassiDefault = null;
     riskClassiSelected = null;
     searchCondition = this.defaultSearchCondition; // 検索条件
    @track searchCondTemp = this.defaultSearchCondition; // 検索条件（一時保管）
    checklist_count = null;
     // ページ情報
     @track pageInfo = {
         pageNumber: 1
         , lastPageNumber: 1
         , pageSize: 30
         , resultSize: 0
         , rowNumberOffset: 0
     };
 
     // 列幅情報
     columnWidthInfo = {
         col: null
         , width: null
         , clientX: null
     }

     get defaultSearchCondition() {
        return {
            riskClassi: {
                isEnabled: false
                , riskClassis: null
            }
        };
    }
 
     // リスクリストラップスタイル
     get risklistWrapStyle() {
         const minHeight = 200;
         const marginHeight = (this.recordId ? 230 : 180);
         let maxHeight = this.windowHeight - marginHeight;
         if (maxHeight < minHeight) maxHeight = minHeight;
         return 'min-height:' + minHeight + 'px;max-height:' + maxHeight + 'px;';
     }
 
     // デフォルトの表示項目名
     get defaultDisplayFieldName() {
         return {
             risk: [
                 'Name'
                 , 'ermt__Organization__c'
             ]
             , riskAssessment: [
                 'ermt__EvaluationWorkedDate__c'
                 , 'ermt__isActive__c'
             ]
             , riskClassificationJunc: []
         };
     }
 
     get isFirstPageEnable() {
         return (this.pageInfo.pageNumber > 2);
     }
 
     get isLastPageEnable() {
         return (this.pageInfo.pageNumber < (this.pageInfo.lastPageNumber - 1));
     }
 
     get isNextPageEnable() {
         return (this.pageInfo.pageNumber < this.pageInfo.lastPageNumber);
     }
 
     get isPreviousPageEnable() {
         return (this.pageInfo.pageNumber > 1);
     }

     async connectedCallback() {
         this.isProcessing = true;
         try {
             window.addEventListener('resize', () => {
                 this.windowHeight = window.innerHeight;
             }, false);
             await this.loadRisklist();
         } catch (error) {
             console.log('error=' + JSON.stringify(error));
             this.errorMessages = getErrorMessages(error);
         }
         this.isProcessing = false;
     }
 
     renderedCallback() {
         this.addOriginalStyle();
     }

     handleMainClick(event) {
         this.finishDetailCellEdit();
     }
 
     handlePageMoveClick(event) {
         event.preventDefault();
         const name = event.target.dataset.name;
         if (name === 'first-page') {
             this.pageInfo.pageNumber = 1;
         } else if (name === 'last-page') {
             this.pageInfo.pageNumber = this.pageInfo.lastPageNumber;
         } else if (name === 'next-page') {
             this.pageInfo.pageNumber++;
         } else if (name === 'previous-page') {
             this.pageInfo.pageNumber--;
         }
 
         const detailParPage = this.pagingRisklistDetail(this.detailRaw);

         const detail = this.groupingRisklistDetail(detailParPage);
 
         this.detail = detail;
     }
 
     handleColumnSortClick(event) {
         event.preventDefault();
         const target = event.currentTarget;
         const col = stringToNumber(target.dataset.col);
         if (col === null) return;
         const cell = target.closest('th');
         if (!cell) return;
         let isAscending = true;
         if (
             cell.classList.contains('slds-is-sorted_asc') &&
             cell.classList.contains('slds-is-sorted')
         ) {
             isAscending = false;
         }
         
         this.header2.forEach((cell, index) => {
             if (col === index) {
                 cell.cellClass = this.getHeader2CellClass(isAscending, true);
             } else {
                 cell.cellClass = this.getHeader2CellClass(true, false);
             }
         });
 
         this.detailRaw.sort((rec1, rec2) => {
             let ret = 0;
             const cell1 = rec1[col];
             const cell2 = rec2[col];
             if (cell1 && cell2) {
                 const value1 = this.getDetailSortValue(cell1.item.value, cell1.item.text, cell1.item.type);
                 const value2 = this.getDetailSortValue(cell2.item.value, cell2.item.text, cell2.item.type);
                 if (value1 !== null && value2 !== null) {
                     if (value1 < value2) {
                         ret = -1;
                     } else if (value1 > value2) {
                         ret = 1;
                     }
                 } else if (value1 !== null) {
                     ret = 1;
                 } else if (value2 !== null) {
                     ret = -1;
                 }
                 if (ret != 0 && !isAscending) ret *= -1;
             }
             return ret;
         });
 
         this.detailRaw.forEach((rec, index) => {
             rec.forEach(cell => {
                 cell.row = index;
             });
         });
 
         const detailParPage = this.pagingRisklistDetail(this.detailRaw);
             
         const detail = this.groupingRisklistDetail(detailParPage);
 
         this.detail = detail;
     }
 
     handleColumnWidthMousedown(event) {
         const target = event.currentTarget;
         const col = stringToNumber(target.dataset.col);
         const cell = target.closest('th');
         if (cell) {
             const elm = cell.querySelector('.col-width');
             if (elm) {
                 this.columnWidthInfo.col = col;
                 this.columnWidthInfo.width = elm.offsetWidth;
                 this.columnWidthInfo.clientX = event.clientX;
             }
         }
     }

     handleEditSaveClick() {
        const dialog = this.template.querySelector('[data-name="display-comment-dialog"]');
        dialog.classList.remove('slds-hide');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
        this.checklist_count = this.template.querySelectorAll('input[name="approval-checkboxes"]:checked').length;
    }

     handleConfirmPopup() {
        const dialog = this.template.querySelector('[data-name="display-submit-confirm-dialog"]');
        dialog.classList.remove('slds-hide');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
        this.handleCancelApproval();
     }


     handleColumnWidthMousemove(event) {
         if (this.columnWidthInfo.col === null) return;
         const col = this.columnWidthInfo.col;
         let width = (event.clientX - this.columnWidthInfo.clientX) + this.columnWidthInfo.width;
         if (width < 0) width = 0;
         const cell = this.header2[col];
         if (cell) {
             cell.colWidthStyle = 'width:' + width + 'px';
         }
         this.detailRaw.forEach(rec => {
             const cell = rec[col];
             if (cell) {
                 cell.colWidthStyle = 'width:' + width + 'px';
             }
         });
     }
 
     handleColumnWidthMouseup(event) {
         this.columnWidthInfo.col = null;
     }
 
     handleRisklistWrapScroll(event) {
         const target = event.target;
         this.fixedHeaderTop = this.createFixedHeaderTop(target);
     }

    handleCancelApproval() {
        const dialog = this.template.querySelector('[data-name="display-comment-dialog"]');
        dialog.classList.add('slds-hide');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    handleCancelConfirmApproval() {
        const dialog = this.template.querySelector('[data-name="display-submit-confirm-dialog"]');
        dialog.classList.add('slds-hide');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    openDisplayFieldsSettingDialog() {
        const dialog = this.template.querySelector('[data-name="display-fields-setting-dialog"]');
        dialog.classList.remove('slds-hide');
        dialog.classList.add('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.add('slds-backdrop_open');
    }

    closeDisplayFieldsSettingDialog() {
        const dialog = this.template.querySelector('[data-name="display-fields-setting-dialog"]');
        dialog.classList.add('slds-hide');
        dialog.classList.remove('slds-fade-in-open');
        const backdrop = this.template.querySelector('[data-name="dialog-backdrop"]');
        backdrop.classList.remove('slds-backdrop_open');
    }

    async handleDisplayFieldsSettingClick() {
        this.errorMessages = null;
        try {
            this.riskDisplayFieldNameSels = await getRiskDisplayFieldNameSels();
            this.riskAssessmentDisplayFieldNameSels = await getRiskAssessmentDisplayFieldNameSels({
                projectId: this.recordId
            });
            this.dispFieldNameTemp.risk = [...this.displayFieldName.risk];
            this.dispFieldNameTemp.riskAssessment = [...this.displayFieldName.riskAssessment];

            this.openDisplayFieldsSettingDialog();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
    }

    handleDisplayFieldsSettingCancelClick() {
        this.closeDisplayFieldsSettingDialog();
    }

    async handleDisplayFieldsSettingOkClick() {
        try {
            await saveRisklistDisplayFieldName({
                projectId: this.recordId
                , fieldName : JSON.stringify(this.dispFieldNameTemp)
            });
            this.closeDisplayFieldsSettingDialog();
            await this.loadRisklist();
        } catch (error) {
            this.errorMessages = getErrorMessages(error);
        }
        this.isProcessing = false;
    }

    handleApproval(){
         this.isProcessing = true;
         this.errorMessages = null;
         try {
            let result = this.multiApplyApproval();
            
            this.handleCancelConfirmApproval();
         } catch (error) {
             this.errorMessages = getErrorMessages(error);
         }
         this.isProcessing = false;
         
    }

    handleCommentChange(event) {
        this.comment = event.detail.value;
    }

    async multiApplyApproval() {
        const listRistId = [];
        var checkedBoxes = this.template.querySelectorAll('input[name="approval-checkboxes"]:checked');
        for(var i=0; i<checkedBoxes.length; i++){
            listRistId.push(checkedBoxes[i].value); 
        }
        let result = await applyApproval({
            comment: this.comment,
            riskIdApproval: listRistId
        });
        if (result.isSuccess){
            const evt = new ShowToastEvent({
                title: this.label.approvalSubmit_complete,
                message: this.label.approvalSubmit_complete_detail +  this.label.approvalSubmit_complete_count + '：'+result.successCount+' 、' + this.label.approvalSubmit_incomplete_count +'：'+result.failCount,
                variant: 'success',
            });
            this.dispatchEvent(evt);
        } else {
            this.errorMessages = getErrorMessages(result.errorMessage);
        }
        return result;
    }

    updateCheckbox() {
        this.isExecuteDisabled = true;
        var checkedBoxes = this.template.querySelectorAll('input[name="approval-checkboxes"]:checked');
        if (checkedBoxes.length > 0) this.isExecuteDisabled = false;
    }

    handleClickAll(){
        var checkedBoxes = this.template.querySelectorAll('input[name="checkAll"]:checked');
        var childBoxes = this.template.querySelectorAll('input[name="approval-checkboxes"]');
        if (checkedBoxes.length == 1){
            for(var i=0; i<childBoxes.length; i++){
                childBoxes[i].checked = true;  
            } 
            this.isExecuteDisabled = false; 
        } else {
            for(var i=0; i<childBoxes.length; i++){
                childBoxes[i].checked = false;  
            }
            this.isExecuteDisabled = true;
        }
    }

     handleErrorAlertCloseClick() {
         this.errorMessages = null;
     }
 
     addOriginalStyle() {
         if (this.isOriginalStyleRendered) return;
         this.isOriginalStyleRendered = true;
 
         const style = document.createElement('style');
         style.innerHTML =
             `table.risklist lightning-input lightning-datepicker lightning-calendar div.slds-datepicker {
                 top: 32px !important;
             }
             table.risklist lightning-input lightning-timepicker div.slds-listbox {
                 top: 32px !important;
             }`;
         this.template.querySelector('lightning-card.main').appendChild(style);
     }
 
     createFixedHeaderTop(target) {
         let style = '';
         if (target) {
             style = (target.scrollTop > 0 ? 'top:' + target.scrollTop + 'px;' : '');
         }
         return {
             style: style
         };
     }

     
    changeRiskClassiGroupSels(event) {
        this.riskClassiSelected = event.detail.value;
        this.displayFieldName.riskClassificationJunc = event.detail.value;
        this.dispFieldNameTemp.riskClassificationJunc = event.detail.value;
    }

    handleRiskDisplayFieldNameChange(event) {
        this.dispFieldNameTemp.risk = event.detail.value;
    }

    handleRiskAssessmentDisplayFieldNameChange(event) {
        this.dispFieldNameTemp.riskAssessment = event.detail.value;
    }

 
     async loadRisklist() {
        this.isProcessing = true;
         const isRiskAssessAllEditable = await checkRiskAssessmentEditPermission();
        
         this.riskClassiGroupSels = await getGroupClassiSels({
            projectId: this.recordId
            , classiGroupRecordTypeName: label_classiRecordType_riskClassiGroup
            , isOptionsBlankAdd: false
        });

        console.log(this.riskClassiGroupSels);
        

         let displayFieldName = await getRisklistDisplayFieldName({
             projectId: this.recordId
         });
         displayFieldName = !displayFieldName ? null : JSON.parse(displayFieldName);
         this.displayFieldName = displayFieldName || this.defaultDisplayFieldName;
         this.riskClassiDefault = !this.displayFieldName.riskClassificationJunc? this.riskClassiGroupSels[0].label : this.displayFieldName.riskClassificationJunc;
         const riskFieldDescByName = await getRiskFieldDescByName({
             dispFieldNames: this.displayFieldName.risk
         });

         const riskAssessmentFieldDescByName = await getRiskAssessmentFieldDescByName({
             projectId: this.recordId
             , dispFieldNames: this.displayFieldName.riskAssessment
         });
         var kindRecord = this.riskClassiSelected == null ? this.riskClassiDefault: this.riskClassiSelected;
         this.displayFieldName.riskClassificationJunc = [];
         this.displayFieldName.riskClassificationJunc.push('ermt__Label_Pick__c');
         
         const controlFieldDescByName = await getClassificationFieldDescByName({
             dispFieldNames : this.displayFieldName.riskClassificationJunc
         });
         const risks = await this.getRisks({
             projectId: this.recordId
             , dispFieldNames: this.displayFieldName.risk
         });

         const riskAssessmentsByRiskId = await this.getRiskAssessmentsByRiskId({
             projectId: this.recordId
             , dispFieldNames: this.displayFieldName.riskAssessment
         });
         
         const controlsByRiskIds = []
            for (let index = 0; index < kindRecord.length; index++) {
                const controlsByRiskId1 = await this.getClassificationsByRiskId({
                    projectId: this.recordId
                    , dispFieldNames: this.displayFieldName.riskClassificationJunc
                    , kindRecordType: kindRecord[index]
                });
                controlsByRiskIds.push(controlsByRiskId1);
            }
         const analyseTimingInfos = [];
         const riskAssessmentsByAnalyseTimingByRiskId = {};
         let isAnalyseTimingGrouping = true;
         if (this.displayFieldName.riskAssessment != null && this.displayFieldName.riskAssessment.length === 1) {
             const fieldName = this.displayFieldName.riskAssessment[0];
             if (fieldName === label_classiRecordType_analyseTiming) {
                 isAnalyseTimingGrouping = false;
             }
         }
         if (isAnalyseTimingGrouping) {
             Object.keys(riskAssessmentsByRiskId).forEach(riskId => {
                 const recs = riskAssessmentsByRiskId[riskId];
                 let riskAssessmentsByAnalyseTiming = riskAssessmentsByAnalyseTimingByRiskId[riskId];
                 if (!riskAssessmentsByAnalyseTiming) {
                     riskAssessmentsByAnalyseTiming = {};
                     riskAssessmentsByAnalyseTimingByRiskId[riskId] = riskAssessmentsByAnalyseTiming;
                 }
                 recs.forEach(rec => {
                     let name = label_classiRecordType_analyseTiming;
                     const value = undefineToNull(rec[name]);
                     name = label_classiRecordType_analyseTiming + '_Label';
                     const label = undefineToNull(rec[name]);
                     name = label_classiRecordType_analyseTiming + '_ViewNo';
                     const viewNo = undefineToNull(rec[name]);
                     if (value) {
                         analyseTimingInfos.push({
                             value: value
                             , label: label
                             , viewNo: viewNo
                         });
                         let riskAssessments = riskAssessmentsByAnalyseTiming[label];
                         if (!riskAssessments) {
                             riskAssessments = [];
                             riskAssessmentsByAnalyseTiming[label] = riskAssessments;
                         }
                         riskAssessments.push(rec);
                     }
                 });
             });
         }

         analyseTimingInfos.sort((item1, item2) => {
             const viewNo1 = (item1.viewNo === null ? 0 : item1.viewNo);
             const viewNo2 = (item2.viewNo === null ? 0 : item2.viewNo);
             const label1 = (item1.label === null ? 0 : item1.label);
             const label2 = (item2.label === null ? 0 : item2.label);
             if (viewNo1 < viewNo2) {
                 return -1;
             } else if (viewNo1 > viewNo2) {
                 return 1;
             } else {
                 if (label1 < label2) {
                     return -1;
                 } else if (label1 > label2) {
                     return 1;
                 }
             }
             return 0;
         });
         const analyseTimings = [];
         analyseTimingInfos.forEach(item => {
             const label = item.label;
             if (!analyseTimings.some(target => target === label)) {
                 analyseTimings.push(label);
             }
         });

         const header1 = [];
         const header2 = [];
         let colspan;
         let row;
         let col;
 
         col = -1;
         colspan = 0;
         this.displayFieldName.risk.forEach(fieldName => {
             const fieldDesc = riskFieldDescByName[fieldName];
             if (fieldDesc) {
                 col++;
                 colspan++;
                 header2.push({
                     text: this.getHeaderText(fieldDesc.label, fieldDesc.type)
                     , col: col
                     , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                     , cellClass : this.getHeader2CellClass(true, false)
                 });
             }
         });
         if (colspan > 0) {
             header1.push({
                 text: this.label.risk
                 , colspan: colspan
             });
         }
 
         if (analyseTimings.length === 0) {
             colspan = 0;
             this.displayFieldName.riskAssessment.forEach(fieldName => {
                 const fieldDesc = riskAssessmentFieldDescByName[fieldName];
                 if (fieldDesc) {
                     col++;
                     colspan++;
                     header2.push({
                         text: this.getHeaderText(fieldDesc.label, fieldDesc.type)
                         , col: col
                         , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                         , cellClass : this.getHeader2CellClass(true, false)
                     });
                 }
             });
             if (colspan > 0) {
                 header1.push({
                     text: this.label.riskAssessment
                     , colspan: colspan
                 });
             }
         } else {
             analyseTimings.forEach(analyseTiming => {
                 colspan = 0;
                 this.displayFieldName.riskAssessment.forEach(fieldName => {
                     if (fieldName !== label_classiRecordType_analyseTiming) {
                         const fieldDesc = riskAssessmentFieldDescByName[fieldName];
                         if (fieldDesc) {
                             col++;
                             colspan++;
                             header2.push({
                                 text: this.getHeaderText(fieldDesc.label, fieldDesc.type)
                                 , col: col
                                 , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                                 , cellClass : this.getHeader2CellClass(true, false)
                             });
                         }
                     }
                 });
                 if (colspan > 0) {
                     header1.push({
                         text: analyseTiming
                         , colspan: colspan
                     });
                 }
             });
         }
         if (this.displayFieldName.riskClassificationJunc.length > 0) {
            colspan = 0;
            kindRecord.forEach(riskClssiName => {
            this.displayFieldName.riskClassificationJunc.forEach(fieldName => {
                const fieldDesc = controlFieldDescByName[fieldName];
                if (fieldDesc) {
                    col++;
                    colspan++;
                    header2.push({
                        text: this.getHeaderText(riskClssiName, fieldDesc.type)
                        , col: col
                        , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                        , cellClass : this.getHeader2CellClass(true, false)
                    });
                }
            });
            });
        }
         if (colspan > 0) {
             header1.push({
                 text: this.label.riskClassi
                 , colspan: colspan
             });
         }

         const detailRaw = [];
         row = -1;
         risks.forEach(risk => {
             const riskId = risk.Id;
             const riskAssessments = (analyseTimings.length !== 0 ? null : riskAssessmentsByRiskId[riskId]);
             const riskAssessmentsByAnalyseTiming = (analyseTimings.length === 0 ? null : riskAssessmentsByAnalyseTimingByRiskId[riskId]);
             
 
             let isTarget = true;
 
             if (isTarget) {
                 let relationMax = 1;
                 if (analyseTimings.length === 0) {
                     if (riskAssessments) {
                         relationMax = (relationMax < riskAssessments.length ? riskAssessments.length : relationMax);
                     }
                 } else {
                     if (riskAssessmentsByAnalyseTiming) {
                         Object.keys(riskAssessmentsByAnalyseTiming).forEach(analyseTiming => {
                             const riskAssessments = riskAssessmentsByAnalyseTiming[analyseTiming];
                             relationMax = (relationMax < riskAssessments.length ? riskAssessments.length : relationMax);
                         });
                     }
                 }
                 

                 const riskItems = [];
                 const isRiskEditable = risk['HasEditAccess'] || false;
                 this.displayFieldName.risk.forEach(fieldName => {
                     const fieldDesc = riskFieldDescByName[fieldName];
                     if (fieldDesc) {
                         let name = fieldName;
                         const value = undefineToNull(risk[name]);
                         name = fieldName + '_Label';
                         const label = undefineToNull(risk[name]);   
                         riskItems.push(this.createDetailItem({
                             value: value
                             , label: label
                             , type: fieldDesc.type
                             , isRequired: (fieldName === 'Name' ? true : !fieldDesc.isNillable)
                             , isEditable: (!isRiskEditable || fieldName === 'RecordTypeId' ? false : fieldDesc.isUpdateable)
                             , objectName: RISK_OBJECT.objectApiName
                             , fieldName: fieldName
                             , riskId: riskId
                         }));
                     }
                 });
                 for (let i = 0; i < relationMax; i++) {
                     const rec = [];
                     row++;
                     col = -1;
 
                     riskItems.forEach(item => {
                         col++;
                         rec.push({
                             row: row
                             , col: col
                             , colWidthStyle: this.getDefaultColumnWidthStyle(item.type)
                             , rowspan: 1
                             , isEditing: false
                             , item: item
                         });
                     });
 
                     if (analyseTimings.length === 0) {
                         let riskAssessment = null;
                         let isRiskAssessEditable = false;
                         if (riskAssessments && i < riskAssessments.length) {
                             riskAssessment = riskAssessments[i];
                             isRiskAssessEditable = isRiskAssessAllEditable;
                             if (!isRiskAssessEditable) {
                                 isRiskAssessEditable = riskAssessment['HasEditAccess'] || false;
                             }
                         }
                         this.displayFieldName.riskAssessment.forEach(fieldName => {
                             const fieldDesc = riskAssessmentFieldDescByName[fieldName];
                             if (fieldDesc) {
                                 let value = null;
                                 let label = null;
                                 let isEditable = false;
                                 let riskAssessmentId = null;
                                 if (riskAssessment) {
                                     let name = fieldName;
                                     value = undefineToNull(riskAssessment[name]);
                                     name = fieldName + '_Label';
                                     label = undefineToNull(riskAssessment[name]);
                                     if (isRiskAssessEditable) {
                                         isEditable = fieldDesc.isUpdateable;
                                     }
                                     riskAssessmentId = riskAssessment.Id;
                                 }
                                 col++;
                                 rec.push({
                                     row: row
                                     , col: col
                                     , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                                     , rowspan: 1
                                     , isEditing: false
                                     , item: this.createDetailItem({
                                         value: value
                                         , label: label
                                         , type: fieldDesc.type
                                         , isRequired: !fieldDesc.isNillable
                                         , isEditable: isEditable
                                         , objectName: RISK_ASSESSMENT_OBJECT.objectApiName
                                         , fieldName:　fieldName
                                         , riskId: riskId
                                         , riskAssessmentId: riskAssessmentId
                                     })
                                 });
                             }
                         });
                     } else {
                         analyseTimings.forEach(analyseTiming => {
                             let riskAssessments = null;
                             if (riskAssessmentsByAnalyseTiming) {
                                 riskAssessments = riskAssessmentsByAnalyseTiming[analyseTiming];
                             }
                             let riskAssessment = null;
                             let isRiskAssessEditable = false;
                             if (riskAssessments && i < riskAssessments.length) {
                                 riskAssessment = riskAssessments[i];
                                 isRiskAssessEditable = isRiskAssessAllEditable;
                                 if (!isRiskAssessEditable) {
                                     isRiskAssessEditable = riskAssessment['HasEditAccess'] || false;
                                 }
                             }
                             this.displayFieldName.riskAssessment.forEach(fieldName => {
                                 if (fieldName !== label_classiRecordType_analyseTiming) {
                                     const fieldDesc = riskAssessmentFieldDescByName[fieldName];
                                     if (fieldDesc) {
                                         let value = null;
                                         let label = null;
                                         let isEditable = false;
                                         let riskAssessmentId = null;
                                         if (riskAssessment) {
                                             let name = fieldName;
                                             value = undefineToNull(riskAssessment[name]);
                                             name = fieldName + '_Label';
                                             label = undefineToNull(riskAssessment[name]);
                                             if (isRiskAssessEditable) {
                                                 if (fieldName !== 'RecordTypeId') {
                                                     isEditable = fieldDesc.isUpdateable;
                                                 }
                                             }
                                             riskAssessmentId = riskAssessment.Id;
                                         }
                                         col++;
                                         rec.push({
                                             row: row
                                             , col: col
                                             , colWidthStyle: this.getDefaultColumnWidthStyle(fieldDesc.type)
                                             , rowspan: 1
                                             , isEditing: false
                                             , item: this.createDetailItem({
                                                 value: value
                                                 , label: label
                                                 , type: fieldDesc.type
                                                 , isRequired: !fieldDesc.isNillable
                                                 , isEditable: isEditable
                                                 , objectName: RISK_ASSESSMENT_OBJECT.objectApiName
                                                 , fieldName:　fieldName
                                                 , riskId: riskId
                                                 , riskAssessmentId: riskAssessmentId
                                             })
                                         });
                                     }
                                 }
                             });
                         });
                     }
                     if (this.displayFieldName.riskClassificationJunc.length > 0) {
                        controlsByRiskIds.forEach( controlsByRiskId => {
                            const controls = controlsByRiskId[riskId];
                            if (controls) {
                                relationMax = (relationMax < controls.length ? controls.length : relationMax);
                            }
                            let control = null;
                            if (controls && i < controls.length) {
                                control = controls[i];
                            }
                            this.displayFieldName.riskClassificationJunc.forEach(fieldName => {
                                const fieldDesc = controlFieldDescByName[fieldName];
                                if (fieldDesc) {
                                    let value = null;
                                    let label = null;
                                    let type = null;
                                    let isEditable = false;
                                    let riskControlId = null;
                                    if (control) {
                                        if (fieldName === 'Name') {
                                            value = undefineToNull(control.Id);
                                            label = undefineToNull(control[fieldName]);
                                            type = TYPE_REFERENCE;
                                            isEditable = true;
                                            riskControlId = control.riskControlId;
                                        } else {
                                            let name = fieldName;
                                            value = undefineToNull(control[name]);
                                            name = fieldName + '_Label';
                                            label = undefineToNull(control[name]);
                                            type = fieldDesc.type;
                                        }
                                    } else {
                                        if (fieldName === 'Name') {
                                            type = TYPE_REFERENCE;
                                            isEditable = true;
                                        }
                                    }
                                    col++;
                                    rec.push({
                                        row: row
                                        , col: col
                                        , colWidthStyle: this.getDefaultColumnWidthStyle(type)
                                        , rowspan: 1
                                        , isEditing: false
                                        , item: this.createDetailItem({
                                            value: value
                                            , label: label
                                            , type: type
                                            , isRequired: false
                                            , isEditable: isEditable
                                            , objectName: CONTROL_OBJECT.objectApiName
                                            , fieldName:　fieldName
                                            , riskId: riskId
                                            , riskControlId: riskControlId
                                        })
                                    });
                                }
                            });
                        });
                    }
                     detailRaw.push(rec);
                 }
             }
         });
         const detailParPage = this.pagingRisklistDetail(detailRaw);
         const detail = this.groupingRisklistDetail(detailParPage);
 
         this.header1 = header1;
         this.header2 = header2;
         this.detailRaw = detailRaw;
         this.detail = detail;
         this.isEditing = false;
         
         this.isProcessing = false;
     }
 
     async getRisks(param) {
         let ret = [];
         let lastId = null;
         let lastName = null;
         let result;
         do {
             result = await getRisks({
                 projectId: param.projectId
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
 
     async getRiskAssessmentsByRiskId(param) {
         const ret = {};
         let lastId = null;
         let lastName = null;
         let result;
         do {
             result = await getRiskAssessmentsByRiskId({
                 projectId: param.projectId
                 , dispFieldNames: param.dispFieldNames
                 , previousLastId: lastId
                 , previousLastName: lastName
             });
             for (let riskId in result.data) {
                 let riskAssessments = ret[riskId];
                 if (!riskAssessments) riskAssessments = [];
                 ret[riskId] = riskAssessments.concat(result.data[riskId]);
             }
             lastId = result.lastId;
             lastName = result.lastName;
         } while (result.isContinue);
         return ret;
     }

     async getClassificationsByRiskId(param) {
         const ret = {};
         let lastId = null;
         let lastName = null;
         let result;
         do {
             result = await getClassificationsByRiskId({
                 projectId: param.projectId
                 , dispFieldNames: param.dispFieldNames
                 , kindRecordType: param.kindRecordType
                 , previousLastId: lastId
                 , previousLastName: lastName
             });
             for (let riskId in result.data) {
                 let controls = ret[riskId];
                 if (!controls) controls = [];
                 ret[riskId] = controls.concat(result.data[riskId]);
             }
             lastId = result.lastId;
             lastName = result.lastName;
         } while (result.isContinue);
         return ret;
     }
 
     pagingRisklistDetail(detailRaw) {
         this.pageInfo.resultSize = detailRaw.length;
         this.pageInfo.lastPageNumber = (
             this.pageInfo.resultSize === 0 ?
             1 : Math.ceil(this.pageInfo.resultSize / this.pageInfo.pageSize)
         );
         if (this.pageInfo.pageNumber <= 0) {
             this.pageInfo.pageNumber = 1;
         } else if (this.pageInfo.lastPageNumber < this.pageInfo.pageNumber) {
             this.pageInfo.pageNumber = this.pageInfo.lastPageNumber;
         }
         this.pageInfo.rowNumberOffset = (this.pageInfo.pageNumber - 1) * this.pageInfo.pageSize;
 
         const startIndex = this.pageInfo.rowNumberOffset;
         const endIndex = this.pageInfo.pageNumber * this.pageInfo.pageSize;
         const detailParPage = detailRaw.slice(startIndex, endIndex);
 
         return detailParPage;
     }

     groupingRisklistDetail(detailParPage) {
         let detail = [];
         let isRiskChange = false;
         let riskIdTemp = null;
         let riskCells = [];
         let riskCnt = 0;
         let rowspan = 1;
         const offset = this.pageInfo.rowNumberOffset;
         detailParPage.forEach((rec, index) => {
             const newRec = {
                 no: index + offset + 1,
                 riskId: rec[0].item.riskId
                 , cells: []
             };
 
             let riskId = null;
             if (rec.length > 0) {
                 const cell = rec[0];
                 riskId = cell.item.riskId;
             }
 
             isRiskChange = (index === 0 || riskId !== riskIdTemp);
             riskIdTemp = riskId;
             if (isRiskChange) {
                 riskCnt++;
                 if (riskCells.length > 0) {
                     riskCells.forEach(cell => {
                         cell.rowspan = rowspan;
                     });
                 }
                 riskCells = [];
                 rowspan = 1;
             } else {
                 rowspan++;
             }
 
             newRec.rowClass = 'slds-hint-parent' + (riskCnt % 2 === 1 ? '' : ' striped');
 
             rec.forEach(cell => {
                 if (cell.item.objectName === RISK_OBJECT.objectApiName) {
                     if (isRiskChange) {
                         newRec.cells.push(cell);
                         riskCells.push(cell);
                     }
                 } else {
                     newRec.cells.push(cell);
                 }
             });
             detail.push(newRec);
         });
 
         if (riskCells.length > 0) {
             riskCells.forEach(cell => {
                 cell.rowspan = rowspan;
             });
         }
 
         return detail;
     }
 
     getDefaultColumnWidthStyle(type) {
         let ret = 'width:200px;';
         if (type === null) {
             ret = 'width:auto;';
         } else if (type === TYPE_BOOLEAN) {
             ret = 'width:100px;';
         } else if (
             type === TYPE_INTEGER ||
             type === TYPE_LONG ||
             type === TYPE_DOUBLE ||
             type === TYPE_CURRENCY ||
             type === TYPE_PERCENT ||
             type === TYPE_DATE ||
             type === TYPE_TIME
         ) {
             ret = 'width:120px;';
         }
         return ret;
     }
 
     getHeaderText(label, type) {
         let ret = null;
         if (type === TYPE_REFERENCE) {
             if (label) {
                 ret = label.replace(/\s*ID$/i, '');
             }
         } else {
             ret = label;
         }
         return ret;
     }
 
     getHeader2CellClass(isAscending, isSorted) {
         let ret = 'slds-is-resizable slds-is-sortable';
         ret += (isAscending ? ' slds-is-sorted_asc' : ' slds-is-sorted_desc');
         if (isSorted) {
             ret += ' slds-is-sorted';
         }
         return ret;
     }
 
     createDetailItem(data) {
         const item = {
             type: data.type
             , isRequired: data.isRequired || false
             , isEditable: data.isEditable || false
             , isEdited: false
             , isError: false
             , objectName: data.objectName
             , fieldName: data.fieldName
             , riskId: data.riskId
         };
         if ('riskAssessmentId' in data) {
             item.riskAssessmentId = data.riskAssessmentId;
         }
         if ('riskControlId' in data) {
             item.riskControlId = data.riskControlId;
         }
         if ('riskClassiGroupId' in data) {
            item.riskClassiGroupId = data.riskClassiGroupId;
        }
        if ('riskClassiSelectMax' in data) {
            item.riskClassiSelectMax = data.riskClassiSelectMax;
        }
         item.value = this.getDetailValue(data.value, item.type);
         item.oldValue = item.value;
         item.label = this.getDetailLabel(data.label, item.type);
         item.oldLabel = item.label;
         item.text = this.getDetailText(item.value, item.label, item.type);
         item.url = this.getDetailUrl(item);
         item.cellClass = this.getDetailCellClass(item.isEditable, item.isEdited, item.isError);
         const inputMode = this.getDetailInputMode(item);
         item.isInputModeNormal = (inputMode === 0);
         item.isInputModeRiskAssessClassi = (inputMode === 1);
         item.isInputModeControl = (inputMode === 2);
         return item;
     }

     getDetailValue(value, type) {
         let ret = value;
         if (type === TYPE_TIME) {
             if (value !== null) {
                 if (isNumber(value)) {
                     ret = new Intl.DateTimeFormat(LOCALE, {
                         hour: 'numeric'
                         , minute: 'numeric'
                         , second: 'numeric'
                         , timeZone: 'UTC'
                     }).format(new Date(value));
                 }
             }
         } else if (type === TYPE_MULTIPICKLIST) {
             if (!isArray(ret)) {
                 ret = (!ret ? [] : ret.split(';'));
             }
         }
         return ret;
     }
 
     getDetailLabel(label, type) {
         let ret = label;
         if (type === TYPE_MULTIPICKLIST) {
             if (!isArray(ret)) {
                 ret = (!ret ? [] : ret.split(';'));
             }
         }
         return ret;
     }
 
     getDetailSortValue(value, text, type) {
         let ret = null;
         if (
             type === TYPE_INTEGER ||
             type === TYPE_LONG ||
             type === TYPE_DOUBLE ||
             type === TYPE_CURRENCY ||
             type === TYPE_PERCENT
         ) {
             if (value !== null) {
                 ret = stringToNumber(value);
             }
         } else if (
             type === TYPE_DATE ||
             type === TYPE_DATETIME
         ) {
             if (value !== null) {
                 ret = new Date(value).getTime();
             }
         } else if (type === TYPE_TIME) {
             if (value !== null) {
                 const arr = value.split(/[:.Z]/);
                 const len = arr.length;
                 const hour = (len < 1 ? 0 : (stringToNumber(arr[0]) || 0)) * 3600000;
                 const minute = (len < 2 ? 0 : (stringToNumber(arr[1]) || 0)) * 60000;
                 const second = (len < 3 ? 0 : (stringToNumber(arr[2]) || 0)) * 1000;
                 const millisecond = (len < 4 ? 0 : (stringToNumber(arr[3]) || 0));
                 return hour + minute + second + millisecond;
             }
         } else {
             ret = text;
         }
         return ret;
     }
 
     getDetailText(value, label, type) {
         let ret = null;
         if (type === TYPE_BOOLEAN) {
             if (value !== null) {
                 ret = (value ? label_true : label_false);
             }
         } else if (
             type === TYPE_INTEGER ||
             type === TYPE_LONG ||
             type === TYPE_DOUBLE
         ) {
             if (value !== null) {
                 ret = new Intl.NumberFormat(LOCALE, {
                     style: 'decimal',
                 }).format(value);
             }
         } else if (type === TYPE_CURRENCY) {
             if (value !== null) {
                 ret = new Intl.NumberFormat(LOCALE, {
                     style: 'currency',
                     currency: CURRENCY,
                     currencyDisplay: 'symbol'
                 }).format(value);
             }
         } else if (type === TYPE_PERCENT) {
             if (value !== null) {
                 ret = new Intl.NumberFormat(LOCALE, {
                     style: 'percent',
                 }).format(value / 100);
             }
         } else if (type === TYPE_DATE) {
             if (value !== null) {
                 ret = new Intl.DateTimeFormat(LOCALE, {
                     year: 'numeric'
                     , month: 'numeric'
                     , day: 'numeric'
                 }).format(new Date(value));
             }
         } else if (type === TYPE_TIME) {
             if (value !== null) {
                 const arr = value.split(/[:.Z]/);
                 const len = arr.length;
                 const hour = (len < 1 ? '00' : arr[0]);
                 const minute = (len < 2 ? '00' : arr[1]);
                 const second = (len < 3 ? '00' : arr[2]);
                 const millisecond = (len < 4 ? '000' : arr[3]);
                 ret = '';
                 ret += (stringToNumber(hour) || 0);
                 ret += ':' + minute;
                 ret += ':' + second;
                 if ((stringToNumber(millisecond) || 0) !== 0) {
                     ret += '.' + millisecond;
                 }
             }
         } else if (type === TYPE_DATETIME) {
             if (value !== null) {
                 ret = new Intl.DateTimeFormat(LOCALE, {
                     year: 'numeric'
                     , month: 'numeric'
                     , day: 'numeric'
                     , hour: 'numeric'
                     , minute: 'numeric'
                     , second: 'numeric'
                     , timeZone: TIME_ZONE
                 }).format(new Date(value));
             }
         } else if (
             type === TYPE_REFERENCE ||
             type === TYPE_PICKLIST
         ) {
             ret = (label ? label : value);
         } else if (type === TYPE_MULTIPICKLIST) {
             if (isArray(label)) {
                 ret = label.join();
             } else {
                 ret = label;
             }
             if (!ret) {
                 if (isArray(value)) {
                     ret = value.join();
                 } else {
                     ret = value;
                 }
             }
         } else {
             ret = value;
         }
         return ret;
     }
 
     getDetailUrl(item) {
         let ret = null;
         if (item.objectName === RISK_OBJECT.objectApiName) {
             if (item.fieldName === 'Name' && item.riskId) {
                 ret = '/' + item.riskId;
             }
         } else if (item.objectName === RISK_ASSESSMENT_OBJECT.objectApiName) {
             if (item.fieldName === 'Name' && item.riskAssessmentId) {
                 ret = '/' + item.riskAssessmentId;
             }
         } else if (item.objectName === CONTROL_OBJECT.objectApiName) {
             if (item.fieldName === 'Name' && item.value) {
                 ret = '/' + item.value;
             }
         }
         return ret;
     }
 
     getDetailCellClass(isEditable, isEdited, isError) {
         let ret = '';
         if (isEditable) {
             ret += 'slds-cell-edit';
             if (isError) {
                 ret += ' is-error';
             } else {
                 if (isEdited) {
                     ret += ' is-edited';
                 }
             }
         }
         return ret;
     }
 
     getDetailInputMode(item) {
         let ret = 0;
         if (item.objectName === RISK_ASSESSMENT_OBJECT.objectApiName) {
             if (
                 item.fieldName === label_classiRecordType_analyseTiming ||
                 item.fieldName === label_classiRecordType_probability ||
                 item.fieldName === label_classiRecordType_resultImpact ||
                 item.fieldName === label_classiRecordType_thirdEvaluation
             ) {
                 ret = 1;
             }
         } else if (item.objectName === CONTROL_OBJECT.objectApiName) {
             if (item.fieldName === 'Name') {
                 ret = 2;
             }
         }
         return ret;
     }
    

 }