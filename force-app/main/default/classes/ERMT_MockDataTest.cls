@isTest
public with sharing class ERMT_MockDataTest {
    public static void MockDataInsertedTest(){
        //Create Project
        List<ermt__Project__c> testProjects = insertProjectTest();

        //Create Account
        List<Account>  accounts = insertAccountTest();

        RecordType rtypes = [Select Name, Id  From RecordType
                  where sObjectType='ermt__M_Classification__c' and isActive=true and Name = '選択肢' Limit 1];

        // Create Risk
        List<ermt__Risk__c> testRisks = insertRiskTest(testProjects, rtypes);
        
        List<ermt__M_Classification__c> mClassList;
        List<RecordType> mClassRecordType; // get recordType
        List<RecordType> rAssessRecordType;
        Map<String, Id> mClassRecordTypeMap = new Map<String, Id>(); // map Name, Id
        Map<String, Id> rAssessRecordTypeMap = new Map<String , Id>();
        mClassRecordType = [SELECT Name,DeveloperName, Id FROM RecordType WHERE sObjectType = 'ermt__M_Classification__c' AND isActive = true];
       
        rAssessRecordType = [SELECT Name,DeveloperName, Id FROM RecordType WHERE sObjectType = 'ermt__RiskAssessment__c' AND isActive = true];
        
        
        for(RecordType type: mClassRecordType) {
            //LikelihoodGroup ,ConsequenceGroup, SeverityRiskLevelGroup, 選択肢, リスク分類
            mClassRecordTypeMap.put(type.DeveloperName, type.Id);
        }
        for(RecordType type : rAssessRecordType){
            // Evaluation   ,  Analysis
            rAssessRecordTypeMap.put(type.DeveloperName , type.Id);
        }

        ermt__M_Classification__c classificationTest = new ermt__M_Classification__c(Name= 'MTest' ,RecordTypeId = mClassRecordTypeMap.get('LikelihoodGroup'),ermt__ViewNo__c = 4);
          insert classificationTest;
         ermt__M_Classification__c classificationTest1 = new ermt__M_Classification__c(Name= 'MTest1' ,RecordTypeId = mClassRecordTypeMap.get('ConsequenceGroup'),ermt__ViewNo__c = 2);
        insert classificationTest1;
         ermt__M_Classification__c classificationTest2 = new ermt__M_Classification__c(Name= 'MTest2' ,RecordTypeId = mClassRecordTypeMap.get('SeverityRiskLevelGroup') ,ermt__ViewNo__c = 5);
         insert classificationTest2;
         ermt__M_Classification__c classificationTest3 = new ermt__M_Classification__c(Name= 'MTest3' ,RecordTypeId = mClassRecordTypeMap.get('EvaluationPeriodGroup') ,ermt__ViewNo__c = 5);
         insert classificationTest3;
         ermt__M_Classification__c classificationTest4 = new ermt__M_Classification__c(Name= 'MTest3' ,RecordTypeId = mClassRecordTypeMap.get('ClassificationGroup') ,ermt__ViewNo__c = 6);
         insert classificationTest4;
        mClassList = new List<ermt__M_Classification__c> {
            new ermt__M_Classification__c(ermt__Label__c='test0', ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ChoiceItem') , Name = 'M1' , ermt__ViewNo__c = 2, ermt__ParentMClassification_del__c = classificationTest.Id ),
            new ermt__M_Classification__c(ermt__Label__c='test1',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('LikelihoodGroup') , ermt__ViewNo__c = 4, Name = 'M2'),
            new ermt__M_Classification__c(ermt__Label__c='test2',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('SeverityRiskLevelGroup') ,ermt__ViewNo__c = 2, Name = 'M3'),
            new ermt__M_Classification__c(ermt__Label__c='test3',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ConsequenceGroup') ,  Name = 'M4'),
            new ermt__M_Classification__c(ermt__Label__c='test4',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('EvaluationPeriodGroup') ,  Name = 'M5'),
            new ermt__M_Classification__c(ermt__Label__c='test5',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ClassificationGroup'), Name = 'M5' , ermt__ViewNo__c = 1),
            new ermt__M_Classification__c(ermt__Label__c='test6',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ChoiceItem') , Name = 'M7' ,ermt__ViewNo__c = 3, ermt__ParentMClassification_del__c = classificationTest1.Id ),
            new ermt__M_Classification__c(ermt__Label__c='test7',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ChoiceItem') , Name = 'M8' , ermt__ViewNo__c = 4 , ermt__ParentMClassification_del__c = classificationTest2.Id ),
            new ermt__M_Classification__c(ermt__Label__c='test8',ermt__invalid__c = true, RecordTypeId = mClassRecordTypeMap.get('ChoiceItem') , Name = 'M9' ,ermt__ViewNo__c = 2 , ermt__ParentMClassification_del__c = classificationTest3.Id ),
            new ermt__M_Classification__c(ermt__Label__c='test9',RecordTypeId = mClassRecordTypeMap.get('ChoiceItem') , Name = 'M10' ,ermt__ViewNo__c = 2 , ermt__ParentMClassification_del__c = classificationTest4.Id )           
        };

        insert mClassList;
        //System.debug('MCLASS LIST' + mClassList);

         createValidRiskScore(testRisks[0].Id);
         createValidRiskScore(testRisks[1].Id);

        // Create RiskAssessment
        List<ermt__RiskAssessment__c> testRiskAssess = new List<ermt__RiskAssessment__c>();
        ermt__RiskAssessment__c riskAssess1 = new ermt__RiskAssessment__c(ermt__Risk__c = testRisks[0].Id , ermt__NumberConsequence__c = 2 , ermt__NumberLikelihood__c = 2 , ermt__NumberSeverityRiskLevel__c = 2 , RecordTypeId = rAssessRecordTypeMap.get('Analysis') , EvaluationTime__c = 'FY-16 (Beforehand)', isActive__c = true);
        insert riskAssess1;

        ermt__RiskAssessment__c riskAssess2 = new ermt__RiskAssessment__c(ermt__Risk__c = testRisks[0].Id, ermt__beforeAssessment__c = riskAssess1.Id , ermt__NumberConsequence__c = 2 , ermt__NumberLikelihood__c = 2 , ermt__NumberSeverityRiskLevel__c = 2, RecordTypeId = rAssessRecordTypeMap.get('Analysis'), EvaluationTime__c = 'FY-17 (Current)', isActive__c = true);
        insert riskAssess2;

        ermt__RiskAssessment__c riskAssess3 = new ermt__RiskAssessment__c(ermt__Risk__c = testRisks[0].Id, ermt__beforeAssessment__c = riskAssess2.Id , ermt__NumberConsequence__c = 2 , ermt__NumberLikelihood__c = 2 , ermt__NumberSeverityRiskLevel__c = 2, RecordTypeId = rAssessRecordTypeMap.get('Analysis'), EvaluationTime__c = 'FY-18 (Target)', isActive__c = true);
        insert riskAssess3;

        ermt__RiskAssessment__c riskAssess4 = new ermt__RiskAssessment__c(ermt__Risk__c = testRisks[1].Id, ermt__NumberConsequence__c = 2 , ermt__NumberLikelihood__c = 2 , ermt__NumberSeverityRiskLevel__c = 2 , RecordTypeId = rAssessRecordTypeMap.get('Evaluation'), isActive__c = true);
        insert riskAssess4;

        //Create Project_Classification_Junc
        ermt__Project_Classification_Junc__c pCJun1=  new ermt__Project_Classification_Junc__c(ermt__Project__c = testProjects[0].Id , ermt__M_Classification__c = classificationTest.Id);
        insert pCJun1;
        ermt__Project_Classification_Junc__c pCJun2=  new ermt__Project_Classification_Junc__c(ermt__Project__c = testProjects[0].Id , ermt__M_Classification__c = classificationTest1.Id);
        insert pCJun2;
        ermt__Project_Classification_Junc__c pCJun3=  new ermt__Project_Classification_Junc__c(ermt__Project__c = testProjects[0].Id , ermt__M_Classification__c = classificationTest2.Id);
        insert pCJun3;
        ermt__Project_Classification_Junc__c pCJun4=  new ermt__Project_Classification_Junc__c(ermt__Project__c = testProjects[0].Id , ermt__M_Classification__c = classificationTest3.Id);
        insert pCJun4;
        ermt__Project_Classification_Junc__c pCJun5=  new ermt__Project_Classification_Junc__c(ermt__Project__c = testProjects[0].Id , ermt__M_Classification__c = classificationTest4.Id);
        insert pCJun5;

        //Create ermt__Risk_Classification_Junc__c
        ermt__Risk_Classification_Junc__c rCJun1=  new ermt__Risk_Classification_Junc__c(ermt__Risk__c = testRisks[0].Id , ermt__M_Classification__c = mClassList[9].Id);
        insert rCJun1;
         ermt__Risk_Classification_Junc__c rCJun2=  new ermt__Risk_Classification_Junc__c(ermt__Risk__c = testRisks[1].Id , ermt__M_Classification__c = mClassList[9].Id);
         insert rCJun2;

         //Create RiskAssessment_Classification_Junc
        List<ermt__RiskAssessment_Classification_Junc__c> riskMclasssJun = new List<ermt__RiskAssessment_Classification_Junc__c>();
        ermt__RiskAssessment_Classification_Junc__c rMJun1=  new ermt__RiskAssessment_Classification_Junc__c(ermt__RiskAssessment__c = riskAssess2.Id , ermt__M_Classification__c = mClassList[0].Id);
        insert rMJun1;
        ermt__RiskAssessment_Classification_Junc__c rMJun2=  new ermt__RiskAssessment_Classification_Junc__c(ermt__RiskAssessment__c = riskAssess3.Id , ermt__M_Classification__c = mClassList[7].Id);
        insert rMJun2;
        ermt__RiskAssessment_Classification_Junc__c rMJun3=  new ermt__RiskAssessment_Classification_Junc__c(ermt__RiskAssessment__c = riskAssess3.Id , ermt__M_Classification__c = mClassList[8].Id);
        insert rMJun3;
        ermt__RiskAssessment_Classification_Junc__c rMJun4=  new ermt__RiskAssessment_Classification_Junc__c(ermt__RiskAssessment__c = riskAssess4.Id , ermt__M_Classification__c = mClassList[9].Id);
        insert rMJun4;
 
        // CREATE ermt__Project_Participant_Junc__c
        ermt__Project_Participant_Junc__c pParJunc = new ermt__Project_Participant_Junc__c(ermt__Project__c = testProjects[0].Id , Account__c = accounts[0].Id);
        insert pParJunc;

        //Create Cell Color
        List<ermt__CellColor__c> ccList = new List<ermt__CellColor__c>();
        ermt__CellColor__c cc1 = new ermt__CellColor__c(ermt__ColorCode__c = 'cc1' , ermt__Project__c = testProjects[0].Id);
        ermt__CellColor__c cc2 = new ermt__CellColor__c(ermt__ColorCode__c = 'cc2' , ermt__Project__c = testProjects[1].Id);
        ccList.add(cc1);
        ccList.add(cc2);
        insert ccList;

        

    }
    private static List<ermt__Project__c> insertProjectTest(){
        List<ermt__Project__c> testProjects = new List<ermt__Project__c>();
        ermt__Project__c prj1 = new ermt__Project__c(Name='Project 1');
        ermt__Project__c prj2 = new ermt__Project__c(Name='Project 2');
        testProjects.add(prj1);
        testProjects.add(prj2);
        insert testProjects;
        return testProjects;
    }

    private static List<Account> insertAccountTest(){
        List<Account> testAccounts = new List<Account>();
        Account acc1 = new Account(Name='acc1');
        Account acc2 = new Account(Name='acc2');
        testAccounts.add(acc1);
        testAccounts.add(acc2);
        insert testAccounts;
        return testAccounts;
    }
    private static List<ermt__Risk__c> insertRiskTest(List<ermt__Project__c> projectList,RecordType rtypes){
        List<ermt__Risk__c> testRisks = new List<ermt__Risk__c>();
         ermt__Risk__c risk1 = new ermt__Risk__c(Name = 'risk1' ,ermt__RiskContents__c = 'Risk 1',ermt__Project__c=projectList[0].Id , RecordType= rtypes , ermt__AssessmentStatus__c = 'Analysis');
        ermt__Risk__c risk2 = new ermt__Risk__c(Name = 'risk2' ,ermt__RiskContents__c = 'Risk 2',ermt__Project__c=projectList[0].Id, RecordType = rtypes , ermt__AssessmentStatus__c = 'Evaluation');
        testRisks.add(risk1);
        testRisks.add(risk2);
        insert testRisks;
        return testRisks;

    }

    private static void createValidRiskScore(string riskId){
        Map<String, RecordType> rTypeAssessMap = ERMT_RecordTypeCache.get(ermt__RiskAssessment__c.sObjectType);
        ermt__RiskAssessment__c riskAssess1 = new ermt__RiskAssessment__c(ermt__Risk__c = riskId , RecordTypeId = rTypeAssessMap.get('Analysis').Id , isActive__c = true);
        insert riskAssess1;
        
        ermt__RiskAssessment__c riskAssess2 = new ermt__RiskAssessment__c(ermt__Risk__c = riskId , RecordTypeId = rTypeAssessMap.get('Analysis').Id , isActive__c = true, ermt__Current_Valuation__c = true);
        insert riskAssess2;

        List<ermt__RiskAssessment_Classification_Junc__c> juncList = new List<ermt__RiskAssessment_Classification_Junc__c>();

        List<ermt__M_Classification__c> classiList = [Select Id From ermt__M_Classification__c Where RecordType.DeveloperName = 'ChoiceItem' and ermt__ParentMClassification_del__r.RecordType.DeveloperName in ('LikelihoodGroup','ConsequenceGroup','EvaluationPeriodGroup')];

        for(ermt__M_Classification__c classi : classiList) {
            ermt__RiskAssessment_Classification_Junc__c junc = new ermt__RiskAssessment_Classification_Junc__c();
            junc.RiskAssessment__c = riskAssess1.Id;
            junc.M_Classification__c = classi.Id;

            ermt__RiskAssessment_Classification_Junc__c junc2 = new ermt__RiskAssessment_Classification_Junc__c();
            junc2.RiskAssessment__c = riskAssess2.Id;
            junc2.M_Classification__c = classi.Id;

            juncList.add(junc);
            juncList.add(junc2);
        }
        insert juncList;
    }
}