// 共通ユーティリティ
public class CommonUtil {
    public static final String FIELD_NAME_DELIMITER = '.'; // 項目名区切り文字

    /**
     * 数値の四捨五入
     * @param value 値（数値）
     * @param scale 丸め位置（0:小数点第一位、1:小数点第二位、-1:整数一の位）
     * @return 四捨五入後の数値
     */
    public static Decimal roundNumber(Decimal value, Integer scale) {
        return (value == null ? null : value.setScale(scale, RoundingMode.HALF_UP));
    }

    /**
     * SOQL文LIKE値エスケープ
     * @param value エスケープ前LIKE値
     * @return エスケープ後LIKE値
     */
    public static String escapeSoqlLikeValue(String value) {
        return (value == null) ? '' : value.replaceAll('[%_]', '\\\\$0');
    }

    /*
	 * SOQL文作成可項目名リスト取得
	 * @param オブジェクト名
     * @param ユニーク属性の項目も含めるか
	 * @return 項目リスト
	 */
	public static String getSoqlCreateableFieldNames(String objectName, Boolean isUniqueInclude) {
        String ret = '';
        SObject sObj = (SObject)Type.forName(objectName).newInstance();
        Schema.DescribeSObjectResult sObjDesc = sObj.getsObjectType().getDescribe();
        Map<String, Schema.SObjectField> fldMap = sObjDesc.fields.getMap();
        for (String fldName : fldMap.keySet()) {
            Schema.SObjectField fld = fldMap.get(fldName);
            Schema.DescribeFieldResult fldDesc = fld.getDescribe();
            if (fldDesc.isCreateable() && (isUniqueInclude || !fldDesc.isUnique())) {
                ret += (',' + fldName);
            }
        }
        return (String.isEmpty(ret) ? '' : ret.substring(1));
    }

    // 項目説明の取得
    public static DescribeFieldResult getFieldDescribe(SObjectType firstSObjType, String fieldName) {
        DescribeFieldResult ret = null;
        DescribeSObjectResult sObjDesc = firstSObjType.getDescribe();
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
                            List<SObjectType> sObjTypes = fieldDesc.getReferenceTo();
                            if (!sObjTypes.isEmpty()) {
                                nextSObjType = sObjTypes[0];
                            }
                            break;
                        }
                    }
                }
                sObjDesc = null;
                if (nextSObjType != null) {
                    sObjDesc = nextSObjType.getDescribe();
                }
            }
        }
        if (sObjDesc != null) {
            SObjectField field = sObjDesc.fields.getMap().get(fieldNameParts[size - 1]);
            if (field != null) {
                ret = field.getDescribe();
            }
        }
        return ret;
    }

    // 親の名前項目名の取得
    public static String getParentNameFieldName(String childFieldName, DescribeFieldResult childFieldDesc) {
        String ret = null;
        // データ型が主従関係、参照関係の項目が対象
        if (childFieldDesc.getType() == Schema.DisplayType.REFERENCE) {
            List<SObjectType> sObjTypes = childFieldDesc.getReferenceTo();
            if (!sObjTypes.isEmpty()) {
                // 先頭オブジェクトの名前項目を取得する
                SObjectType sObjType = sObjTypes[0];
                DescribeSObjectResult sObjDesc = sObjType.getDescribe();
                for (SObjectField field : sObjDesc.fields.getMap().values()) {
                    DescribeFieldResult fieldDesc = field.getDescribe();
                    if (fieldDesc.isNameField()) {
                        List<String> childFieldNameParts = childFieldName.split(Pattern.quote(FIELD_NAME_DELIMITER));
                        ret = '';
                        for (Integer i = 0, size = childFieldNameParts.size(); i < (size - 1); i++) {
                            ret += (String.isEmpty(ret) ? '' : FIELD_NAME_DELIMITER);
                            ret += childFieldNameParts[i];
                        }
                        ret += (String.isEmpty(ret) ? '' : FIELD_NAME_DELIMITER);
                        ret += childFieldDesc.getRelationshipName();
                        ret += (String.isEmpty(ret) ? '' : FIELD_NAME_DELIMITER);
                        ret += fieldDesc.getName();
                        break;
                    }
                }
            }
        }
        return ret;
    }
    
    // 項目値の取得
    public static Object getFieldValue(SObject firstSObj, String fieldName) {
        Object ret = null;
        SObject sObj = firstSObj;
        List<String> fieldNameParts = fieldName.split(Pattern.quote(FIELD_NAME_DELIMITER));
        Integer size = fieldNameParts.size();
        for (Integer i = 0; i < (size - 1); i++) {
            if (sObj != null) {
                sObj = sObj.getSObject(fieldNameParts[i]);
            }
        }
        if (sObj != null) {
            ret = sObj.get(fieldNameParts[size - 1]);
        }
        return ret;
    }
}