// ERMTのインストール後スクリプトのテスト
@isTest
class ERMT_PostInstallScriptTest {
    // インストール時のテスト
    @isTest static void onInstallTest_1() {
        // インストールのテスト
        ERMT_PostInstallScript postInstall = new ERMT_PostInstallScript();
        Test.testInstall(postInstall, null);

        // 検証
        ermt__RiskLockSetting__c riskLockStt = ermt__RiskLockSetting__c.getOrgDefaults();
        System.assert(riskLockStt.ermt__IsLockEnabled__c);
    }
}