#HMRC-MTD

Changes to the HMRC REST components February 2021

The principal change this time is the addition of the Self Assessment (SA) processes. There have been a few changes to the underlying Rest Component and associated changes to the VAT component. Documentation has been updated and some new document have been added.

I. The Core Rest Component

There is a new method, CallApi, to handle generic api calls and the option to accept a pointer to a method that will load access tokens on demand. These do not affect any existing VAT implementations.

The CallApi function allows API specific classes like the SA Client to simply format the parameters, rather than including all of the call handling in each method. See the HmrcSAClient for examples of how to use it.

II. The Test Client.

This currently handles all of the application level processes, as well as the hello world and hello user examples. The VRN check functions have been moved from the VAT client to the Test client, so that the VAT client again only targets the active API endpoints.

The test client is used in the SA test form, but the parameters are set in the form and passed to the overridden CallApi method of the Test client.

III. The Vat Client.

The only changes here are the removal of the VRN checks, now moved to the Test Client. Any application using the VRN checks will need to use a TestClient component to handle this.

IV. The SA Client.

New to this release, this is similar to the VAT client, targetting the 7 current endpoints provided in the API. This is expected to evolve over time. To test this, use it in conjunction with the existing create users and the new set up PAYE data functions in the Test client.

