// チェックリスト割当コントローラテスト
@isTest
private class ChecklistAssignControllerTest {
    private static final Datetime NOW_DATETIME = Datetime.now(); // 現在日時

    // プロファイルマップ取得
    // キー:プロファイル名
    // 値:プロファイルのレコード
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
        Integer usrsSize = 2;
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
            // 組織・部門
            List<Account> accs = new List<Account>();
            Integer accsSize = 1;
            for (Integer i = 0; i < accsSize; i++) {
                Integer no = i + 1;
                Account acc = new Account(
                    Name = '組織・部門' + no
                );
                accs.add(acc);
            }
            insert accs;

            // 組織・部門ユーザ
            List<ermt__Account_User__c> accUsrs = new List<ermt__Account_User__c>();
            Integer accUsrsSize = 2;
            for (Integer i = 0; i < accUsrsSize; i++) {
                Integer no = i + 1;
                ermt__Account_User__c accUsr = new ermt__Account_User__c(
                    ermt__Account__c = accs[0].Id
                    , ermt__User__c = usrs[i].Id
                );
                accUsrs.add(accUsr);
            }
            insert accUsrs;

            // チェックリスト
            List<ermt__Checklist__c> chks = new List<ermt__Checklist__c>();
            Integer chksSize = 2;
            for (Integer i = 0; i < chksSize; i++) {
                Integer no = i + 1;
                ermt__Checklist__c chk = new ermt__Checklist__c(
                    Name = 'チェックリスト' + no
                    , ermt__Title__c = 'チェックリスト' + no 
                    , ermt__Valid__c = true
                );
                chks.add(chk);
            }
            insert chks;

            // カテゴリ
            List<ermt__Category__c> ctgs = new List<ermt__Category__c>();
            Integer ctgsSize = 0;
            for (Integer i = 0; i < chksSize; i++) {
                for (Integer j = 0; j < 1; j++) {
                    ctgsSize++;
                    Integer no = j + 1;
                    ermt__Category__c ctg = new ermt__Category__c(
                        Name = 'カテゴリ' + no
                        , ermt__Title__c = 'カテゴリ' + no
                        , ermt__Checklist__c = chks[i].Id
                        , ermt__Order__c = no
                    );
                    ctgs.add(ctg);
                }
            }
            insert ctgs;

            // セクション
            List<ermt__Section__c> scts = new List<ermt__Section__c>();
            Integer sctsSize = 0;
            for (Integer i = 0; i < ctgsSize; i++) {
                for (Integer j = 0; j < 1; j++) {
                    sctsSize++;
                    Integer no = j + 1;
                    ermt__Section__c sct = new ermt__Section__c(
                        Name = 'セクション' + no
                        , ermt__Title__c = 'セクション' + no
                        , ermt__Category__c = ctgs[i].Id
                        , ermt__Order__c = no
                    );
                    scts.add(sct);
                }
            }
            insert scts;

            // 質問
            List<ermt__Question__c> qsts = new List<ermt__Question__c>();
            Integer qstsSize = 0;
            for (Integer i = 0; i < sctsSize; i++) {
                for (Integer j = 0; j < 2; j++) {
                    qstsSize++;
                    Integer no = j + 1;
                    ermt__Question__c qst = new ermt__Question__c(
                        Name = '質問' + no
                        , ermt__Title__c = '質問' + no
                        , ermt__Section__c = scts[i].Id
                        , ermt__Order__c = no
                        , ermt__Label_0__c = '選択肢０'
                        , ermt__Label_1__c = '選択肢１'
                        , ermt__Label_2__c = '選択肢２'
                        , ermt__Label_3__c = '選択肢３'
                        , ermt__Label_4__c = '選択肢４'
                        , ermt__Label_5__c = '選択肢５'
                        , ermt__Label_Date_field__c = '日付'
                        , ermt__Label_Textarea__c = '質問補足'
                    );
                    qsts.add(qst);
                }
            }
            insert qsts;

            // 回答票
            List<ermt__Checklist_User__c> chkUsrs = new List<ermt__Checklist_User__c>();
            Integer chkUsrsSize = 1;
            for (Integer i = 0; i < chkUsrsSize; i++) {
                ermt__Checklist_User__c chkUsr = new ermt__Checklist_User__c(
                    ermt__Checklist__c = chks[0].Id
                    , ermt__User__c = usrs[0].Id
                    , ermt__Answer_Status__c = System.Label.ChecklistUser_AnswerStatus_Unanswered
                );
                chkUsrs.add(chkUsr);
            }
            insert chkUsrs;

            // 回答
            List<ermt__Answer__c> anss = new List<ermt__Answer__c>();
            Integer qstCnt = 0;
            for (Integer i = 0; i < chkUsrsSize; i++) {
                for (Integer j = 0; j < 2; j++) {
                    qstCnt++;
                    Integer no = j + 1;
                    ermt__Answer__c ans = new ermt__Answer__c(
                        ermt__Checklist_User__c = chkUsrs[i].Id
                        , ermt__Question__c = qsts[qstCnt - 1].Id
                        , ermt__Answer_0__c = true
                        , ermt__Answer_Datefield__c = System.today()
                        , ermt__Answer_Textarea__c = '回答テキスト'
                    );
                    anss.add(ans);
                }
            }
            insert anss;
        }
    }

    // ラベルマップ取得テスト
    @isTest static void getLabelMapTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // ラベルマップ取得
            Map<String, String> labelMap = ChecklistAssignController.getLabelMap();

            // 検証
            System.assertEquals(false, labelMap.isEmpty());
        }
    }

    // 割当元オブジェクト名選択リスト取得テスト
    @isTest static void getAssignSourceObjectNameSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当元オブジェクト名選択リスト取得
            List<Map<String, Object>> sels = ChecklistAssignController.getAssignSourceObjectNameSels();

            // 検証
            System.assertEquals(false, sels.isEmpty());
        }
    }

    // 割当先オブジェクト名選択リスト取得テスト
    // 割当元：チェックリスト
    @isTest static void getAssignDestinationObjectNameSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先オブジェクト名選択リスト取得
            List<Map<String, Object>> sels = ChecklistAssignController.getAssignDestinationObjectNameSels('ermt__Checklist__c');

            // 検証
            System.assertEquals(false, sels.isEmpty());
        }
    }

    // 割当先オブジェクト名選択リスト取得テスト
    // 割当元：ユーザ
    @isTest static void getAssignDestinationObjectNameSelsTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先オブジェクト名選択リスト取得
            List<Map<String, Object>> sels = ChecklistAssignController.getAssignDestinationObjectNameSels('User');

            // 検証
            System.assertEquals(false, sels.isEmpty());
        }
    }

    // 割当済選択リスト取得テスト
    @isTest static void getAssignedSelsTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当済選択リスト取得
            List<Map<String, Object>> sels = ChecklistAssignController.getAssignedSels();

            // 検証
            System.assertEquals(false, sels.isEmpty());
        }
    }

    // 割当元情報の取得テスト
    // 割当元：チェックリスト
    @isTest static void getAssignSourceInfoTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        System.runAs(usr) {
            //  割当元情報の取得
            ChecklistAssignController.AssignSourceInfo info;
            info = ChecklistAssignController.getAssignSourceInfo(
                'ermt__Checklist__c'
                , chk.Id
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, String.isEmpty(info.recordName));
        }
    }

    // 割当元情報の取得テスト
    // 割当元：組織・部門
    @isTest static void getAssignSourceInfoTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            //  割当元情報の取得
            ChecklistAssignController.AssignSourceInfo info;
            info = ChecklistAssignController.getAssignSourceInfo(
                'Account'
                , acc.Id
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, String.isEmpty(info.recordName));
        }
    }

    // 割当元情報の取得テスト
    // 割当元：組織・部門
    // その他の検索条件が有り
    @isTest static void getAssignSourceInfoTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            //  割当元情報の取得
            ChecklistAssignController.AssignSourceInfo info;
            info = ChecklistAssignController.getAssignSourceInfo(
                'Account'
                , acc.Id
                , 'ユーザ'
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, String.isEmpty(info.recordName));
        }
    }

    // 割当元情報の取得テスト
    // 割当元：組織・部門
    // ソート項目：ユーザ名
    @isTest static void getAssignSourceInfoTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            //  割当元情報の取得
            ChecklistAssignController.AssignSourceInfo info;
            info = ChecklistAssignController.getAssignSourceInfo(
                'Account'
                , acc.Id
                , null
                , 'userNameLink'
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, String.isEmpty(info.recordName));
        }
    }

    // 割当先情報の取得テスト
    // 割当元：チェックリスト
    @isTest static void getAssignDestinationInfoTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'ermt__Checklist__c'
                , chk.Id
                , 'Account'
                , acc.Id
                , null
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：チェックリスト
    // その他の検索条件が有り
    @isTest static void getAssignDestinationInfoTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'ermt__Checklist__c'
                , chk.Id
                , 'Account'
                , acc.Id
                , null
                , 'ユーザ'
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：チェックリスト
    // ソート項目：ユーザ名
    @isTest static void getAssignDestinationInfoTest_3() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'ermt__Checklist__c'
                , chk.Id
                , 'Account'
                , acc.Id
                , null
                , null
                , 'userNameLink'
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：チェックリスト
    // 割当済：未割当
    @isTest static void getAssignDestinationInfoTest_4() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'ermt__Checklist__c'
                , chk.Id
                , 'Account'
                , acc.Id
                , 'false'
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：チェックリスト
    // 割当済：割当済
    @isTest static void getAssignDestinationInfoTest_5() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // 組織・部門の取得
        Account acc = [
            SELECT Id FROM Account
            WHERE Name = '組織・部門1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'ermt__Checklist__c'
                , chk.Id
                , 'Account'
                , acc.Id
                , 'true'
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：ユーザ
    @isTest static void getAssignDestinationInfoTest_6() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'User'
                , usr.Id
                , 'ermt__Checklist__c'
                , null
                , null
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：ユーザ
    // その他の検索条件が有り
    @isTest static void getAssignDestinationInfoTest_7() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'User'
                , usr.Id
                , 'ermt__Checklist__c'
                , null
                , null
                , 'チェックリスト'
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：ユーザ
    // ソート項目：名称
    @isTest static void getAssignDestinationInfoTest_8() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'User'
                , usr.Id
                , 'ermt__Checklist__c'
                , null
                , null
                , null
                , 'nameLink'
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：ユーザ
    // 割当済：未割当
    @isTest static void getAssignDestinationInfoTest_9() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'User'
                , usr.Id
                , 'ermt__Checklist__c'
                , null
                , 'false'
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }

    // 割当先情報の取得テスト
    // 割当元：ユーザ
    // 割当済：割当済
    @isTest static void getAssignDestinationInfoTest_10() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        System.runAs(usr) {
            // 割当先情報の取得
            ChecklistAssignController.AssignDestinationInfo info;
            info = ChecklistAssignController.getAssignDestinationInfo(
                'User'
                , usr.Id
                , 'ermt__Checklist__c'
                , null
                , 'true'
                , null
                , null
                , 0
                , 1
            );

            // 検証
            System.assertEquals(false, info.records.isEmpty());
        }
    }
    
    // 回答票の作成テスト
    // 割当元：チェックリスト
    @isTest static void createAnswerSheetTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // ユーザの取得
        List<Id> usrIds = new List<Id>();
        for (User u : [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ2' LIMIT 1
        ]) {
            usrIds.add(u.Id);
        }

        System.runAs(usr) {
            //  回答票の作成
            ChecklistAssignController.createAnswerSheet(
                'ermt__Checklist__c'
                , chk.Id
                , 'User'
                , usrIds
            );

            // 検証
            List<ermt__Checklist_User__c> chkUsrs = [
                SELECT Id FROM ermt__Checklist_User__c
                WHERE ermt__Checklist__c = :chk.Id
                AND ermt__User__c IN :usrIds
                LIMIT 1
            ];
            System.assertEquals(false, chkUsrs.isEmpty());
        }
    }

    // 回答票の作成テスト
    // 割当元：ユーザ
    @isTest static void createAnswerSheetTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        List<Id> chkIds = new List<Id>();
        for (ermt__Checklist__c c : [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ]) {
            chkIds.add(c.Id);
        }

        // ユーザの取得
        Id usrId = null;
        for (User u : [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ2' LIMIT 1
        ]) {
            usrId = u.Id;
        }

        System.runAs(usr) {
            //  回答票の作成
            ChecklistAssignController.createAnswerSheet(
                'User'
                , usrId
                , 'ermt__Checklist__c'
                , chkIds
            );

            // 検証
            List<ermt__Checklist_User__c> chkUsrs = [
                SELECT Id FROM ermt__Checklist_User__c
                WHERE ermt__Checklist__c IN :chkIds
                AND ermt__User__c = :usrId
                LIMIT 1
            ];
            System.assertEquals(false, chkUsrs.isEmpty());
        }
    }

    // 回答票の削除テスト
    // 割当元：チェックリスト
    @isTest static void deleteAnswerSheetTest_1() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        ermt__Checklist__c chk = [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ];

        // ユーザの取得
        List<Id> usrIds = new List<Id>();
        for (User u : [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ2' LIMIT 1
        ]) {
            usrIds.add(u.Id);
        }

        System.runAs(usr) {
            //  回答票の削除
            ChecklistAssignController.deleteAnswerSheet(
                'ermt__Checklist__c'
                , chk.Id
                , 'User'
                , usrIds
            );

            // 検証
            List<ermt__Checklist_User__c> chkUsrs = [
                SELECT Id FROM ermt__Checklist_User__c
                WHERE ermt__Checklist__c = :chk.Id
                AND ermt__User__c IN :usrIds
                LIMIT 1
            ];
            System.assertEquals(true, chkUsrs.isEmpty());
        }
    }

    // 回答票の削除テスト
    // 割当元：組織・部門
    @isTest static void deleteAnswerSheetTest_2() {
        // ユーザの取得
        User usr = [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ1' LIMIT 1
        ];

        // チェックリストの取得
        List<Id> chkIds = new List<Id>();
        for (ermt__Checklist__c c : [
            SELECT Id FROM ermt__Checklist__c
            WHERE Name = 'チェックリスト1' LIMIT 1
        ]) {
            chkIds.add(c.Id);
        }

        // ユーザの取得
        Id usrId = null;
        for (User u : [
            SELECT Id FROM User
            WHERE LastName = 'ユーザ2' LIMIT 1
        ]) {
            usrId = u.Id;
        }

        System.runAs(usr) {
            //  回答票の削除
            ChecklistAssignController.deleteAnswerSheet(
                'User'
                , usrId
                , 'ermt__Checklist__c'
                , chkIds
            );

            // 検証
            List<ermt__Checklist_User__c> chkUsrs = [
                SELECT Id FROM ermt__Checklist_User__c
                WHERE ermt__Checklist__c IN :chkIds
                AND ermt__User__c = :usrId
                LIMIT 1
            ];
            System.assertEquals(true, chkUsrs.isEmpty());
        }
    }
}