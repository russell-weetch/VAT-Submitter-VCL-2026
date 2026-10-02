#HMRC-MTD

Updating the HMRC VAT submission components December 2020

I. A few simple changes to the code following on from the earlier updates by Russell Weetch.
II. Updating the demos and docs


# I Code Changes #

THmrcTestClient.

1. A bizarre one this. When first compiled in 10.3.3 (Rio) none of the tests worked, returning 404 not found, because the url did not exist. The url was built from the base url and the request resource, but for some reason, where the resource contained more than 1 part, separated by "/", it was truncating it at the first instance of "/".

After some testing of the Delphi Rest components in other apps, the compiler started to work properly !? In the code some of the tests build a single, complete url now, instead of using the resource properties. - This is included as a historical note, just in case anyone else experiences this behaviour.

2. Added a set of objects to match the returned json formats and a set of functions to parse the json into the objects.



THmrcVatClient.

1. In the function SubmitReturn, I have made a small rearrangement to the process of logging the result of the submission returned by HMRC. It will now only do the logging bit, if a log file path has been set. - To enable it, set a valid file path in the property "StoreFolder".

2. There is a second submit function which uses a submission object for the data, rather than a string list.

3. Added methods to target the VRN check endpoints.



#  II Demo Changes  #

The FMX demo app has been updated to include the new endpoints added to the Test and VAT APIs.

All of the test functions worked on the Test API at the time of writing, December 2020. The anti-fraud headers are those required for desktop apps and are in a format that I could get to work. That is not necessarily the only way to make them work.

There is a new VCL demo that handles a few vat endpoints using a vat component created in code. It uses the FMX related support units and adding them to a VCL project will generate a warning, but it seems to compile and work ok.



Updating the HMRC VAT submission components January 2021

A few more changes to the code following on from the earlier updates and some more contributions by Russell Weetch.


General.

If the original release in 2019 was version 1, then the release in December 2020 was version 2 and the release in January 2021 is version 3.

In v2 the VAT client was extracted from the RestClient unit and placed in its own unit. V3 introduces 2 more structural changes. Firstly, the VAT support elements have been extracted from the RestSupport unit and placed in their own VatSupport unit. Secondly the TestClient has been extracted from the RestClient unit and placed in a separate TestClient unit, with a TestSupport unit. The RestClient and TestClient units are intended to be common across both VAT and PAYE/Income Tax and should contain nothing specific to VAT.

There is also a change in the project structure. V3 now has only 1 version of the RestClient unit, common to both frameworks, VCL & FMX. This unit is now in the common units folder and the separate VCL and FMX versions and folders have been removed.

Documents have been updated where appropriate and possble and are up to date at the point of release, as far as is known. HMRC periodically update the MTD process and their websites, so it is not possible to guarantee that the documents will remain in sync with the HMRC information going forward.


RestClient unit.

This now only contains the THmrcRestClient component. It requires the HmrcRestSupport unit.

A couple of updates / bug fixes related to the OAuth2 token object.

Conditional defines for VCL, to identify the framework used. If using the VCL, then it is recommended that a conditional define of VCL is created. If VCl is defined, it will (should) use the VCL versions of the authenticator form, otherwise it will use the FMX form. In a VCL app, usinf the FMX form should create a warning, but may still work.

There is now only one version of the RestClient unit, which is now in the CmnUnits folder, along with everything else. The separate units and folders found in v2 have now been removed.


RestSupport unit.

Removed the VAT support classes and processes and put them in a new VatSupport unit.


TestClient unit.

The THmrcTestClient has been removed from the RestClient unit and put into a new TestClient unit, with a TestSupport unit.

The TestClient has been updated to use the OAuth validation for those endpoints requiring applcation level authentication. This changes from the use of the application server token, created when the applicationh was registered with HMRC, although at the time of release, these endpoints still worked with server token validation as well as application access tokens. It is, however, not possible to generate server tokens for new applications.

The application token lasts for 4 hours, the same as the normal access token, but there is no refresh mechanism, it is just necessary to get a fresh one. Note that the applcation token process does not pop up the authorisation form. The use of the test client can be seen in the test client form in the FMX demo project.


Headers.

These are still a bit of a moving target. The demos in V1 of the HMRC package contained coverage of the headers as first proposed. V2 contained a potential solution for the headers at the time, with contributions from RW. V3 contains potential solutions for the revised headers for January 2021, again with updated contributions from RW. Please read the fraud headers readme.

Setting the correct headers and header values is the responsibility of the application and the application developer. The rest client will apply the headers, if provided with the data.

The demos contain a process for getting and setting the headers, in unit HmrcHeaders. This process makes use of some of the elements provided in the headers helper units from RW. The Systematic.VAT.Headers unit by RW contains a class which performs a similar task. Users can, therfore, make use of either of these, or do their own thing. 

The demos show desktop headers only, which worked with the fraud headers testing endpoint as it was at the end of January 2021. Users should make sure that they monitor ongoing changes made to the fraud headers by HMRC.
  

Demos.

The demos have been updated to work with the new unit structure, the revised class / unit distribution and the new headers. The FMX demo remains the full demo, testing just about everything. This creates the rest clients in code and should just work, with any luck.

There are 2 vcl demos, both quite limited. One uses the installed component, so will raise errors if the VCL version of the VAT component is not installed. The other creates the rest client in code and should demonstrate that the headers helper units should work in VCL, even though they are declared as FMX.


Installation packages.

There are installation packages for both VCL and FMX, which install the test client and vat client onto the component palette. It is, however, only possible to have one of them installed at any time. No installer is provided, so it is necessary to compile the required project and move the dcus to somewhere in the search path.


If in doubt, ask.