import { LightningElement,track } from 'lwc';
import getAccounts from '@salesforce/apex/GetCompaniesController.companySearch';

export default class GetCompaniesLwc extends LightningElement {

	@track name;
	@track zip;
	//@track opText;
	@track tableData;
	@track mapMarkers;

	resultColumns = [
		{label:'Name',fieldName:'name'},
		{label:'Address',fieldName:'formatted_address'},
		{label:'Rating',fieldName:'rating',type:'number'},
		{label:'Total Ratings',fieldName:'user_ratings_total',type:'number'}
	]

	handleNameChange(event){
		this.name = event.target.value;
	}

	handleZipChange(event){
		this.zip = event.target.value;
	}

	doSearch(){
		const {name,zip} = this;
		getAccounts({name,zip})
			.then(resp=>{
				//console.log(resp);
				this.tableData = JSON.parse(resp).results;
				this.mapMarkers = this.tableData.map(row=>{
					let {lat,lng} = row.geometry.location;
					return {location:{Latitude:lat,Longitude:lng},icon:'custom:92',title:row.name}
				});
			})
			.catch(err=>console.error(err));
	}
}

