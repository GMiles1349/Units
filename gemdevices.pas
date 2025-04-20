unit gemdevices;

{$ifdef linux}
  {$mode ObjFPC}{$H+}
  {$modeswitch advancedrecords}
{$endif}

{$ifdef windows}
  {$ifdef FPC}
    {$mode delphi}
  {$endif}
{$endif}

interface

uses
  Classes, Types, SysUtils, StrUtils;

type

  TGEMDeviceBitmask = record
    MaskLabel: String;
    Count: Integer;
    Bitmask: Array of Integer;
  end;

  PGEMLinuxDevice = ^TGEMLinuxDevice;
  TGEMLinuxDevice = record
    ID: String;
    Bus: String;
    Vendor: String;
    Product: String;
    Version: String;
    Name: String;
    Phys: String;
    Sysfs: String;
    Uniq: String;
    Handlers: Array of String;
    NumBitmasks: Integer;
    BitMasks: Array of TGEMDeviceBitmask;
  end;

  TGEMSystemDevice = record
    LinuxAttribs: TGEMLinuxDevice;
  end;

var
  Devices: Array of TGEMSystemDevice;

implementation

var
LineBuff: Array [0..29] of String;
LineCount: Integer;
DevCount: Integer;


procedure HandleBitMasks(const Attribs: PGEMLinuxDevice; const P: Integer);
var
DString: String;
SString: TStringDynArray;
Masks: TStringDynArray;
MaskLabel: String;
pMask: ^TGEMDeviceBitmask;
I: Integer;
  begin
    if LineBuff[P][1..3] <> 'B: ' then Exit();

    SetLength(SString, 0);
    SetLength(Masks, 0);

    DString := LineBuff[P][4..High(LineBuff[P])];
    SString := SplitString(DString, '=');

    if Pos(' ', SString[1]) <> 0 then begin
      Masks := SplitString(SString[1], ' ');
    end else begin
      SetLength(Masks,1);
      Masks[0] := SString[1];
    end;

    MaskLabel := SString[0];

    SetLength(Attribs^.BitMasks, Length(Attribs^.BitMasks) + 1);
    pMask := @Attribs^.BitMasks[Attribs^.NumBitmasks];

    pMask^.MaskLabel := MaskLabel;
    pMask^.Count := Length(Masks);
    Initialize(pMask^.Bitmask);
    SetLength(pMask^.Bitmask, pMask^.Count);

    for I := 0 to pMask^.Count - 1 do begin
      pMask^.Bitmask[I] := Masks[I].();
    end;

    Inc(Attribs^.NumBitmasks);
  end;

procedure AddNewDevice();
var
SString: TStringArray;
Attribs: ^TGEMLinuxDevice;
P: Integer;
I: Integer;
  begin
    Inc(DevCount);
    SetLength(Devices, DevCount);

    Attribs := @Devices[DevCount - 1].LinuxAttribs;

    // get bus, vendor, product, version, ID
    SString := SplitString(LineBuff[0], ' ');
    Attribs^.Bus := UpperCase(SplitString(SString[1], '=')[1]);
    Attribs^.Vendor := UpperCase(SplitString(SString[2], '=')[1]);
    Attribs^.Product := UpperCase(SplitString(SString[3], '=')[1]);
    Attribs^.Version := UpperCase(SplitString(SString[4], '=')[1]);
    Attribs^.ID := Attribs^.Bus + ':' + Attribs^.Vendor + ':' + Attribs^.Product + '.' + Attribs^.Version;

    // name
    P := Pos('=', LineBuff[1]);
    Attribs^.Name := LineBuff[1][P + 2 .. High(LineBuff[1]) - 1];

    // phys
    P := Pos('=', LineBuff[2]);
    Attribs^.Phys := LineBuff[2][P + 1 .. High(LineBuff[2])];

    // sysfs
    P := Pos('=', LineBuff[3]);
    Attribs^.Sysfs := LineBuff[3][P + 1 .. High(LineBuff[3])];

    // uniq
    P := Pos('=', LineBuff[4]);
    Attribs^.Uniq := LineBuff[4][P + 1 .. High(LineBuff[4])];

    // handlers
    SString := SplitString(LineBuff[5], '=');
    SString := SplitString(SString[1], ' ');

    I := High(SString);
    while I >= 0 do begin
      if SString[I] = '' then begin
        SetLength(SString, Length(SString) - 1);
        Dec(I);
      end else begin
        Break;
      end;
    end;

    Attribs^.Handlers := SString;

    // check for bitmasks
    Attribs^.NumBitmasks := 0;

    if LineCount > 6 then begin
      P := 6;

      while P < LineCount do begin
        HandleBitMasks(Attribs, P);
        Inc(P);
      end;
    end;
  end;

procedure ReadDevices();
var
InFile: TextFile;
ReadString: String;

const
Path: String = '/proc/bus/input/devices';
  begin
    DevCount := 0;

    AssignFile(InFile, Path);
    Reset(InFile);

    while not EOF(InFile) do begin
      LineCount := 0;
      ReadString := ' ';

      while ReadString <> '' do begin
        ReadLn(InFile, ReadString);
        LineBuff[LineCount] := ReadString;
        LineCount := LineCount + 1;
      end;

      LineCount := LineCount - 1;
      if LineCount = 0 then Break;

      AddNewDevice();

    end;

  end;

initialization
  begin
    ReadDevices();
  end;

end.

