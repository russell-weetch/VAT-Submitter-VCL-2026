{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.App.Settings;

interface

uses
  VAT.Enumerations;

type
  TVATAppSettings = record
  public
    ConfigFolder: string;
    DataPath: string;
    LicenceKey: string;
    DeviceId: string;
    Mode: TOpMode;
    ClientId: string;
    ClientSecret: string;
    ServerToken: string;
    CallbackUrl: string;
    CallbackPort: string;
    Scenario: string;
    function IniFileName: string;
    function DatabaseFile: string;
    function LockFile: string;
    procedure Load;
    procedure Save;
  end;

function DefaultConfigFolder: string;

const
  DebugFirstName = 'John';
  DebugLastName = 'Doe';
  DebugUserName = 'John';
  DebugPassword = 'testing';
  DebugClientId = 'Rd1TtGBs_cgUubcaDSn5C14ws7wa';
  DebugClientSecret = '0afa9cc4-4fab-45cc-8be5-2519a9b3174e';
  DebugServerToken = 'c099ff9cb7aca1bd3a8675f511c7258';

implementation

uses
  System.IniFiles,
  System.IOUtils,
  System.SysUtils;

const
  IniName = 'vatsubmitter.ini';
  DatabaseName = 'VATSubmitter.db';

function DefaultConfigFolder: string;
begin
  {$IFDEF DEBUG}
  Result := TPath.Combine(TPath.GetPublicPath, 'SMX\VAT Submitter VCL Test');
  {$ELSE}
  Result := TPath.Combine(TPath.GetPublicPath, 'SMX\VAT Submitter VCL');
  {$ENDIF}
end;

function NewKey: string;
begin
  Result := StringReplace(TGUID.NewGuid.ToString, '-', '', [rfReplaceAll]).Trim(['{', '}']).ToLower;
end;

function TVATAppSettings.IniFileName: string;
begin
  Result := TPath.Combine(ConfigFolder, IniName);
end;

function TVATAppSettings.DatabaseFile: string;
begin
  Result := TPath.Combine(DataPath, DatabaseName);
end;

function TVATAppSettings.LockFile: string;
begin
  Result := TPath.Combine(DataPath, 'VATData.lck');
end;

procedure TVATAppSettings.Load;
var
  Ini: TIniFile;
begin
  if ConfigFolder = '' then
    ConfigFolder := DefaultConfigFolder;
  if not TDirectory.Exists(ConfigFolder) then
    TDirectory.CreateDirectory(ConfigFolder);
  if DataPath = '' then
    DataPath := ConfigFolder;
  CallbackUrl := 'http://localhost:8080';
  CallbackPort := '8080';
  Mode := opmTest;
  if not TFile.Exists(IniFileName) then
  begin
    {$IFDEF DEBUG}
    ClientId := DebugClientId;
    ClientSecret := DebugClientSecret;
    ServerToken := DebugServerToken;
    {$ENDIF}
    Exit;
  end;
  Ini := TIniFile.Create(IniFileName);
  try
    DataPath := Ini.ReadString('Settings', 'DataPath', DataPath);
    LicenceKey := Ini.ReadString('Settings', 'LicenceKey', '');
    DeviceId := Ini.ReadString('Settings', 'DeviceId', '');
    Mode := ParseOpMode(Ini.ReadString('Settings', 'Mode', 'Test'));
    ClientId := Ini.ReadString('HMRC', 'ClientId', '');
    ClientSecret := Ini.ReadString('HMRC', 'ClientSecret', '');
    ServerToken := Ini.ReadString('HMRC', 'ServerToken', '');
    CallbackUrl := Ini.ReadString('HMRC', 'CallbackUrl', CallbackUrl);
    CallbackPort := Ini.ReadString('HMRC', 'CallbackPort', CallbackPort);
    Scenario := Ini.ReadString('HMRC', 'Scenario', '');
  finally
    Ini.Free;
  end;
  {$IFDEF DEBUG}
  Mode := opmTest;
  {$ENDIF}
  {$IFDEF DEBUG}
  if ClientId.Trim = '' then
    ClientId := DebugClientId;
  if ClientSecret.Trim = '' then
    ClientSecret := DebugClientSecret;
  if ServerToken.Trim = '' then
    ServerToken := DebugServerToken;
  {$ENDIF}
end;

procedure TVATAppSettings.Save;
var
  Ini: TIniFile;
begin
  if ConfigFolder = '' then
    ConfigFolder := DefaultConfigFolder;
  if not TDirectory.Exists(ConfigFolder) then
    TDirectory.CreateDirectory(ConfigFolder);
  if not TDirectory.Exists(DataPath) then
    TDirectory.CreateDirectory(DataPath);
  if LicenceKey.Trim = '' then
    LicenceKey := NewKey;
  if DeviceId.Trim = '' then
    DeviceId := NewKey;
  Ini := TIniFile.Create(IniFileName);
  try
    Ini.WriteString('Settings', 'DataPath', DataPath);
    Ini.WriteString('Settings', 'LicenceKey', LicenceKey);
    Ini.WriteString('Settings', 'DeviceId', DeviceId);
    Ini.WriteString('Settings', 'Mode', OpModeText(Mode));
    Ini.WriteString('HMRC', 'ClientId', ClientId);
    Ini.WriteString('HMRC', 'ClientSecret', ClientSecret);
    Ini.WriteString('HMRC', 'ServerToken', ServerToken);
    Ini.WriteString('HMRC', 'CallbackUrl', CallbackUrl);
    Ini.WriteString('HMRC', 'CallbackPort', CallbackPort);
    Ini.WriteString('HMRC', 'Scenario', Scenario);
  finally
    Ini.Free;
  end;
end;

end.
