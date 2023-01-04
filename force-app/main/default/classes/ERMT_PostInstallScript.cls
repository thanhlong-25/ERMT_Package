// ERMTのインストール後スクリプト
global without sharing class ERMT_PostInstallScript implements InstallHandler {
    // インストール時
    global void onInstall(InstallContext context) {
        if (Schema.SObjectType.ermt__RiskLockSetting__c.isCreateable() &&
            Schema.SObjectType.ermt__RiskLockSetting__c.isUpdateable() &&
            Schema.SObjectType.ermt__RiskLockSetting__c.fields.ermt__IsLockEnabled__c.isCreateable() &&
            Schema.SObjectType.ermt__RiskLockSetting__c.fields.ermt__IsLockEnabled__c.isUpdateable()
        ) {
            // リスクのロック設定
            ermt__RiskLockSetting__c riskLockStt = ermt__RiskLockSetting__c.getOrgDefaults();
            if (!riskLockStt.ermt__IsLockEnabled__c) {
                riskLockStt.ermt__IsLockEnabled__c = true;
                upsert riskLockStt;
            }
        }
    }
}