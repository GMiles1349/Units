unit GEMBitField;

{$mode ObjFPC}{$H+}
{$modeswitch ADVANCEDRECORDS}

interface

uses
  Classes, SysUtils;

type

  PGEMBinary = ^TGEMBinary;
  TGEMBinary = 0..1;
  TGEMByteBits = Bitpacked Array [0..7] of TGEMBinary;

  TGEMBitField = packed record
    private
    	fData: Array of TGEMByteBits;
      fPosition: Int32;
      fBytePos, fBitPos: Int32;

    	function GetData(const Index: UInt64): TGEMBinary; inline;
      procedure SetData(const Index: UInt64; const Value: TGEMBinary); inline;

      function GetBits(): UInt32; inline;
      function GetBytes(): UInt32; inline;
      function GetPtr(): PByte; inline;

    public
    	property Ptr: PByte read GetPtr;
    	property Data[Index: UInt64]: TGEMBinary read GetData write SetData; default;
      property Bits: UInt32 read GetBits;
      property Bytes: UInt32 read GetBytes;
      property Position: Int32 read fPosition;

      class operator Initialize(var Dest: TGEMBitField);
      class operator Finalize(var Dest: TGEMBitField);

      class operator := (const A: Byte): TGEMBitField; inline;
      class operator := (const A: Array of Byte): TGEMBitField; inline;

      procedure SetSize(const SizeInBits: UInt64); inline;
      procedure SetAllOff(); inline;
      procedure SetAllOn(); inline;
      function CountOff(): UInt32; inline;
      function CountOn(): UInt32; inline;
      procedure CopyBits(const Source: Pointer; const SizeInBytes: UInt32); inline;
      procedure SetPosition(const aPosition: Uint32); inline;
      procedure GoNext(); inline;

      function ReadCurrent(): TGEMBinary;
      function ReadNext(): TGEMBinary; inline;

  end;

implementation

class operator TGEMBitField.Initialize(var Dest: TGEMBitField);
	begin
    Dest.fData := nil;
    Dest.fPosition := -1;
  end;

class operator TGEMBitField.Finalize(var Dest: TGEMBitField);
	begin
  	Finalize(Dest.fData);
  end;

class operator TGEMBitField.:= (const A: Byte): TGEMBitField;
var
I: Integer;
	begin
    Initialize(Result);
   	Result.SetSize(8);
    Move(A, Result.fData[0], 1);
  end;

class operator TGEMBitField.:= (const A: Array of Byte): TGEMBitField;
var
I: Integer;
	begin
  	Initialize(Result);
		Result.SetSize(Length(A) * 8);
    Move(A[0], Result.fData[0], Length(A));
  end;

function TGEMBitField.GetData(const Index: UInt64): TGEMBinary;
var
I, M: Integer;
	begin
    I := trunc(Index / 8);
    M := Index mod 8;
    Result := Self.fData[I,M];
  end;

procedure TGEMBitField.SetData(const Index: UInt64; const Value: TGEMBinary);
var
I, M: Integer;
	begin
    I := trunc(Index / 8);
    M := Index mod 8;
    Self.fData[I,M] := Value;
  end;

function TGEMBitField.GetBits(): UInt32;
	begin
  	Exit(Length(Self.fData) * 8);
  end;

function TGEMBitField.GetBytes(): UInt32;
	begin
  	Exit(Length(Self.fData));
  end;

function TGEMBitField.GetPtr(): PByte;
	begin
  	Exit(PByte(@Self.fData[0]));
  end;

procedure TGEMBitField.SetSize(const SizeInBits: UInt64);
var
Len: UInt64;
Rem: UInt64;
	begin
		Rem := SizeInBits mod 8;
    Len := trunc(SizeInBits / 8);
    if Rem <> 0 then Len := Len + 1;

    SetLength(Self.fData, Len);
  end;

procedure TGEMBitField.SetAllOff();
	begin
    if Self.Bytes = 0 then Exit();
    FillByte(Self.fData[0], Self.Bytes, 0);
  end;

procedure TGEMBitField.SetAllOn();
	begin
    if Self.Bytes = 0 then Exit();
    FillByte(Self.fData[0], Self.Bytes, 255);
  end;

function TGEMBitField.CountOff(): UInt32;
var
I: Integer;
	begin
		if Self.Bytes = 0 then Exit(0);
    Result := Self.Bits;
    for I := 0 to Self.Bits - 1 do begin
    	Result := Result - Self[I];
    end;
  end;

function TGEMBitField.CountOn(): UInt32;
var
I: Integer;
	begin
		if Self.Bytes = 0 then Exit(0);
    Result := 0;
    for I := 0 to Self.Bits - 1 do begin
			Result := Result + Self[I];
    end;
  end;

procedure TGEMBitField.CopyBits(const Source: Pointer; const SizeInBytes: UInt32);
	begin
    Self.SetSize(SizeInBytes * 8);
    Move(PByte(Source)[0], Self.fData[0], SizeInBytes);
  end;

procedure TGEMBitField.SetPosition(const aPosition: UInt32);
	begin
  	Self.fPosition := aPosition;
    //if Self.fPosition >= Self.Bits then Self.fPosition := Self.Bits - 1;
    //Self.fBytePos := trunc(Self.fPosition / 8);
    //Self.fBitPos := Self.fPosition mod 8;
  end;

procedure TGEMBitField.GoNext();
	begin
    Self.fPosition := Self.fPosition + 1;
    Self.fBitPos := Self.fBitPos + 1;
    Self.fBytePos := Self.fBytePos + ((Self.fBitPos shr 3) and 1);
    Self.fBitPos := Self.fBitPos * ((Self.fBitPos shr 3) xor 1);
  end;

function TGEMBitField.ReadCurrent(): TGEMBinary;
	begin
  	Result := ((PByte(@Self.fData[0])[Self.fBytePos] shr Self.fBitPos) and 1);
    Self.fPosition := Self.fPosition + 1;
    Self.fBytePos := Self.fBytePos + ((Self.fBitPos + 1 shr 3) and 1);
    Self.fBitPos := Self.fBitPos * ((Self.fBitPos shr 3) xor 1);
  end;

function TGEMBitField.ReadNext(): TGEMBinary;
	begin
    Self.fPosition := Self.fPosition + 1;
    Self.fBitPos := Self.fBitPos + 1;
    if Self.fBitPos >= 8 then begin
    	Self.fBitPos := 0;
      Self.fBytePos := Self.fBytePos + 1;
    end;
    Result := ((PByte(@Self.fData[0])[Self.fBytePos] shr Self.fBitPos) and 1);
  end;

end.

