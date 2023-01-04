// 項目値入力コントローラ
public with sharing class FieldValueInputCtlr {
    public static final String VALUE_TRUE = 'true'; // 値：真
    public static final String VALUE_FALSE = 'false'; // 値：偽
    public static final String VALUE_NULL = 'null'; // Null

    // 入力情報の取得
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInputInfo(
        String objectName // オブジェクト名
        , String fieldName // 項目名
    ) {
        Map<String, Object> ret = new Map<String, Object>();
        if (String.isNotEmpty(fieldName)) {
            List<String> fldNames = fieldName.split(Pattern.quote(FieldLookupCtlr.FIELD_NAME_DELIMITER));
            SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            if (sObjType != null) {
                // 項目説明の取得
                DescribeFieldResult fldDesc = FieldOperatorSelectCtlr.getFieldDescribe(sObjType, 1, fldNames);
                if (fldDesc != null) {
                    // 入力情報の作成
                    ret = createInputInfo(fldDesc);
                }
            }
        }
        return ret;
    }

    // 入力情報の作成
    private static Map<String, Object> createInputInfo(DescribeFieldResult fieldDesc) {
        Map<String, Object> ret = new Map<String, Object>();
        Schema.DisplayType type = fieldDesc.getType();
        if (type == Schema.DisplayType.BOOLEAN) {
            List<Map<String, Object>> sels = new List<Map<String, Object>>();
            sels.add(new Map<String, Object>{
                'label' => System.Label.Value_True
                , 'value' => VALUE_TRUE
            });
            sels.add(new Map<String, Object>{
                'label' => System.Label.Value_False
                , 'value' => VALUE_FALSE
            });
            ret = new Map<String, Object>{
                'type' => String.valueOf(type)
                , 'selectList' => sels
            };
        } else if (
            type == Schema.DisplayType.PICKLIST
            || type == Schema.DisplayType.MULTIPICKLIST
        ) {
            List<Map<String, Object>> sels = new List<Map<String, Object>>();
            if (type == Schema.DisplayType.PICKLIST) {
                sels.add(new Map<String, Object>{
                    'label' => ''
                    , 'value' => ''
                });
            }
            for (PicklistEntry pe : fieldDesc.getPicklistValues()) {
                if (pe.isActive()) {
                    sels.add(new Map<String, Object>{
                        'label' => pe.getlabel()
                        , 'value' => pe.getValue()
                    });
                }
            }
            ret = new Map<String, Object>{
                'type' => String.valueOf(type)
                , 'selectList' => sels
            };
        } else if (type == Schema.DisplayType.REFERENCE) {
            List<Map<String, Object>> objectNameSels = null;
            List<SObjectType> sObjTypes = fieldDesc.getReferenceTo();
            if (!sObjTypes.isEmpty()) {
                objectNameSels = new List<Map<String, Object>>();
                for (SObjectType sObjType : sObjTypes) {
                    DescribeSObjectResult sObjDesc = sObjType.getDescribe();
                    objectNameSels.add(new Map<String, Object>{
                        'label' => sObjDesc.getLabel()
                        , 'value' => sObjDesc.getName()
                        , 'keyPrefix' => sObjDesc.getKeyPrefix()
                    });
                }
            }
            ret = new Map<String, Object>{
                'type' => String.valueOf(type)
                , 'objectNameSels' => objectNameSels
            };
        } else {
            ret = new Map<String, Object>{
                'type' => String.valueOf(type)
            };
        }
        return ret;
    }
}