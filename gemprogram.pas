unit gemprogram;

{$mode ObjFPC}{$H+}

interface

uses
  Unix, BaseUnix, Process, Users,
  Classes, SysUtils;

{ IMPORTS }
{$REGION IMPORTS}
const
  SIGHUP     = BaseUnix.SIGHUP;
  SIGINT     = BaseUnix.SIGINT;
  SIGQUIT    = BaseUnix.SIGQUIT;
  SIGILL     = BaseUnix.SIGILL;
  SIGTRAP    = BaseUnix.SIGTRAP;
  SIGABRT    = BaseUnix.SIGABRT;
  SIGIOT     = BaseUnix.SIGIOT;
  SIGFPE     = BaseUnix.SIGFPE;
  SIGKILL    = BaseUnix.SIGKILL;
  SIGSEGV    = BaseUnix.SIGSEGV;
  SIGPIPE    = BaseUnix.SIGPIPE;
  SIGALRM    = BaseUnix.SIGALRM;
  SIGTERM    = BaseUnix.SIGTERM;
{$ENDREGION}

type

  TGEMSigProc = procedure();

  TGEMProgram = class(TObject)
    private
      fPID: Cardinal;
      fUID: Cardinal;
      fEUID: Cardinal;
      fUserName: String;
      fEUserName: String;
      fPath: String;
      fName: String;
      fArg: Array of String;
      fArgCount: Cardinal;

      class var fSigProc: Array [1..31] of TGEMSigProc;
      class var fSigAction: Array [1..31] of PSigActionRec;
      class var fSigOld: Array [1..31] of PSigActionRec;

      class procedure SignalHandler(Sig: cint); cdecl; static;

      function GetArg(const Index: Cardinal): String;
      function GetIsRoot(): Boolean;

      procedure RelaunchRoot();

    public
      property PID: Cardinal read fPID;
      property UID: Cardinal read fUID;
      property EUID: Cardinal read fEUID;
      property UserName: String read fUserName;
      property EUserName: String read fEUserName;
      property IsRoot: Boolean read GetIsRoot;
      property Path: String read fPath;
      property Name: String read fName;
      property Arg[Index: Cardinal]: String read GetArg;
      property ArgCount: Cardinal read fArgCount;

      constructor Create(const aNeedRoot: Boolean = False);

      function DropRoot(): Integer;
      function SetSigHandler(const aSignal: Integer; const aProc: TGEMSigProc): Integer;
  end;

(*-----------------------------------------------------------------------------)
                               Implemenatation
(-----------------------------------------------------------------------------*)

implementation

class procedure TGEMProgram.SignalHandler(Sig: cint); cdecl; static;
  begin
    TGEMProgram.fSigProc[Sig];
  end;

constructor TGEMProgram.Create(const aNeedRoot: Boolean = False);
var
I: Integer;
RetStr: String;
  begin
    inherited Create();

    if aNeedRoot then begin
      Self.RelaunchRoot(); // will halt here if not root
    end;

    // PID
    Self.fPID := fpGetPID();

    // args
    Self.fArgCount := ParamCount;
    Initialize(Self.fArg);
    SetLength(Self.fArg, ParamCount);

    for I := 0 to Self.fArgCount - 1 do begin
      Self.fArg[I] := ParamStr(I + 1);
    end;

    // path and name
    Self.fPath := ExtractFilePath(ParamStr(0));
    Self.fName := ExtractFileName(ParamStr(0));

    // UID and usernames
    fEUID := fpGetUID;
    RetStr := GetEnvironmentVariable('SUDO_UID');
    if RetStr <> '' then begin
      fUID := Cardinal(RetStr.ToInteger());
    end else begin
      fUID := fEUID;
    end;

    fEUserName := GetEnvironmentVariable('USER');
    fUserName := GetUserName(fUID);

  end;

function TGEMProgram.GetArg(const Index: Cardinal): String;
  begin
    if Index >= Self.fArgCount then Exit('');
    Exit(fArg[Index]);
  end;

function TGEMProgram.GetIsRoot(): Boolean;
  begin
    Exit(fEUID = 0);
  end;

procedure TGEMProgram.RelaunchRoot();
var
Args: String;
I: Integer;
  begin
    if fpGetEUID = 0 then Exit();

    if ParamCount <> 0 then begin
      Initialize(Args);

      for I := 1 to ParamCount do begin
        Args := Args + ' ' + ParamStr(I);
      end;
    end;

    fpSystem('sudo ' + ParamStr(0) + Args);
    Halt();
  end;

function TGEMProgram.DropRoot(): Integer;
  begin
    if Self.fEUID <> 0 then Exit(0);

    Result := fpSetUID(Self.fUID);
    if Result = 0 then begin
      Self.fEUserName := Self.fUserName;
      Self.fEUID := Self.fUID;
    end;
  end;

function TGEMProgram.SetSigHandler(const aSignal: Integer; const aProc: TGEMSigProc): Integer;
var
JunkAction: PSigActionRec;
  begin
    // make sure aSignal in range 1-31
    if (aSignal < 1) or (aSignal > 31) then begin
      Exit(-1);
    end;

    // just exit success if we're trying to set the same handler as the existing one
    if Self.fSigProc[aSignal] = aProc then begin
      Exit(0);
    end;

    if Assigned(aProc) then begin
      // if proc passed is not nil
      if Assigned(Self.fSigProc[aSignal]) = False then begin

        // create signal handler when the proc is not assigned
        New(Self.fSigAction[aSignal]);
        New(Self.fSigOld[aSignal]);

        Self.fSigAction[aSignal]^.sa_Handler := SigActionHandler(@TGEMProgram.SignalHandler);
        FillChar(Self.fSigAction[aSignal]^.Sa_Mask, SizeOf(Self.fSigAction[aSignal]^.sa_mask), #0);
        Self.fSigAction[aSignal]^.Sa_Flags := 0;
        Self.fSigAction[aSignal]^.Sa_Restorer := nil;

        fpSigAction(aSignal, Self.fSigAction[aSignal], Self.fSigOld[aSignal]);

        Self.fSigProc[aSignal] := aProc;

        Exit(0);

      end else begin

        // replace signal handler when the proc is already assigned
        New(JunkAction);

        Self.fSigAction[aSignal]^.sa_Handler := SigActionHandler(@TGEMProgram.SignalHandler);
        FillChar(Self.fSigAction[aSignal]^.Sa_Mask, SizeOf(Self.fSigAction[aSignal]^.sa_mask), #0);
        Self.fSigAction[aSignal]^.Sa_Flags := 0;
        Self.fSigAction[aSignal]^.Sa_Restorer := nil;

        fpSigAction(aSignal, Self.fSigAction[aSignal], JunkAction);

        Dispose(JunkAction);

        Self.fSigProc[aSignal] := aProc;

        Exit(0);

      end;

    end else begin
      // if proc passed is nil / signal handler being removed
      // replace signal handler with the default
      New(JunkAction);
      fpSigAction(aSignal, Self.fSigOld[aSignal], JunkAction);
      Dispose(JunkAction);

      Self.fSigProc[aSignal] := nil;

      Exit(0);

    end;

  end;

(*-----------------------------------------------------------------------------)
                               Initialization
(-----------------------------------------------------------------------------*)

initialization
  begin

  end;

(*-----------------------------------------------------------------------------)
                                 Finalization
(-----------------------------------------------------------------------------*)

finalization
  begin

  end;

end.

