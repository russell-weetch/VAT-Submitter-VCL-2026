//This include file is for use by the HMRC MTD Components and support files.

{$IF DECLARED(FireMonkeyVersion)}
  {$DEFINE USE_FMX}
{$ELSE}
  {$DEFINE USE_VCL}
{$IFEND}

{$IFDEF MACOS}
  {$DEFINE APPLE}
{$ENDIF}

{$IFDEF IOS}
  {$DEFINE APPLE}
{$ENDIF}


