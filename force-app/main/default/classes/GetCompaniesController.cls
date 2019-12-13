public class GetCompaniesController {

    class Company{

        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String phone{get;set;}
        @AuraEnabled public String address{get;set;}
        @AuraEnabled public String types{get;set;}
        @AuraEnabled public Decimal lat{get;set;}
        @AuraEnabled public Decimal lng{get;set;}
        @AuraEnabled public String rating{get;set;}
        @AuraEnabled public String id{get;set;}

    }

    @AuraEnabled
    public static String companySearch(String name,String zip){

        String searchUrl='https://maps.googleapis.com/maps/api/place/textsearch/json?query='+name+'+near+'+zip+'&key='+Label.googleapikey;
        system.debug(searchUrl);
        HttpRequest req = new HttpRequest();
        req.setEndPoint(searchUrl);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse resp = http.send(req);
        String res = resp.getBody();
        system.debug(res);
        return res;

    }

    @AuraEnabled
    public static void saveMultipleAccounts(String[] acctIds){
        Account[] acctsToAdd = new Account[]{};
        for(String acct:acctIds){
            acctsToAdd.add(prepareAccountFromId(acct));
        }
        upsert acctsToAdd Place_Id__c;
    }


    private static Account prepareAccountFromId(String acctString){
        Company cmp = (Company)JSON.deserialize(acctString, Company.class);
        String[] addrsplit = cmp.address.split(',');
        String country = addrsplit.remove(addrsplit.size()-1);
        String statezip = addrsplit.remove(addrsplit.size()-1);
        String zip = statezip.split(' ')[2];
        String state = statezip.split(' ')[1];
        String street = String.join(addrsplit, ',');
        String stdRating = '';
        if(!String.isBlank(cmp.rating)){
            stdRating = Decimal.valueOf(cmp.rating)>4?'Hot':Decimal.valueOf(cmp.rating)>3?'Warm':'Cold';
        }

        String placeDetailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?placeid='+cmp.id+'&key='+Label.googleapikey;

        HttpRequest req = new HttpRequest();
        req.setEndPoint(placeDetailsUrl);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse resp = http.send(req);
        String res = resp.getBody();
        system.debug(res);
        String ph='',website='';
        JSONParser parser = JSON.createParser(res);
        while(parser.nextToken()!=null){
            if(parser.getCurrentToken()==JSONToken.FIELD_NAME){
                if(parser.getText() == 'formatted_phone_number'){
                    parser.nextToken();
                    ph = parser.getText();
                }else if(parser.getText() == 'website'){
                    parser.nextToken();
                    website = parser.getText();
                }
            }
        }
        Account a = new Account(Name=cmp.name,BillingStreet=street,BillingState=state,BillingPostalCode=zip,BillingCountry=country,Place_Id__c=cmp.id,BillingLatitude=cmp.lat,BillingLongitude=cmp.lng,Rating__c=cmp.rating,Description=cmp.types,Rating=stdRating,Phone=ph,Website=website);
        return a;
    }

    @AuraEnabled
    public static void saveAccount(String acctString){
        upsert prepareAccountFromId(acctString) Place_Id__c;
    }


    
}