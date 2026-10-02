Unit VAT.Headers.Utils;

(* ***********************************************************************
  copyright 2019-2021  Systematic Marketing Limited

  https://smxi.com

  Distributed under the MIT software license, see the accompanying file
  LICENSE or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.

  *********************************************************************** *)

Interface

Uses
  Winapi.Windows;

Type

  THMRCMTDUtils = Class
    Class Function ScreensInfo: String;
    Class Function getTimeZone: String;
    Class Function getOSUserName: String;
    Class Function getUserAgent: String;
  End;

{$I HmrcMtd.inc}

Implementation

Uses
{$IFDEF USE_FMX}
  FMX.Platform,
  FMX.Forms,
{$ELSE}
  VCL.Forms,
{$ENDIF}
  System.SysUtils,
  System.Rtti,

  System.DateUtils,
  System.StrUtils,
  System.TimeSpan,
  REST.Utils,
  uSMBIOS;

{ THMRCMTDUtils }

Function GetDisplayBits: Integer;
Var
  ZeroDC: HDC;
Begin
  ZeroDC := GetDC(0);
  Try
    Result := GetDeviceCaps(ZeroDC, BITSPIXEL) * GetDeviceCaps(ZeroDC, PLANES);
  Finally
    ReleaseDC(0, ZeroDC);
  End;
End;

Class Function THMRCMTDUtils.getOSUserName: String;
Var
  lSize: DWORD;
Begin
  lSize := 1024;
  SetLength(Result, lSize);
  If Winapi.Windows.GetUserName(PChar(Result), lSize) Then
    SetLength(Result, lSize - 1)
  Else
    RaiseLastOSError;
End;

{$IFDEF USE_FMX}

Class Function THMRCMTDUtils.ScreensInfo: String;
Resourcestring
  tpl = 'width=$W&height=$H&scaling-factor=$S&colour-depth=$C';
Var
  ScreenService: IFMXScreenService;

Begin
  Result := tpl.Replace('$W', Screen.Width.ToString).Replace('$H', Screen.Height.ToString)
    .Replace('$C', GetDisplayBits.ToString);

  If TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, IInterface(ScreenService)) Then
  Begin
    Result := Result.Replace('$S', ScreenService.GetScreenScale.ToString);
    // ScreenService.GetScreenSize
  End
  Else
  Begin
    Result := Result.Replace('$S', '1');
  End;
End;
{$ELSE}

Class Function THMRCMTDUtils.ScreensInfo: String;
Resourcestring
  tpl = 'width=$W&height=$H&scaling-factor=$S&colour-depth=$C';
Var
  DC: HDC;
  lScale: Single;
Begin
  Result := tpl.Replace('$W', Screen.Width.ToString).Replace('$H', Screen.Height.ToString)
    .Replace('$C', GetDisplayBits.ToString);
  DC := GetDC(0);
  Try
    lScale := GetDeviceCaps(DC, LOGPIXELSX) / 96;
    Result := Result.Replace('$S', lScale.ToString);
  Finally
    ReleaseDC(0, DC);
  End;

End;
{$ENDIF}

Class Function THMRCMTDUtils.getTimeZone: String;
Var
  retval: TTimeSpan;
Begin
  retval := TTimeZone.Local.GetUtcOffset(Now);
  Result := 'UTC' + ifThen(retval.Hours >= 0, '+') + FormatFloat('00', retval.Hours) + ':' +
    FormatFloat('00', retval.Minutes);
End;

Class Function THMRCMTDUtils.getUserAgent: String;
Var
  bios: TSMBios;
Begin

  Result := 'os-family=' + TRttiEnumerationType.GetName<TOSVersion.TPlatform>(TOSVersion.Platform).SubString(2) +
    '&os-version=' + TOSVersion.Major.ToString + '.' + TOSVersion.Minor.ToString;

  // wmic computersystem get model, manufacturer
  bios := TSMBios.Create();
  Try
    Result := Result + '&device-manufacturer=' + URIEncode(bios.SysInfo.ManufacturerStr) + '&device-model=' +
      URIEncode(bios.SysInfo.ProductNameStr);
  Finally
    bios.Free;
  End;
End;

End.
