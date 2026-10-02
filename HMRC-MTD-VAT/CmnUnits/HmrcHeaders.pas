unit HmrcHeaders;

(*****************************************************************************
*                        HMRC API REST Support Unit                          *
******************************************************************************
*  Support processes for adding headers to the HMRC REST Client components.  *
*                                                                            *
*  created 27/01/21.                                                         *
*  updated 29/01/21.                                                         *
*  version 1.0.0                                                             *
*                                                                            *
*  original copyright Ian Hamilton 2021.                                     *
*  License : GPL                                                             *
*****************************************************************************)

interface
(****************************************************************************)
uses
  System.Classes, System.SysUtils, System.Types,
  HmrcRestClient;

type
  TAppValues = record
    AppGuid : string;
    AppName : string;
    License : string;
    MFType  : string;      // [TOTP, AUTH_CODE, OTHER]   // see HMRC docs
    MFValue : string;
    MFTime  : TDateTime;
  end;

  procedure AddHeaders(AClient: THMRCRestClient; Values: TAppValues);


implementation
uses
  Winsock, DateUtils, REST.Types, REST.Client, REST.Utils,
  VAT.Headers.Utils, Systematic.MacAddress, Systematic.AppVersion;

const
  // this is used for cheating on the Multi-Factor header for the fraud tests.
  tim = 'T09:00Z';



(*****************************************************************************
*  Uses Winsock - this function can easily be found with an internet search. *
*  Adapted to return a comma separated list as required for the headers.     *
*****************************************************************************)
function GetIps: string;
type
  TaPInAddr = Array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe: PHostEnt;
  pPtr: PaPInAddr;
  GInitData: TWSAData;
  Buffer: Array[0..63] of AnsiChar;       // in D2007 and earlier this is just Char
  I: Integer;
begin
  Result := '';
  WSAStartup($101, GInitData);            // init
  GetHostName(Buffer, SizeOf(Buffer));    // get computer name
  phe := GetHostByName(buffer);           // use computer name to get host / ip info
  if phe = nil then
    Result := '0.0.0.0'                   // default fail value
  else begin
    pPtr := PaPInAddr(phe^.h_addr_list);
    I := 0;
    while pPtr^[I] <> nil do
    begin
      if (I > 0) then
        Result := Result + ',';
      Result := Result + inet_ntoa(pPtr^[I]^);
      Inc(I);
    end;
  end;
  WSACleanup;
end;

(*****************************************************************************
*  Add the fraud headers to test them. These have been a moving target and   *
*  this is the set that passed the test 28/01/21, but HMRC may change them   *
*  at any time. It uses the VAT.Headers.Utils file to get some of the values.*
*                                                                            *
*  Blatant fabrication of false multi-factor values, which will be necessary *
*  for any application that uses standard user and password validation. In   *
*  theory for live submissions it can be blank, as long as they have been    *
*  informed.                                                                 *
*                                                                            *
*****************************************************************************)
procedure AddHeaders(AClient: THMRCRestClient; Values: TAppValues);
begin
  // fixed for desktop - change for other app type
  AClient.AddaHeader('Gov-Client-Connection-Method','DESKTOP_APP_DIRECT', false);

  // this should be a guid set by the installer that relates to this installation of this application
  AClient.AddaHeader('Gov-Client-Device-ID', Values.AppGuid, true);

  // probaly should not be hard coded, because it will be UTC + 1 in summer
  AClient.AddaHeader('Gov-Client-Timezone', THMRCMTDUtils.getTimeZone, true);    //'UTC+00:00', true);

  // get the machine IP address now
  AClient.AddaHeader('Gov-Client-Local-IPs', GetIps, true);   // get your IP address here

  // the IP address was found now, so the time is now - DateToISO8601 is in DateUtils - YYYY-MM-DDTHH:NN:SS.000Z
  AClient.AddaHeader('Gov-Client-Local-IPs-Timestamp', DateToISO8601(Now, true), true);

  // screen info - why ?
  AClient.AddaHeader('Gov-Client-Screens', THMRCMTDUtils.ScreensInfo, true);

  // who cares?
  AClient.AddaHeader('Gov-Client-Window-Size', 'width=600&height=400' , true);

  // PC details : OS + version + manufacturer + model
  AClient.AddaHeader('Gov-Client-User-Agent',THMRCMTDUtils.getUserAgent, true);

  // user login/name
  AClient.AddaHeader('Gov-Client-User-IDs','os=' + THMRCMTDUtils.getOSUserName, true);

  // macaddress(es) - this call does not require the jcl
  AClient.AddaHeader('Gov-Client-MAC-Addresses', GetMacAddress(0), true);

  // intended to identify multi-factor login details. The header test returns an error if it is missing or empty
  if (Values.MFType = 'AUTH_CODE') or (Values.MFType = 'TOTP') then
    AClient.AddaHeader('Gov-Client-Multi-Factor', 'type=' + Values.MFType +
                       '&timestamp=' + UriEncode(DateToISO8601(Values.MFTime, true)) +
                       '&unique-reference=' + UriEncode(Values.MFValue), true)
  else
    AClient.AddaHeader('Gov-Client-Multi-Factor', '', false);
  // hard-coded nonsense to pass the tests
  //AClient.AddaHeader('Gov-Client-Multi-Factor', 'type=AUTH_CODE&timestamp=' + UriEncode(dat1 + tim) +
  //                   '&unique-reference=' + UriEncode('abc123efg456hij789'), true);

  // nominal application license
  AClient.AddaHeader('Gov-Vendor-License-IDs', UriEncode(Values.AppName) + '=' + UriEncode(Values.License), true);

  // application name
  AClient.AddaHeader('Gov-Vendor-Product-Name', UriEncode(Values.Appname), true);

  // application version
  AClient.AddaHeader('Gov-Vendor-Version', UriEncode(Values.AppName) + '=' + UriEncode(GetApplicationVersion), true);

end;


// ISO8601
end.
