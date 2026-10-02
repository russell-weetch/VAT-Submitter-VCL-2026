unit fVclHmrcBase;

(*****************************************************************************
*               HMRC PAYE API REST Test Application Base Form                *
******************************************************************************
*                                VCL FORMS                                   *
******************************************************************************
*  This just provides a means to hold the client keys and the filepath for   *
*  the keys and tokens.                                                      *
*                                                                            *
*  created 22/12/20.    IanH                                                 *
*  updated 01/02/21.    IanH - added AppValues record for new header details *
*  version 1.0.1                                                             *
*                                                                            *
*  Original copyright Ian Hamilton 2020/21                                   *
*****************************************************************************)
interface
(****************************************************************************)

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  HmrcRestSupport, HmrcHeaders, Vcl.Imaging.pngimage, Vcl.ExtCtrls;
(****************************************************************************)

type
  TfrmVclHmrcBase = class(TForm)
    Image1: TImage;
  private
  protected
    FAppValues : TAppValues;             // application settings for the vat headers
    FFilePath  : string;                 // config/ini file location for tests
    ODetails: THmrcClientDetails;        // client id/secret for oauth2
    // load a token from file - matches THmrcTokenLoadEvent signature (in HmrcRestSupport)
    procedure LoadToken(Sender: TObject; const Uid, Scope: string; var found: boolean);
    // save the supplied token details to file - matches THmrcTokenEvent signature (in HmrcRestSupport)
    procedure SaveToken(Sender: TObject; const Uid, Scope, AccessTkn, RefreshTkn: string;
                        const Expires, TimeOut: TDateTime);
    procedure SetDetails(const Value: THmrcClientDetails); virtual;   // property method
  public
    procedure SetAppValues(Values: TAppValues); virtual;
    property ClientDetails : THmrcClientDetails read ODetails   write SetDetails;
    property FilePath      : string             read FFilePath  write FFilePath;
  end;

(****************************************************************************)
implementation
(****************************************************************************)
uses
  IniFiles, HmrcRestClient;

{$R *.dfm}

(*****************************************************************************
*  Load a token from file by UID and scope.                                  *
*****************************************************************************)
procedure TfrmVclHmrcBase.LoadToken(Sender: TObject; const Uid, Scope: string; var found: boolean);
var
  lvTemp    : string;
  lvAccess  : string;
  lvRefresh : string;
  lvStops   : TDateTime;
  lvExpires : TDateTime;
  f : TIniFile;
begin
  found := false;
  if (Assigned(Sender)) and (Sender is THmrcRestClient) then
  begin
    f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
    try
      // are there any tokens for this UID ?
      if (f.SectionExists(Uid)) then
      begin
        lvAccess  := f.ReadString(Uid, Scope + '_Access', '');
        // did it find a token for this scope ?
        if (lvAccess = '') then
          Exit;

        lvRefresh := f.ReadString(Uid, Scope + '_Refresh', '');
        lvTemp    := f.ReadString(Uid, Scope + '_Stops', '');
        lvStops   := StrToDateDef(lvTemp,Date);
        lvTemp    := f.ReadString(Uid, Scope + '_Expires', '');
        lvExpires := StrToDateTimeDef(lvTemp,Now);

        (Sender as THmrcRestClient).SetaToken(Scope, Uid, lvAccess, lvRefresh, lvStops, lvExpires);

        found := true;
      end;
    finally
      f.Free;
    end;
  end;
end;

(*****************************************************************************
*  Save these details to the tokens file.                                    *
*****************************************************************************)
procedure TfrmVclHmrcBase.SaveToken(Sender: TObject; const Uid, Scope, AccessTkn, RefreshTkn: string;
                                    const Expires, TimeOut: TDateTime);
var
  f : TIniFile;
begin
  f := TIniFile.Create(FFilePath + 'CurrentTokens.ini');
  try
      f.WriteString(Uid, Scope + '_Access', AccessTkn);
      f.WriteString(Uid, Scope + '_Refresh', RefreshTkn);
      f.WriteString(Uid, Scope + '_Stops', DateToStr(Expires));
      f.WriteString(Uid, Scope + '_Expires', DateTimeToStr(TimeOut));
  finally
    f.Free;
  end;
end;

(*****************************************************************************
*                         PROPERTY METHODS SECTION                           *
******************************************************************************
*  Set the AppValues.                                                        *
*****************************************************************************)
procedure TfrmVclHmrcBase.SetAppValues(Values: TAppValues);
begin
  FAppValues := Values;
end;

(*****************************************************************************
*  Set the client details.                                                   *
*****************************************************************************)
procedure TfrmVclHmrcBase.SetDetails(const Value: THmrcClientDetails);
begin
  ODetails := Value;
end;


end.
