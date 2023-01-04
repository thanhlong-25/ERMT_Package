// 分類・評価軸表示順の選択リストのテスト
@isTest
private class ERMT_ClsEvaAxisDispOrderPickListTest {
    // デフォルト値の取得のテスト
    @isTest static void getDefaultValueTest_1() {
        ERMT_ClsEvaAxisDispOrderPickList pickList = new ERMT_ClsEvaAxisDispOrderPickList();
        VisualEditor.DataRow row = pickList.getDefaultValue();
        System.assertEquals('LikelihoodGroup,ConsequenceGroup,SeverityRiskLevelGroup', row.getValue());
    }

    // 値リストの取得のテスト
    @isTest static void getValuesTest_1() {
        ERMT_ClsEvaAxisDispOrderPickList pickList = new ERMT_ClsEvaAxisDispOrderPickList();
        VisualEditor.DynamicPickListRows rows = pickList.getValues();
        VisualEditor.DataRow row = rows.get(0);
        System.assertEquals('LikelihoodGroup,ConsequenceGroup,SeverityRiskLevelGroup', row.getValue());
    }
}