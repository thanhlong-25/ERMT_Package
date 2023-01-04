// レコード検索コントローラのテスト
@isTest
private class RecordLookupCtlrTest {
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
            // グループ
            List<Group> grps = new List<Group>();
            for (Integer i = 0; i < 1; i++) {
                Group grp = TestDataFactory.createGroup(i + 1);
                grps.add(grp);
            }
            insert grps;
            ret.put('Group', grps);

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

    // レコードの取得のテスト
    @isTest static void getRecordTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        List<Account> accs = (List<Account>)data.get('Account');
        System.runAs(usrs[0]) {
            // レコードの取得
            SObject rec = RecordLookupCtlr.getRecord('Account', accs[0].Id);

            // 検証
            System.assert(rec != null);
        }
    }

    // レコードリストの取得のテスト
    @isTest static void getRecordsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // レコードリストの取得
            List<SObject> recs = RecordLookupCtlr.getRecords('Account', '組織・部門');

            // 検証
            System.assert(!recs.isEmpty());
        }
    }

    // グループのレコードリストの取得のテスト
    @isTest static void getGroupRecordsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            List<String> groupTypes = new List<String>{ 'Regular' };

            // グループのレコードリストの取得
            List<SObject> recs = RecordLookupCtlr.getGroupRecords('Group', 'グループ', groupTypes);

            // 検証
            System.assert(!recs.isEmpty());
        }
    }

    // レコードタイプのレコードリストの取得のテスト
    @isTest static void getRecordTypeRecordsTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            // レコードタイプのレコードリストの取得
            List<SObject> recs = RecordLookupCtlr.getRecordTypeRecords('RecordType', null, 'Account');

            // 検証
            //System.debug('recs=' + recs);
            System.assert(!recs.isEmpty());
        }
    }
}