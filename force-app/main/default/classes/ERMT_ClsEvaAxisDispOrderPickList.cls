// 分類・評価軸表示順の選択リスト
global class ERMT_ClsEvaAxisDispOrderPickList extends VisualEditor.DynamicPickList {
    // レコードタイプマップ取得
    // キー:レコードタイプ名
    // 値:レコードタイプのレコード
    private static Map<String, RecordType> recTypeByDevName {
        get {
            if (recTypeByDevName == null) {
                recTypeByDevName = new Map<String, RecordType>();
                for (RecordType r : [
                    SELECT toLabel(Name), DeveloperName FROM RecordType
                    WHERE SobjectType = 'ermt__M_Classification__c'
                ]) {
                    recTypeByDevName.put(r.DeveloperName, r);
                }
            }
            return recTypeByDevName;
        }
        set;
    }

    // デフォルト値の取得
    global override VisualEditor.DataRow getDefaultValue(){
        RecordType recType1 = recTypeByDevName.get('LikelihoodGroup');
        RecordType recType2 = recTypeByDevName.get('ConsequenceGroup');
        RecordType recType3 = recTypeByDevName.get('SeverityRiskLevelGroup');
        VisualEditor.DynamicPickListRows  rows = new VisualEditor.DynamicPickListRows();
        String label = recType1.Name + ',' + recType2.Name + ',' + recType3.Name;
        String value = recType1.DeveloperName + ',' + recType2.DeveloperName + ',' + recType3.DeveloperName;
        VisualEditor.DataRow row = new VisualEditor.DataRow(label, value);
        return row;
    }

    // 値リストの取得
    global override VisualEditor.DynamicPickListRows getValues() {
        RecordType recType1 = recTypeByDevName.get('LikelihoodGroup');
        RecordType recType2 = recTypeByDevName.get('ConsequenceGroup');
        RecordType recType3 = recTypeByDevName.get('SeverityRiskLevelGroup');
        VisualEditor.DynamicPickListRows  rows = new VisualEditor.DynamicPickListRows();
        String label = recType1.Name + ',' + recType2.Name + ',' + recType3.Name;
        String value = recType1.DeveloperName + ',' + recType2.DeveloperName + ',' + recType3.DeveloperName;
        VisualEditor.DataRow row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        label = recType1.Name + ',' + recType3.Name + ',' + recType2.Name;
        value = recType1.DeveloperName + ',' + recType3.DeveloperName + ',' + recType2.DeveloperName;
        row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        label = recType2.Name + ',' + recType1.Name + ',' + recType3.Name;
        value = recType2.DeveloperName + ',' + recType1.DeveloperName + ',' + recType3.DeveloperName;
        row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        label = recType2.Name + ',' + recType3.Name + ',' + recType1.Name;
        value = recType2.DeveloperName + ',' + recType3.DeveloperName + ',' + recType1.DeveloperName;
        row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        label = recType3.Name + ',' + recType1.Name + ',' + recType2.Name;
        value = recType3.DeveloperName + ',' + recType1.DeveloperName + ',' + recType2.DeveloperName;
        row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        label = recType3.Name + ',' + recType2.Name + ',' + recType1.Name;
        value = recType3.DeveloperName + ',' + recType2.DeveloperName + ',' + recType1.DeveloperName;
        row = new VisualEditor.DataRow(label, value);
        rows.addRow(row);
        return rows;
    }
}