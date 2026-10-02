Unit Systematic.VAT.Headers;

(* ***********************************************************************
  copyright 2019-2021  Systematic Marketing Limited

  https://smxi.com

  Distributed under the MIT software license, see the accompanying file
  LICENSE or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.

  *********************************************************************** *)

Interface

Uses
  System.SysUtils,
  HmrcRestClient;

Type

  THMRCConnectionMethod = (cmDesktopDirect, cmDesktopViaServer, cmWebAppViaServer, cmMobileAppDirect,
    cmMobileAppViaServer, cmBatchProcessDirect, cmOtherDirect, cmOtherViaServer);

  TMultiFactorType = (mfNone, mfTOTP, mfAUTH_CODE, mfOTHER);

  EVATHeaderException = Class(Exception);

  /// <summary>
  ///   Multi Factor is sent as a blank string. You need to tell HMRC that you
  ///   can't collect it, or if you can, add some code here.
  /// </summary>
  TMultiFactorHeader = record
    /// <summary>
    ///   One of: TOTP,AUTH_CODE,OTHER
    /// </summary>
    MultiFactorType: TMultiFactorType;
    /// <summary>
    ///   UTC TimeStamp
    /// </summary>
    TimeStamp: TDateTime;
    TimeStampIsUTC: Boolean;
    /// <summary>
    ///   identifies a single factor. For example, a salted-and-hashed phone
    ///   number used for SMS, or an identifier linked to a TOTP secret, but
    ///   not the secret itself. Use the same hashing function consistently so
    ///   that this can be recognised across API calls. <br /><br />
    ///   Just add the plain text reference and the function will SHA1 it.
    /// </summary>
    UniqueReference: String;
    Function GetHeader: String;
  end;

  TVATHeaders = Class
  Private
    FConnectionMethod: THMRCConnectionMethod;
    FLocalIP: String;
    /// <summary>
    /// UTC Time
    /// </summary>
    FLocalIPTimeStamp: TDateTime;
    FPublicIP: String;
    /// <summary>
    /// UTC Time
    /// </summary>
    FPublicIPTimeStamp: TDateTime;
    FComputerName: String;
    FMACAddress: String;
    FDeviceId: String;
    FUserAgent: String;
    FTimeZone: String;
    FScreens: String;
    FCurrentSystemUser: String;
    FWindowWidth: Integer;
    FWindowHeight: Integer;
    FLicenseKey: String;
    FAppVersion: String;
    FProductName: string;
    FPublicPort: Word;
    FMultiFactor: TMultiFactorHeader;
    procedure CheckValues;
    function PercentEncode(const Value : string): String;
    function GetLocalIPTimeStampAsString: String;
    function GetPublicIPTimeStampAsString: String;

  Public
    Constructor Create(Const AConnectionMethod: THMRCConnectionMethod);
    Procedure AddHeaders(AClient: THMRCRestClient);
    Procedure RefreshDates;

    function ConnectionMethodString: String;


    Property ConnectionMethod: THMRCConnectionMethod read FConnectionMethod;
    Property LocalIP: String read FLocalIP;
    Property LocalIPTimeStamp: TDateTime read FLocalIPTimeStamp;
    Property LocalIPTimeStampAsString: String Read GetLocalIPTimeStampAsString;
    Property PublicIP: String read FPublicIP;
    Property PublicIPTimeStamp: TDateTime read FPublicIPTimeStamp;
    Property PublicIPTimeStampAsString: String Read GetPublicIPTimeStampAsString;
    Property ComputerName: String read FComputerName;
    Property MacAddress: String read FMacAddress;
    Property UserAgent: String read FUserAgent;
    Property TimeZone: String read FTimeZone;
    Property Screens: String read FScreens;
    Property CurrentSystemUser: String read FCurrentSystemUser;

    Property MultiFactor: TMultiFactorHeader read FMultiFactor;

    Property WindowWidth: Integer Read FWindowWidth Write FWindowWidth;
    Property WindowHeight: Integer Read FWindowHeight Write FWindowHeight;

    /// <summary>
    ///   Required, if blank the version will be read from the application
    /// </summary>
    property AppVersion: String Read FAppVersion Write FAppVersion;
    /// <summary>
    ///   <para>
    ///     Required
    ///   </para>
    ///   <para>
    ///     This should be the plain text license key the object will hash it with SHA1
    ///   </para>
    /// </summary>
    property LicenseKey: String read FLicenseKey write FLicenseKey;
    /// <summary>
    ///   Required
    /// </summary>
    property DeviceId: String read FDeviceId write FDeviceId;
    /// <summary>
    ///   Required
    /// </summary>
    property ProductName: string read FProductName write FProductName;
    /// <summary>
    ///   Required - Server Connections Only
    /// </summary>
    property PublicPort: Word read FPublicPort write FPublicPort;
  End;

  {$I HmrcMtd.inc}

Implementation

Uses
  System.DateUtils,
  System.NetEncoding,
  System.Hash,
  System.Rtti,
  Systematic.Internet.Support,
  VAT.Headers.Utils,
  JCLSysInfo,
  Systematic.MacAddress,
  Systematic.AppVersion,
  REST.Utils;

Const
  C_CONNECTION_METHOD: Array [THMRCConnectionMethod] Of String = ('DESKTOP_APP_DIRECT', 'DESKTOP_APP_VIA_SERVER',
    'WEB_APP_VIA_SERVER', 'MOBILE_APP_DIRECT', 'MOBILE_APP_VIA_SERVER', 'BATCH_PROCESS_DIRECT', 'OTHER_DIRECT',
    'OTHER_VIA_SERVER');


  SERVER_CONNECTIONS = [cmDesktopViaServer, cmWebAppViaServer, cmMobileAppViaServer, cmOtherViaServer];

{ TMultiFactorHeader }

function TMultiFactorHeader.GetHeader: String;
var lTimeStampUTC: TDateTime;
begin
  if MultiFactorType = mfNone then
     Exit('');
  if TimeStampIsUTC then
     lTimeStampUTC := TimeStamp
  else
    lTimeStampUTC := TTimeZone.Local.ToUniversalTime(TimeStamp);

  Result := 'type=' + TRttiEnumerationType.GetName<TMultiFactorType>(MultiFactorType).SubString(2) +
             '&timestamp=' + DateToISO8601(lTimeStampUTC) +
             '&uniquereference=' + THashSHA1.GetHashString(UniqueReference);
end;


{ TVATHeaders }

Procedure TVATHeaders.AddHeaders(AClient: THMRCRestClient);
Begin

  CheckValues;
  { see https://developer.service.hmrc.gov.uk/api-documentation/docs/fraud-prevention }

  AClient.AddaHeader('Gov-Client-Connection-Method', C_CONNECTION_METHOD[FConnectionMethod]);
  AClient.AddaHeader('Gov-Client-Device-ID', FDeviceId.ToLower, True);
  AClient.AddaHeader('Gov-Client-Local-IPs', FLocalIP, True);
  AClient.AddaHeader('Gov-Client-Local-IPs-Timestamp', GetLocalIPTimeStampAsString, True);
  AClient.AddaHeader('Gov-Client-MAC-Addresses', FMACAddress, True);

  if FMultiFactor.MultiFactorType > mfNone then
     AClient.AddaHeader('Gov-Client-Multi-Factor', FMultiFactor.GetHeader);

  AClient.AddaHeader('Gov-Client-Screens', FScreens, True);
  AClient.AddaHeader('Gov-Client-Timezone', FTimeZone, True);
  AClient.AddaHeader('Gov-Client-User-Agent', FUserAgent, True);
  AClient.AddaHeader('Gov-Client-User-IDs', 'os=' + FCurrentSystemUser, True);
  AClient.AddaHeader('Gov-Client-Window-Size', 'width=500&height=400'.Replace('500', FWindowWidth.ToString)
    .Replace('400', FWindowHeight.ToString), True);
  AClient.AddaHeader('Gov-Vendor-License-IDs', PercentEncode(FProductName) + '=' + THashSHA1.GetHashString(FLicenseKey), True);
  AClient.AddaHeader('Gov-Vendor-Product-Name', PercentEncode(FProductName));

  if FAppVersion = '' then
     FAppVersion := GetApplicationVersion;
  AClient.AddaHeader('Gov-Vendor-Version', PercentEncode(FProductName) + '=' + FAppVersion, True);


  if FConnectionMethod in SERVER_CONNECTIONS then
  begin
  // Only Required for _SERVER Connection Methods
    AClient.AddaHeader('Gov-Client-Public-IP', FPublicIP);
    AClient.AddaHeader('Gov-Client-Public-IPs-Timestamp', GetPublicIPTimeStampAsString, True);
    AClient.AddaHeader('Gov-Client-Public-Port', FPublicPort.ToString);
  // AClient.AddaHeader('Gov-Vendor-Forwarded', '');
     if FConnectionMethod = cmWebAppViaServer then
     begin
  // WEB_APP_VIA_SERVER only so not needed
  // Gov-Client-Browser-Plugins
  // Gov-Client-Browser-JS-User-Agent
  // Gov-Client-Browser-Do-Not-Track
     end;
  end;

End;

function TVATHeaders.ConnectionMethodString: String;
begin
  Result := C_CONNECTION_METHOD[FConnectionMethod];
end;

constructor TVATHeaders.Create(Const AConnectionMethod: THMRCConnectionMethod);
Begin
  FConnectionMethod := AConnectionMethod;
  FMultiFactor.MultiFactorType := mfNone;
  FMultiFactor.TimeStampIsUTC := False;

  FWindowWidth := 500;
  FWindowHeight := 400;

  FTimeZone := THMRCMTDUtils.getTimeZone;
  FScreens := THMRCMTDUtils.ScreensInfo;

  FLocalIP := TInternetSupport.GetLocalIPs(',', True, True);
  If FLocalIP = '' Then
    FLocalIP := TInternetSupport.GetLocalIP;
  FLocalIPTimeStamp := TTimeZone.Local.ToUniversalTime(Now);

//  if FConnectionMethod in SERVER_CONNECTIONS then
//  begin
//  Let's do this for DeskTop apps too as it is useful
  FPublicIP := TInternetSupport.GetPublicIp;
  FPublicIPTimeStamp := TTimeZone.Local.ToUniversalTime(Now);
//  end;

  FMACAddress := GetAllMacAddresses(True);
  FComputerName := URIEncode(GetLocalComputerName);
  FCurrentSystemUser := URIEncode(THMRCMTDUtils.getOSUserName);
  FUserAgent := THMRCMTDUtils.getUserAgent;

End;

function TVATHeaders.GetLocalIPTimeStampAsString: String;
begin
  Result := DateToISO8601(FLocalIPTimeStamp);
end;

function TVATHeaders.GetPublicIPTimeStampAsString: String;
begin
  Result := DateToISO8601(FPublicIPTimeStamp);
end;

procedure TVATHeaders.CheckValues;
begin
   if (FLicenseKey = '') OR
   (FDeviceId = '') OR
   (FProductName = '') then
   raise EVATHeaderException.Create('Some required values have not been set');
end;

function TVATHeaders.PercentEncode(const Value : string): String;
begin
  Result := Value.Replace(' ', '%20', [rfReplaceAll]);
end;

procedure TVATHeaders.RefreshDates;
begin
  FTimeZone := THMRCMTDUtils.getTimeZone;
  FLocalIPTimeStamp := TTimeZone.Local.ToUniversalTime(Now);
  FPublicIPTimeStamp := TTimeZone.Local.ToUniversalTime(Now);
end;

End.
