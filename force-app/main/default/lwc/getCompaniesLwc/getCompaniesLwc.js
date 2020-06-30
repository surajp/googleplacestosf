import { LightningElement } from "lwc";
import getAccounts from "@salesforce/apex/GetCompaniesController.companySearch";
import addCompaniesToSF from "@salesforce/apex/GetCompaniesController.saveMultipleAccounts";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class GetCompaniesLwc extends LightningElement {
  name;
  zip;
  //@track opText;
  tableData;
  mapMarkers;

  resultColumns = [
    { label: "Name", fieldName: "name" },
    { label: "Address", fieldName: "address" },
    { label: "Rating", fieldName: "rating", type: "number" },
    { label: "Total Ratings", fieldName: "user_ratings_total", type: "number" }
  ];

  handleKeyup(event) {
    if (event.keyCode === 13) this.doSearch();
  }

  handleNameChange(event) {
    this.name = event.target.value;
  }

  handleZipChange(event) {
    this.zip = event.target.value;
  }

  doSearch() {
    const { name, zip } = this;
    getAccounts({ name, zip })
      .then((resp) => {
        //console.log(resp);
        this.tableData = JSON.parse(resp).results.map((row) => {
          row.lat = row.geometry.location.lat;
          row.lng = row.geometry.location.lng;
          row.id = row.place_id;
          row.address = row.formatted_address;
          row.types = row.types.join(",");
          return row;
        });
        this.mapMarkers = this.tableData.map((row) => {
          return {
            location: { Latitude: row.lat, Longitude: row.lng },
            icon: "custom:92",
            title: row.name
          };
        });
      })
      .catch((err) => console.error(err));
  }

  addToSF() {
    const params = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows()
      .map((row) => JSON.stringify(row));
    addCompaniesToSF({ strAccounts: params })
      .then(() =>
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Accounts created successfully",
            variant: "success"
          })
        )
      )
      .catch((err) =>
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: err.body.message,
            variant: "error"
          })
        )
      );
  }
}
