public class GetCompaniesController {
  @AuraEnabled
  public static String companySearch(String name, String zip) {
    if (name == null || String.isEmpty(name))
      return null;
    name = EncodingUtil.urlEncode(name, 'utf-8');
    String searchUrl =
      'https://maps.googleapis.com/maps/api/place/textsearch/json?query=' +
      name +
      '+near+' +
      zip +
      '&key=' +
      Label.googleapikey;
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
  public static void saveMultipleAccounts(String[] strAccounts) {
    Account[] acctsToAdd = new List<Account>{};
    for (String strAcct : strAccounts) {
      acctsToAdd.add(prepareAccountFromId(strAcct));
    }
    upsert acctsToAdd Place_Id__c;
  }

  private static Account prepareAccountFromId(String accString) {
    Company cmp = (Company) JSON.deserialize(accString, Company.class);
    String[] addrsplit = cmp.address.split(',');
    String country = addrsplit.remove(addrsplit.size() - 1);
    String statezip = addrsplit.remove(addrsplit.size() - 1);
    String zip = statezip.split(' ')[2];
    String state = statezip.split(' ')[1];
    String street = String.join(addrsplit, ',');
    String stdRating = '';
    if (cmp.rating != null) {
      stdRating = cmp.rating > 4 ? 'Hot' : cmp.rating > 3 ? 'Warm' : 'Cold';
    }

    String placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json?placeid=' +
      cmp.id +
      '&key=' +
      Label.googleapikey;

    HttpRequest req = new HttpRequest();
    req.setEndPoint(placeDetailsUrl);
    req.setMethod('GET');

    Http http = new Http();
    HttpResponse resp = http.send(req);
    String res = resp.getBody();
    system.debug(res);
    String ph = '', website = '';
    JSONParser parser = JSON.createParser(res);
    while (parser.nextToken() != null) {
      if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
        if (parser.getText() == 'formatted_phone_number') {
          parser.nextToken();
          ph = parser.getText();
        } else if (parser.getText() == 'website') {
          parser.nextToken();
          website = parser.getText();
        }
      }
    }
    Account a = new Account(
      Name = cmp.name,
      BillingStreet = street,
      BillingState = state,
      BillingPostalCode = zip,
      BillingCountry = country,
      Place_Id__c = cmp.id,
      BillingLatitude = cmp.lat,
      BillingLongitude = cmp.lng,
      Description = cmp.types,
      Rating = stdRating,
      Phone = ph,
      Website = website
    );
    return a;
  }

  @AuraEnabled
  public static void saveAccount(String acctString) {
    upsert prepareAccountFromId(acctString) Place_Id__c;
  }
}
