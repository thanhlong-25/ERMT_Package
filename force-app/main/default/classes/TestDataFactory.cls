// テストデータファクトリ
@isTest
public class TestDataFactory {
    public static final Datetime NOW_DATETIME = Datetime.now(); // 現在日時

    // プロファイルマップ
    // キー:プロファイル名
    // 値:プロファイルのレコード
    public static Map<String, Profile> profileByName {
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
        set;
    }

    // レコードタイプマップ
    // キー:Sオブジェクトタイプ,レコードタイプ名
    // 値:レコードタイプのレコード
    public static Map<String, RecordType> recordTypeByKey {
        get {
            if (recordTypeByKey == null) {
                recordTypeByKey = new Map<String, RecordType>();
                for (RecordType rt : [
                    SELECT SobjectType, DeveloperName
                    FROM RecordType
                    WHERE IsActive = true
                    ORDER BY SobjectType, DeveloperName
                ]) {
                    String key = rt.SobjectType + ',' + rt.DeveloperName;
                    recordTypeByKey.put(key, rt);
                }
            }
            return recordTypeByKey;
        }
        set;
    }

    // ユーザの作成
    public static User createUser(Integer no) {
        return new User(
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
    }

    // グループの作成
    public static Group createGroup(Integer no) {
        return new Group(
            Name = 'グループ' + no
            , DeveloperName = 'Group' + no + '_' + NOW_DATETIME.format('yyyyMMdd')
        );
    }

    // 組織・部門の作成
    public static Account createAccount(Integer no) {
        return new Account(
            Name = '組織・部門' + no
            , RecordTypeId = recordTypeByKey.get('Account,OrganizationRecordType').Id
        );
    }

    // 分類・評価軸設定の作成
    public static ermt__M_Classification__c createClassification(
        Integer no
        , String recordTypeDevName
        , ermt__M_Classification__c parentClassi
    ) {
        return new ermt__M_Classification__c(
            Name = '分類・評価軸設定' + no
            , RecordTypeId = recordTypeByKey.get('ermt__M_Classification__c,' + recordTypeDevName).Id
            , ermt__ParentMClassification_del__c = (parentClassi == null ? null : parentClassi.Id)
            , ermt__invalid__c = false
        );
    }

    // プロジェクトの作成
    public static ermt__Project__c createProject(Integer no) {
        return new ermt__Project__c(
            Name = 'プロジェクト' + no
            , RecordTypeId = recordTypeByKey.get('ermt__Project__c,GoUnderway').Id
        );
    }

    // プロジェクト分類の作成
    public static ermt__Project_Classification_Junc__c createProjectClassi(
        ermt__Project__c prj
        , ermt__M_Classification__c cls
    ) {
        return new ermt__Project_Classification_Junc__c(
            ermt__Project__c = prj.Id
            , ermt__M_Classification__c = cls.Id
        );
    }

    // リスクの作成
    public static ermt__Risk__c createRisk(Integer no, Account acc) {
        return new ermt__Risk__c(
            Name = 'リスク' + no
            , RecordTypeId = recordTypeByKey.get('ermt__Risk__c,Master').Id
            , ermt__Organization__c = acc.Id
            , ermt__ApprovalStatus__c = System.Label.Risk_ApprovalStatus_Applying
        );
    }

    // リスク分類の作成
    public static ermt__Risk_Classification_Junc__c createRiskClassi(
        ermt__Risk__c rsk
        , ermt__M_Classification__c cls
    ) {
        return new ermt__Risk_Classification_Junc__c(
            ermt__Risk__c = rsk.Id
            , ermt__M_Classification__c = cls.Id
        );
    }

    // リスクアセスメントの作成
    public static ermt__RiskAssessment__c createRiskAssessment(ermt__Risk__c rsk) {
        return new ermt__RiskAssessment__c(
            RecordTypeId = recordTypeByKey.get('ermt__RiskAssessment__c,Analysis').Id
            , ermt__Risk__c = rsk.Id
            , ermt__isActive__c = true
        );
    }

    // リスクアセスメント分類の作成
    public static ermt__RiskAssessment_Classification_Junc__c createRiskAssessmentClassi(
        ermt__RiskAssessment__c rskAss
        , ermt__M_Classification__c cls
    ) {
        return new ermt__RiskAssessment_Classification_Junc__c(
            ermt__RiskAssessment__c = rskAss.Id
            , ermt__M_Classification__c = cls.Id
        );
    }

    // 対応策の作成
    public static ermt__Control__c createControl(Integer no, Account acc) {
        return new ermt__Control__c(
            Name = '対応策' + no
            , ermt__AssignedOrg__c = acc.Id
        );
    }

    // リスク対応策の作成
    public static ermt__Risk_Control_Junc__c createRiskControl(
        ermt__Risk__c rsk
        , ermt__Control__c ctl
    ) {
        return new ermt__Risk_Control_Junc__c(
            ermt__Risk__c = rsk.Id
            , ermt__Control__c = ctl.Id
        );
    }

    // セル色の作成
    public static ermt__CellColor__c createCellColor(
        ermt__Project__c prj
        , ermt__M_Classification__c xCls
        , ermt__M_Classification__c yCls
    ) {
        return new ermt__CellColor__c(
            ermt__Project__c = prj.Id
            , ermt__XCordinate__c = xCls.Id
            , ermt__YCordinate__c = yCls.Id
            , ermt__ColorCode__c = '#ffffff'
            , ermt__ColorLinkCode__c = '#ffffff'
        );
    }

    // インシデントの作成
    public static ermt__Incident__c createIncident(Integer no, Account acc) {
        return new ermt__Incident__c(
            ermt__Title__c = 'インシデントタイトル' + no
            , ermt__Organization__c = acc.Id
        );
    }

    // インシデントリスクの作成
    public static ermt__Incident_Risk_Junc__c createIncidentRisk(
        ermt__Incident__c inc
        , ermt__Risk__c rsk
    ) {
        return new ermt__Incident_Risk_Junc__c(
            ermt__Incident__c = inc.Id
            , ermt__Risk__c = rsk.Id
        );
    }

    // インシデント対応策の作成
    public static ermt__Incident_Control_Junc__c createIncidentControl(
        ermt__Incident__c inc
        , ermt__Control__c ctl
    ) {
        return new ermt__Incident_Control_Junc__c(
            ermt__Incident__c = inc.Id
            , ermt__Control__c = ctl.Id
        );
    }
}