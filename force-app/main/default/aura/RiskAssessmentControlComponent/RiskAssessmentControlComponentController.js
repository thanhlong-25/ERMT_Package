({
	doInit : function(cmp, event, helper) {
		helper.getEvaluations(cmp);

		// 確定の使用可否の読込み
		helper.loadCanConfirm(cmp);

		// コピーの使用可否の読込み
		helper.loadCanCopy(cmp);
	},
	clickOnTab : function(cmp, event, helper) {
		var idtab = event.target.id;
		if (idtab){
			var tmp = idtab.split('__');
			if (tmp.length > 1) {
				var id = tmp[1];
				var listEvaluations = cmp.get("v.listEvaluations");
				for (var i in listEvaluations){
					if (id === listEvaluations[i].classId){
						cmp.set("v.currentTab", listEvaluations[i].label);
						break;
					}
				}
			}
		}
	}
})