{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Data.Lock;

interface

type
  TDataLockStatus = (lsNotLocked, lsLockedByMe, lsLockedByOther);

  TVATDataLock = class
  public
    class function Status(const FileName, LockKey: string): TDataLockStatus;
    class function IsStale(const FileName: string): Boolean;
    class procedure Acquire(const FileName, LockKey, LockedBy: string);
    class procedure UpdateOwner(const FileName, UserId, LockedBy: string);
    class function Describe(const FileName, LockKey: string): string;
    class procedure Clear(const FileName: string);
    class function ReleaseIfMine(const FileName, LockKey: string): Boolean;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows;

function ProcessExists(ProcessId: Cardinal): Boolean;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  Handle: THandle;
begin
  if ProcessId = 0 then
    Exit(False);
  Handle := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, ProcessId);
  if Handle <> 0 then
  begin
    CloseHandle(Handle);
    Exit(True);
  end;
  Result := GetLastError = ERROR_ACCESS_DENIED;
end;

function LoadLock(const FileName: string): TStringList;
begin
  Result := TStringList.Create;
  if TFile.Exists(FileName) then
    Result.LoadFromFile(FileName);
end;

class function TVATDataLock.Status(const FileName, LockKey: string): TDataLockStatus;
var
  Lines: TStringList;
begin
  if not TFile.Exists(FileName) then
    Exit(lsNotLocked);
  Lines := LoadLock(FileName);
  try
    if Lines.Values['LockKey'] = LockKey then
      Result := lsLockedByMe
    else
      Result := lsLockedByOther;
  finally
    Lines.Free;
  end;
end;

class procedure TVATDataLock.Acquire(const FileName, LockKey, LockedBy: string);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Values['LockKey'] := LockKey;
    Lines.Values['LockedBy'] := LockedBy;
    Lines.Values['LockedOn'] := Double(Now).ToString;
    Lines.Values['ProcessId'] := GetCurrentProcessId.ToString;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

class procedure TVATDataLock.UpdateOwner(const FileName, UserId, LockedBy: string);
var
  Lines: TStringList;
begin
  Lines := LoadLock(FileName);
  try
    Lines.Values['UserId'] := UserId;
    Lines.Values['LockedBy'] := LockedBy;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

class function TVATDataLock.Describe(const FileName, LockKey: string): string;
var
  Lines: TStringList;
  Owner: string;
  LockedOn: TDateTime;
begin
  if not TFile.Exists(FileName) then
    Exit('The data is no longer locked. Restart the application to reopen it.');
  Lines := LoadLock(FileName);
  try
    if Lines.Values['LockKey'] = LockKey then
      Owner := 'You'
    else
      Owner := Lines.Values['LockedBy'];
    LockedOn := StrToFloatDef(Lines.Values['LockedOn'], 0);
    Result := 'locked by: ' + Owner + ' on: ' + FormatDateTime('dd-mmm-yyyy hh:nn', LockedOn);
  finally
    Lines.Free;
  end;
end;

class function TVATDataLock.IsStale(const FileName: string): Boolean;
var
  Lines: TStringList;
  ProcessId: Cardinal;
begin
  Result := False;
  if not TFile.Exists(FileName) then
    Exit;
  Lines := LoadLock(FileName);
  try
    ProcessId := StrToUIntDef(Lines.Values['ProcessId'], 0);
    Result := not ProcessExists(ProcessId);
  finally
    Lines.Free;
  end;
end;

class procedure TVATDataLock.Clear(const FileName: string);
begin
  if TFile.Exists(FileName) then
    TFile.Delete(FileName);
end;

class function TVATDataLock.ReleaseIfMine(const FileName, LockKey: string): Boolean;
begin
  Result := not TFile.Exists(FileName);
  if Result then
    Exit;
  if Status(FileName, LockKey) <> lsLockedByMe then
    Exit(False);
  TFile.Delete(FileName);
  Result := not TFile.Exists(FileName);
end;

end.
