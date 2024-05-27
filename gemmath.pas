unit GEMMath;

{$ifdef FPC}
	{$mode ObjFPC}{$H+}
	{$modeswitch ADVANCEDRECORDS}
	{$INLINE ON}
	{$MACRO ON}

	{$IFOPT D+}
		{$DEFINE DEBUG_INLINE := }
	{$ELSE}
		{$DEFINE DEBUG_INLINE := inline;}
	{$ENDIF}

{$endif}

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
  function Rnd(Low: Single; High: Single): Single; overload;  DEBUG_INLINE
  function Rnd(High: Single = 1): Single; overload;  DEBUG_INLINE
  function PosOrNeg(): Integer;  DEBUG_INLINE
  procedure IncF(var X: Single; N: Single = 1);  DEBUG_INLINE
  procedure DecF(var X: Single; N: Single = 1);  DEBUG_INLINE
  procedure IncRange(var X: Integer; N: Integer; Low: Integer; High: Integer); overload;  DEBUG_INLINE
  procedure IncRange(var X: Single; N: Single; Low: Single; High: Single); overload;  DEBUG_INLINE
  function RoundF(X: Single): Integer;  DEBUG_INLINE
  function RoundUp(X: Single): Integer;  DEBUG_INLINE
  function Distance(X1,Y1,X2,Y2: Single): Single;  DEBUG_INLINE
  function Radians(ADegrees: Single): Single;  DEBUG_INLINE
  function Degrees(ARadians: Single): Single;  DEBUG_INLINE
  procedure ClampRadians(var ARadians: Single);  DEBUG_INLINE
  procedure ClampDegrees(var ADegrees: Single);  DEBUG_INLINE
  function Biggest(Values: specialize TArray<Single>): Single; DEBUG_INLINE
  function BiggestIndex(Values: specialize TArray<Single>): Integer;  DEBUG_INLINE
  function Smallest(Values: specialize TArray<Single>): Single;  DEBUG_INLINE
  function SmallestIndex(Values: specialize TArray<Single>): Integer;  DEBUG_INLINE
  function InRange(AValue: Single; ALow,AHigh: Single): Boolean;  DEBUG_INLINE
  procedure ClampRange(var AValue: Integer; ALow,AHigh: Integer); overload;  DEBUG_INLINE
  procedure ClampRange(var AValue: Single; ALow,AHigh: Single); overload;  DEBUG_INLINE
  function ZeroBelow(var AVar: Single; ALowLimit: Single): Boolean;  DEBUG_INLINE
  function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer;  DEBUG_INLINE
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
  function Point(X,Y: Single): TPoint; overload;  DEBUG_INLINE
  function AngularDiameter(AObjectSize, ADistToObject: Single): Single;  DEBUG_INLINE
  function Median(const aMin: Single = 0; const aMax: Single = 0): Single;

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
    Result := Low + (((High - Low) + 1) * Random);
  end;

function Rnd(High: Single = 1): Single;
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
    if ARadians > Pi then begin
      IncF(ARadians, -(Pi * 2));
    end;
    if ARadians < -Pi then begin
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

function RotateTo(ACurrentAngle, ATargetAngle: Single): Integer;  DEBUG_INLINE
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

end.
