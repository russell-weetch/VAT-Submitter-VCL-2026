unit Systematic.AppVersion;

(* ***********************************************************************
  copyright 2019-2021  Systematic Marketing Limited

  https://smxi.com

  Distributed under the MIT software license, see the accompanying file
  LICENSE or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.

  *********************************************************************** *)

{$I HmrcMtd.inc}

interface

  function GetApplicationVersion: string;

implementation

{$IFDEF ANDROID}
uses
  FMX.Helpers.Android, FMX.Platform.Android,
  Androidapi.JNI.JavaTypes, Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText;
{$ENDIF}
{$IFDEF APPLE}
uses
  {$IFDEF IOS}
  iOSapi.Foundation,
  {$ELSE}
  Macapi.Foundation,
  {$ENDIF}
  Macapi.Helpers,
  Macapi.ObjectiveC;
{$ENDIF}
{$IFDEF MSWINDOWS}
uses
  System.Types, System.SysUtils, Windows;
{$ENDIF}


function GetApplicationVersion: string;
{$IFDEF ANDROID}
var
  PackageManager: JPackageManager;
  PackageInfo: JPackageInfo;
begin
  Result := '?';
  try
    PackageManager := TAndroidHelper.Context.getPackageManager; //SharedActivityContext.getPackageManager;
    PackageInfo := PackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);  //SharedActivityContext.getPackageName, 0);
    Result := JStringToString(PackageInfo.versionName);

  except
  end;
end;
{$ENDIF}
{$IFDEF IOS}
var
  AppKey: Pointer;
  AppBundle: NSBundle;
  BuildStr : NSString;
begin
  Result := '?';
  try
    AppKey := (StrToNSStr('CFBundleVersion') as ILocalObject).GetObjectID;

    AppBundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
    BuildStr := TNSString.Wrap(AppBundle.infoDictionary.objectForKey(AppKey));
    Result := UTF8ToString(BuildStr.UTF8String);

  except
  end;
end;
{$ENDIF}
{$IFDEF MSWINDOWS}
var
  sExe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Result := '?';
  try
    sExe := ParamStr(0);
    Size := GetFileVersionInfoSize(PChar(sExe), Handle);
    if (Size = 0) then
      exit; // RaiseLastOSError;
    SetLength(Buffer, Size);
    if not GetFileVersionInfo(PChar(sExe), Handle, Size, Buffer) then
      exit; // RaiseLastOSError;
    if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
      exit; // RaiseLastOSError;
    Result := Format('%d.%d.%d.%d',
      [LongRec(FixedPtr.dwFileVersionMS).Hi,  //major
       LongRec(FixedPtr.dwFileVersionMS).Lo,  //minor
       LongRec(FixedPtr.dwFileVersionLS).Hi,  //release
       LongRec(FixedPtr.dwFileVersionLS).Lo]) //build

  except

  end;
end;
{$ENDIF}
{$IFDEF OSX}
var
  AppKey: Pointer;
  AppBundle: NSBundle;
  BuildStr : NSString;
begin
  Result := '?';
  try
    AppKey := (StrToNSStr('CFBundleVersion') as ILocalObject).GetObjectID;

    AppBundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
    BuildStr := TNSString.Wrap(AppBundle.infoDictionary.objectForKey(AppKey));
    Result := UTF8ToString(BuildStr.UTF8String);

  except
  end;
end;
{$ENDIF}

end.
