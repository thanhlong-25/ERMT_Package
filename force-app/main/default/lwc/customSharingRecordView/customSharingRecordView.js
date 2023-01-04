import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getRecordSharing from "@salesforce/apex/CustomSharingRecordCtrl.getRecordSharing";
import editRecordSharing from "@salesforce/apex/CustomSharingRecordCtrl.editRecordSharing";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import label_Action_Save from "@salesforce/label/c.Action_Save";
import label_Action_Cancel from "@salesforce/label/c.Action_Cancel";
const columns = [
  {
    label: "名前",
    fieldName: "name",
    typeAttributes: {
      disabled: { fieldName: "disabled" }
    }
  },
  {
    label: "種別",
    fieldName: "type",
    typeAttributes: {
      disabled: { fieldName: "disabled" }
    }
  },
  {
    label: "リスク アクセス権",
    fieldName: "access",
    type: "accessLevelPicklist",
    wrapText: true,
    typeAttributes: {
      options: { fieldName: "picklistOptions" },
      value: { fieldName: "access" },
      placeholder: { fieldName: "access" },
      context: { fieldName: "id" },
      required: "true",
      variant: "label-hidden",
      disabled: { fieldName: "disabled" }
    }
  },
  {
    fieldName: "actionRemove",
    type: "button",
    sortable: false,
    wrapText: false,
    editable: false,
    cellAttributes: { alignment: "center" },
    typeAttributes: {
      iconName: "utility:close",
      class: "slds-icon-text-default",
      iconPosition: "center",
      value: { fieldName: "id" },
      name: "Remove",
      title: "Remove",
      variant: "base",
      disabled: { fieldName: "disabled" }
    }
  }
];
export default class CustomSharingRecordView extends NavigationMixin(
  LightningElement
) {
  @api get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    this.invokeFetchData();
  }
  _recordId;
  columns = columns;
  customSharingView = {
    USER: [],
    PUBLIC_GROUP: [],
    DATATABLE: [],
    OPTION: [],
    OBJECT_NAME: ""
  };
  labelPage = {
    headerPopup: "共有",
    bodyPopup: "部署、リスク、インシデントをコピーします",
    titleSuccess: "部署コピー",
    messageSuccess: `コピーが完了しました`,
    cancelBtn: label_Action_Cancel,
    submitBtn: label_Action_Save,
    editBtn: "編集",
    navigateHierarchy: "共有階層を表示",
    labelAccessLevel: "",
    labelInputSearch: "検索"
  };
  eventClickWithOutElement = false;
  @track isProcessing = false;
  @track dataUserOrGroupIdShare = [];
  @track selectedAccessLevel = "Read";
  @track initTable = {
    draftData: [],
    data: [],
    isOpen: false,
    isExistData: false,
    errorEmpty: "",
    valueFilter: "",
    isInputLoading: false,
    numberRowTable: "",
    displayOpenTable: false
  };
  isInitializable = false;
  isErrorsInitializable = "";
  @track wiredRecordSharing;
  renderedCallback() {
    this.isInitializable = true;
  }

  async invokeFetchData() {
    this.eventShowProcessing(true);

    await this.fetchRecordSharing({
      recordId: this.recordId
    })
      .then((data) => {
        this.wiredRecordSharing = data;
        this.invokeLoadDataView();
      })
      .catch((error) => {
        this.isErrorsInitializable = error?.body?.message;
        this.showNotification(error?.body?.message, "error");
      });
    this.eventShowProcessing(false);
  }

  async fetchRecordSharing(param) {
    const fetchRecordSharing = await getRecordSharing({
      recordId: param.recordId
    });
    return fetchRecordSharing;
  }

  eventShowProcessing(flag = true) {
    this.isProcessing = flag;
  }

  async invokeLoadDataView() {
    let data = this.wiredRecordSharing;
    if (typeof data === "string") {
      data = JSON.parse(data);
    }
    const configDataView = this.customSharingView;

    if (data.USER) {
      configDataView.USER = data.USER.map(({ Id: id, Name: name }) => ({
        id,
        name
      }));
    }
    if (data.PUBLIC_GROUP) {
      configDataView.PUBLIC_GROUP = data.PUBLIC_GROUP.map(
        ({ Id: id, Name: name }) => ({ id, name })
      );
    }
    if (data.OPTION_ACCESS_LEVEL) {
      configDataView.OPTION = data.OPTION_ACCESS_LEVEL;
    }
    if (data.OBJECT_NAME) {
      this.labelPage.labelAccessLevel = `${data.OBJECT_NAME} アクセス権`;
    }
    if (data.LIST_SHARING) {
      const mapDatatable = this.mapPropsData(data.LIST_SHARING);
      this.initTable.data = mapDatatable;
      this.initTable.draftData = mapDatatable;
      this.initTable.numberRowTable = `${mapDatatable.length} 個のユーザグループと共有されています。`;
      this.initTable.displayOpenTable = mapDatatable.length > 0;
      configDataView.DATATABLE = mapDatatable;
    }
  }

  eventSearchSelected(event) {
    this.dataUserOrGroupIdShare = event.detail.selected;
  }

  eventAccessLevelSelected(event) {
    this.selectedAccessLevel = event.detail.value;
  }

  mapPropsData(propsData) {
    let option = [...this.customSharingView.OPTION];
    return [...propsData].map((item) => {
      let instanceObject = {
        id: item.RecordID ?? "",
        userOrGroupId: item.UserOrGroupId ?? "",
        name: item.UserOrGroupName ?? "",
        type: item.UserOrGroupType ?? "",
        access: item.AccessLevel ?? ""
      };
      let isDisable = option.findIndex((obj) => obj.value === item.AccessLevel);
      return {
        ...instanceObject,
        picklistOptions: [...this.customSharingView.OPTION],
        disabled: isDisable >= 0 ? false : true
      };
    });
  }

  async handleRowAction(event) {
    let data = event.detail.row;
    let draftData = await this.handleRemove(this.initTable.data, "id", data.id);
    this.initTable.draftData = draftData;
    this.initTable.data = draftData;
  }

  async handleRemove(array, key, value) {
    const index = array.findIndex((obj) => obj[key] === value);
    if (index < 0) return array;
    return [...array.slice(0, index), ...array.slice(index + 1)];
  }

  eventPicklistChanged(event) {
    event.stopPropagation();
    let picklistData = event.detail.picklistData;
    this.updateDraftValues(picklistData, "access", "value");
  }

  updateDraftValues(updateItem, fieldName, updateKey) {
    let flagRecordUpdate = false;
    let copyDraft = [...this.initTable.data].map((item) => {
      if (item.id === updateItem.id) {
        item = {
          ...item,
          [fieldName]: updateItem[updateKey]
        };
        flagRecordUpdate = true;
      }
      return item;
    });

    if (flagRecordUpdate) {
      this.initTable.draftData = copyDraft;
      this.initTable.data = copyDraft;
    }
  }

  openTableAction() {
    if (!this.initTable.isOpen) {
      this.initTable.isOpen = true;
    }
  }

  setIsLoadingFilter(flag) {
    this.initTable.isInputLoading = flag;
  }

  handleFiltered = function (list, key, value) {
    var filtered = [],
      i = list.length;
    var reg = new RegExp("(.*)(" + value.toLowerCase() + ")(.*)");
    while (i--) {
      if (reg.test(list[i][key].toLowerCase())) {
        filtered.push(list[i]);
      }
    }
    return filtered;
  };
  handleIsEmptyFilter() {
    if (this.initTable.draftData.length === 0) {
      this.initTable.isFilterExist = true;
    }
  }

  async handleFilterDataTable(event) {
    this.initTable.valueFilter = event.target.value;

    if (!this.initTable.valueFilter) {
      this.initTable.draftData = this.initTable.data;
      this.initTable.isFilterExist = false;
      return;
    }

    const filteredData = this.handleFiltered(
      [...this.initTable.data],
      "name",
      this.initTable.valueFilter
    );
    this.initTable.draftData = filteredData;
    this.initTable.isFilterExist = filteredData.length === 0;

    if (this.initTable.isFilterExist) {
      this.initTable.errorEmpty = `No results for "${this.initTable.valueFilter}" in your shared groups.`;
    }
  }

  navigateToHierarchy() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        actionName: "recordShareHierarchy"
      }
    });
  }

  eventSubmit(event) {
    event.preventDefault();
    this.eventShowProcessing(true);
    let validate = this.template.querySelector(".slds-has-error");
    if (validate) {
      this.eventShowProcessing(false);
      return;
    }
    let data = this.handleEditData();

    let flagEditRecord = Object.values(data).some((value) => {
      return Array.isArray(value) && value?.length > 0;
    });
    if (!flagEditRecord) {
      this.eventShowProcessing(false);
      this.handleCancel();
      return;
    }

    editRecordSharing({
      recordId: this.recordId,
      dataEdit: JSON.stringify(data)
    })
      .then((result) => {
        let messsages = JSON.parse(result);
        messsages.forEach((item) => {
          this.showNotification(item.message, item.variant);
        });
        this.handleCancel();
        this.eventShowProcessing(false);
      })
      .catch((error) => {
        this.showNotification(error?.body?.message, "error");
      });
  }

  handleEditData() {
    const dataTable = [...this.initTable.data];
    const currentDataTable = [...this.customSharingView.DATATABLE];

    const groupRecordDelete = currentDataTable
      .filter((obj) => {
        return !dataTable.some(({ id }) => obj.id === id);
      })
      .map(({ id }) => id);
    const groupRecordChange = dataTable
      .filter((obj) => {
        const record = currentDataTable.find(({ id }) => obj.id === id);
        return record && obj.access !== record.access;
      })
      .map((item) => ({
        RecordID: item.id ?? "",
        UserOrGroupId: item.userOrGroupId ?? "",
        UserOrGroupName: item.name ?? "",
        UserOrGroupType: item.type ?? "",
        AccessLevel: item.access ?? ""
      }));
    return {
      UserOrGroupId: this.dataUserOrGroupIdShare.map(({ id }) => id),
      AccessLevel: this.selectedAccessLevel,
      UserOrGroupDelete: groupRecordDelete,
      UserOrGroupChange: groupRecordChange
    };
  }
  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  showNotification(message, variant) {
    const evt = new ShowToastEvent({
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }

  handleTriggerClick(event) {
    event.stopPropagation();
    this.eventClickWithOutElement = event;
  }
}