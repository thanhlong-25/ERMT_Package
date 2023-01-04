import LightningDatatable from "lightning/datatable";
import DatatablePicklistTemplate from "./picklist-template.html";
export default class CustomSharingRecordTable extends LightningDatatable {
  static customTypes = {
    accessLevelPicklist: {
      template: DatatablePicklistTemplate,
      standardCellLayout: true,
      typeAttributes: [
        "label",
        "value",
        "placeholder",
        "options",
        "required",
        "variant",
        "context",
        "disabled"
      ]
    }
  };
}