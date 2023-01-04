public without sharing class ERMT_ProjectClassificationJuncHandler {
	public static void deleteRiskClassiJuncChild(List<ermt__Project_Classification_Junc__c> pJuncList){
		try {
			//Generate set ids to bulkify
			Set<Id> classiList = new Set<Id>();
			Set<Id> prjList = new Set<Id>();
			for(ermt__Project_Classification_Junc__c junc: pJuncList){
				classiList.add(junc.ermt__M_Classification__c);
				prjList.add(junc.ermt__Project__c);
			}

			List<ermt__Risk_Classification_Junc__c> rJuncList = [Select Id, ermt__M_Classification__r.ermt__ParentMClassification_del__c, ermt__Risk__r.ermt__Project__c From ermt__Risk_Classification_Junc__c Where ermt__Risk__r.ermt__Project__c In :prjList And ermt__M_Classification__r.ermt__ParentMClassification_del__c In :classiList];
			System.debug(rJuncList);
			List<ermt__RiskAssessment_Classification_Junc__c> raJuncList = [Select Id, ermt__M_Classification__r.ermt__ParentMClassification_del__c, RiskAssessment__r.ermt__Risk__r.ermt__Project__c From ermt__RiskAssessment_Classification_Junc__c Where RiskAssessment__r.ermt__Risk__r.ermt__Project__c In :prjList And ermt__M_Classification__r.ermt__ParentMClassification_del__c In :classiList];

			List<SObject> deleteList = new List<SObject>();
			for(ermt__Project_Classification_Junc__c pJunc: pJuncList){
				//Delete ermt__Risk_Classification_Junc__c child of ermt__Project_Classification_Junc__c
				for(ermt__Risk_Classification_Junc__c rJunc: rJuncList){
					if(pJunc.ermt__M_Classification__c == rJunc.ermt__M_Classification__r.ermt__ParentMClassification_del__c && pJunc.ermt__Project__c == rJunc.ermt__Risk__r.ermt__Project__c){
						deleteList.add(rJunc);
					}
				}

				//Delete ermt__RiskAssessment_Classification_Junc__c child of ermt__Project_Classification_Junc__c
				for(ermt__RiskAssessment_Classification_Junc__c raJunc: raJuncList){
					if(pJunc.ermt__M_Classification__c == raJunc.ermt__M_Classification__r.ermt__ParentMClassification_del__c && pJunc.ermt__Project__c == raJunc.RiskAssessment__r.ermt__Risk__r.ermt__Project__c){
						deleteList.add(raJunc);
					}
				}
			}
			if (ermt__Risk_Classification_Junc__c.sObjectType.getDescribe().isDeletable() &&
				ermt__RiskAssessment_Classification_Junc__c.sObjectType.getDescribe().isDeletable()
			) {
				delete deleteList;
			}
			

		} catch(Exception e) {
			System.debug(e.getMessage());
		}
		
	}

	// リスクマップのセル色の削除
	public static void deleteCellColor(List<ermt__Project_Classification_Junc__c> projectClassis) {
		if (!Schema.SObjectType.ermt__CellColor__c.isDeletable()) return;

		// プロジェクトIDリストマップの作成
		Map<Id, List<Id>> projectIdsByClassiId = new Map<Id, List<Id>>();
		for(ermt__Project_Classification_Junc__c projectClassi : projectClassis) {
			List<Id> projectIds = projectIdsByClassiId.get(projectClassi.ermt__M_Classification__c);
			if (projectIds == null) {
				projectIds = new List<Id>();
				projectIdsByClassiId.put(projectClassi.ermt__M_Classification__c, projectIds);
			}
			projectIds.add(projectClassi.ermt__Project__c);
		}

		// 分類・評価軸の取得
		Set<Id> projectIdSet = new Set<Id>();
		for (ermt__M_Classification__c classi : [
			SELECT Id FROM ermt__M_Classification__c
			WHERE Id IN :projectIdsByClassiId.keySet()
			AND RecordType.DeveloperName IN (
				:System.Label.ClassiRecordType_Probability
				, :System.Label.ClassiRecordType_ResultImpact
			)
		]) {
			List<Id> projectIds = projectIdsByClassiId.get(classi.Id);
			projectIdSet.addAll(projectIds);
		}
		if (!projectIdSet.isEmpty()) {
			// 削除用リスクマップのセル色の作成
			List<ermt__CellColor__c> delCellColors = [
				SELECT Id FROM ermt__CellColor__c
				WHERE ermt__Project__c IN :projectIdSet
			];

			// リスクマップのセル色の削除
			if (!delCellColors.isEmpty()) {
				if (ermt__CellColor__c.sObjectType.getDescribe().isDeletable()) {
					delete delCellColors;
				}
			}
		}		
	}
}