unit gemrandom;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

  function gemRndLCG: Double; overload; inline;
  function gemRndLCG(const range: LongInt): LongInt; overload; inline;
  function gemRnd(): Single; overload; inline;
  function gemRnd(const aHigh: Single): Single; overload; inline;
  function gemRnd(const aLow, aHigh: Single): Single; overload;
  function Xorshift(): Uint64; inline;

implementation

const
  MaxLong: Int32 = High(Int32);
  MaxU64: Int64 = High(Int64);
  Modulus: UInt64 = 42949672960;
  Multiplier: UInt64 = 1664525;
  Increment: UInt64 = 1013904223;

var
  Seed: LongInt;
  ShuffleTable: Array [0..3] of UInt64;

function IM: Cardinal;
  begin
    //Seed := (Multiplier * Seed * Increment) mod Modulus;
    //Result := Seed;
    Result := Xorshift();
  end;

function gemRndLCG: Double; overload;
var
M: UInt64;
LowBits: PInteger;
  begin
    //Result := IM * 2.32830643653870e-10;
    M := IM;
    LowBits := @M;
    Result := LowBits[0] / MaxLong;
  end;

function gemRndLCG(const range: LongInt): LongInt; overload;
  begin
    Result := IM * range shr 32;
  end;

function gemRnd(): Single; overload;
  begin
    Result := gemRndLCG / MaxLong;
  end;

function gemRnd(const aHigh: Single): Single; overload;
  begin
    Result := aHigh * gemRndLCG;
  end;

function gemRnd(const aLow, aHigh: Single): Single; overload;
var
Range: Single;
  begin
    Range := 0;

    if aHigh >= 0 then begin
      Range := Range + aHigh;
      if aLow < 0 then begin
        Range := Range + Abs(aLow);
      end else begin
        Range := Range - aLow;
      end;

    end else begin
      Range := Range + Abs(aLow);
      if aHigh >= 0 then begin
        Range := Range + aHigh;
      end else begin
        Range := Range - aHigh;
      end;
    end;

    Result := aLow + (Range * gemRndLCG);
  end;

function Xorshift(): Uint64;
var
X, Y: UInt64;
  begin
    X := ShuffleTable[0];
	  Y := ShuffleTable[1];
	  ShuffleTable[0] := Y;
    X := X xor (X shl 23);
    X := X xor (X shr 17);
    X := X xor Y;
    ShuffleTable[1] := X + Y;
	  Exit(X);
  end;

initialization
  begin
    Randomize();
    Seed := Random(MaxLong);
    ShuffleTable[0] := trunc(MaxLong * Random());
    ShuffleTable[1] := trunc(MaxLong * Random());
    ShuffleTable[2] := trunc(MaxLong * Random());
    ShuffleTable[3] := trunc(MaxLong * Random());
  end;

end.

