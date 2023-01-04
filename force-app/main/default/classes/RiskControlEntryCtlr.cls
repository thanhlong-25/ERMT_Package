// リスク対応策の登録コントローラ
public with sharing class RiskControlEntryCtlr {
    private static final Integer CONTROL_LIST_PAGE_SIZE = 50; // 対応策リストのページサイズ

    // ラベルマップの取得
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLabelMap() {
        Map<String, String> ret = new Map<String, String>();
        ret.put('title', System.Label.RiskControlEntry_Title);
        ret.put('searchCond', System.Label.RiskControlEntry_SearchCond);
        ret.put('list_page', System.Label.RiskControlEntry_List_Page);
        ret.put('list_first', System.Label.RiskControlEntry_List_First);
        ret.put('list_previous', System.Label.RiskControlEntry_List_Previous);
        ret.put('list_next', System.Label.RiskControlEntry_List_Next);
        ret.put('list_last', System.Label.RiskControlEntry_List_Last);
        ret.put('entry', System.Label.RiskControlEntry_Entry);
        ret.put('cancel', System.Label.RiskControlEntry_Cancel);
        ret.put('close', System.Label.RiskControlEntry_Close);
        ret.put('inputError', System.Label.RiskControlEntry_InputError);
        ret.put('inputError_control_require', System.Label.RiskControlEntry_InputError_Control_Require);
        ret.put('ok', System.Label.RiskControlEntry_Ok);
        ret.put('entry_confirm', System.Label.RiskControlEntry_Entry_Confirm);
        ret.put('entry_complete', System.Label.RiskControlEntry_Entry_Complete);
        ret.put('delete', System.Label.RiskControlEntry_Delete);
        ret.put('delete_confirm', System.Label.RiskControlEntry_Delete_Confirm);
        ret.put('delete_complete', System.Label.RiskControlEntry_Delete_Complete);
        ret.put('registered', System.Label.RiskControlEntry_Registered);
        ret.put('unregistered', System.Label.RiskControlEntry_Unregistered);
        ret.put('all', System.Label.RiskControlEntry_All);
        ret.put('control_newCreate_title', System.Label.RiskControlEntry_Control_NewCreate_Title);
        ret.put('control_newCreate', System.Label.RiskControlEntry_Control_NewCreate);
        ret.put('control_newCreate_complete', System.Label.RiskControlEntry_Control_NewCreate_Complete);

        sObjectType sObjType;
        DescribeSObjectResult sObjDesc;
        
        sObjType = ermt__Risk__c.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.put('risk', sObjDesc.getLabel());

        sObjType = ermt__Control__c.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.put('control', sObjDesc.getLabel());

        return ret;
    }

    // 登録種別選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRegisterTypeSels() {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        ret.add(new Map<String, Object>{
            'label' => System.Label.RiskControlEntry_All
            , 'value' => System.Label.RiskControlEntry_All
        });
        ret.add(new Map<String, Object>{
            'label' => System.Label.RiskControlEntry_Unregistered
            , 'value' => System.Label.RiskControlEntry_Unregistered
        });
        ret.add(new Map<String, Object>{
            'label' => System.Label.RiskControlEntry_Registered
            , 'value' => System.Label.RiskControlEntry_Registered
        });
        return ret;
    }

    // 対応策情報の取得
    @AuraEnabled
    public static ControlInfo getControlInfo(
        Id riskId // リスクID
        , String registerType // 登録種別
        , List<Map<String, Object>> searchConds // 検索条件リスト
        , String searchCondLogic // 検索条件ロジック
        , String otherSearchCond // その他の検索条件
        , String sortFieldName // ソート項目名
        , Integer sortDirectionType // ソート方向種別（0：昇順、1：降順）
        , Integer pageNumber // ページ番号
    ) {
        //System.debug('riskId=' + riskId);
        //System.debug('registerType=' + registerType);
        //System.debug('searchConds=' + searchConds);
        //System.debug('searchCondLogic=' + searchCondLogic);
        //System.debug('otherSearchCond=' + otherSearchCond);
        //System.debug('sortFieldName=' + sortFieldName);
        //System.debug('sortDirectionType=' + sortDirectionType);
        //System.debug('pageNumber=' + pageNumber);
        
        ControlInfo ret = new ControlInfo();

        // 項目リストの作成
        Schema.DescribeFieldResult sObjFldDesc;
        ret.fields.add(new Map<String, Object>{
            'fieldName' => 'registered'
            , 'label' => System.Label.RiskControlEntry_Registered
            , 'type' => 'boolean'
            , 'initialWidth' => 60
            , 'cellAttributes' => new Map<String, Object>{
                'alignment' => 'center'
            }
        });
        sObjFldDesc = ermt__Control__c.Name.getDescribe();
        ret.fields.add(new Map<String, Object>{
            'fieldName' => 'nameLink'
            , 'label' => sObjFldDesc.getLabel()
            , 'type' => 'url'
            , 'typeAttributes' => new Map<String, Object>{
                'label' => new Map<String, Object>{
                    'fieldName' => 'name'
                }, 'target' => '_blank'
            }, 'sortable' => true
        });
        sObjFldDesc = ermt__Control__c.ermt__AssignedOrg__c.getDescribe();
        ret.fields.add(new Map<String, Object>{
            'fieldName' => 'assignedOrgName'
            , 'label' => sObjFldDesc.getLabel()
            , 'type' => 'text'
            , 'sortable' => true
        });

        // 登録済フラグの取得
        Boolean registered = null;
        if (registerType == System.Label.RiskControlEntry_Unregistered) {
            registered = false;
        } else if (registerType == System.Label.RiskControlEntry_Registered) {
            registered = true;
        }

        // 検索条件式の作成
        String searchCondExp = null;
        if (searchConds != null && !searchConds.isEmpty()) {
            searchCondExp = RecordSearchConditionCtlr.createSearchConditionExpression(
                'ermt__Control__c'    
                , searchConds
                , searchCondLogic
            );
            if (String.isNotEmpty(searchCondExp)) {
                searchCondExp = ' AND (' + searchCondExp + ')';
            }
        }

        // 対応策の取得
        List<ermt__Control__c> ctrls = new List<ermt__Control__c>();
        if (String.isNotEmpty(riskId)) {
            String soql = '';
            soql += 'SELECT Name, ermt__AssignedOrg__r.Name';
            soql += ', UserRecordAccess.HasEditAccess';
            soql += ', (SELECT Id FROM ermt__Risk_Control__r';
            soql += ' WHERE ermt__Risk__c = \'' + String.escapeSingleQuotes(riskId) + '\'';
            soql += ' LIMIT 1';
            soql += ')';
            soql += ' FROM ermt__Control__c';
            soql += ' WHERE Id != null';
            if (String.isNotEmpty(searchCondExp)) {
                soql += searchCondExp;
            }
            if (String.isNotEmpty(otherSearchCond)) {
                soql += ' AND (Name LIKE \'%' +
                    String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(otherSearchCond)) + '%\'';
                soql += ' OR ermt__AssignedOrg__r.Name LIKE \'%' +
                    String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(otherSearchCond)) + '%\')';
            }
            if (sortFieldName == 'nameLink') {
                soql += ' ORDER BY Name' + (sortDirectionType == 0 ? ' ASC NULLS FIRST' : ' DESC NULLS LAST');
            } else if (sortFieldName == 'assignedOrgName') {
                soql += ' ORDER BY ermt__AssignedOrg__r.Name' + (sortDirectionType == 0 ? ' ASC NULLS FIRST' : ' DESC NULLS LAST');
            } else {
                soql += ' ORDER BY Name';
            }
            soql += ' LIMIT 10000';
            // System.debug('soql=' + soql);
            for (ermt__Control__c c : Database.query(soql)) {
                if (c.UserRecordAccess.HasEditAccess) {
                    if (registered == null) {
                        ctrls.add(c);
                    } else {
                        if (registered == !c.ermt__Risk_Control__r.isEmpty()) {
                            ctrls.add(c);
                        }
                    }
                }
            }
        }

        // ページネーション情報の作成
        PaginationInfo pageInfo = ret.pageInfo;
        pageInfo.pageSize = CONTROL_LIST_PAGE_SIZE;
        pageInfo.resultSize = ctrls.size();
        pageInfo.lastPageNumber = Integer.valueOf(Math.ceil(Decimal.valueOf(pageInfo.resultSize) / pageInfo.pageSize));
        pageInfo.lastPageNumber = (pageInfo.lastPageNumber < 1 ? 1 : pageInfo.lastPageNumber);
        pageInfo.pageNumber = pageNumber;
        pageInfo.pageNumber = (pageInfo.pageNumber < 1 ? 1 : pageInfo.pageNumber);
        pageInfo.pageNumber = (pageInfo.pageNumber <= pageInfo.lastPageNumber ? pageInfo.pageNumber : pageInfo.lastPageNumber);
        pageInfo.rowNumberOffset = (pageInfo.pageNumber - 1) * pageInfo.pageSize;

        // レコードリストの作成
        Integer recStart = pageInfo.rowNumberOffset + 1;
        Integer recEnd = pageInfo.pageNumber * pageInfo.pageSize;
        recEnd = (recEnd <= pageInfo.resultSize ? recEnd : pageInfo.resultSize);
        for (Integer i = recStart - 1; i < recEnd; i++) {
            ermt__Control__c ctrl = ctrls[i];
            ret.records.add(new Map<String, Object>{
                'id' => ctrl.Id
                , 'registered' => !ctrl.ermt__Risk_Control__r.isEmpty()
                , 'nameLink' => '/' + ctrl.Id
                , 'name' => ctrl.Name
                , 'assignedOrgName' => ctrl.ermt__AssignedOrg__r.Name
            });
        }

        //System.debug('ret=' + ret);

        return ret;
    }

    // リスク対応策の登録
    @AuraEnabled
    public static Boolean registerRiskControl(
        Id riskId // リスクID
        , List<Id> ctrlIds // 対応策IDリスト
    ) {
        // System.debug('riskId=' + riskId);
        // System.debug('ctrlIds=' + ctrlIds);

        if (String.isEmpty(riskId)) return false;
        if (ctrlIds == null) return false;

        // リスク対応策を取得
        Set<Id> ctrlIdSet = new Set<Id>();
        for (ermt__Risk_Control_Junc__c rcj : [
            SELECT ermt__Control__c
            FROM ermt__Risk_Control_Junc__c
            WHERE ermt__Risk__c = :riskId
        ]) {
            ctrlIdSet.add(rcj.ermt__Control__c);
        }

        // 追加用のリスク対応策を作成
        List<ermt__Risk_Control_Junc__c> insRiskCtrls = new List<ermt__Risk_Control_Junc__c>();
        for (Id ctrlId : ctrlIds) {
            if (!ctrlIdSet.contains(ctrlId)) {
                insRiskCtrls.add(new ermt__Risk_Control_Junc__c(
                    ermt__Risk__c = riskId
                    , ermt__Control__c = ctrlId
                ));
            }
        }

        // リスク対応策の追加
        if (!insRiskCtrls.isEmpty()) {
            insert insRiskCtrls;
        }

        return true;
    }

    // リスク対応策の削除
    @AuraEnabled
    public static Boolean deleteRiskControl(
        Id riskId // リスクID
        , List<Id> ctrlIds // 対応策IDリスト
    ) {
        // System.debug('riskId=' + riskId);
        // System.debug('ctrlIds=' + ctrlIds);

        if (String.isEmpty(riskId)) return false;
        if (ctrlIds == null) return false;

        // リスク対応策を取得
        Map<Id, List<ermt__Risk_Control_Junc__c>> riskCtrlsByCtrlId;
        List<ermt__Risk_Control_Junc__c> riskCtrls;
        riskCtrlsByCtrlId = new Map<Id, List<ermt__Risk_Control_Junc__c>>();
        for (ermt__Risk_Control_Junc__c rcj : [
            SELECT ermt__Control__c
            FROM ermt__Risk_Control_Junc__c
            WHERE ermt__Risk__c = :riskId
        ]) {
            riskCtrls = riskCtrlsByCtrlId.get(rcj.ermt__Control__c);
            if (riskCtrls == null) {
                riskCtrls = new List<ermt__Risk_Control_Junc__c>();
                riskCtrlsByCtrlId.put(rcj.ermt__Control__c, riskCtrls);
            }
            riskCtrls.add(rcj);
        }

        // 削除用のリスク対応策を作成
        List<ermt__Risk_Control_Junc__c> delRiskCtrls = new List<ermt__Risk_Control_Junc__c>();
        for (Id ctrlId : ctrlIds) {
            riskCtrls = riskCtrlsByCtrlId.get(ctrlId);
            if (riskCtrls != null) {
                for (ermt__Risk_Control_Junc__c rcj : riskCtrls) {
                    delRiskCtrls.add(new ermt__Risk_Control_Junc__c(
                        Id = rcj.Id
                    ));
                }
            }
        }

        // リスク対応策の削除
        if (!delRiskCtrls.isEmpty()) {
            delete delRiskCtrls;
        }

        return true;
    }

    // 対応策情報クラス
    public class ControlInfo {
        @AuraEnabled
        public List<Map<String, Object>> fields; // 項目リスト
        @AuraEnabled
        public List<Map<String, Object>> records; // レコードリスト
        @AuraEnabled
        public PaginationInfo pageInfo; // ページネーション情報

        // コンストラクタ
        public ControlInfo() {
            fields = new List<Map<String, Object>>();
            records = new List<Map<String, Object>>();
            pageInfo = new PaginationInfo();
        }
    }

    // ページネーション情報クラス
    public class PaginationInfo {
        @AuraEnabled
        public Integer pageNumber;
        @AuraEnabled
        public Integer lastPageNumber;
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Integer resultSize;
        @AuraEnabled
        public Integer rowNumberOffset;

        // コンストラクタ
        public PaginationInfo() {
            pageNumber = 1;
            lastPageNumber = 1;
            pageSize = 0;
            resultSize = 0;
            rowNumberOffset = 0;
        }
    }
}