// 組織・部門コンボボックスコントローラ
public with sharing class AccountComboboxCtlr {
    // 組織・部門リストの取得
    @AuraEnabled
    public static List<Account> getAccounts() {
        return [
            SELECT Name, ParentId
            FROM Account
            ORDER BY Name
        ];
    }
}