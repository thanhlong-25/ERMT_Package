import { LightningElement, api } from "lwc";

export default class CustomSharingRecordTablePicklist extends LightningElement {
  @api label;
  @api placeholder;
  @api options;
  @api value;
  @api context;
  @api variant;
  @api required;
  @api disabled;
  handleChange(event) {
    //show the selected value on UI
    this.value = event.detail.value;

    //fire event to send context and selected value to the data table
    this.dispatchEvent(
      new CustomEvent("picklistchanged", {
        composed: true,
        bubbles: true,
        detail: {
          picklistData: {
            id: this.context,
            value: this.value
          }
        }
      })
    );
  }

  formatCombobox() {}
}