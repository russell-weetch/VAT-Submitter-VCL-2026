# HMRC-MTD Fraud Prevention Headers

There is now a class in `Systematic.VAT.Headers.pas` that will retrieve most of this data for you and add it to the RESTClient component, at least for the DESKTOP_APP_DIRECT.

## Sourcing the data required by the headers ##

This only covers headers needed for DESKTOP_APP_DIRECT, if you are using any other type, you are on your own :-). I have listed the headers in the order they are listed on the HMRC Dev Web Page [https://developer.service.hmrc.gov.uk/api-documentation/docs/fraud-prevention](https://developer.service.hmrc.gov.uk/api-documentation/docs/fraud-prevention).

stop auto encoding means that you use <code>AddaHeader(name, value, **True**);</code>. The auto encoding has to be stopped because where there are lists you do not want to encode the delimiters. The values below show on what you need to <code>URIEncode()</code> which is in the unit *REST.Utils*. 
Code provided in source files in this repo:

<code>InternetSupport.SomeFunction</code> is a reference to *Systematic.Internet.Support.pas* they are class functions of the class *TInternetSupport*.

<code>Utils.SomeFunction</codes is a reference to *VAT.Header.Utils.pas* they are class functions of *THMRCMTDUtils*.  

<code>MACAddress.SomeFunction</code> is a reference to *Systematic.FMX.MacAddress.pas*.

**Gov-Client-Connection-Method**  
- stop auto encoding: No
- value: 'DESKTOP_APP_DIRECT'

**Gov-Client-Device-ID**
- stop auto encoding: Yes
- value: Create your own, use a GUID and store in the registry. This should never change

**Gov-Client-User-IDs**  
- stop auto encoding: Yes
- value: <code>'os=' + URIEncode(Utils.GetUserName)</code>
- notes: os does not stand for operating system as it does elsewhere in the HMRC documentation it is actually literal.

**Gov-Client-Timezone** 
- stop auto encoding: Yes
- Value:<code>Utils.getTimeZone</code> 

**Gov-Client-Local-IPs** 
- stop auto encoding: Yes 
- value: <code>InternetSupport.GetLocalIPs(',', True, True);</code>
- notes: They don't mean local IPs they mean private IPs. Each IP has to be encoded, but not the delimiter. That function manages that.

**Gov-Client-MAC-Addresses** 
- stop auto encoding: Yes
- value: <code>MacAddress.GetAllMacAddresses(True)</code>
- notes: Each mac address has to be encoded, but not the delimiter. That function manages that.

**Gov-Client-Screens**
- stop auto encoding: Yes
- value: <code>Utils.ScreensInfo</code>

**Gov-Client-Window-Size** 
- stop auto encoding: Yes
- value: <code>width=500&height=400</code>
- notes: set this to the width and height that you will use to show the OAUTH browser pop up.

**Gov-Client-User-Agent** 
- stop auto encoding: Yes
- value: <code>Utils.getUserAgent</code>
- notes: you will need https://github.com/RRUZ/tsmbios/uSMBIOS.pas

These headers are only required for **WEB_APP_VIA_SERVER** only so not needed
-   Gov-Client-Browser-Plugins
-   Gov-Client-Browser-JS-User-Agent
-   Gov-Client-Browser-Do-Not-Track

**Gov-Client-Multi-Factor** 
- stop auto encoding: not if leaving blank
- value: leave blank if you aren't using 2FA

**Gov-Vendor-Version** 
- stop auto encoding: Yes
- value: <code>URIEncode(SystemName)=Appversion</code> e.g. 'SMX%20VAT%20Submitter=1.1.1.1'

**Gov-Vendor-License-IDs** 
- stop auto encoding: Yes
- value: <code>UriEncode(Software)=HashedLicenceKey,UriEncode(Software2)=HashedLicenceKey</code>
- notes: may only be one software licence as in our case.

These headers arfe only required for ***_SERVER** Connection Methods
- Gov-Client-Public-IPFPublicIP
- Gov-Client-Public-Port
- Gov-Vendor-Forwarded

## III. Test the Headers ##  

- Make sure you subscribe for the header testing API on the HMRC Sandbox
- Make sure you are in test mode
- Call the new TestHeaders function                                                               




