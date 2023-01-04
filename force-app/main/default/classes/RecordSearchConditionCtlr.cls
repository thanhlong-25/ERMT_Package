// レコード検索条件コントローラ
public with sharing class RecordSearchConditionCtlr {
    // 検索条件のチェック
    @AuraEnabled
    public static Map<String, Object> checkSearchCondition(
        String objectName // オブジェクト名
        , List<Map<String, Object>> searchConditions // 検索条件リスト
        , String searchConditionLogic // 検索条件ロジック
    ) {

        // System.debug('objectName=' + objectName);
        // System.debug('searchConditions=' + searchConditions);
        // System.debug('searchConditionLogic=' + searchConditionLogic);

        Map<String, Object> ret = new Map<String, Object>{
            'result' => true
            , 'searchConditions' => searchConditions
            , 'searchConditionLogic' => searchConditionLogic
            , 'searchConditionLogicErrMsg' => ''
        };

        SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType == null) return ret;
        if (searchConditions == null) return ret;

        // 検索条件リストのチェック
        Set<Decimal> noSet = new Set<Decimal>();
        for (Map<String, Object> sc : searchConditions) {
            Decimal no = (Decimal)sc.get('no');
            noSet.add(no);
            String fieldName = (String)sc.get('fieldName');
            String operator = (String)sc.get('operator');
            String value = convertValueString(sc.get('value'));
            Boolean isErr = false;
            String errMsg = '';
            DescribeFieldResult fldDesc = null;
            
            // 項目名の必須チェック
            if (String.isEmpty(fieldName)) {
                isErr = true;
                errMsg += System.Label.RecordSearchCondition_Error_Field_Require;
            } else {
                // 項目説明の取得
                if (String.isNotEmpty(fieldName)) {
                    List<String> names = fieldName.split(Pattern.quote(FieldLookupCtlr.FIELD_NAME_DELIMITER));
                    fldDesc = FieldOperatorSelectCtlr.getFieldDescribe(sObjType, 1, names);
                }
                if (fldDesc == null) {
                    isErr = true;
                    errMsg += System.Label.RecordSearchCondition_Error_Field_Incorrect;
                }
            }

            // 演算子の必須チェック
            if (String.isEmpty(operator)) {
                isErr = true;
                errMsg += System.Label.RecordSearchCondition_Error_Operator_Require;
            } else {
                // 演算子の論理チェック
                if (
                    String.isEmpty(value)
                    && !(operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL)
                ) {
                    isErr = true;
                    errMsg += System.Label.RecordSearchCondition_Error_Operator_Incorrect;
                }
            }

            // 値の論理チェック
            if (String.isNotEmpty(value)) {
                if (fldDesc != null) {
                    Schema.DisplayType type = fldDesc.getType();
                    if (
                        type == Schema.DisplayType.ID
                        || type == Schema.DisplayType.REFERENCE
                    ) {
                        Id recId = null;
                        try {
                            recId = Id.valueOf(value);
                        } catch(StringException ex) {
                        }
                        if (recId == null) {
                            isErr = true;
                            errMsg += System.Label.RecordSearchCondition_Error_Value_Id_Incorrect;
                        }
                    } else if (
                        type == Schema.DisplayType.LONG
                        || type == Schema.DisplayType.INTEGER
                    ) {
                        if (!Pattern.matches('^[-+]?\\d+$', value)) {
                            isErr = true;
                            errMsg += System.Label.RecordSearchCondition_Error_Value_Number_Incorrect;
                        }
                    } else if (
                        type == Schema.DisplayType.DOUBLE
                        || type == Schema.DisplayType.PERCENT
                        || type == Schema.DisplayType.CURRENCY
                    ) {
                        if (!Pattern.matches('^[-+]?\\d+(\\.\\d+)?$', value)) {
                            isErr = true;
                            errMsg += System.Label.RecordSearchCondition_Error_Value_Number_Incorrect;
                        }
                    }
                }
            }

            // エラーチェック
            if (isErr) {
                ret.put('result', false);
            }
            sc.put('errMsg', errMsg);
        }

        // 検索条件ロジックのチェック
        if (String.isNotEmpty(searchConditionLogic)) {
            // 単語で分割
            List<String> words = new List<String>();
            String word = '';
            for (String s : searchConditionLogic.split('')) {
                if (' '.equals(s)) {
                    if (String.isNotEmpty(word)) {
                        words.add(word);
                        word = '';
                    }
                } else if ('('.equals(s) || ')'.equals(s)) {
                    if (String.isNotEmpty(word)) {
                        words.add(word);
                        word = '';
                    }
                    words.add(s);
                } else {
                    word += s;
                }
            }
            if (String.isNotEmpty(word)) {
                words.add(word);
                word = '';
            }

            // 出現単語チェック
            Boolean isErr = false;
            Boolean isEnd = false;
            Integer bracketCnt = 0;
            Integer bracketStartType = 1;
            Integer bracketEndType = 2;
            Integer notType = 3;
            Integer andType = 4;
            Integer orType = 5;
            Integer numberType = 6;
            Set<Integer> wordTypeSet = new Set<Integer>{
                bracketStartType
                , numberType
            };
            for (String w : words) {
                if ('('.equals(w)) {
                    if (!wordTypeSet.contains(bracketStartType)) {
                        isErr = true;
                        break;
                    }
                    bracketCnt++;
                    isEnd = false;
                    wordTypeSet = new Set<Integer>{
                        bracketStartType
                        , notType
                        , numberType
                    };
                } else if (')'.equals(w)) {
                    if (!wordTypeSet.contains(bracketEndType)) {
                        isErr = true;
                        break;
                    }
                    bracketCnt--;
                    isEnd = (bracketCnt == 0);
                    wordTypeSet = new Set<Integer>{
                        bracketEndType
                        , andType
                        , orType
                    };
                } else if ('NOT'.equalsIgnoreCase(w)) {
                    if (!wordTypeSet.contains(notType)) {
                        isErr = true;
                        break;
                    }
                    isEnd = false;
                    wordTypeSet = new Set<Integer>{
                        bracketStartType
                        , numberType
                    };
                } else if ('AND'.equalsIgnoreCase(w)) {
                    if (!wordTypeSet.contains(andType)) {
                        isErr = true;
                        break;
                    }
                    isEnd = false;
                    wordTypeSet = new Set<Integer>{
                        bracketStartType
                        , numberType
                    };
                } else if ('OR'.equalsIgnoreCase(w)) {
                    if (!wordTypeSet.contains(orType)) {
                        isErr = true;
                        break;
                    }
                    isEnd = false;
                    wordTypeSet = new Set<Integer>{
                        bracketStartType
                        , numberType
                    };
                } else if (Pattern.matches('^\\d+$', w)) {
                    if (!wordTypeSet.contains(numberType)) {
                        isErr = true;
                        break;
                    }
                    Decimal no = Decimal.valueOf(w);
                    if (!noSet.contains(no)) {
                        isErr = true;
                        break;
                    }
                    isEnd = (bracketCnt == 0);
                    wordTypeSet = new Set<Integer>{
                        bracketEndType
                        , andType
                        , orType
                    };
                } else {
                    isErr = true;
                    break;
                }
            }
            if (!isEnd) {
                isErr = true;
            }

            // エラーチェック
            if (isErr) {
                ret.put('result', false);
                ret.put('searchConditionLogicErrMsg', System.Label.RecordSearchCondition_Error_Logic_Incorrect);
            }
        }
        
        //System.debug('ret=' + ret);

        return ret;
    }

    // 検索条件式の作成
    // SOQLのWHERE句の文字列を作成する
    public static String createSearchConditionExpression(
        String objectName // オブジェクト名
        , List<Map<String, Object>> searchConditions // 検索条件リスト
        , String searchConditionLogic // 検索条件ロジック
    ) {
        
        // System.debug('objectName=' + objectName);
        // System.debug('searchConditions=' + searchConditions);
        // System.debug('searchConditionLogic=' + searchConditionLogic);

        String ret = '';

        SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType == null) return ret;
        if (searchConditions == null) return ret;

        // 検索条件式マップの作成
        Map<Decimal, String> schCndExpByNo = new Map<Decimal, String>();
        for (Map<String, Object> sc : searchConditions) {
            Decimal no = (Decimal)sc.get('no');
            String fieldName = (String)sc.get('fieldName');
            String operator = (String)sc.get('operator');
            String value = convertValueString(sc.get('value'));

            // 項目説明の取得
            DescribeFieldResult fldDesc = null;
            if (String.isNotEmpty(fieldName)) {
                List<String> names = fieldName.split(Pattern.quote(FieldLookupCtlr.FIELD_NAME_DELIMITER));
                fldDesc = FieldOperatorSelectCtlr.getFieldDescribe(sObjType, 1, names);
            }
            if (fldDesc == null) continue;

            // 値の作成
            if (String.isEmpty(value)) {
                value = FieldValueInputCtlr.VALUE_NULL;
            } else {
                Schema.DisplayType type = fldDesc.getType();
                if (type == Schema.DisplayType.BOOLEAN) {
                    value = (
                        value == FieldValueInputCtlr.VALUE_TRUE
                        || value == FieldValueInputCtlr.VALUE_FALSE
                        ? value : null
                    );
                } else if (type == Schema.DisplayType.DATETIME) {
                    value = value.replace('T', ' ');
                    value = value.replace('.000Z', '');
                    Datetime dt = Datetime.valueOf(value);
                    value = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } else if (
                    type == Schema.DisplayType.DATE
                    || type == Schema.DisplayType.TIME
                    || type == Schema.DisplayType.CURRENCY
                    || type == Schema.DisplayType.DOUBLE
                    || type == Schema.DisplayType.INTEGER
                    || type == Schema.DisplayType.LONG
                    || type == Schema.DisplayType.PERCENT
                ) {
                } else {
                    if (
                        operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_PARTIAL_MATCH
                        || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_PARTIAL_MATCH
                        ) {
                        value = CommonUtil.escapeSoqlLikeValue(value);
                        // value = '\'%' + String.escapeSingleQuotes(value) + '%\'';
                        value = '\'%' + value + '%\'';
                    } else if (
                        operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_PREFIX_MATCH
                        || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_PREFIX_MATCH
                    ) {
                        value = CommonUtil.escapeSoqlLikeValue(value);
                        // value = '\'' + String.escapeSingleQuotes(value) + '%\'';
                        value = '\'%' + value + '%\'';
                    } else if (
                        operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_BACKWARD_MATCH
                        || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_BACKWARD_MATCH
                    ) {
                        value = CommonUtil.escapeSoqlLikeValue(value);
                        // value = '\'%' + String.escapeSingleQuotes(value) + '\'';
                        value = '\'%' + value + '%\'';
                    } else {
                        value = '\'' + String.escapeSingleQuotes(value) + '\'';
                    }
                }
            }
            if (String.isEmpty(value)) continue;
            // 式の作成
            String exp = '';
            if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL) {
                exp = fieldName + ' = ' + value;
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL) {
                exp = fieldName + ' != ' + value;
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_GREATER_THAN) {
                exp = fieldName + ' > ' + value;
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_GREATER_THAN_EQUAL) {
                exp = fieldName + ' >= ' + value;
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_LESS_THAN) {
                exp = fieldName + ' < ' + value;
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_LESS_THAN_EQUAL) {
                exp = fieldName + ' <= ' + value;
            } else if (
                operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_PARTIAL_MATCH
                || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_PREFIX_MATCH
                || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_BACKWARD_MATCH
            ) {
                exp = fieldName + ' LIKE ' + value;
            } else if (
                operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_PARTIAL_MATCH
                || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_PREFIX_MATCH
                || operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_BACKWARD_MATCH
            ) {
                exp = '(NOT ' + fieldName + ' LIKE ' + value + ')';
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_INCLUDE) {
                exp = fieldName + ' includes (' + value + ')';
            } else if (operator == FieldOperatorSelectCtlr.OPERATOR_VALUE_EXCLUDE) {
                exp = fieldName + ' excludes (' + value + ')';
            }
            if (String.isEmpty(exp)) continue;
            schCndExpByNo.put(no, exp);
        }

        // 検索条件ロジックを含めた式を作成
        if (String.isEmpty(searchConditionLogic)) {
            for (String e : schCndExpByNo.values()) {
                ret += (String.isEmpty(ret) ? '' : ' AND ');
                ret += e;
            }
        } else {
            Pattern ptn = Pattern.compile('\\d+');
            Matcher mtc = ptn.matcher(searchConditionLogic);
            Integer pos = 0;
            while (mtc.find()) {
                Decimal no = Decimal.valueOf(mtc.group(0));
                String exp = schCndExpByNo.get(no);
                exp = (exp != null ? exp : 'Id != null');
                ret += searchConditionLogic.substring(pos, mtc.start(0));
                ret += exp;
                pos = mtc.end(0);
            }
            ret += searchConditionLogic.substring(pos);
        }

        //System.debug('ret=' + ret);

        return ret;
    }

    // 値を文字列に変換
    private static String convertValueString(Object value) {
        String ret = null;
        if (value != null) {
            if (value instanceof List<Object>) {
                ret = '';
                for (Object o : (List<Object>)value) {
                    ret += (String.isEmpty(ret) ? '' : ';');
                    ret += String.valueOf(o);
                }
            } else {
                ret = String.valueOf(value);
            }
        }
        return ret;
    }
}