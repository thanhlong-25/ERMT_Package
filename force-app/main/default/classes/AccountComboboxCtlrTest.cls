// 組織・部門コンボボックスコントローラのテスト
@isTest
private class AccountComboboxCtlrTest {
    // データ作成
    static Map<String, Object> makeData_1() {
        Map<String, Object> ret = new Map<String, Object>();

        // ユーザ
        List<User> usrs = new List<User>();
        for (Integer i = 0; i < 1; i++) {
            User usr = TestDataFactory.createUser(i + 1);
            usrs.add(usr);
        }
        insert usrs;
        ret.put('User', usrs);

        System.runAs(usrs[0]) {
            // 組織・部門
            List<Account> accs = new List<Account>();
            for (Integer i = 0; i < 1; i++) {
                Account acc = TestDataFactory.createAccount(i + 1);
                accs.add(acc);
            }
            insert accs;
            ret.put('Account', accs);
        }
        return ret;
    }

    // 組織・部門リストの取得のテスト
    @isTest static void getAccountsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // 組織・部門リストの取得
            List<Account> accs = AccountComboboxCtlr.getAccounts();

            // 検証
            System.assert(!accs.isEmpty());
        }
    }
}