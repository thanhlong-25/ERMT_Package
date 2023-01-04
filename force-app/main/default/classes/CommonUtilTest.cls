// 共通ユーティリティテスト
@isTest
private class CommonUtilTest {
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

            // リスク
            List<ermt__Risk__c> rsks = new List<ermt__Risk__c>();
            for (Integer i = 0; i < 1; i++) {
                ermt__Risk__c rsk = TestDataFactory.createRisk(i + 1, accs[0]);
                rsks.add(rsk);
            }
            insert rsks;
            ret.put('ermt__Risk__c', rsks);
        }
        return ret;
    }

    // 数値の四捨五入テスト
    @isTest static void roundNumberTest_1() {
        Decimal value = CommonUtil.roundNumber(2.45, 1);
        System.assertEquals(2.5, value);
    }

    // SOQL文LIKE値エスケープのテスト
    @isTest static void escapeSoqlLikeValueTest_1() {
    	String ret = CommonUtil.escapeSoqlLikeValue('abc%');
    	System.assertEquals('abc\\%', ret);
    }

    // SOQL文作成可項目名リスト取得のテスト
    @isTest static void getSoqlCreateableFieldNamesTest_1() {
    	String ret = CommonUtil.getSoqlCreateableFieldNames('Account', false);
    	System.assert(String.isNotEmpty(ret));
    }

    // 項目説明の取得のテスト
    @isTest static void getFieldDescribeTest_1() {
        SObjectType sObjType = ermt__Risk__c.getSObjectType();
        String fieldName = 'ermt__Organization__r.Name';
        DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
    	System.assert(fieldDesc != null);
    }

    // 親の名前項目名の取得テスト
    @isTest static void getParentNameFieldNameTest_1() {
        SObjectType sObjType = Account.getSObjectType();
        String fieldName = 'Owner.ProfileId';
        DescribeFieldResult fieldDesc = CommonUtil.getFieldDescribe(sObjType, fieldName);
        String parentNameFieldName = CommonUtil.getParentNameFieldName(fieldName, fieldDesc);
        //System.debug('parentNameFieldName=' + parentNameFieldName);
    	System.assert(String.isNotEmpty(parentNameFieldName));
    }
    
    // 項目値の取得のテスト
    @isTest static void getFieldValueTest_1() {
        // データ作成
        Map<String, Object> data = makeData_1();
        // ユーザの取得
        List<User> usrs = (List<User>)data.get('User');
        System.runAs(usrs[0]) {
            ermt__Risk__c rsk = [
                SELECT ermt__Organization__r.Name
                FROM ermt__Risk__c
                WHERE Name = 'リスク1'
                LIMIT 1
            ];
            String fieldName = 'ermt__Organization__r.Name';
    	    Object obj = CommonUtil.getFieldValue(rsk, fieldName);
            System.assert(obj != null);
        }
    }
}