// 項目演算子選択コントローラ
public with sharing class FieldOperatorSelectCtlr {
    public static final String OPERATOR_VALUE_EQUAL = 'Equal'; // 演算子の値：一致
    public static final String OPERATOR_VALUE_NOT_EQUAL = 'NotEqual'; // 演算子の値：不一致
    public static final String OPERATOR_VALUE_GREATER_THAN = 'GreaterThan'; // 演算子の値：より大きい
    public static final String OPERATOR_VALUE_GREATER_THAN_EQUAL = 'GreaterThanEqual'; // 演算子の値：以上
    public static final String OPERATOR_VALUE_LESS_THAN = 'LessThan'; // 演算子の値：より小さい
    public static final String OPERATOR_VALUE_LESS_THAN_EQUAL = 'LessThanEqual'; // 演算子の値：以下
    public static final String OPERATOR_VALUE_PARTIAL_MATCH = 'PartialMatch'; // 演算子の値：含む
    public static final String OPERATOR_VALUE_NOT_PARTIAL_MATCH = 'NotPartialMatch'; // 演算子の値：含まない
    public static final String OPERATOR_VALUE_PREFIX_MATCH = 'PrefixMatch'; // 演算子の値：始まる
    public static final String OPERATOR_VALUE_NOT_PREFIX_MATCH = 'NotPrefixMatch'; // 演算子の値：始まらない
    public static final String OPERATOR_VALUE_BACKWARD_MATCH = 'BackwardMatch'; // 演算子の値：終わる
    public static final String OPERATOR_VALUE_NOT_BACKWARD_MATCH = 'NotBackwardMatch'; // 演算子の値：終わらない
    public static final String OPERATOR_VALUE_INCLUDE = 'Include'; // 演算子の値：含む（複数選択リスト）
    public static final String OPERATOR_VALUE_EXCLUDE = 'Exclude'; // 演算子の値：含まない（複数選択リスト）

    // 演算子選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOperatorSels(
        String objectName // オブジェクト名
        , String fieldName // 項目名
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        if (String.isNotEmpty(fieldName)) {
            List<String> fldNames = fieldName.split(Pattern.quote(FieldLookupCtlr.FIELD_NAME_DELIMITER));
            SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            if (sObjType != null) {
                // 項目説明の取得
                DescribeFieldResult fldDesc = getFieldDescribe(sObjType, 1, fldNames);
                if (fldDesc != null) {
                    // 選択リストの作成
                    ret = createOperatorSels(fldDesc.getType());
                }
            }
        }
        return ret;
    }

    // 項目説明の取得
    public static DescribeFieldResult getFieldDescribe(
        SObjectType sObjType // Sオブジェクトタイプ
        , Integer level // 階層
        , List<String> fieldNames // 項目名リスト
    ) {
        DescribeFieldResult ret = null;
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        Integer maxLevel = fieldNames.size();
        if (level == maxLevel) {
            String fldName = fieldNames[level - 1];
            SObjectField fld = sObjDesc.fields.getMap().get(fldName);
            if (fld != null) {
                ret = fld.getDescribe();
            }
        } else if (level < maxLevel) {
            String fldName = fieldNames[level - 1];
            for (SObjectField fld : sObjDesc.fields.getMap().values()) {
                DescribeFieldResult fldDesc = fld.getDescribe();

                // データ型が主従関係、参照関係の項目が対象
                if (fldDesc.getType() == Schema.DisplayType.REFERENCE) {
                    if (fldDesc.getRelationshipName() == fldName) {
                        for (Schema.sObjectType sot : fldDesc.getReferenceTo()) {
                             // 項目説明の取得
                            ret = getFieldDescribe(sot, level + 1, fieldNames);
                            if (ret != null) {
                                break;
                            }
                        }
                        break;
                    }
                }
            }
        }
        return ret;
    }

    // 選択リストの作成
    @TestVisible
    private static List<Map<String, Object>> createOperatorSels(Schema.DisplayType dataType) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        if (
            dataType == Schema.DisplayType.ID
            || dataType == Schema.DisplayType.REFERENCE
            || dataType == Schema.DisplayType.BOOLEAN
        ) {
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Equal
                , 'value' => OPERATOR_VALUE_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotEqual
                , 'value' => OPERATOR_VALUE_NOT_EQUAL
            });
        } else if (
            dataType == Schema.DisplayType.DATE
            || dataType == Schema.DisplayType.DATETIME
            || dataType == Schema.DisplayType.TIME
            || dataType == Schema.DisplayType.CURRENCY
            || dataType == Schema.DisplayType.DOUBLE
            || dataType == Schema.DisplayType.INTEGER
            || dataType == Schema.DisplayType.LONG
            || dataType == Schema.DisplayType.PERCENT
        ) {
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Equal
                , 'value' => OPERATOR_VALUE_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotEqual
                , 'value' => OPERATOR_VALUE_NOT_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_GraterThen
                , 'value' => OPERATOR_VALUE_GREATER_THAN
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_GraterThenEqual
                , 'value' => OPERATOR_VALUE_GREATER_THAN_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_LessThen
                , 'value' => OPERATOR_VALUE_LESS_THAN
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_LessThenEqual
                , 'value' => OPERATOR_VALUE_LESS_THAN_EQUAL
            });
        } else if (
            dataType == Schema.DisplayType.PICKLIST
        ) {
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Equal
                , 'value' => OPERATOR_VALUE_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotEqual
                , 'value' => OPERATOR_VALUE_NOT_EQUAL
            });
        } else if (
            dataType == Schema.DisplayType.MULTIPICKLIST
        ) {
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Equal
                , 'value' => OPERATOR_VALUE_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotEqual
                , 'value' => OPERATOR_VALUE_NOT_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Include
                , 'value' => OPERATOR_VALUE_INCLUDE
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Exclude
                , 'value' => OPERATOR_VALUE_EXCLUDE
            });
        } else {
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_Equal
                , 'value' => OPERATOR_VALUE_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotEqual
                , 'value' => OPERATOR_VALUE_NOT_EQUAL
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_PartialMatch
                , 'value' => OPERATOR_VALUE_PARTIAL_MATCH
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotPartialMatch
                , 'value' => OPERATOR_VALUE_NOT_PARTIAL_MATCH
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_PrefixMatch
                , 'value' => OPERATOR_VALUE_PREFIX_MATCH
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotPrefixMatch
                , 'value' => OPERATOR_VALUE_NOT_PREFIX_MATCH
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_BackwardMatch
                , 'value' => OPERATOR_VALUE_BACKWARD_MATCH
            });
            ret.add(new Map<String, Object>{
                'label' => System.Label.Operator_NotBackwardMatch
                , 'value' => OPERATOR_VALUE_NOT_BACKWARD_MATCH
            });
        }
        return ret;
    }
}