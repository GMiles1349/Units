unit gemnumbers;

{$mode ObjFPC}{$H+}
{$modeswitch advancedrecords}
{$packset 1}
{$packenum 1}
{$bitpacking on}

interface

uses
  Classes, SysUtils;

type

{$A1}
  TGEMByteBits = bitpacked record
    Bit0, Bit1, Bit2, Bit3, Bit4, Bit5, Bit6, Bit7: Boolean;
    procedure SetBit(const aIndex: Integer; const aValue: Boolean);
    procedure ToggleBit(const aIndex: Integer);
    function GetBit(const aIndex: Integer): Boolean;
  end;

  TGEMSimpleBits = record
    private
      fBytes: array of TGEMByteBits;
      function GetData(): PByte;
      function GetByte(const Index: Integer): Byte;
      function GetBit(const ByteIndex: Integer; const BitIndex: Integer): Byte;
      procedure SetByte(const Index: Integer; const Value: Byte);
      procedure SetBit(const ByteIndex: Integer; const BitIndex: Integer; const Value: Byte);
      function GetByteCount(): Integer;
      function GetBitCount(): Integer;
    public
      property Data: PByte read GetData;
      property Bytes[Index: Integer]: Byte read GetByte write SetByte;
      property Bits[ByteIndex: Integer; BitIndex: Integer]: Byte read GetBit write SetBit;
      property ByteCount: Integer read GetByteCount;
      property BitCount: Integer read GetBitCount;

      procedure MakeFrom(const aData: Pointer; const aSizeInBytes: Integer);
      procedure SetByteCount(const aCount: Integer);
      procedure AddHiByte(const aValue: Byte = 0);
      procedure AddLoByte(const aValue: Byte = 0);
      procedure InsertByte(const aIndex: Integer; const aValue: Byte = 0);
      procedure RemoveHiByte();
      procedure RemoveLoByte();
      procedure DeleteByte(const aIndex: Integer);
      procedure SwapBytes(const A,B: Integer);
      procedure SwapBits(const AByte, ABit, BByte, BBit: Integer);
      procedure Invert();
      procedure InvertByte(const aIndex: Integer);
      procedure Negate();
  end;

implementation

procedure TGEMByteBits.SetBit(const aIndex: Integer; const aValue: Boolean);
  begin
    case aIndex of
      0: Self.Bit0 := aValue;
      1: Self.Bit1 := aValue;
      2: Self.Bit2 := aValue;
      3: Self.Bit3 := aValue;
      4: Self.Bit4 := aValue;
      5: Self.Bit5 := aValue;
      6: Self.Bit6 := aValue;
      7: Self.Bit7 := aValue;
    end;
  end;

function TGEMByteBits.GetBit(const aIndex: Integer): Boolean;
  begin
    case aIndex of
      0: Exit(Self.Bit0);
      1: Exit(Self.Bit1);
      2: Exit(Self.Bit2);
      3: Exit(Self.Bit3);
      4: Exit(Self.Bit4);
      5: Exit(Self.Bit5);
      6: Exit(Self.Bit6);
      7: Exit(Self.Bit7);
    end;
  end;

procedure TGEMByteBits.ToggleBit(const aIndex: Integer);
  begin
    Self.SetBit(aIndex, not Self.GetBit(aIndex));
  end;

function TGEMSimpleBits.GetData(): PByte;
  begin
    Exit(PByte(@Self.fBytes[0]));
  end;

function TGEMSimpleBits.GetByte(const Index: Integer): Byte;
  begin
    Exit(PByte(@Self.fBytes[Index])^);
  end;

function TGEMSimpleBits.GetBit(const ByteIndex: Integer; const BitIndex: Integer): Byte;
  begin
    Exit(Self.fBytes[ByteIndex].GetBit(BitIndex).ToInteger());
  end;

procedure TGEMSimpleBits.SetByte(const Index: Integer; const Value: Byte);
  begin
    Move(Value, Self.fBytes[Index], 1);
  end;

procedure TGEMSimpleBits.SetBit(const ByteIndex: Integer; const BitIndex: Integer; const Value: Byte);
  begin
    Self.fBytes[ByteIndex].SetBit(BitIndex, (Value >= 1));
  end;

function TGEMSimpleBits.GetByteCount(): Integer;
  begin
    Exit(Length(Self.fBytes));
  end;

function TGEMSimpleBits.GetBitCount(): Integer;
  begin
    Exit(Length(Self.fBytes) * 8);
  end;

procedure TGEMSimpleBits.MakeFrom(const aData: Pointer; const aSizeInBytes: Integer);
  begin
    SetLength(Self.fBytes, aSizeInBytes);
    Move(aData^, Self.fBytes[0], aSizeInBytes);
  end;

procedure TGEMSimpleBits.SetByteCount(const aCount: Integer);   
  begin
    if aCount = 0 then Exit();
    SetLength(Self.fBytes, aCount);
  end;

procedure TGEMSimpleBits.AddHiByte(const aValue: Byte = 0);    
  begin
    SetLength(Self.fBytes, Self.ByteCount + 1);
    Move(Self.fBytes[0], Self.fBytes[1], Self.ByteCount - 1);
    Move(aValue, Self.fBytes[0], 1);
  end;

procedure TGEMSimpleBits.AddLoByte(const aValue: Byte = 0);    
  begin
    SetLength(Self.fBytes, Self.ByteCount + 1);
    Move(aValue, Self.fBytes[Self.ByteCount - 1], 1);
  end;

procedure TGEMSimpleBits.InsertByte(const aIndex: Integer; const aValue: Byte = 0);
  begin
    if aIndex = 0 then begin
      Self.AddHiByte(aValue);
      Exit();
    end;

    if aIndex = Self.ByteCount then begin
      Self.AddLoByte(aValue);
      Exit();
    end;

    SetLength(Self.fBytes, Self.ByteCount + 1);
    Move(Self.fBytes[aIndex], Self.fBytes[aIndex + 1], (Self.ByteCount - 1) - aIndex);
    Move(aValue, Self.fBytes[aIndex], 1);
  end;

procedure TGEMSimpleBits.RemoveHiByte();
  begin
    if Self.ByteCount = 1 then Exit();
    SetLength(Self.fBytes, Self.ByteCount - 1);
  end;

procedure TGEMSimpleBits.RemoveLoByte();
  begin
    if Self.ByteCount = 1 then Exit();
    Move(Self.fBytes[1], Self.fBytes[0], 1);
    SetLength(Self.fBytes, Self.ByteCount - 1);
  end;

procedure TGEMSimpleBits.DeleteByte(const aIndex: Integer);
  begin
    if Self.ByteCount = 1 then Exit();
    if aIndex = 0 then begin
      Self.RemoveLoByte();
      Exit();
    end;

    if aIndex = Self.ByteCount - 1 then begin
      Self.RemoveHiByte();
      Exit();
    end;

    Move(Self.fBytes[aIndex + 1], Self.fBytes[aIndex], (Self.ByteCount - 1) - aIndex);
    SetLength(Self.fBytes, Self.ByteCount - 1);
  end;

procedure TGEMSimpleBits.SwapBytes(const A,B: Integer);
var
Temp: Byte;
  begin
    Move(Self.fBytes[A], Temp, 1);
    Move(Self.fBytes[B], Self.fBytes[A], 1);
    Move(Temp, Self.fBytes[A], 1);
  end;

procedure TGEMSimpleBits.SwapBits(const AByte, ABit, BByte, BBit: Integer);
var
Temp: Boolean;
  begin
    Temp := Self.fBytes[AByte].GetBit(ABit);
    Self.fBytes[AByte].SetBit(ABit, Self.fBytes[BByte].GetBit(BBit));
    Self.fBytes[BByte].SetBit(BBit, Temp);
  end;

procedure TGEMSimpleBits.Invert();
var
I: Integer;
  begin
    for I := 0 to Self.ByteCount - 1 do begin
      PByte(@Self.fBytes[I])[0] := not PByte(@Self.fBytes[I])[0];
    end;
  end;

procedure TGEMSimpleBits.InvertByte(const aIndex: Integer);
var
Ptr: PByte;
  begin
    Ptr := @Self.fBytes[aIndex];
    Ptr[0] := not Ptr[0];
  end;

procedure TGEMSimpleBits.Negate();
var
I,Z: Integer;
  begin
    Self.Invert();

  end;

end.

