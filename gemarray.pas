unit GEMArray;

{$mode Delphi}{$H+}
{$modeswitch ADVANCEDRECORDS}
{$modeswitch ALLOWINLINE}
{$modeswitch AUTODEREF}
{$modeswitch OUT}

{$varpropsetter ON}

{$i gemoptimizations.Inc}

interface

uses
  Classes, SysUtils;

type

  TGEMArray<T> = record
    type TPointer = ^T;

		private
      fTypeSize: Cardinal;
    	fElement: Array of T;
      fReserved: UInt64;
      fSize: UInt64;
      fHigh: Int64;

      // getters/setters
      function GetElement(const Index: UInt64): T;
      function GetData(const Index: UInt64): TPointer;
      procedure SetElement(const Index: UInt64; Value: T);

      // under the hood resizing and checking
      procedure UpdateLength(const IncBy: Int64); //

    public
      property Element[Index: UInt64]: T read GetElement write SetElement; default;
      property Data[Index: UInt64]: TPointer read GetData;
      property Reserved: UInt64 read fReserved;
      property Size: UInt64 read fSize;
      property High: Int64 read fHigh;

      class operator Initialize(var Dest: TGEMArray<T>);
      class operator :=(var aArray: TArray<T>): TGEMArray<T>; overload;
      class operator :=(var aArray: TGEMArray<T>): TArray<T>; overload;

      // queries
      function GetSizeMem(): UInt64;
      function GetReservedMem(): UInt64;

      function Copy(): TArray<T>;

      // sizing
      procedure Reserve(const ResLength: UInt64);
      procedure SetSize(const aSize: UInt64);
      procedure Shrink();

      // pushing
      procedure PushBack(); overload;
      procedure PushBack(const Value: T); overload;
      procedure PushBack(const Values: TArray<T>); overload;
      procedure PushFront(const Value: T); overload;
      procedure PushFront(const Values: TArray<T>); overload;
      procedure Insert(const Value: T; const Index: UInt64); overload;
      procedure Insert(const Values: TArray<T>; const Index: UInt64); overload;

      // popping
      procedure PopBack(); overload;
      procedure PopBack(const Count: UInt64); overload;
      procedure PopFront(); overload;
      procedure PopFront(const Count: UInt64); overload;

      // search
      function Count(const Value: T): UInt64; overload;
      function FindFirst(const Value: T): Int64; overload;
      function FindLast(const Value: T): Int64; overload;
      function FindAll(const Value: T): TArray<UInt64>; overload;

      function Replace(const Value: T; const NewValue: T): UInt64; overload;
      function Replace(const NewValue: T; const Indices: TArray<UInt64>): UInt64; overload;

      function DeleteFirst(const Value: T): UInt64; overload;
      function DeleteLast(const Value: T): UInt64; overload;
      function DeleteAll(const Value: T): UInt64; overload;

  end;

  procedure Push(var Arr: TArray<UInt8>; const Value: UInt8); register; overload;
  procedure Push(var Arr: TArray<UInt16>; const Value: UInt16); register; overload;
  procedure Push(var Arr: TArray<UInt32>; const Value: UInt32); register; overload;
  procedure Push(var Arr: TArray<UInt64>; const Value: UInt64); register; overload;
  procedure Push(var Arr: TArray<Int8>; const Value: Int8); register; overload;
  procedure Push(var Arr: TArray<Int16>; const Value: Int16); register; overload;
  procedure Push(var Arr: TArray<Int32>; const Value: Int32); register; overload;
  procedure Push(var Arr: TArray<Int64>; const Value: Int64); register; overload;
  procedure Push(var Arr: TArray<Single>; const Value: Single); register; overload;
  procedure Push(var Arr: TArray<Double>; const Value: Double); register; overload;

  procedure PushFront(var Arr: TArray<UInt8>; const Value: UInt8); register; overload;
  procedure PushFront(var Arr: TArray<UInt16>; const Value: UInt16); register; overload;
  procedure PushFront(var Arr: TArray<UInt32>; const Value: UInt32); register; overload;
  procedure PushFront(var Arr: TArray<UInt64>; const Value: UInt64); register; overload;
  procedure PushFront(var Arr: TArray<Int8>; const Value: Int8); register; overload;
  procedure PushFront(var Arr: TArray<Int16>; const Value: Int16); register; overload;
  procedure PushFront(var Arr: TArray<Int32>; const Value: Int32); register; overload;
  procedure PushFront(var Arr: TArray<Int64>; const Value: Int64); register; overload;
  procedure PushFront(var Arr: TArray<Single>; const Value: Single); register; overload;
  procedure PushFront(var Arr: TArray<Double>; const Value: Double); register; overload;

  procedure Pop(var Arr: TArray<UInt8>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<UInt16>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<UInt32>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<UInt64>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Int8>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Int16>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Int32>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Int64>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Single>; const Count: UInt64 = 1); register; overload;
  procedure Pop(var Arr: TArray<Double>; const Count: UInt64 = 1); register; overload;

  procedure PopFront(var Arr: TArray<UInt8>; const Count: UInt64 =1); register; overload;
  procedure PopFront(var Arr: TArray<UInt16>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<UInt32>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<UInt64>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Int8>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Int16>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Int32>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Int64>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Single>; const Count: UInt64 = 1); register; overload;
  procedure PopFront(var Arr: TArray<Double>; const Count: UInt64 = 1); register; overload;

  procedure ArrCom(var Dest: TArray<UInt8>; constref Source: TArray<UInt8>); overload;
  procedure ArrCom(var Dest: TArray<UInt16>; constref Source: TArray<UInt16>); overload;
  procedure ArrCom(var Dest: TArray<UInt32>; constref Source: TArray<UInt32>); overload;
  procedure ArrCom(var Dest: TArray<UInt64>; constref Source: TArray<UInt64>); overload;
  procedure ArrCom(var Dest: TArray<Int8>; constref Source: TArray<Int8>); overload;
  procedure ArrCom(var Dest: TArray<Int16>; constref Source: TArray<Int16>); overload;
  procedure ArrCom(var Dest: TArray<Int32>; constref Source: TArray<Int32>); overload;
  procedure ArrCom(var Dest: TArray<Int64>; constref Source: TArray<Int64>); overload;
  procedure ArrCom(var Dest: TArray<Single>; constref Source: TArray<Single>); overload;
  procedure ArrCom(var Dest: TArray<Double>; constref Source: TArray<Double>); overload;

implementation

procedure Push(var Arr: TArray<UInt8>; const Value: UInt8);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<UInt16>; const Value: UInt16);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<UInt32>; const Value: UInt32);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<UInt64>; const Value: UInt64);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Int8>; const Value: Int8);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Int16>; const Value: Int16);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Int32>; const Value: Int32);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Int64>; const Value: Int64);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Single>; const Value: Single);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure Push(var Arr: TArray<Double>; const Value: Double);
	begin
    SetLength(Arr, Length(Arr) + 1);
    Arr[High(Arr)] := Value;
  end;

procedure PushFront(var Arr: TArray<UInt8>; const Value: UInt8);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<UInt16>; const Value: UInt16);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<UInt32>; const Value: UInt32);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<UInt64>; const Value: UInt64);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Int8>; const Value: Int8);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Int16>; const Value: Int16);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Int32>; const Value: Int32);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Int64>; const Value: Int64);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Single>; const Value: Single);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure PushFront(var Arr: TArray<Double>; const Value: Double);
var
S: UInt64;
	begin
    S := Length(Arr);
  	SetLength(Arr, Length(Arr) + 1);
    Move(Arr[0], Arr[1], S * SizeOf(Value));
    Arr[0] := Value;
  end;

procedure Pop(var Arr: TArray<UInt8>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<UInt16>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<UInt32>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<UInt64>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Int8>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Int16>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Int32>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Int64>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Single>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure Pop(var Arr: TArray<Double>; const Count: UInt64 = 1);
	begin
  	SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<UInt8>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<UInt16>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<UInt32>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<UInt64>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Int8>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Int16>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Int32>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Int64>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Single>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure PopFront(var Arr: TArray<Double>; const Count: UInt64 = 1);
var
S: Integer;
	begin
  	S := Length(Arr) - Count;
    Move(Arr[Count], Arr[0], S * SizeOf(Arr[0]));
    SetLength(Arr, Length(Arr) - Count);
  end;

procedure ArrCom(var Dest: TArray<UInt8>; constref Source: TArray<UInt8>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<UInt16>; constref Source: TArray<UInt16>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<UInt32>; constref Source: TArray<UInt32>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<UInt64>; constref Source: TArray<UInt64>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Int8>; constref Source: TArray<Int8>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Int16>; constref Source: TArray<Int16>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Int32>; constref Source: TArray<Int32>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Int64>; constref Source: TArray<Int64>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Single>; constref Source: TArray<Single>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

procedure ArrCom(var Dest: TArray<Double>; constref Source: TArray<Double>);
var
DSize, SSize: Int64;
	begin
  	DSize := Length(Dest);
    SSize := Length(Source);
    SetLength(Dest, DSize + SSize);
    Move(Source[0], Dest[DSize + 1], SSize * SizeOf(Dest[0]));
  end;

class operator TGEMArray<T>.Initialize(var Dest: TGEMArray<T>);
	begin
  	Dest.fTypeSize := SizeOf(T);
    Initialize(Dest.fElement);
    Dest.fReserved := 0;
    Dest.fSize := 0;
    Dest.fHigh := -1;
  end;

class operator TGEMArray<T>.:=(var aArray: TArray<T>): TGEMArray<T>;
  begin
    Result.fTypeSize := SizeOf(T);
    Initialize(Result.fElement);
    Result.Reserve(Length(aArray) * 2);
    Result.fSize := Length(aArray);
    Result.fHigh := Result.fSize - 1;
    Move(aArray[0], Result.fElement[0], Result.fTypeSize * Result.fSize);
  end;

class operator TGEMArray<T>.:=(var aArray: TGEMArray<T>): TArray<T>;
  begin

  end;

function TGEMArray<T>.GetElement(const Index: UInt64): T;
	begin
    Exit(Self.fElement[Index]);
  end;

function TGEMArray<T>.GetData(const Index: UInt64): TPointer;
  begin
    Result := nil;
    if Index <= Self.fHigh then begin
      Result := TPointer(@Self.fElement[Index]);
    end;
  end;

procedure TGEMArray<T>.SetElement(const Index: UInt64; Value: T);
	begin
  	Self.fElement[Index] := Value;
  end;

procedure TGEMArray<T>.UpdateLength(const IncBy: Int64);
	begin
    // change length by IncBy
  	if Self.fSize + IncBy < 0 then begin
      Self.fSize := 0;
      Self.fHigh := -1;
    end else begin
      Self.fSize := Self.fSize + IncBy;
      Self.fHigh := Int64(Self.fSize) - 1;
    end;

    // just exit on no resize needed
    if Self.fSize <= Self.fReserved then begin
      Exit();
    end;

    // double the size of reserved length and resize elements
    if Self.fReserved = 0 then begin
      Self.fReserved := Self.fSize;
    end;

    Self.fReserved := Self.fReserved * 2;
    if Self.fReserved < Self.fSize then begin
      Self.fReserved := Self.fSize * 2;
    end;

    SetLength(Self.fElement, Self.fReserved);
  end;

function TGEMArray<T>.GetSizeMem(): UInt64;
	begin
  	Exit(Self.fSize * Self.fTypeSize);
  end;

function TGEMArray<T>.GetReservedMem(): UInt64;
	begin
 		Exit(Self.fReserved * Self.fTypeSize);
  end;

function TGEMArray<T>.Copy(): TArray<T>;
	begin
    Initialize(Result);
		SetLength(Result, Self.fSize);
    Move(Self.fElement[0], Result[0], Self.fTypeSize * Self.fSize);
  end;

procedure TGEMArray<T>.Reserve(const ResLength: UInt64);
	begin
  	Self.fReserved := ResLength;
    SetLength(Self.fElement, Self.fReserved);
    if Self.fReserved < Self.fSize then begin
      Self.UpdateLength(Self.fSize - Self.fReserved);
    end;
  end;

procedure TGEMArray<T>.SetSize(const aSize: UInt64);
	begin
  	Self.UpdateLength(aSize - Self.fSize);
  end;

procedure TGEMArray<T>.Shrink();
	begin
    Self.fReserved := Self.fSize;
    Self.fHigh := Self.fSize - 1;
    SetLength(Self.fElement, Self.fSize);
  end;

procedure TGEMArray<T>.PushBack(); overload;
  begin
    Self.UpdateLength(1);
  end;

procedure TGEMArray<T>.PushBack(const Value: T);
	begin
    Self.UpdateLength(1);
    Self.fElement[Self.fHigh] := Value;
  end;

procedure TGEMArray<T>.PushBack(const Values: TArray<T>);
	begin
    Self.UpdateLength(Length(Values));
    Move(Values[0], Self.fElement[Self.fSize - Length(Values)], Self.fTypeSize * Length(Values));
  end;

procedure TGEMArray<T>.PushFront(const Value: T);
var
I: Integer;
	begin

    // just push to back if length is 0
  	if Self.fSize = 0 then begin
      Self.PushBack(Value);
      Exit();
    end;

    Self.UpdateLength(1);

    // move all element values up 1 index
    I := Self.fHigh;
    while I >= 1 do begin
			Self.fElement[I] := Self.fElement[I - 1];
      I := I - 1;
    end;

    Self.fElement[0] := Value;
  end;

procedure TGEMArray<T>.PushFront(const Values: TArray<T>);
var
O: UInt64;
L: UInt64;
	begin

    if Self.fSize = 0 then begin
      Self.PushBack(Values);
      Exit();
    end;

    O := Self.fSize;
    L := Length(Values);
    Self.UpdateLength(L);
    Move(Self.fElement[0], Self.fElement[L], Self.fTypeSize * O);
    Move(Values[0], Self.fElement[0], Self.fTypeSize * L);

  end;

procedure TGEMArray<T>.Insert(const Value: T; const Index: UInt64);
var
MLen: UInt64;
	begin
    Self.UpdateLength(1);
    MLen := Self.fSize - Index;
    Move(Self.fElement[Index], Self.fElement[Index + 1], MLen * Self.fTypeSize);
    Self.fElement[Index] := Value;
  end;

procedure TGEMArray<T>.Insert(const Values: TArray<T>; const Index: UInt64);
var
MLen: UInt64;
	begin
    Self.UpdateLength(Length(Values));
    MLen := Self.fSize - Index;
    Move(Self.fElement[Index], Self.fElement[Index + System.High(Values)], MLen * Self.fTypeSize);
    Move(Values[0], Self.fElement[Index], Length(Values) * Self.fTypeSize);
  end;

procedure TGEMArray<T>.PopBack();
	begin
  	Self.UpdateLength(-1);
  end;

procedure TGEMArray<T>.PopBack(const Count: UInt64);
	begin
  	Self.UpdateLength(-Count);
  end;

procedure TGEMArray<T>.PopFront();
var
I: Integer;
	begin
  	// if length is 1 then just pop back
    if Self.fSize = 1 then begin
      Self.PopBack();
      Exit();
    end;

    // move all element values down 1 index
    for I := 0 to Self.fHigh - 1 do begin
			Self.fElement[I] := Self.fElement[I + 1];
    end;

    Self.UpdateLength(-1);
  end;

procedure TGEMArray<T>.PopFront(const Count: UInt64);
	begin
  	Move(Self.fElement[Count], Self.fElement[0], Self.fTypeSize * (Self.fSize - Count));
    Self.UpdateLength(-Count);
  end;

function TGEMArray<T>.Count(const Value: T): UInt64;
var
I: Integer;
	begin
  	Result := 0;
		for I := 0 to Self.fHigh do begin
      if Self.fElement[I] = Value then Result := Result + 1;
    end;
  end;

function TGEMArray<T>.FindFirst(const Value: T): Int64;
var
I: Integer;
	begin
    Result := -1;
    for I := 0 to Self.fHigh do begin
      if Self.fElement[I] = Value then begin
        Result := I;
        Exit();
      end;
    end;
  end;

function TGEMArray<T>.FindLast(const Value: T): Int64;
var
I: Integer;
	begin
    Result := -1;
    I := Self.fHigh;
    while I >= 0 do begin
      if Self.fElement[I] = Value then begin
        Result := I;
        Exit();
      end;
      I := I - 1;
    end;
  end;

function TGEMArray<T>.FindAll(const Value: T): TArray<UInt64>;
var
I: Integer;
C: UInt64;
	begin
    SetLength(Result, Self.fSize);
    C := 0;

    for I := 0 to Self.fHigh do begin
      if Self.fElement[I] = Value then begin
        Result[C] := I;
        C := C + 1;
      end;
    end;

    if C = 0 then begin
      SetLength(Result, 0);
    end else begin
      SetLength(Result, C);
    end;
  end;

function TGEMArray<T>.Replace(const Value: T; const NewValue: T): UInt64;
var
Ret: Array of UInt64;
I: Integer;
	begin
    Ret := Self.FindAll(Value);
    for I := 0 to System.High(Ret) do begin
      Self.fElement[Ret[I]] := NewValue;
    end;
   	Exit(Length(Ret));
  end;

function TGEMArray<T>.Replace(const NewValue: T; const Indices: TArray<UInt64>): UInt64;
var
I: Integer;
	begin
    for  I := 0 to System.High(Indices) do begin
      Self.fElement[Indices[I]] := NewValue;
    end;
    Exit(0);
  end;

function TGEMArray<T>.DeleteFirst(const Value: T): UInt64;
var
C: Integer;
MSize: UInt64;
	begin
  	C := Self.FindFirst(Value);
    if C = -1 then Exit(0);

    MSize := (Self.fSize - C) * Self.fTypeSize;
    Move(Self.fElement[C+1], Self.fElement[C], MSize);
    Self.UpdateLength(-1);
    Exit(1);
  end;

function TGEMArray<T>.DeleteLast(const Value: T): UInt64;
var
C: Integer;
MSize: UInt64;
	begin
  	C := Self.FindLast(Value);
    if C = -1 then Exit(0);

    MSize := (Self.fSize - C) * Self.fTypeSize;
    Move(Self.fElement[C+1], Self.fElement[C], MSize);
    Self.UpdateLength(-1);
    Exit(1);
  end;

function TGEMArray<T>.DeleteAll(const Value: T): UInt64;
// Delete indicies that match Value
// Only move what needs to be moved
var
Ret: Array of UInt64;
C: Integer;
I: Integer;
RLow, RHigh, LastHigh: UInt64;
MLen, MSize: UInt64;
	begin

    Ret := Self.FindAll(Value);
    C := Length(Ret);
    if C = 0 then Exit(0);

    LastHigh := Ret[0];

    for I := 0 to C - 1 do begin
    	if I = C - 1 then begin
        RLow := Ret[I] + 1;
        RHigh := Self.fHigh;
      end else begin
        RLow := Ret[I] + 1;
        RHigh := Ret[I + 1] - 1;
      end;

      MLen := (RHigh - RLow) + 1;
      MSize := MLen * Self.fTypeSize;

      Move(Self.fElement[RLow], Self.fElement[LastHigh], MSize);

      LastHigh := LastHigh + MLen;

    end;

    Self.UpdateLength(-C);
    Exit(C);


  end;

end.

