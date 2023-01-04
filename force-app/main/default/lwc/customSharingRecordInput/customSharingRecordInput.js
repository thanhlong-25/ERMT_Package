import { LightningElement, track, api } from "lwc";

export default class CustomSharingRecordInput extends LightningElement {
  @api get propsData() {
    return this._propsData;
  }
  set propsData(value) {
    this._propsData = value;
  }

  @api get propsEvent() {
    return this._eventWithoutElement;
  }
  set propsEvent(event) {
    this._eventWithoutElement = event;
    this.handleTriggerClick(event);
  }

  labelPage = {
    titleInput: "検索"
  };
  optionShares = [
    {
      value: 0,
      label: "ユーザを検索",
      icon: "standard:user",
      placeholder: "ユーザを検索...",
      group: "USER"
    },
    {
      value: 1,
      label: "公開グループを検索",
      icon: "standard:groups",
      placeholder: "公開グループを検索...",
      group: "PUBLIC_GROUP"
    }
  ];
  configIcon = {
    close: "utility:close",
    search: "utility:search",
    down: "utility:down"
  };
  configAction = {
    userAction: "user-group",
    groupAction: "select-option"
  };
  @track _propsData;
  @track valueFilter = "";
  @track dataShare = [];
  @track dataSelectedShare = [];
  @track _cancelBlur;
  @track _eventWithoutElement;
  @track isSearching = false;
  @track valueShare = [...this.optionShares].shift();
  // handle selected item with id
  async handleSelectedShare(event) {
    let selected = event.currentTarget.dataset.id;

    let valueSelected = this.dataShare.find(({ id }) => {
      return id === selected;
    });
    this.toggleSelector(this.configAction.userAction, false);

    if (
      !this.dataSelectedShare.find(({ id }) => {
        return id === selected;
      })
    ) {
      this.valueFilter = "";
      //push value
      valueSelected = {
        ...valueSelected,
        icon: this.valueShare.icon,
        group: this.valueShare.group
      };

      this.dataSelectedShare.push(valueSelected);
      this.dispatchEventSelected();
      // remove item out collection
      this._propsData = {
        ...this._propsData,
        [this.valueShare.group]: await this.handleRemove(
          [...this._propsData[this.valueShare.group]],
          "id",
          selected
        )
      };

      this.handleFilterData();
    }
  }

  async handleRemoveRecordShare(evt) {
    let valueId = evt.currentTarget.dataset.id;
    let selectedItem = this.dataSelectedShare.find(({ id }) => {
      return id === valueId;
    });
    if (!selectedItem) {
      return;
    }
    let groupItem = selectedItem.group;
    this.dataSelectedShare = await this.handleRemove(
      this.dataSelectedShare,
      "id",
      valueId
    );
    this._propsData = {
      ...this._propsData,
      [groupItem]: await this.pushArrayUniqueKey(
        [...this._propsData[groupItem]],
        "id",
        selectedItem
      )
    };
    this.handleFilterData();
  }

  closeResultSearchShare() {
    if (this._cancelBlur) {
      return;
    }
    this.toggleSelector(this.configAction.userAction, false);
  }

  closeOptions() {
    if (this._cancelBlur) {
      return;
    }
    this.toggleSelector(this.configAction.groupAction, false);
  }

  handleShowOptions() {
    this.allowBlur();

    this.toggleSelector(this.configAction.groupAction, true);
  }

  handleChangeSeachObjectShare(event) {
    this.valueFilter = event.target.value;
    this.cancelBlur();

    this.handleFilterData();
    this.toggleSelector(this.configAction.userAction, true);
  }

  async handleRemove(array, key, value) {
    const index = array.findIndex((obj) => obj[key] === value);
    return index >= 0
      ? [...array.slice(0, index), ...array.slice(index + 1)]
      : array;
  }

  handleSelectOption(event) {
    let changeId = event.currentTarget.dataset.id;
    let selected = {
      ...this.optionShares.find(({ value }) => {
        return parseInt(value, 10) === parseInt(changeId, 10);
      })
    };
    this.valueShare = selected;

    this.allowBlur();
    this.handleTriggerClick(event);
    this.handleFilterData();
  }

  handleFilterData() {
    this.isSearching = true;
    this.dataShare = [];
    if (this.valueFilter.trim().length === 0) {
      this.dataShare = [...this._propsData[this.valueShare.group]];
      return;
    }
    this.dataShare = this.handleFiltered(
      [...this._propsData[this.valueShare.group]],
      "name",
      this.valueFilter
    );
    this.isSearching = false;
  }
  handleShareGroup(event) {
    if (!event.currentTarget.dataset.id) {
      return;
    }
    this.pushRecordUniqueId(
      this.dataSelectedShare,
      event.currentTarget.dataset
    );
  }

  pushArrayUniqueKey = async (array, key, value) => {
    if (!array.find((item) => item[key] === value[key])) {
      array.push(value);
    }
    return array;
  };

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

  pushRecordUniqueId = (array, item) => {
    if (!array.find(({ id }) => id === item.id)) {
      array.push(item);
    }
  };

  toggleSelector(selector, flag = true) {
    var optionsView = this.template.querySelector(`div[data-name=${selector}]`);

    if (!optionsView) {
      return;
    }
    if (flag) {
      optionsView.style.display = "block";
      optionsView.style.visibility = "visible";
      optionsView.style.opacity = 1;
    } else {
      optionsView.style.visibility = "hidden";
      optionsView.style.opacity = 0;
      optionsView.style.display = "none";
    }
  }
  allowBlur() {
    this._cancelBlur = false;
  }

  cancelBlur() {
    this._cancelBlur = true;
  }

  handleTriggerClick(event) {
    if (!event) {
      return;
    }
    event.stopPropagation();
    this.allowBlur();
    let keyAction = event.currentTarget.getAttribute("data-key");
    let selector = this.template.querySelectorAll(`div[data-name]`);
    selector.forEach((item) => {
      let attributes = item.getAttribute("data-name");
      if (!attributes) {
        return;
      }
      let toggle = attributes === keyAction;
      this.toggleSelector(attributes, toggle);
    });
  }

  dispatchEventSelected() {
    const selected = new CustomEvent("selected", {
      detail: {
        selected: this.dataSelectedShare
      }
    });
    this.dispatchEvent(selected);
  }
}