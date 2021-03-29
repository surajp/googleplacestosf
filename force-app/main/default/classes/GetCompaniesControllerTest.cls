@isTest
public class GetCompaniesControllerTest {
  @isTest
  public static void it_should_return_matching_companies() {
    String name = 'Test Company';
    String zip = '332434';
    Test.setMock(HttpCalloutMock.class, new MockGoogleApiSearchRequests());
    Test.startTest();
    String searchResults = GetCompaniesController.companySearch(name, zip);
    Test.stopTest();
    system.assert(!String.isBlank(searchResults), 'Search Results was blank');
    List<Company> companies = (List<Company>) JSON.deserialize(
      searchResults,
      List<Company>.class
    );
    system.assertEquals(
      companies[0].lat,
      22.12,
      'Company latitude does not match expected value'
    );
  }

  @isTest
  private static void it_should_create_account_from_search_result() {
    Company comp1 = new Company();
    comp1.name = 'Acme Inc';
    comp1.phone = '123422543';
    comp1.address = '345 Main St. New York City, NY 11111,USA';
    comp1.types = '';
    comp1.lat = 22.12;
    comp1.lng = 10.10;
    comp1.rating = 4;
    comp1.id = 'x';

    String compStr = JSON.serialize(comp1);
    Test.setMock(HttpCalloutMock.class, new MockGoogleApiDetailRequests());
    Test.startTest();
    GetCompaniesController.saveAccount(compStr);
    Test.stopTest();
    Account acc = [
      SELECT
        Phone,
        Website,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        BillingStreet
      FROM Account
      LIMIT 1
    ];
    system.assertEquals(
      acc.Phone,
      '312311332',
      'Phone number was not set correctly on the Account'
    );
    system.assertEquals(
      acc.Website,
      'https://salesforce.com',
      'Website was not set correctly on the Account'
    );
    system.assertEquals(
      acc.BillingState,
      'NY',
      'State was not set correctly on the Account'
    );
    system.assertEquals(
      acc.BillingPostalCode,
      '11111',
      'Zipcode was not set correctly on the Account'
    );
    system.assertEquals(
      acc.BillingCountry,
      'USA',
      'Billing Country was not set correctly on the Account'
    );
    system.assertEquals(
      acc.BillingStreet,
      '345 Main St. New York City',
      'BillingStreet was not set correctly on the Account'
    );
  }

  @isTest
  private static void it_should_upsert_multiple_accounts() {
    it_should_create_account_from_search_result();
    Account existing = [SELECT Rating, Name, Place_Id__c FROM Account];
    system.assertEquals(
      'Acme Inc',
      existing.Name,
      'Name was not set to expected value by test method'
    );
    system.assertEquals(
      'Warm',
      existing.Rating,
      'Rating was not set to expected value by test method'
    );
    system.assertEquals(
      'x',
      existing.Place_Id__c,
      'Place Id was not set to expected value by test method'
    );

    Company comp1 = new Company();
    comp1.address = '345 Main St. New York City, NY 11111,USA';
    comp1.name = 'Acme Inc New';
    comp1.rating = 2;
    comp1.id = 'x';

    Company comp2 = new Company();
    comp2.name = 'Universal Containers';
    comp2.phone = '123422443';
    comp2.address = '345 Main St. New York City, NY';
    comp2.types = '';
    comp2.lat = 22.12;
    comp2.lng = 10.10;
    comp2.rating = 4;
    comp2.id = 'y';

    List<String> companyStrList = new List<String>{
      JSON.serialize(comp1),
      JSON.serialize(comp2)
    };
    GetCompaniesController.saveMultipleAccounts(companyStrList);
    existing = [
      SELECT Place_Id__c, Name, Rating
      FROM Account
      WHERE Id = :existing.Id
    ];

    system.assertEquals(
      existing.Name,
      'Acme Inc New',
      'Account Name was not updated'
    );
    system.assertEquals(
      existing.Rating,
      'Cold',
      'Account Rating was not updated'
    );
    system.assertEquals(
      2,
      [SELECT Id FROM Account].size(),
      'We dont have 2 Accounts, one existing and one new'
    );
  }

  private class MockGoogleApiDetailRequests implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      system.assert(
        req.getEndpoint()
          .startsWith(
            'https://maps.googleapis.com/maps/api/place/details/json?placeid='
          )
      );
      HttpResponse resp = new HttpResponse();
      resp.setHeader('Content-Type', 'application/json');
      resp.setBody(
        '{"formatted_phone_number":"312311332","website":"https://salesforce.com"}'
      );
      resp.setStatus('200');
      return resp;
    }
  }

  private class MockGoogleApiSearchRequests implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      system.assert(
        req.getEndpoint()
          .startsWith(
            'https://maps.googleapis.com/maps/api/place/textsearch/json?query='
          )
      );

      HttpResponse resp = new HttpResponse();
      resp.setHeader('Content-Type', 'application/json');
      Company comp1 = new Company();
      comp1.name = 'Acme Inc';
      comp1.phone = '123422543';
      comp1.address = '123 Main St. New York City, NY';
      comp1.types = '';
      comp1.lat = 22.12;
      comp1.lng = 10.10;
      comp1.rating = 4;
      comp1.id = 'x';

      Company comp2 = new Company();
      comp2.name = 'Universal Containers';
      comp2.phone = '123422443';
      comp2.address = '345 Main St. New York City, NY';
      comp2.types = '';
      comp2.lat = 22.12;
      comp2.lng = 10.10;
      comp2.rating = 4;
      comp2.id = 'y';

      List<Company> companies = new List<Company>{ comp1, comp2 };
      resp.setBody(JSON.serialize(companies));
      resp.setStatus('200');
      return resp;
    }
  }
}
