// 項目検索コントローラ
public with sharing class FieldLookupCtlr {
    public static final String FIELD_NAME_DELIMITER = '.'; // 項目名区切り文字
    private static final String FIELD_LABEL_DELIMITER = ':'; // 項目ラベル区切り文字

    // 項目ラベルの取得
    @AuraEnabled(cacheable=true)
    public static String getFieldLabel(
        String objectName // オブジェクト名
        , String fieldName // 項目名
    ) {
        String ret = '';
        if (String.isNotEmpty(fieldName)) {
            List<String> fldNames = fieldName.split(Pattern.quote(FIELD_NAME_DELIMITER));
            SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            if (sObjType != null) {
                // 項目ラベルの取得
                String label = getFieldLabelInner(sObjType, 1, fldNames);
                ret = createFieldLabel(label, fieldName);
            }
        }
        return ret;
    }

    // 項目ラベルの取得
    private static String getFieldLabelInner(
        SObjectType sObjType // Sオブジェクトタイプ
        , Integer level // 階層
        , List<String> fieldNames // 項目名リスト
    ) {
        String ret = '';
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        Integer maxLevel = fieldNames.size();
        if (level == maxLevel) {
            String fldName = fieldNames[level - 1];
            SObjectField fld = sObjDesc.fields.getMap().get(fldName);
            if (fld != null) {
                DescribeFieldResult fldDesc = fld.getDescribe();
                ret = fldDesc.getLabel();
            }
        } else if (level < maxLevel) {
            String fldName = fieldNames[level - 1];
            for (SObjectField fld : sObjDesc.fields.getMap().values()) {
                DescribeFieldResult fldDesc = fld.getDescribe();

                // データ型が主従関係、参照関係の項目が対象
                if (fldDesc.getType() == Schema.DisplayType.REFERENCE) {
                    if (fldDesc.getRelationshipName() == fldName) {
                        ret = fldDesc.getLabel();
                        for (Schema.sObjectType sot : fldDesc.getReferenceTo()) {
                            // 項目ラベルの取得
                            String fldLabel = getFieldLabelInner(sot, level + 1, fieldNames);
                            if (String.isNotEmpty(fldLabel)) {
                                ret += FIELD_LABEL_DELIMITER + fldLabel;
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

    // 項目選択リストの取得
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getFieldSels(
        String objectName // オブジェクト名
        , Object fieldNames // 項目名リスト
        , Integer maxLevel // 最大階層
        , Boolean isQuery // クエリ用か
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType != null) {
            if (fieldNames instanceof List<Object>) {
                // 項目選択リストの取得
                ret.addAll(getFieldSelsInner(sObjType, (List<Object>)fieldNames));
            } else {
                // 項目選択リストの取得
                ret.addAll(getFieldSelsInner(sObjType, 1, maxLevel, '', '', isQuery));
            }
        }
        return ret;
    }

    // 項目選択リストの取得
    private static List<Map<String, Object>> getFieldSelsInner(
        SObjectType firstSObjType
        , List<Object> fieldNames
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        DescribeSObjectResult firstSObjDesc = firstSObjType.getDescribe();

        // オブジェクト参照権限チェック
        if (firstSObjDesc.isAccessible()) {
            for (Object o : fieldNames) {
                DescribeSObjectResult sObjDesc = firstSObjDesc;
                String fieldName = String.valueOf(o).trim();
                String fieldLabel = '';
                List<String> fieldNameParts = fieldName.split(Pattern.quote(FIELD_NAME_DELIMITER));
                Integer size = fieldNameParts.size();
                for (Integer i = 0; i < (size - 1); i++) {
                    if (sObjDesc != null) {
                        SObjectType nextSObjType = null;
                        String fieldNamePart = fieldNameParts[i];
                        for (SObjectField field : sObjDesc.fields.getMap().values()) {
                            DescribeFieldResult fieldDesc = field.getDescribe();
                            
                            // データ型が主従関係、参照関係の項目が対象
                            if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                                if (fieldDesc.getRelationshipName() == fieldNamePart) {
                                    // 項目参照権限チェック
                                    if (fieldDesc.isAccessible()) {
                                        fieldLabel = fieldLabel + (String.isEmpty(fieldLabel) ? '' : FIELD_LABEL_DELIMITER) + fieldDesc.getLabel();
                                        List<SObjectType> sObjTypes = fieldDesc.getReferenceTo();
                                        if (!sObjTypes.isEmpty()) {
                                            nextSObjType = sObjTypes[0];
                                        }
                                    }
                                    break;
                                }
                            }
                        }

                        // 次のオブジェクト説明の取得
                        sObjDesc = null;
                        if (nextSObjType != null) {
                            DescribeSObjectResult nextSObjDesc = nextSObjType.getDescribe();

                            // オブジェクト参照権限チェック
                            if (nextSObjDesc.isAccessible()) {
                                sObjDesc = nextSObjDesc;
                            }
                        }
                    }
                }
                if (sObjDesc != null) {
                    SObjectField field = sObjDesc.fields.getMap().get(fieldNameParts[size - 1]);
                    if (field != null) {
                        DescribeFieldResult fieldDesc = field.getDescribe();

                        // 項目参照権限チェック
                        if (fieldDesc.isAccessible()) {
                            fieldLabel = fieldLabel + (String.isEmpty(fieldLabel) ? '' : FIELD_LABEL_DELIMITER) + fieldDesc.getLabel();
                            ret.add(new Map<String, Object>{
                                'label' => createFieldLabel(fieldLabel, fieldName)
                                , 'value' => fieldName
                            });
                        }
                    }
                }
            }
        }
        return ret;
    }

    // 項目選択リストの取得
    private static List<Map<String, Object>> getFieldSelsInner(
        SObjectType sObjType // Sオブジェクトタイプ
        , Integer level // 階層
        , Integer maxLevel // 最大階層
        , String prefixLabel // 接頭辞の表示ラベル
        , String prefixName // 接頭辞の項目名
        , Boolean isQuery // クエリ用か
    ) {
        List<Map<String, Object>> ret = new List<Map<String, Object>>();
        DescribeSObjectResult sObjDesc = sObjType.getDescribe();

        // オブジェクト参照権限チェック
        if (sObjDesc.isAccessible()) {
            List<Map<String, Object>> subFldSels = new List<Map<String, Object>>();
            for (SObjectField fld : sObjDesc.fields.getMap().values()) {
                DescribeFieldResult fldDesc = fld.getDescribe();

                // 項目参照権限チェック
                if (fldDesc.isAccessible()) {
                    String label = prefixLabel + (String.isEmpty(prefixLabel) ? '' : FIELD_LABEL_DELIMITER) + fldDesc.getLabel();
                    String name = prefixName + (String.isEmpty(prefixName) ? '' : FIELD_NAME_DELIMITER) + fldDesc.getName();
                    
                    Boolean isTarget = true;
                    if (isQuery) {
                        // ロングテキストエリア、リッチテキストエリアは除外する
                        if (fldDesc.getType() == Schema.DisplayType.TEXTAREA) {
                            if (!(fldDesc.getLength() <= 255 && !fldDesc.isHtmlFormatted())) {
                                isTarget = false;
                            }
                        }
                        // 2階層以上は、レコードタイプ、ユーザ、グループは除外する
                        if (
                            level > 1 &&
                            (sObjDesc.getName() == 'RecordType' ||
                            sObjDesc.getName() == 'User' ||
                            sObjDesc.getName() == 'Group')
                        ) {
                            isTarget = false;
                        }
                    }
                    if (isTarget) {
                        ret.add(new Map<String, Object>{
                            'label' => createFieldLabel(label, name)
                            , 'value' => name
                        });
                    }

                    // データ型が主従関係、参照関係の場合、親オブジェクトの項目リストを取得
                    if (isTarget && level < maxLevel && fldDesc.getType() == Schema.DisplayType.REFERENCE) {
                        name = prefixName + (String.isEmpty(prefixName) ? '' : FIELD_NAME_DELIMITER) + fldDesc.getRelationshipName();
                        for (Schema.sObjectType sot : fldDesc.getReferenceTo()) {
                            // 項目リストの取得
                            subFldSels.addAll(getFieldSelsInner(sot, level + 1, maxLevel, label, name, isQuery));
                        }
                    }
                }
            }
            ret.addAll(subFldSels);
        }
        return ret;
    }

    // 項目ラベルの作成
    private static String createFieldLabel(String label, String name) {
        return label + '(' + name  + ')';
    }
}