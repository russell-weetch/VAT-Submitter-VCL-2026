{
  Copyright (c) 1990-2026 Systematic Marketing Limited (SMXi Software).
  All rights reserved.

  This source code is proprietary and confidential. No part of this code
  may be used, copied, modified, distributed, or disclosed without the
  express prior written permission of the copyright holder.
}
unit VAT.Users.Password;

interface

function PasswordHash(const APassword, ASalt: string; const KeyStretch: Integer = 65536): string;
function GenerateSalt(const ALength: Integer = 32): string;
function Pbkdf2HmacSha256Hex(const Password, Salt: string; Iterations, KeyBytes: Integer): string;

implementation

uses
  System.Hash,
  System.SysUtils;

const
  Pepper = 'BL7q9egVP!PH1pBigxvWyc2648pN';

function HmacSha256(const Key, Data: TBytes): TBytes;
begin
  if (Length(Key) = 0) or (Length(Data) = 0) then
    raise Exception.Create('HMAC input is empty');
  Result := THashSHA2.GetHMACAsBytes(Data, Key, THashSHA2.TSHA2Version.SHA256);
end;

function Pbkdf2Sha256(const Password, Salt: TBytes; Iterations, KeyLength: Integer): TBytes;
var
  BlockIndex, Iteration, ByteIndex, BlockCount: Integer;
  U, Block, SaltAndIndex: TBytes;
  IndexBytes: array[0..3] of Byte;
begin
  if Iterations < 1 then
    raise Exception.Create('Password stretch must be at least 1');
  BlockCount := (KeyLength + 31) div 32;
  SetLength(Result, 0);
  for BlockIndex := 1 to BlockCount do
  begin
    IndexBytes[0] := Byte(BlockIndex shr 24);
    IndexBytes[1] := Byte(BlockIndex shr 16);
    IndexBytes[2] := Byte(BlockIndex shr 8);
    IndexBytes[3] := Byte(BlockIndex);
    SetLength(SaltAndIndex, Length(Salt) + 4);
    if Length(Salt) > 0 then
      Move(Salt[0], SaltAndIndex[0], Length(Salt));
    Move(IndexBytes[0], SaltAndIndex[Length(Salt)], 4);
    U := HmacSha256(Password, SaltAndIndex);
    Block := Copy(U);
    for Iteration := 2 to Iterations do
    begin
      U := HmacSha256(Password, U);
      for ByteIndex := 0 to High(Block) do
        Block[ByteIndex] := Block[ByteIndex] xor U[ByteIndex];
    end;
    Result := Result + Block;
  end;
  SetLength(Result, KeyLength);
end;

function BytesToHex(const Value: TBytes): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 0 to High(Value) do
    Result := Result + IntToHex(Value[Index], 2).ToLower;
end;

function Pbkdf2HmacSha256Hex(const Password, Salt: string; Iterations, KeyBytes: Integer): string;
begin
  Result := BytesToHex(Pbkdf2Sha256(
    TEncoding.UTF8.GetBytes(Password),
    TEncoding.UTF8.GetBytes(Salt),
    Iterations,
    KeyBytes));
end;

function PasswordHash(const APassword, ASalt: string; const KeyStretch: Integer): string;
begin
  Result := Pbkdf2HmacSha256Hex(APassword, ASalt + Pepper, KeyStretch, 32);
end;

function GenerateSalt(const ALength: Integer): string;
begin
  Result := StringReplace(TGUID.NewGuid.ToString, '-', '', [rfReplaceAll]);
  Result := Result.Trim(['{', '}']).ToLower;
  while Result.Length < ALength do
    Result := Result + StringReplace(TGUID.NewGuid.ToString, '-', '', [rfReplaceAll]).Trim(['{', '}']).ToLower;
  Result := Result.Substring(0, ALength);
end;

end.
