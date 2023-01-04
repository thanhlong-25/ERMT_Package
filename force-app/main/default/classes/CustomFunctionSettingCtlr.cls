// カスタム機能設定コントローラ
public with sharing class CustomFunctionSettingCtlr {
    // カスタム機能設定の取得
    @AuraEnabled
    public static Object getCustomFunctionSettingValue(
        String functionType
        , String settingType
        , Id projectId
    ) {
        Object settingValue = null;
        if (
            functionType == System.Label.FunctionType_Risklist ||
            functionType == System.Label.FunctionType_RiskMatrixRiskClassi ||
            functionType == System.Label.FunctionType_RiskMatrixRiskAssessClassi
        ) {
            if (
                settingType == System.Label.SettingType_SearchCond
            ) {
                Id userId = UserInfo.getUserId();
                List<ermt__CustomFunctionSetting__c> settings = [
                    SELECT ermt__SettingValue_LongText__c
                    FROM ermt__CustomFunctionSetting__c
                    WHERE ermt__FunctionType__c = :functionType
                    AND ermt__SettingType__c = :settingType
                    AND ermt__User__c = :userId
                    AND ermt__Project__c = :projectId
                    LIMIT 1
                ];
                if (!settings.isEmpty()) {
                    settingValue = settings[0].ermt__SettingValue_LongText__c;
                }
            }
        }
        return settingValue;
    }

    // カスタム機能設定のセット
    @AuraEnabled
    public static void setCustomFunctionSettingValue(
        String functionType
        , String settingType
        , Id projectId
        , Object settingValue
    ) {
        if (
            functionType == System.Label.FunctionType_Risklist ||
            functionType == System.Label.FunctionType_RiskMatrixRiskClassi ||
            functionType == System.Label.FunctionType_RiskMatrixRiskAssessClassi
        ) {
            if (
                settingType == System.Label.SettingType_SearchCond
            ) {
                Id userId = UserInfo.getUserId();
                List<ermt__CustomFunctionSetting__c> settings = [
                    SELECT Id FROM ermt__CustomFunctionSetting__c
                    WHERE ermt__FunctionType__c = :functionType
                    AND ermt__SettingType__c = :settingType
                    AND ermt__User__c = :userId
                    AND ermt__Project__c = :projectId
                    LIMIT 1
                ];
                if (settings.isEmpty()) {
                    insert new ermt__CustomFunctionSetting__c(
                        ermt__FunctionType__c = functionType
                        , ermt__SettingType__c = settingType
                        , ermt__User__c = userId
                        , ermt__Project__c = projectId
                        , ermt__SettingValue_LongText__c = (String)settingValue
                    );
                } else {
                    update new ermt__CustomFunctionSetting__c(
                        Id = settings[0].Id
                        , ermt__SettingValue_LongText__c = (String)settingValue
                    );
                }
            }
        }
    }
}