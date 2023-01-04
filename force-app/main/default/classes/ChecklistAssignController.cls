// チェックリスト割当コントローラ
public with sharing class ChecklistAssignController {
    private static final Integer ASSIGN_SORUCE_LIST_PAGE_SIZE = 50; // 割当元リストのページサイズ
    private static final Integer ASSIGN_DESTINATION_LIST_PAGE_SIZE = 50; // 割当先リストのページサイズ

    // ラベルマップ取得
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLabelMap() {
        Map<String, String> ret = new Map<String, String>();
        ret.put('title', System.Label.ChecklistAssign_Title);
        ret.put('assignSoruce', System.Label.ChecklistAssign_AssignSoruce);
        ret.put('assignSoruceObject', System.Label.ChecklistAssign_AssignSoruce_Object);
        ret.put('assignDestination', System.Label.ChecklistAssign_AssignDestination);
        ret.put('assignDestinationObject', System.Label.ChecklistAssign_AssignDestination_Object);
        ret.put('list_page', System.Label.List_Page);
        ret.put('list_first', System.Label.List_First);
        ret.put('list_previous', System.Label.List_Previous);
        ret.put('list_next', System.Label.List_Next);
        ret.put('list_last', System.Label.List_Last);
        ret.put('input_error', System.Label.ChecklistAssign_InputError);
        ret.put('input_error_ok', System.Label.ChecklistAssign_InputError_Ok);
        ret.put('input_error_assignSoruce_require', System.Label.ChecklistAssign_InputError_AssignSoruce_Require);
        ret.put('input_error_assignDestination_require', System.Label.ChecklistAssign_InputError_AssignDestination_Require);
        ret.put('assign', System.Label.ChecklistAssign_Assign);
        ret.put('assign_cancel', System.Label.ChecklistAssign_Assign_Cancel);
        ret.put('assign_ok', System.Label.ChecklistAssign_Assign_Ok);
        ret.put('assign_confirm', System.Label.ChecklistAssign_Assign_Confirm);
        ret.put('assign_complete', System.Label.ChecklistAssign_Assign_Complete);
        ret.put('unassign', System.Label.ChecklistAssign_Unassign);
        ret.put('unassign_cancel', System.Label.ChecklistAssign_Unassign_Cancel);
        ret.put('unassign_ok', System.Label.ChecklistAssign_Unassign_Ok);
        ret.put('unassign_confirm', System.Label.ChecklistAssign_Unassign_Confirm);
        ret.put('unassign_complete', System.Label.ChecklistAssign_Unassign_Complete);

        sObjectType sObjType;
        DescribeSObjectResult sObjDesc;
        
        sObjType = ermt__Checklist__c.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.put('checklist', sObjDesc.getLabel());

        sObjType = Account.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.put('account', sObjDesc.getLabel());

        sObjType = User.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.put('user', sObjDesc.getLabel());

        return ret;
    }

    // 割当元オブジェクト名選択リスト取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAssignSourceObjectNameSels() {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        sObjectType sObjType;
        DescribeSObjectResult sObjDesc;
        sObjType = ermt__Checklist__c.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.add(new Map<String, Object>{
            'label' => sObjDesc.getLabel()
            , 'value' => sObjDesc.getName()
        });
        sObjType = User.getSObjectType();
        sObjDesc= sObjType.getDescribe();
        ret.add(new Map<String, Object>{
            'label' => sObjDesc.getLabel()
            , 'value' => sObjDesc.getName()
        });
        return ret;
    }

    // 割当先オブジェクト名選択リスト取得
    @AuraEnabled
    public static List<Map<String, Object>> getAssignDestinationObjectNameSels(
        String assignSourceObjectName
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        sObjectType sObjType;
        DescribeSObjectResult sObjDesc;
        if (assignSourceObjectName == 'ermt__Checklist__c') {
            sObjType = User.getSObjectType();
            sObjDesc= sObjType.getDescribe();
            ret.add(new Map<String, Object>{
                'label' => sObjDesc.getLabel()
                , 'value' => sObjDesc.getName()
            });
        } else if (assignSourceObjectName == 'User') {
            sObjType = ermt__Checklist__c.getSObjectType();
            sObjDesc= sObjType.getDescribe();
            ret.add(new Map<String, Object>{
                'label' => sObjDesc.getLabel()
                , 'value' => sObjDesc.getName()
            });
        }
        return ret;
    }

    // 割当済選択リスト取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAssignedSels() {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        ret.add(new Map<String, Object>{
            'label' => System.Label.ChecklistAssign_Assigned_All
            , 'value' => ''
        });
        ret.add(new Map<String, Object>{
            'label' => System.Label.ChecklistAssign_Unassigned
            , 'value' => 'false'
        });
        ret.add(new Map<String, Object>{
            'label' => System.Label.ChecklistAssign_Assigned
            , 'value' => 'true'
        });
        return ret;
    }

    // 割当元情報の取得
    @AuraEnabled
    public static AssignSourceInfo getAssignSourceInfo(
        String assignSourceObjectName // 配置元オブジェクト名
        , String assignSourceRecordId // 配置元レコードID
        , String otherSearchCond // その他の検索条件
        , String sortFieldName // ソート項目名
        , Integer sortDirectionType // ソート方向種別（0：昇順、1：降順）
        , Integer pageNumber // ページ番号
    ) {
        //System.debug('assignSourceObjectName=' + assignSourceObjectName);
        //System.debug('assignSourceRecordId=' + assignSourceRecordId);
        //System.debug('otherSearchCond=' + otherSearchCond);
        //System.debug('sortFieldName=' + sortFieldName);
        //System.debug('sortDirectionType=' + sortDirectionType);
        //System.debug('pageNumber=' + pageNumber);

        AssignSourceInfo ret = new AssignSourceInfo();

        // 配置元オブジェクト名のオブジェクトを検索
        if (assignSourceObjectName == 'ermt__Checklist__c') {
            if (String.isNotEmpty(assignSourceRecordId)) {
                for (ermt__Checklist__c c : [
                    SELECT Name
                    FROM ermt__Checklist__c
                    WHERE Id = :assignSourceRecordId
                    LIMIT 1
                ]) {
                    ret.recordName = c.Name;
                }
            }
        } else if (assignSourceObjectName == 'Account') {
            // 項目リストの作成
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'userNameLink'
                , 'label' => System.Label.ChecklistAssign_UserName
                , 'type' => 'url'
                , 'initialWidth' => 150
                , 'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'userName'
                    }, 'target' => '_blank'
                }, 'sortable' => true
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'nameLink'
                , 'label' => System.Label.ChecklistAssign_OrgDeptName
                , 'type' => 'url'
                , 'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'name'
                    }, 'target' => '_blank'
                }
            });
            
            // 組織・部門の取得
            Account acc = new Account();
            if (String.isNotEmpty(assignSourceRecordId)) {
                String soql = '';
                soql += 'SELECT Name';
                soql += ', (SELECT ermt__User__c, ermt__User__r.Name FROM ermt__Account_User__r';
                if (String.isNotEmpty(otherSearchCond)) {
                    soql += ' WHERE ermt__User__r.Name LIKE \'%' +
                        String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(otherSearchCond)) + '%\'';
                }
                if (sortFieldName == 'userNameLink') {
                    soql += ' ORDER BY ermt__User__r.Name' + (sortDirectionType == 0 ? ' ASC NULLS FIRST' : ' DESC NULLS LAST');
                } else {
                    soql += ' ORDER BY ermt__User__r.Name';
                }
                soql += ')';
                soql += ' FROM Account';
                soql += ' WHERE Id = \'' + String.escapeSingleQuotes(assignSourceRecordId) + '\'';
                soql += ' LIMIT 1';
                //System.debug('soql=' + soql);
                for (Account a : Database.query(soql)) {
                    acc = a;
                    ret.recordName = a.Name;
                }
            }

            // ページネーション情報の作成
            PaginationInfo pageInfo = ret.pageInfo;
            pageInfo.pageSize = ASSIGN_SORUCE_LIST_PAGE_SIZE;
            pageInfo.resultSize = (String.isEmpty(acc.Id) ? 0 : acc.ermt__Account_User__r.size());
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
            Integer recCnt = 0;
            for (Integer i = recStart - 1; i < recEnd; i++) {
                ermt__Account_User__c accUsr = acc.ermt__Account_User__r[i];
                ret.records.add(new Map<String, Object>{
                    'id' => accUsr.ermt__User__c
                    , 'nameLink' => '/' + acc.Id
                    , 'name' => acc.Name
                    , 'userNameLink' => '/' + accUsr.ermt__User__c
                    , 'userName' => accUsr.ermt__User__r.Name
                });
            }
        }

        //System.debug('ret=' + ret);

        return ret;
    }

    // 割当先情報の取得
    @AuraEnabled
    public static AssignDestinationInfo getAssignDestinationInfo(
        String assignSourceObjectName // 配置元オブジェクト名
        , String assignSourceRecordId // 配置元レコードID
        , String assignDestinationObjectName // 配置先オブジェクト名
        , String assignDestinationRecordId // 配置先レコードID
        , String assignedStr // 割当済
        , String otherSearchCond // その他の検索条件
        , String sortFieldName // ソート項目名
        , Integer sortDirectionType // ソート方向種別（0：昇順、1：降順）
        , Integer pageNumber // ページ番号
    ) {
        // System.debug('assignSourceObjectName=' + assignSourceObjectName);
        // System.debug('assignSourceRecordId=' + assignSourceRecordId);
        // System.debug('assignDestinationObjectName=' + assignDestinationObjectName);
        // System.debug('assignedStr=' + assignedStr);
        // System.debug('otherSearchCond=' + otherSearchCond);
        // System.debug('sortFieldName=' + sortFieldName);
        // System.debug('sortDirectionType=' + sortDirectionType);
        // System.debug('pageNumber=' + pageNumber);
        
        AssignDestinationInfo ret = new AssignDestinationInfo();

        // 配置先オブジェクト名のオブジェクトを検索
        if (assignDestinationObjectName == 'ermt__Checklist__c') {
            // 項目リストの作成
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'assigned'
                , 'label' => System.Label.ChecklistAssign_Assigned
                , 'type' => 'boolean'
                , 'initialWidth' => 60
                , 'cellAttributes' => new Map<String, Object>{
                    'alignment' => 'center'
                }
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'nameLink'
                , 'label' => System.Label.ChecklistAssign_ChecklistName
                , 'type' => 'url'
                , 'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'name'
                    }, 'target' => '_blank'
                }, 'sortable' => true
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'answerStatus'
                , 'label' => System.Label.ChecklistAssign_AnswerStatus
                , 'type' => 'text'
                , 'initialWidth' => 140
                , 'cellAttributes' => new Map<String, Object>{
                    'alignment' => 'center'
                }
            });

            // チェックリストの取得
            List<ermt__Checklist__c> chks = new List<ermt__Checklist__c>();
            if (String.isNotEmpty(assignSourceRecordId)) {
                String soql = '';
                soql += 'SELECT Name';
                soql += ', (SELECT toLabel(ermt__Answer_Status__c) FROM ermt__Checklist_User__r';
                if (assignSourceObjectName == 'User') {
                    soql += ' WHERE ermt__User__c = \'' + String.escapeSingleQuotes(assignSourceRecordId) + '\'';
                }
                soql += ')';
                soql += ' FROM ermt__Checklist__c';
                soql += ' WHERE ermt__Valid__c = true';
                if (String.isNotEmpty(otherSearchCond)) {
                    soql += ' AND Name LIKE \'%' +
                        String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(otherSearchCond)) + '%\'';
                }
                if (sortFieldName == 'nameLink') {
                    soql += ' ORDER BY Name' + (sortDirectionType == 0 ? ' ASC NULLS FIRST' : ' DESC NULLS LAST');
                } else {
                    soql += ' ORDER BY Name';
                }
                soql += ' LIMIT 10000';
                //System.debug('soql=' + soql);
                Boolean assigned = null;
                if (String.isNotEmpty(assignedStr)) {
                    assigned = Boolean.valueOf(assignedStr);
                }
                for (ermt__Checklist__c c : Database.query(soql)) {
                    if (assigned == null) {
                        chks.add(c);
                    } else {
                        if (assigned != c.ermt__Checklist_User__r.isEmpty()) {
                            chks.add(c);
                        }
                    }
                }
            }

            // ページネーション情報の作成
            PaginationInfo pageInfo = ret.pageInfo;
            pageInfo.pageSize = ASSIGN_DESTINATION_LIST_PAGE_SIZE;
            pageInfo.resultSize = chks.size();
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
            Integer recCnt = 0;
            for (Integer i = recStart - 1; i < recEnd; i++) {
                ermt__Checklist__c chk = chks[i];
                ermt__Checklist_User__c chkUsr = null;
                if (!chk.ermt__Checklist_User__r.isEmpty()) {
                    chkUsr = chk.ermt__Checklist_User__r[0];
                }
                ret.records.add(new Map<String, Object>{
                    'id' => chk.Id
                    , 'assigned' => (chkUsr != null)
                    , 'nameLink' => '/' + chk.Id
                    , 'name' => chk.Name
                    , 'answerStatus' => (chkUsr == null ? null : chkUsr.ermt__Answer_Status__c)
                });
            }
        } else if (assignDestinationObjectName == 'Account') {
            // 項目リストの作成
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'assigned'
                , 'label' => System.Label.ChecklistAssign_Assigned
                , 'type' => 'boolean'
                , 'initialWidth' => 60
                , 'cellAttributes' => new Map<String, Object>{
                    'alignment' => 'center'
                }
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'userNameLink'
                , 'label' => System.Label.ChecklistAssign_UserName
                , 'type' => 'url'
                , 'initialWidth' => 150
                , 'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'userName'
                    }, 'target' => '_blank'
                }, 'sortable' => true
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'nameLink'
                , 'label' => System.Label.ChecklistAssign_OrgDeptName
                , 'type' => 'url'
                , 'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{
                        'fieldName' => 'name'
                    }, 'target' => '_blank'
                }
            });
            ret.fields.add(new Map<String, Object>{
                'fieldName' => 'answerStatus'
                , 'label' => System.Label.ChecklistAssign_AnswerStatus
                , 'type' => 'text'
                , 'initialWidth' => 140
                , 'cellAttributes' => new Map<String, Object>{
                    'alignment' => 'center'
                }
            });

            // 組織・部門の取得
            Account acc = new Account();
            Set<Id> usrIds = new Set<Id>();
            if (String.isNotEmpty(assignDestinationRecordId)) {
                String soql = '';
                soql += 'SELECT Name';
                soql += ', (SELECT ermt__User__c, ermt__User__r.Name FROM ermt__Account_User__r';
                if (String.isNotEmpty(otherSearchCond)) {
                    soql += ' WHERE ermt__User__r.Name LIKE \'%' +
                        String.escapeSingleQuotes(CommonUtil.escapeSoqlLikeValue(otherSearchCond)) + '%\'';
                }
                if (sortFieldName == 'userNameLink') {
                    soql += ' ORDER BY ermt__User__r.Name' + (sortDirectionType == 0 ? ' ASC NULLS FIRST' : ' DESC NULLS LAST');
                } else {
                    soql += ' ORDER BY ermt__User__r.Name';
                }
                soql += ')';
                soql += ' FROM Account';
                soql += ' WHERE Id = \'' + String.escapeSingleQuotes(assignDestinationRecordId) + '\'';
                soql += ' LIMIT 1';
                //System.debug('soql=' + soql);
                for (Account a : Database.query(soql)) {
                    acc = a;
                    ret.recordName = a.Name;
                    for (ermt__Account_User__c au : a.ermt__Account_User__r) {
                        usrIds.add(au.ermt__User__c);
                    }
                }
            }

            // 回答票の取得
            Map<Id, ermt__Checklist_User__c> chkUsrByUsrId = new Map<Id, ermt__Checklist_User__c>();
            if (String.isNotEmpty(assignSourceRecordId)) {
                String soql = '';
                soql += 'SELECT ermt__User__c, toLabel(ermt__Answer_Status__c)';
                soql += ' FROM ermt__Checklist_User__c';
                soql += ' WHERE ermt__User__c IN :usrIds';
                if (assignSourceObjectName == 'ermt__Checklist__c') {
                    soql += ' AND ermt__Checklist__c = \'' + String.escapeSingleQuotes(assignSourceRecordId) + '\'';
                }
                //System.debug('soql=' + soql);
                for (ermt__Checklist_User__c cu : Database.query(soql)) {
                    chkUsrByUsrId.put(cu.ermt__User__c, cu);
                }
            }

            // 割当済の絞込み
            List<ermt__Account_User__c> accUsrs = new List<ermt__Account_User__c>();
            if (String.isNotEmpty(acc.Id)) {
                Boolean assigned = null;
                if (String.isNotEmpty(assignedStr)) {
                    assigned = Boolean.valueOf(assignedStr);
                }
                for (ermt__Account_User__c au : acc.ermt__Account_User__r) {
                    if (assigned == null) {
                        accUsrs.add(au);
                    } else {
                        if (assigned == chkUsrByUsrId.containsKey(au.ermt__User__c)) {
                            accUsrs.add(au);
                        }
                    }
                }
            }

            // ページネーション情報の作成
            PaginationInfo pageInfo = ret.pageInfo;
            pageInfo.pageSize = ASSIGN_DESTINATION_LIST_PAGE_SIZE;
            pageInfo.resultSize = accUsrs.size();
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
            Integer recCnt = 0;
            for (Integer i = recStart - 1; i < recEnd; i++) {
                ermt__Account_User__c accUsr = accUsrs[i];
                ermt__Checklist_User__c chkUsr = chkUsrByUsrId.get(accUsr.ermt__User__c);
                ret.records.add(new Map<String, Object>{
                    'id' => accUsr.ermt__User__c
                    , 'assigned' => (chkUsr != null)
                    , 'nameLink' => '/' + acc.Id
                    , 'name' => acc.Name
                    , 'userNameLink' => '/' + accUsr.ermt__User__c
                    , 'userName' => accUsr.ermt__User__r.Name
                    , 'answerStatus' => (chkUsr == null ? null : chkUsr.ermt__Answer_Status__c)
                });
            }
        }

        //System.debug('ret=' + ret);

        return ret;
    }

    // 回答票の作成
    @AuraEnabled
    public static Boolean createAnswerSheet(
        String assignSourceObjectName // 配置元オブジェクト名
        , String assignSourceRecordId // 配置元レコードID
        , String assignDestinationObjectName // 配置先オブジェクト名
        , List<String> assignDestinationRecordIds // 配置先レコードIDリスト
    ) {
        // System.debug('assignSourceObjectName=' + assignSourceObjectName);
        // System.debug('assignSourceRecordId=' + assignSourceRecordId);
        // System.debug('assignDestinationObjectName=' + assignDestinationObjectName);
        // System.debug('assignDestinationRecordIds=' + assignDestinationRecordIds);

        if (String.isEmpty(assignSourceObjectName)) return false;
        if (String.isEmpty(assignSourceRecordId)) return false;
        if (String.isEmpty(assignDestinationObjectName)) return false;
        if (assignDestinationRecordIds == null) return false;

        // 回答票を取得して、回答票マップを作成
        String soql = '';
        soql += 'SELECT ermt__Checklist__c';
        soql += ', ermt__User__c';
        soql += ' FROM ermt__Checklist_User__c';
        soql += ' WHERE Id != null';
        if (assignSourceObjectName == 'ermt__Checklist__c') {
            soql += ' AND ermt__Checklist__c = \'' +  String.escapeSingleQuotes(assignSourceRecordId) + '\'';
        } else if (assignSourceObjectName == 'User') {
            soql += ' AND ermt__User__c = \'' +  String.escapeSingleQuotes(assignSourceRecordId) + '\'';
        }
        if (assignDestinationObjectName == 'ermt__Checklist__c') {
            soql += ' AND ermt__Checklist__c IN :assignDestinationRecordIds';
        } else if (assignDestinationObjectName == 'User') {
            soql += ' AND ermt__User__c IN :assignDestinationRecordIds';
        }
        Map<Id, ermt__Checklist_User__c> chkUsrByAnyId = new Map<Id, ermt__Checklist_User__c>();
        for (ermt__Checklist_User__c cu : Database.query(soql)) {
            if (assignDestinationObjectName == 'ermt__Checklist__c') {
                chkUsrByAnyId.put(cu.ermt__Checklist__c, cu);
            } else if (assignDestinationObjectName == 'User') {
                chkUsrByAnyId.put(cu.ermt__User__c, cu);
            }
        }

        // 追加・更新用の回答票を作成
        List<ermt__Checklist_User__c> upsChkUsrs = new List<ermt__Checklist_User__c>();
        for (String recId : assignDestinationRecordIds) {
            ermt__Checklist_User__c upsChkUsr = new ermt__Checklist_User__c();
            if (assignDestinationObjectName == 'ermt__Checklist__c') {
                ermt__Checklist_User__c chkUsr = chkUsrByAnyId.get(recId);
                if (chkUsr == null) {
                    upsChkUsr.ermt__Answer_Status__c = System.Label.ChecklistUser_AnswerStatus_Unanswered;
                } else {
                    upsChkUsr.Id = chkUsr.Id;
                }
                upsChkUsr.ermt__Checklist__c = recId;
            } else if (assignDestinationObjectName == 'User') {
                ermt__Checklist_User__c chkUsr = chkUsrByAnyId.get(recId);
                if (chkUsr == null) {
                    upsChkUsr.ermt__Answer_Status__c = System.Label.ChecklistUser_AnswerStatus_Unanswered;
                } else {
                    upsChkUsr.Id = chkUsr.Id;
                }
                upsChkUsr.ermt__User__c = recId;
            }
            if (assignSourceObjectName == 'ermt__Checklist__c') {
                upsChkUsr.ermt__Checklist__c = assignSourceRecordId;
            } else if (assignSourceObjectName == 'User') {
                upsChkUsr.ermt__User__c = assignSourceRecordId;
            }
            if (String.isNotEmpty(upsChkUsr.ermt__Checklist__c) &&
                String.isNotEmpty(upsChkUsr.ermt__User__c)) {
                upsChkUsrs.add(upsChkUsr);
            }            
        }

        // 回答票の追加・更新
        if (!upsChkUsrs.isEmpty()) {
            upsert upsChkUsrs;
        }

        return true;
    }

    // 回答票の削除
    @AuraEnabled
    public static Boolean deleteAnswerSheet(
        String assignSourceObjectName // 配置元オブジェクト名
        , String assignSourceRecordId // 配置元レコードID
        , String assignDestinationObjectName // 配置先オブジェクト名
        , List<String> assignDestinationRecordIds // 配置先レコードIDリスト
    ) {
        // System.debug('assignSourceObjectName=' + assignSourceObjectName);
        // System.debug('assignSourceRecordId=' + assignSourceRecordId);
        // System.debug('assignDestinationObjectName=' + assignDestinationObjectName);
        // System.debug('assignDestinationRecordIds=' + assignDestinationRecordIds);

        if (String.isEmpty(assignSourceObjectName)) return false;
        if (String.isEmpty(assignSourceRecordId)) return false;
        if (String.isEmpty(assignDestinationObjectName)) return false;
        if (assignDestinationRecordIds == null) return false;

        // 回答票を取得して、削除用の回答票を作成
        String soql = '';
        soql += 'SELECT Id';
        soql += ' FROM ermt__Checklist_User__c';
        soql += ' WHERE Id != null';
        if (assignSourceObjectName == 'ermt__Checklist__c') {
            soql += ' AND ermt__Checklist__c = \'' +  String.escapeSingleQuotes(assignSourceRecordId) + '\'';
        } else if (assignSourceObjectName == 'User') {
            soql += ' AND ermt__User__c = \'' +  String.escapeSingleQuotes(assignSourceRecordId) + '\'';
        }
        if (assignDestinationObjectName == 'ermt__Checklist__c') {
            soql += ' AND ermt__Checklist__c IN :assignDestinationRecordIds';
        } else if (assignDestinationObjectName == 'User') {
            soql += ' AND ermt__User__c IN :assignDestinationRecordIds';
        }
        List<ermt__Checklist_User__c> delChkUsrs =  Database.query(soql);

        // 回答票の削除
        if (!delChkUsrs.isEmpty()) {
            delete delChkUsrs;
        }

        return true;
    }

    // 割当元情報クラス
    public class AssignSourceInfo {
        @AuraEnabled
        public String recordName; // レコード名称
        @AuraEnabled
        public List<Map<String, Object>> fields; // 項目リスト
        @AuraEnabled
        public List<Map<String, Object>> records; // レコードリスト
        @AuraEnabled
        public PaginationInfo pageInfo; // ページネーション情報

        // コンストラクタ
        public AssignSourceInfo() {
            recordName = null;
            fields = new List<Map<String, Object>>();
            records = new List<Map<String, Object>>();
            pageInfo = new PaginationInfo();
        }
    }

    // 割当先情報クラス
    public class AssignDestinationInfo {
        @AuraEnabled
        public String recordName; // レコード名称
        @AuraEnabled
        public List<Map<String, Object>> fields; // 項目リスト
        @AuraEnabled
        public List<Map<String, Object>> records; // レコードリスト
        @AuraEnabled
        public PaginationInfo pageInfo; // ページネーション情報

        // コンストラクタ
        public AssignDestinationInfo() {
            recordName = null;
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