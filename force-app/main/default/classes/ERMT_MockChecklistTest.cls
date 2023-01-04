@isTest
public with sharing class ERMT_MockChecklistTest {
	
	public static void MockDataInsertedAccountHandleTest(){
        // create Account
        insertAccountTest();
    }
	
	public static void MockDataInsertedChecklistTest(){
        // insert checklist
		ermt__Checklist__c checklist = new ermt__Checklist__c(Name='myChecklist',ermt__Title__c='My Checklist');
		insert checklist;

		// insert category
		List<ermt__Category__c> listCate = new List<ermt__Category__c>();
		
		for (Integer i = 0; i < 10; i ++){
			ermt__Category__c cl = new ermt__Category__c(ermt__Checklist__c=checklist.Id,ermt__Title__c='Category '+ string.valueOf(i));
			listCate.add(cl);
		}
		insert listCate;

		// insert section
		List<ermt__Section__c> listSecs = new List<ermt__Section__c>();
		for (Integer i = 0; i < listCate.size(); i++){
			ermt__Section__c sec = new ermt__Section__c(ermt__Category__c=listCate[i].Id,ermt__Title__c=listCate[i].ermt__Title__c+ ' - Section '+ string.valueOf(i));
			listSecs.add(sec);
		}
		insert listSecs;

		// insert question

		List<ermt__Question__c> listQues = new List<ermt__Question__c>();
		for (Integer i = 0; i < listSecs.size(); i++){
			ermt__Question__c q = new ermt__Question__c(ermt__Section__c=listSecs[i].Id,ermt__Title__c='Q ' + listSecs[i].ermt__Title__c+ ' - Question '+ string.valueOf(i));
			
			List<String> options = getRandomOptions();
			for (String op : options){
				if (op == '0') {
					q.ermt__Label_0__c = 'Label option 0';
				}
				if (op == '1') {
					q.ermt__Label_1__c = 'Label option 1';
				}
				if (op == '2') {
					q.ermt__Label_2__c = 'Label option 2';
				}
				if (op == '3') {
					q.ermt__Label_3__c = 'Label option 3';
				}
				if (op == '4') {
					q.ermt__Label_4__c = 'Label option 4';
				}
				if (op == '5') {
					q.ermt__Label_5__c = 'Label option 5';
				}
			}
			listQues.add(q);
		}
		insert listQues;
    }	

	public static void MockDataChecklistTest(){
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];
		// insert Chechlist_User
		ermt__Checklist_User__c checklistUser = new ermt__Checklist_User__c(ermt__Checklist__c=cl.Id,ermt__User__c=UserInfo.getUserId());
		insert checklistUser;
	}

	public static List<ermt__Answer__c> MockDataChecklistAnswersTest(){
		
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		List<ermt__Checklist_User__c> clus = [SELECT Id FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id];

		
        // create answers data
		List<ermt__Question__c> questions = [SELECT Id, ermt__Title__c, ermt__Label_0__c, ermt__Label_1__c, ermt__Label_2__c, ermt__Label_3__c, ermt__Label_4__c, ermt__Label_5__c  FROM ermt__Question__c WHERE ermt__Title__c like 'Q %'];
		List<ermt__Answer__c> answers = new List<ermt__Answer__c>();
		for (ermt__Question__c q : questions){
			ermt__Answer__c a = new ermt__Answer__c(ermt__Question__c=q.Id,ermt__Answer_Textarea__c='Answer text' + q.ermt__Title__c);
			
			if (q.ermt__Label_0__c != null){
				a.ermt__Answer_0__c = true;
			} else if (q.ermt__Label_1__c != null){
				a.ermt__Answer_1__c = true;
			} else if (q.ermt__Label_2__c != null){
				a.ermt__Answer_2__c = true;
			} else if (q.ermt__Label_3__c != null){
				a.ermt__Answer_3__c = true;
			} else if (q.ermt__Label_4__c != null){
				a.ermt__Answer_4__c = true;
			} else if (q.ermt__Label_5__c != null){
				a.ermt__Answer_5__c = true;
			} 

			if (!clus.isEmpty()){
				a.ermt__Checklist_User__c = clus[0].Id;
			}
			answers.add(a);
		}
		return answers;
    }

	public static List<String> getRandomOptions(){
		// Generate the set
		Set<String> setArray = new Set<String> {'0', '1', '2', '3', '4', '5'};
		
		// Create a random index
		Double randomNumber = Math.random();
		Integer arraySize = setArray.size();
		Integer randomIndex = (randomNumber *(arraySize-1)).intValue();
		
		List<String> listElements = new List<String>();
		// Loop through the Set until you get to the element.
		for (String str : setArray) {
			if (randomIndex == 0) {
				listElements.add(str);
			}
			randomIndex--;
		}
		return listElements;
	}
	
	public static void MockDataInsertedAccountUserHandleTest(){
        // create Account
        List<Account> testAccs = insertAccountTest();

        // create User
        List<User> testUsers = insertUserTest();

		// create ermt__Account_User__c
		insertAccountUserTest(testAccs, testUsers);

		insert new ermt__Checklist__c(Name='testChecklist');

    }

	private static List<Account> insertAccountTest(){
        List<Account> testAccounts = new List<Account>();
		for (Integer i = 0; i < 10; i ++){
			Account acc = new Account(Name='acc_test'+ string.valueOf(i), RecordTypeId=[SELECT Id FROM RecordType WHERE DeveloperName = 'BranchLocationRecordType' AND SobjectType = 'Account'].Id);
			testAccounts.add(acc);
		}
		insert testAccounts;
		
		// 2020/08/13 tsuji mod start
		// for(Account acc : testAccounts){
		// 	createGroup(acc.Id, acc.Name, 'Account');
		// }
		Map<Id, Group> grpByAccId = getGroupByAccountId('Account', 'acc_test');
		for(Account acc : testAccounts) {
			if (!grpByAccId.containsKey(acc.Id)) {
				createGroup(acc.Id, acc.Name, 'Account');
			}
		}
		// 2020/08/13 tsuji mod end

        return testAccounts;
    }

	private static void createGroup(String groupId, String groupName, String prefix){
		Group grp = new Group(DeveloperName = (prefix+'_')+groupId, Name = groupName);
		insert grp;
	}
	
	// 2020/08/13 tsuji add start
	// 部門・組織IDごとのグループを取得
	private static Map<Id, Group> getGroupByAccountId(String groupDevNamePrefix, String groupNamePrefix) {
		Map<Id, Group> ret = new Map<Id, Group>();
		for (Group g : [
			SELECT DeveloperName FROM Group
			WHERE DeveloperName LIKE :groupDevNamePrefix +'%'
			AND Name LIKE :groupNamePrefix + '%'
		]) {
			String accountId = g.DeveloperName.removeStart(groupDevNamePrefix + '_');
            ret.put(accountId, g);
		}
		return ret;
	}
	// 2020/08/13 tsuji add end

	private static List<User> insertUserTest(){
        List<User> testUsers = new List<User>();
		for (Integer i = 0; i < 10; i ++){
			User usr = new User();
			usr.LastName = 'user' + string.valueOf(i);
			usr.Alias = 'user' + string.valueOf(i);
			usr.Email = 'user' + string.valueOf(i) + '@gmail.com';
			usr.Username = 'user_test' + string.valueOf(i) + '@xyz.com';
			usr.ProfileId = [Select Id from Profile where Name = 'ERMT'].Id;
			usr.EmailEncodingKey='UTF-8';
			usr.LanguageLocaleKey='en_US';
			usr.LocaleSidKey='en_US';
			usr.TimeZoneSidKey='America/Los_Angeles';
        	testUsers.add(usr);
		}
        
        insert testUsers;
        return testUsers;
    }

	private static List<ermt__Account_User__c> insertAccountUserTest(List<Account> accs, List<User> users){
		List<ermt__Account_User__c> testAccUsers = new List<ermt__Account_User__c>();
		for (Integer i = 0; i < accs.size(); i++){
			ermt__Account_User__c accUsr = new ermt__Account_User__c();
			accUsr.ermt__Account__c = accs[i].Id;
			accUsr.ermt__User__c = users[i].Id;
			testAccUsers.add(accUsr);
		}
		insert testAccUsers;
		return testAccUsers;
    }

	@future
	public static void insertGroupMemberTest(){

		List<Account> accs = [SELECT Id FROM Account WHERE Name like 'acc_test%'];
		List<User> users = [SELECT Id FROM User WHERE Username like 'user_test%'];

		List<GroupMember> testGroupMembers = new List<GroupMember>();
		for (Integer i = 0; i < accs.size(); i++){
			if (users[i] != null){
				String id = 'Account_' + accs[i].Id + '%';
				GroupMember mem = new GroupMember();
				mem.GroupId = [SELECT Id FROM Group WHERE DeveloperName like :id].Id;
				mem.UserOrGroupId = users[i].Id;
				testGroupMembers.add(mem);
			}
		}
		insert testGroupMembers;
    }

	public static void MockDataInsertChecklistAnswersTest(){
		
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		List<ermt__Checklist_User__c> clus = [SELECT Id FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id];
		
        // create answers data
		List<ermt__Question__c> questions = [SELECT Id, ermt__Title__c, ermt__Label_0__c, ermt__Label_1__c, ermt__Label_2__c, ermt__Label_3__c, ermt__Label_4__c, ermt__Label_5__c  FROM ermt__Question__c WHERE ermt__Title__c like 'Q %'];
		List<ermt__Answer__c> answers = new List<ermt__Answer__c>();
		for (ermt__Question__c q : questions){
			ermt__Answer__c a = new ermt__Answer__c(ermt__Question__c=q.Id,ermt__Answer_Textarea__c='Answer text' + q.ermt__Title__c);
			
			if (q.ermt__Label_0__c != null){
				a.ermt__Answer_0__c = true;
			} else if (q.ermt__Label_1__c != null){
				a.ermt__Answer_1__c = true;
			} else if (q.ermt__Label_2__c != null){
				a.ermt__Answer_2__c = true;
			} else if (q.ermt__Label_3__c != null){
				a.ermt__Answer_3__c = true;
			} else if (q.ermt__Label_4__c != null){
				a.ermt__Answer_4__c = true;
			} else if (q.ermt__Label_5__c != null){
				a.ermt__Answer_5__c = true;
			} 

			if (!clus.isEmpty()){
				a.ermt__Checklist_User__c = clus[0].Id;
			}
			answers.add(a);
		}
		insert answers;
    }
	
	public static void MockDataInsertChecklistMissingAnswersTest(){
		
		ermt__Checklist__c cl = [SELECT Id FROM ermt__Checklist__c WHERE Name = 'myChecklist'];

		List<ermt__Checklist_User__c> clus = [SELECT Id FROM ermt__Checklist_User__c WHERE ermt__Checklist__c =:cl.Id];
		
        // create answers data
		List<ermt__Question__c> questions = [SELECT Id, ermt__Title__c, ermt__Label_0__c, ermt__Label_1__c, ermt__Label_2__c, ermt__Label_3__c, ermt__Label_4__c, ermt__Label_5__c  FROM ermt__Question__c WHERE ermt__Title__c like 'Q %'];
		List<ermt__Answer__c> answers = new List<ermt__Answer__c>();
		for (INteger i = 0; i < questions.size() - 1; i ++){
			ermt__Question__c  q = questions[i];
			ermt__Answer__c a = new ermt__Answer__c(ermt__Question__c=q.Id,ermt__Answer_Textarea__c='Answer text' + q.ermt__Title__c);
			
			if (q.ermt__Label_0__c != null){
				a.ermt__Answer_0__c = true;
			} else if (q.ermt__Label_1__c != null){
				a.ermt__Answer_1__c = true;
			} else if (q.ermt__Label_2__c != null){
				a.ermt__Answer_2__c = true;
			} else if (q.ermt__Label_3__c != null){
				a.ermt__Answer_3__c = true;
			} else if (q.ermt__Label_4__c != null){
				a.ermt__Answer_4__c = true;
			} else if (q.ermt__Label_5__c != null){
				a.ermt__Answer_5__c = true;
			} 

			if (!clus.isEmpty()){
				a.ermt__Checklist_User__c = clus[0].Id;
			}
			answers.add(a);
		}
		insert answers;
    }

	public static void MockDataDeleteChecklistUserTest(){
		delete [SELECT Id FROM ermt__Checklist_User__c WHERE ermt__Checklist__r.Name = 'myChecklist'];
	}
}