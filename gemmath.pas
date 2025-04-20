unit GEMMath;

{$ifdef FPC}
	{$mode ObjFPC}{$H+}
	{$modeswitch ADVANCEDRECORDS}
	{$INLINE ON}
{$endif}

{$i gemoptimizations.Inc}

interface

uses
  {$ifndef FPC}
  System.SysUtils, System.Variants, System.VarConv, System.VarUtils,
  {$else}
  SysUtils, Variants, VarUtils,
  {$endif}
  Types, Classes, Math, GEMTypes;

  function ClampF(AValue: Single): Single;
  function ClampI(AValue: Single): Integer;
  function Rnd(Low: Single; High: Single): Single; overload;
  function Rnd(constref High: Single = 1): Single; overload;
  function PosOrNeg(): Integer;
  procedure IncF(var X: Single; N: Single = 1);
  procedure DecF(var X: Single; N: Single = 1);
  procedure IncRange(var X: Integer; N: Integer; Low: Integer; High: Integer); overload;
  procedure IncRange(var X: Single; N: Single; Low: Single; High: Single); overload;
  function RoundF(X: Single): Integer;
  function RoundUp(X: Single): Integer;
  function Distance(X1,Y1,X2,Y2: Single): Single;
  function Radians(ADegrees: Single): Single;
  function Degrees(ARadians: Single): Single;
  procedure ClampRadians(var ARadians: Single);
  procedure ClampDegrees(var ADegrees: Single);
  function Biggest(Values: specialize TArray<Single>): Single;
  function BiggestIndex(Values: specialize TArray<Single>): Integer;
  function Smallest(Values: specialize TArray<Single>): Single;
  function SmallestIndex(Values: specialize TArray<Single>): Integer;
  function InRange(AValue: Single; ALow,AHigh: Single): Boolean;
  procedure ClampRange(var AValue: Integer; ALow,AHigh: Integer); overload;
  procedure ClampRange(var AValue: Single; ALow,AHigh: Single); overload;
  function ZeroBelow(var AVar: Single; ALowLimit: Single): Boolean;
  function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer;
  procedure DeleteIndex(AArray: specialize TArray<Variant>; AIndex: Cardinal);
  procedure AssignConvert(var AOrgValue: Byte; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Integer; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Cardinal; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Single; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Double; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Int64; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: UInt64; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Char; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: String; const AAssignValue: Variant); overload;
  procedure AssignConvert(var AOrgValue: Boolean; const AAssignValue: Variant); overload;
  function Point(X,Y: Single): TPoint; overload;
  function AngularDiameter(AObjectSize, ADistToObject: Single): Single;
  function Median(const aMin: Single = 0; const aMax: Single = 0): Single;
  function OptimalTurn(CAngle,TAngle: Single): Integer;


const
  Pi2: Double = 6.28318530718;

implementation

function ClampF(AValue: Single): Single;
// clamp single to between 0 and 1 inclusive
  begin
    if AValue < 0 then Result := 0
    else if AValue > 1 then Result := 1
    else Result := AValue;
  end;

function ClampI(AValue: Single): Integer;
// clamp Integer to between 0 and 255 inclusive
  begin
    if AValue < 0 then Result := 0
    else if AValue > 255 then Result := 255
    else Result := trunc(AValue);
  end;


function Rnd(Low: Single; High: Single): Single;
// return random float between low and high inclusive
  begin
    Result := Low + (((High - Low)) * Random);
  end;

function Rnd(constref High: Single = 1): Single;
// return random float between 0 and high inclusive
  begin
    Result := (High * Random);
  end;

function PosOrNeg(): Integer;
  begin
    Result := Random(2);

    if Result = 0 then begin
      Result := -1;
    end;
  end;


procedure IncF(var X: Single; N: Single = 1);
  begin
    X := X + N;
  end;

procedure DecF(var X: Single; N: Single = 1);
  begin
    X := X - N;
  end;

procedure IncRange(var X: Integer; N: Integer; Low: Integer; High: Integer);
  begin
    X := X + N;

    if N > 0 then begin
      if X > High then X := Low + (X - High);
    end else begin
      if X < Low then X := High - (Low - X);
    end;
  end;

procedure IncRange(var X: Single; N: Single; Low: Single; High: Single);
  begin
    X := X + N;

    if N > 0 then begin
      if X > High then X := Low + (X - High);
    end else begin
      if X < Low then X := High - (Low - X);
    end;
  end;

function RoundF(X: Single): Integer;
var
Rem: Single;
  begin
    Rem := X - trunc(X);

    if Rem < 0.5 then begin
      Result := trunc(X);
    end else begin
      Result := trunc(X) + 1;
    end;
  end;

function RoundUp(X: Single): Integer;
var
Rem: Single;
  begin
    Rem := X - trunc(X);
    if Rem = 0 then begin
      Result := trunc(X);
    end else begin
      Result := trunc(X) + 1;
    end;
  end;

function Distance(X1,Y1,X2,Y2: Single): Single;
  begin
    Result := Sqrt( ((X1 - X2) * (X1 - X2)) + ((Y1 - Y2) * (Y1 - Y2)) );
  end;

function Radians(ADegrees: Single): Single;
  begin
    Result := ADegrees * (pi / 180);
  end;

function Degrees(ARadians: Single): Single;
  begin
    Result := ARadians * (180 / pi);
  end;

procedure ClampRadians(var ARadians: Single);
  begin
    if ARadians > Pi * 2 then begin
      IncF(ARadians, -(Pi * 2));
    end;
    if ARadians < 0 then begin
      IncF(ARadians, (Pi * 2));
    end;
  end;

procedure ClampDegrees(var ADegrees: Single);
  begin
    if ADegrees > 360 then begin
      IncF(ADegrees, 360);
    end;
    if ADegrees < 0 then begin
      IncF(ADegrees, 360);
    end;
  end;


function Biggest(Values: specialize TArray<Single>): Single;
var
I: Integer;
  begin
    Result := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] > Result then begin
        Result := Values[i];
      end;
    end;
  end;

function BiggestIndex(Values: specialize TArray<Single>): Integer;
var
I: Integer;
B: Single;
  begin
    Result := 0;
    B := 0;
    for I := 1 to High(Values) do begin
      if Values[i] > B then begin
        B := Values[i];
        Result := I;
      end;
    end;
  end;

function Smallest(Values: specialize TArray<Single>): Single;
var
I: Integer;
  begin
    Result := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] < Result then begin
        Result := Values[i];
      end;
    end;
  end;

function SmallestIndex(Values: specialize TArray<Single>): Integer;
var
I: Integer;
B: Single;
  begin
    Result := 0;
    B := Values[0];
    for I := 1 to High(Values) do begin
      if Values[i] < B then begin
        B := Values[i];
        Result := I;
      end;
    end;
  end;

function InRange(AValue: Single; ALow,AHigh: Single): Boolean;
  begin
    result := False;
    if (AValue >= ALow) and (AValue <= AHigh) then begin
      Result := True;
    end;
  end;

procedure ClampRange(var AValue: Integer; ALow,AHigh: Integer);
  begin
    if AValue < ALow then AValue := ALow;
    if AValue > AHigh then AValue := AHigh;
  end;

procedure ClampRange(var AValue: Single; ALow,AHigh: Single);
  begin
    if AValue < ALow then AValue := ALow;
    if AValue > AHigh then AValue := AHigh;
  end;

function ZeroBelow(var AVar: Single; ALowLimit: Single): Boolean;
  begin
    Result := False;
    if AVar < ALowLimit then begin
      AVar := 0;
      Exit(True);
    end;
  end;

function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer;
var
a,b,c,d: Single;
  begin
    a := ATargetAngle - ACurrentAngle;
    b := ATargetAngle - ACurrentAngle + (Pi * 2);
    c := ATargetAngle - ACurrentAngle - (Pi * 2);

    if (abs(a) < abs(b)) and (abs(a) < abs(c)) then begin
      Result := sign(a);
    end else if (abs(b) < abs(a)) and (abs(b) < abs(c)) then begin
      Result := sign(b);
    end else begin
      Result := sign(c);
    end;

  end;

procedure DeleteIndex(AArray: specialize TArray<Variant>; AIndex: Cardinal);
var
I: Integer;
  begin
    if AIndex > Cardinal(High(AArray)) then Exit;

    For I := AIndex to High(AArray) - 1 do begin
      AArray[i] := AArray[i + 1];
    end;

    SetLength(AArray, length(AArray) - 1);
  end;


procedure AssignConvert(var AOrgValue: Byte; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Integer; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Cardinal; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Single; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Double; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Int64; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: UInt64; const AAssignValue: Variant);
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := 0;
    end;
  end;

procedure AssignConvert(var AOrgValue: Char; const AAssignValue: Variant);
  begin
    try
      AOrgValue := VariantToAnsiString(TVarData(AAssignValue)).ToCharArray[0];
    except
      AorgValue := Char(0);
    end;
  end;

procedure AssignConvert(var AOrgValue: String; const AAssignValue: Variant);
  begin
    try
      AOrgValue := String(AAssignValue);
    except
      AorgValue := '';
    end;
  end;

procedure AssignConvert(var AOrgValue: Boolean; const AAssignValue: Variant); overload;
  begin
    try
      AOrgValue := AAssignValue;
    except
      AorgValue := False;
    end;
  end;

function Point(X,Y: Single): TPoint;
  begin
    Result.X := trunc(X);
    Result.Y := trunc(Y);
  end;

function AngularDiameter(AObjectSize, ADistToObject: Single): Single;
  begin
    Result := Degrees(2 * ArcTan(AObjectSize / (2 * ADistToObject)));
  end;

function Median(const aMin: Single = 0; const aMax: Single = 0): Single;
var
Range: Single;
	begin
  	Range := aMax - aMin;
    Exit(aMin + (Range / 2));
  end;

function OptimalTurn(CAngle,TAngle: Single): Integer;
var
A,B,C,D: Double;
  begin
    ClampRadians(CAngle);
    ClampRadians(TAngle);

    A := TAngle - CAngle;
    B := TAngle - CAngle + (Pi * 2);
    C := TAngle - CAngle - (Pi * 2);

    if (abs(A) < abs(B)) and (abs(A) < abs(C)) then D := A;
    if (abs(B) < abs(A)) and (abs(B) < abs(C)) then D := B;
    if (abs(C) < abs(A)) and (abs(C) < abs(B)) then D := C;

    if D > 0 Then Result := 1;
    if D < 0 Then Result := -1;
    if D = 0 Then Result := 0;
  end;

end.
