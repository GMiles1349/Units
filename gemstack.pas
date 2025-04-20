unit gemstack;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
   TGEMStack<T> = record
    type TPointer = ^T;

    private
      fItem: TArray<T>;
      fCount: Integer;
      fMaxCount: Integer;
      fShrinkOnPop: Boolean;

      function GetItem(const Index: Cardinal): T;
      function GetTopItem(): T;
      procedure SetMaxCount(const aMaxCount: Integer);
      procedure AddItem(const aItem: T);
      procedure SetShrinkOnPop(const aShrink: Boolean);

    public
      property Item[Index: Cardinal]: T read GetItem;
      property Top: T read GetTopItem;
      property Count: Integer read fCount;
      property MaxCount: Integer read fMaxCount write SetMaxCount;
      property ShrinkOnPop: Boolean read fShrinkOnPop write SetShrinkOnPop;

      class operator Initialize(var dest: TGEMStack<T>);

      function Push(const aItem: T): Integer; overload;
      function Push(const aItem: TArray<T>): Integer; overload;
      function Pop(): T;
      procedure Clear();
      procedure Shrink();
      function GetStack(pCount: PInteger = nil): TArray<T>;
  end;

implementation

class operator TGEMStack<T>.Initialize(var dest: TGEMStack<T>);
  begin
    dest.fCount := 0;
    dest.fMaxCount := 0;
    dest.fShrinkOnPop := False;
    Initialize(dest.fItem);
  end;

function TGEMStack<T>.GetItem(const Index: Cardinal): T;
  begin
    Exit(Self.fItem[Index]);
  end;

function TGEMStack<T>.GetTopItem(): T;
  begin
    Initialize(Result);
    if Self.fCount <> 0 then begin
      Exit(Self.fItem[Self.fCount - 1]);
    end;
  end;

procedure TGEMStack<T>.SetMaxCount(const aMaxCount: Integer);
  begin
    if aMaxCount <= 0 then begin
      fMaxCount := 0;

    end else begin
      Self.fMaxCount := aMaxCount;
      if Self.fMaxCount < fCount then begin
        fCount := fMaxCount;
        SetLength(Self.fItem, Self.fMaxCount);
      end;
    end;
  end;

procedure TGEMStack<T>.AddItem(const aItem: T);
  begin
    Inc(Self.fCount);
    if Self.fCount > Length(Self.fItem) then begin
      SetLength(Self.fItem, Self.fCount);
    end;
    Self.fItem[Self.fCount - 1] := aItem;
  end;

procedure TGEMStack<T>.SetShrinkOnPop(const aShrink: Boolean);
  begin
    Self.fShrinkOnPop := aShrink;
    if aShrink = True then begin
      Self.Shrink();
    end;
  end;

function TGEMStack<T>.Push(const aItem: T): Integer;
  begin
    if Self.fMaxCount = 0 then begin
      Self.AddItem(aItem);
      Exit(1);
    end else begin
      if Self.fCount < Self.fMaxCount then begin
        Self.AddItem(aItem);
        Exit(1);
      end else begin
        Exit(0);
      end;
    end;
  end;

function TGEMStack<T>.Push(const aItem: TArray<T>): Integer; overload;
var
I: Integer;
Ret: Integer;
  begin
    Result := 0;
    for I := 0 to High(aItem) do begin
      Ret := Self.Push(aItem[I]);
      Inc(Result, Ret);
      if Ret = 0 then begin
        Exit(Result);
      end;
    end;
  end;

function TGEMStack<T>.Pop(): T;
  begin
    Dec(Self.fCount);
    Result := Self.fItem[Self.fCount];
    if Self.fShrinkOnPop then begin
      Self.Shrink();
    end;
  end;

procedure TGEMStack<T>.Clear();
  begin
    Self.fCount := 0;
    if Self.fShrinkOnPop then begin
      SetLength(Self.fItem, 0);
    end;
  end;

procedure TGEMStack<T>.Shrink();
  begin
    if Self.fCount < Length(Self.fItem) then begin
      SetLength(Self.fItem, Self.fCount);
    end;
  end;

function TGEMStack<T>.GetStack(pCount: PInteger = nil): TArray<T>;
var
I: Integer;
  begin
    if Assigned(pCount) then pCount^ := Self.fCount;
    Initialize(Result);
    SetLength(Result, Self.fCount);

    for I := 0 to Self.fCount - 1 do begin
      Result[I] := Self.fItem[I];
    end;
  end;

end.

