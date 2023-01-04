// レコード検索条件コントローラテスト
@isTest
private class RecordSearchConditionCtlrTest {
    private static final Datetime NOW_DATETIME = Datetime.now(); // 現在日時

    // プロファイルマップ取得
    // キー:プロファイル名
    // 値:プロファイルレコード
    private static Map<String, Profile> profileByName {
        get {
            if (profileByName == null) {
                profileByName = new Map<String, Profile>();
                for (Profile p : [
                    SELECT Name FROM Profile
                    ORDER BY Name
                ]) {
                    profileByName.put(p.Name, p);
                }
            }
            return profileByName;
        }
        private set;
    }

    // テストータ作成
    @testSetup static void makeTestData() {
        // ユーザ
        List<User> usrs = new List<User>();
        Integer usrsSize = 1;
        for (Integer i = 0; i < usrsSize; i++) {
            Integer no = i + 1;
            User usr = new User(
                LastName = 'ユーザ' + no
                , Alias = 'ユーザ' + no
                , UserName = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , Email = 'user' + no + '_' + NOW_DATETIME.format('yyyyMMdd') + '@test.com'
                , EmailEncodingKey = 'ISO-2022-JP'
                , TimeZoneSidKey = 'Asia/Tokyo'
                , LocaleSidKey = 'ja_JP'
                , LanguageLocaleKey = 'ja'
                , ProfileId = profileByName.get(System.Label.Profile_System_Admin).Id
            );
            usrs.add(usr);
        }
        insert usrs;

        System.runAs(usrs[0]) {
            
        }
    }

    // 検索条件のチェックのテスト
    // エラー無し
    @isTest static void checkSearchConditionTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert((Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => ''
                    , 'operator' => ''
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'ErrorField__a'
                    , 'operator' => ''
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 3
                    , 'fieldName' => 'Id'
                    , 'operator' => ''
                    , 'value' => 'xxx'
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 4
                    , 'fieldName' => 'FiscalYear'
                    , 'operator' => ''
                    , 'value' => 'xxx'
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 5
                    , 'fieldName' => 'Amount'
                    , 'operator' => ''
                    , 'value' => 'xxx'
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 6
                    , 'fieldName' => 'Amount'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_GREATER_THAN
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND (NOT 2) AND (3 OR 4)(x';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND )2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND NOT 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_5() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND AND 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_6() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND OR 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_7() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_8() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 AND 3';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件のチェックのテスト
    // エラー有り
    @isTest static void checkSearchConditionTest_9() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '1 XOR 2';

            // 検索条件のチェック
            Map<String, Object> data = RecordSearchConditionCtlr.checkSearchCondition(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(!(Boolean)data.get('result'));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：BOOLEAN
    // 演算子：EQUAL
    //　検索条件ロジック：有り
    @isTest static void createSearchConditionExpressionTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Id'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => ''
                    , 'errMsg' => ''
                }
                , new Map<String, Object>{
                    'no' => 2
                    , 'fieldName' => 'IsClosed'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EQUAL
                    , 'value' => FieldValueInputCtlr.VALUE_FALSE
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '(NOT 1) AND 2';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：DATETIME
    // 演算子：GREATER_THAN
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'CreatedDate'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_GREATER_THAN
                    , 'value' => '2020-06-01T12:00:00.000Z'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：INTEGER
    // 演算子：GREATER_THAN_EQUAL
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'FiscalYear'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_GREATER_THAN_EQUAL
                    , 'value' => '2020'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：INTEGER
    // 演算子：LESS_THAN
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'FiscalYear'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_LESS_THAN
                    , 'value' => '2020'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：INTEGER
    // 演算子：LESS_THAN_EQUAL
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_5() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'FiscalYear'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_LESS_THAN_EQUAL
                    , 'value' => '2020'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING
    // 演算子：NOT_EQUAL
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_6() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_EQUAL
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING
    // 演算子：PARTIAL_MATCH
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_7() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_PARTIAL_MATCH
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING
    // 演算子：PREFIX_MATCH
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_8() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_PREFIX_MATCH
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING
    // 演算子：BACKWARD_MATCH
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_9() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_BACKWARD_MATCH
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING
    // 演算子：NOT_PARTIAL_MATCH
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_10() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_NOT_PARTIAL_MATCH
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING（実際は複数選択リスト）
    // 演算子：INCLUDE
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_11() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_INCLUDE
                    , 'value' => '商談'
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }

    // 検索条件式の作成のテスト
    // 項目のデータ型：STRING（実際は複数選択リスト）
    // 演算子：EXCLUDE
    //　検索条件ロジック：無し
    @isTest static void createSearchConditionExpressionTest_12() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            String objectName = 'Opportunity';
            List<Map<String, Object>> searchConditions = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'no' => 1
                    , 'fieldName' => 'Name'
                    , 'operator' => FieldOperatorSelectCtlr.OPERATOR_VALUE_EXCLUDE
                    , 'value' => new List<Object>{'商談'}
                    , 'errMsg' => ''
                }
            };
            String searchConditionLogic = '';

            // 検索条件式の作成
            String exp = RecordSearchConditionCtlr.createSearchConditionExpression(
                objectName
                , searchConditions
                , searchConditionLogic
            );

            // 検証
            System.assert(String.isNotEmpty(exp));
        }
    }
}