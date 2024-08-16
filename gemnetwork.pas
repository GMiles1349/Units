unit gemnetwork;

{$mode ObjFPC}{$H+}
{$modeswitch advancedrecords}

interface

uses
  gemutil, Unix, BaseUnix, Process, fphttpclient,
  Classes, SysUtils, StrUtils;

type

  { TGEMPingResult}
  { Used to describe results of a ping }

  PGEMPingResult = ^TGEMPingResult;
  TGEMPingResult = record
    Success: Boolean; // true = was able to ping, false = ping failed
    Address: String;
    NumSent: Integer; // number of packets/pings sents
    NumReceived: Integer; // number of packets returned/received
    PacketLoss: Single; // percentage of packet loss, range 0 - 1
    TotalTime: Single;  // total time to send/receive all pings in milliseconds
    MinTime, AvgTime, MaxTime: Single; // Minimum, average and maximum time of pings in milliseconds

    class operator Initialize(var Dest: TGEMPingResult);
  end;

  function gemPing(const aAddress: String; const aCount: Integer = 1; pResult: PGEMPingResult = nil): Integer;
  function gemParsePing(const aStringList: TStringList; pResult: PGEMPingResult): Integer;
  function gemGetPageText(const aAddress: String): String;

implementation

class operator TGEMPingResult.Initialize(var Dest: TGEMPingResult);
  begin
    Dest.Address := '';
    Dest.Success := False;
    Dest.NumSent := 0;
    Dest.NumReceived := 0;
    Dest.PacketLoss := 0;
    Dest.TotalTime := 0;
    Dest.MinTime := 0;
    Dest.AvgTime := 0;
    Dest.MaxTime := 0;
  end;

function gemPing(const aAddress: String; const aCount: Integer = 1; pResult: PGEMPingResult = nil): Integer;
// ping address at aAddress aCount times, and return results of pings in pResult
// function result is 0 = failed to ping, or 1 = ping succeeded
var
Proc: TProcess;
OList: TStringList;
  begin

    if aCount <= 0 then Exit(0);

    Proc := TProcess.Create(nil);
    Proc.Executable := '/usr/bin/ping';
    Proc.Parameters.Add('-c ' + aCount.ToString());
    Proc.Parameters.Add('-q');
    Proc.Parameters.Add('-i 0.01');
    Proc.Parameters.Add('-W 1');
    Proc.Parameters.Add(aAddress);;
    Proc.Options := Proc.Options + [poWaitOnExit, poUsePipes];
    Proc.Execute;

    OList := TStringList.Create();
    OList.LoadFromStream(Proc.Output);

    if (OList.Count = 0) or (Pos('failure', OList[0]) <> 0 ) then begin
      Result := 0;
      if Assigned(pResult) then pResult^.Success := False;
    end else begin
      if Assigned(pResult) then begin
        pResult^.Address := aAddress;
        Result := gemParsePing(OList, pResult);
      end;
    end;

    OList.Free();

    Proc.Free;
  end;

function gemParsePing(const aStringList: TStringList; pResult: PGEMPingResult): Integer;
var
I: Integer;
FirstLine: Integer;
SString: TStringArray;
RString: TStringArray;
ValString: String;

  procedure PrepRString();
  begin
    while RString[0] = '' do begin
      Delete(RString, 0, 1);
    end;

    RString[0] := StrTrimLeft(RString[0], ' ');
  end;

  begin

    Result := 0;

    for I := 0 to aStringList.Count - 1 do begin
      if Pos('---', AStringList[I]) <> 0 then begin
        FirstLine := I + 1;
        break;
      end;
    end;

    { get packet and total time info }
    SString := SplitString(aStringList[FirstLine], ',');
    for I := 0 to High(SString) do begin
      if Pos('transmitted', SString[I]) <> 0 then begin
        // packets sent
        RString := SplitString(SString[I], ' ');
        PrepRString();
        pResult^.NumSent := RString[0].ToInteger();
      end else if Pos('received', SString[I]) <> 0 then begin
        // packets received
        RString := SplitString(SString[I], ' ');
        PrepRString();
        pResult^.NumReceived := RString[0].ToInteger();
      end else if Pos('loss', SString[I]) <> 0 then begin
        // packet loss
        RString := SplitString(SString[I], ' ');
        PrepRString();
        RString[0] := RString[0][1..High(RString[0]) - 1];
        pResult^.PacketLoss := RString[0].ToInteger() / 100;
      end else if Pos('time', SString[I]) <> 0 then begin
        // total time
        RString := SplitString(SString[I], ' ');
        PrepRString();
        ValString := StrTrimLeft(RString[High(RString)], ' ');
        pResult^.TotalTime := String(ValString[1..High(ValString) - 2]).ToInteger();
      end;
    end;

    { get time info }
    if pResult^.NumReceived > 0 then begin
      SString := SplitString(aStringList[FirstLine + 1], '=');
      SString[1] := StrTrimLeft(SString[1], ' ');
      RString := SplitString(SString[1], '/');
      pResult^.MinTime := RString[0].ToSingle();
      pResult^.AvgTime := RString[1].ToSingle();
      pResult^.MaxTime := RString[2].ToSingle();
      pResult^.Success := True;
      Result := 1;
    end;
  end;

function gemGetPageText(const aAddress: String): String;
var
HClient: TFPCustomHTTPClient;
  begin
    Initialize(Result);
    HClient := TFPCustomHTTPClient.Create(nil);

    while Result = '' do begin
      try
        Result := HClient.SimpleGet(aAddress);
      finally
      end;
    end;

    HClient.Free();
  end;

end.

