unit GEMLinkedList;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
  {$modeswitch ADVANCEDRECORDS}
  {$modeswitch TYPEHELPERS}
  {$INLINE ON}
{$endif}

interface

uses
  Classes, SysUtils;

type

  generic TGEMLinkedList<T> = class(TPersistent)

    type TGEMListNode = class
      private
	      Last: TGEMListNode;
	      Next: TGEMListNode;
        Marked: Boolean;

        destructor Destroy(); override;

      public
        Value: T;
        procedure MarkForDeletion(const Mark: Boolean = True); inline;
    end;

    private
      fCount: UINT32;
      fHead: TGEMListNode;
      fTail: TGEMListNode;
      fCurrentNode: TGEMListNode;

      function GetNode(Index: UINT32): TGEMListNode;

    public
      property Count: UINT32 read fCount;
      property Node[Index: UINT32]: TGEMListNode read GetNode; default;
      property CurrentNode: TGEMListNode read fCurrentNode;

      constructor Create();
      destructor Destroy(); override;

      procedure Clear();
      procedure Push(const aValue: T); overload;
      procedure Push(const aValues: Array of T); overload;
      procedure Pop(); overload;
      procedure Pop(const aCount: UINT32); overload;
      procedure InsertAt(const aIndex: UINT32; const aValue: T); overload;
      procedure InsertAt(const aIndex: UINT32; const aValues: Array of T); overload;
      procedure Delete(const aIndex: UINT32); overload;
      procedure Delete(const aIndex: UINT32; const aCount: UINT32); overload;
      procedure DumpList(out Arr: {$ifdef FPC} specialize {$endif} TArray<T>);

      function FindFirst(const aValue: T): INT32;
      function FindLast(const aValue: T): INT32;
      function FindAll(const aValue: T): {$ifdef FPC} specialize {$endif} TArray<UINT32>;

      procedure ClearAllMarked(); inline;
      procedure DeleteAllMarked(); inline;

      procedure SeekHead(); inline;
      procedure SeekTail(); inline;
      procedure SeekNext(); inline;
      procedure SeekLast(); inline;


  end;

implementation

destructor TGEMLinkedList.TGEMListNode.Destroy();
  begin
    Self.Last := nil;
    Self.Next := nil;
    inherited;
  end;

procedure TGEMLinkedList.TGEMListNode.MarkForDeletion(const Mark: Boolean = True);
	begin
    Self.Marked := Mark;
  end;

constructor TGEMLinkedList.Create();
  begin
    Self.fCount := 0;
    Self.fHead := nil;
    Self.fTail := nil;
    Self.fCurrentNode := nil;
  end;

destructor TGEMLinkedList.Destroy();
  begin
    Self.Clear();
    inherited;
  end;


procedure TGEMLinkedList.Clear();
var
Cur: TGEMListNode;
Next: TGEMListNode;
  begin

    if Self.fCount = 0 then Exit;

    Cur := Self.fHead;
    Next := Cur.Next;

    while Assigned(Cur) do begin
      FreeAndNil(Cur);
      if Assigned(Next) then begin
        Cur := Next;
        Next := Cur.Next;
      end;
    end;

    Self.fHead := nil;
    Self.fTail := nil;
    Self.fCurrentNode := nil;
    Self.fCount := 0;

  end;


function TGEMLinkedList.GetNode(Index: UINT32): TGEMListNode;
var
I: UINT32;
Cur: TGEMListNode;
  begin

    if Index > Self.fCount - 1 then Exit;

    Cur := Self.fHead;
    if Index > 0 then begin
      for I := 0 to Index - 1 do begin
        Cur := Cur.Next;
      end;
    end;

    Exit(Cur);

  end;


procedure TGEMLinkedList.Push(const aValue: T);
var
Cur: TGEMListNode;
  begin

    Cur := TGEMListNode.Create();
    Cur.Last := nil;
    Cur.Next := nil;
    Cur.Value := aValue;

    if Self.fHead = nil then begin
      Self.fHead := Cur;
      Self.fTail := Cur;
      Self.fCurrentNode := Cur;
    end else begin
      Self.fTail.Next := Cur;
      Cur.Last := Self.fTail;
      Self.fTail := Cur;
    end;

    Self.fCount := Self.fCount + 1;

  end;


procedure TGEMLinkedList.Push(const aValues: Array of T); overload;
var
I: UINT32;
  begin

    if Length(aValues) = 0 then Exit;

    for I := 0 to High(aValues) do begin
      Self.Push(aValues[I]);
    end;

  end;


procedure TGEMLinkedList.Pop();
  begin
    if Self.fCount = 0 then Exit;

    if Self.fCurrentNode = Self.fTail then begin
      Self.fCurrentNode := Self.fTail.Last;
    end;

    Self.fTail := Self.fTail.Last;
    Self.fTail.Next.Free();
    Self.fTail.Next := nil;
    Self.fCount := Self.fCount - 1;
  end;


procedure TGEMLinkedList.Pop(const aCount: UINT32);
var
I: UINT32;
  begin
    for I := 0 to aCount - 1 do begin
      Self.Pop();
      if Self.fCount = 0 then Exit;
    end;
  end;


procedure TGEMLinkedList.InsertAt(const aIndex: UINT32; const aValue: T);
var
Cur: TGEMListNode;
Sel: TGEMListNode;
I: UINT32;
  begin

    if aIndex > Self.fCount - 1 then Exit;
    if aIndex = Self.fCount - 1 then begin
      Self.Push(aValue);
      Exit;
    end;

    Cur := TGEMListNode.Create();
    Cur.Value := aValue;
    Cur.Last := nil;
    Cur.Next := nil;

    Self.fCount := Self.fCount + 1;

    Sel := Self.fHead;

    if aIndex = 0 then begin
      Self.fHead.Last := Cur;
      Cur.Next := Self.fHead;
      Self.fHead := Cur;
      Exit;
    end;

    if aIndex > 0 then begin
      for I := 1 to aIndex - 1 do begin
        Sel := Sel.Next;
      end;
    end;

    Cur.Last := Sel.Last;
    Sel.Last := Cur;
    Cur.Next := Sel;
    Cur.Last.Next := Cur;

  end;


procedure TGEMLinkedList.InsertAt(const aIndex: UINT32; const aValues: Array of T); overload;
var
I: UINT32;
Len: UINT32;
  begin

    if Length(aValues) = 0 then Exit;
    if aIndex > Self.fCount - 1 then Exit;

    Len := Length(aValues);

    // if we're inserting at the tail, then just push the values individually
    if aIndex = Self.fCount - 1 then begin
      for I := 0 to Len - 1 do begin
        Self.Push(aValues[I]);
      end;
      Exit;
    end;

    // otherwise, keep calling insert on I + aIndex
    for I := 0 to Len - 1 do begin
      Self.InsertAt(aIndex + I, aValues[I]);
    end;

  end;


procedure TGEMLinkedList.Delete(const aIndex: UINT32); overload;
var
Cur: TGEMListNode;
I: UINT32;
  begin
    // exit on index too large
    if aIndex > Self.fCount - 1 then Exit;

    // pop if last index
    if aIndex = Self.fCount - 1 then begin
      Self.Pop();
      exit;
    end;

    Self.fCount := Self.fCount - 1;

    // simple swap and delete on aIndex is head
    if aIndex = 0 then begin
      Cur := Self.fHead;
      if Self.fCurrentNode = Cur then begin
        Self.fCurrentNode := Cur.Next;
      end;
      Self.fHead := Cur.Next;
      Cur.Free();
      Self.fHead.Last := nil;
      Exit;
    end;

    Cur := Self.fHead;
    for I := 0 to aIndex - 1 do begin
      Cur := Cur.Next;
    end;

    Cur.Last.Next := Cur.Next;
    Cur.Next.Last := Cur.Last;

    if Self.fCurrentNode = Cur then begin
      Self.fCurrentNode := nil;
    end;

    Cur.Free();

  end;


procedure TGEMLinkedList.Delete(const aIndex: UINT32; const aCount: UINT32); overload;
var
I: UINT32;
  begin

    if aIndex > Self.fCount - 1 then Exit;

    // if we're removing up to or passed the tail, then just pop from aIndex to tail
    if aIndex + aCount >= Self.fCount then begin
      Self.Pop(aCount);
      Exit;
    end;

    for I := 0 to aCount - 1 do begin
      Self.Delete(aIndex);
      if Self.fCount = 0 then Exit;
    end;

  end;


function TGEMLinkedList.FindFirst(const aValue: T): INT32;
var
I: UINT32;
Cur: TGEMListNode;
  begin

    if Self.fCount = 0 then Exit(-1);

    Cur := Self.fHead;
    for I := 0 to Self.fCount - 1 do begin
      if Cur.Value = aValue then Exit(I);
      Cur := Cur.Next;
      if Assigned(Cur) = False then Exit(-1);
    end;

  end;


function TGEMLinkedList.FindLast(const aValue: T): INT32;
var
I: UINT32;
Cur: TGEMListNode;
  begin

    if Self.fCount = 0 then Exit(-1);

    Cur := Self.fTail;
    for I := 0 to Self.fCount - 1 do begin
      if Cur.Value = aValue then Exit(I);
      Cur := Cur.Last;
      if Assigned(Cur) = False then Exit (-1);
    end;

  end;


function TGEMLinkedList.FindAll(const aValue: T): {$ifdef FPC} specialize {$endif} TArray<UINT32>;
var
I: UINT32;
Len: UINT32;
Cur: TGEMListNode;
  begin

    if Self.fCount = 0 then Exit(nil);

    Cur := Self.fHead;
    Len := 0;
    Initialize(Result);
    SetLength(Result, 0);

    for I := 0 to Self.fCount - 1 do begin
      if Cur.Value = aValue then begin
        Inc(Len);
        SetLength(Result, Len);
        Result[Len - 1] := I;
      end;
      Cur := Cur.Next;
    end;

  end;


procedure TGEMLinkedList.DumpList(out Arr: {$ifdef FPC} specialize {$endif} TArray<T>);
var
I: UINT32;
Cur: TGEMListNode;
  begin

    if Self.fCount = 0 then begin
      SetLength(Arr,0);
      Exit;
    end;

    SetLength(Arr, Self.fCount);
    Cur := Self.fHead;

    for I := 0 to Self.fCount - 1 do begin
      Arr[I] := Cur.Value;
      Cur := Cur.Next;
    end;

  end;


procedure TGEMLinkedList.ClearAllMarked();
var
CurNode: TGEMListNode;
  begin
		if Self.fCount = 0 then Exit();

    CurNode := Self.fHead;
    while Assigned(CurNode) do begin
			CurNode.Marked := False;
      CurNode := CurNode.Next;
    end;
  end;

procedure TGEMLinkedList.DeleteAllMarked();
var
CurNode, Last, Next: TGEMListNode;
	begin
    if Self.fCount = 0 then Exit();

    CurNode := Self.fHead;
    while Assigned(CurNode) do begin
      // move on if not marked
      if CurNode.Marked = False then begin
        CurNode := CurNode.Next;
        Continue;
      end;

      Last := CurNode.Last;
      Next := CurNode.Next;

      if Assigned(Last) then begin
      	Last.Next := Next;
      end;

    	if Assigned(Next) then begin
        Next.Last := Last;
      end;

      if Self.fHead = CurNode then Self.fHead := Next;
      if Self.fTail = CurNode then Self.fTail := Last;
      if Self.fCurrentNode = CurNode then Self.fCurrentNode := Next;

      CurNode.Free();
      Dec(Self.fCount);

      CurNode := Next;

    end;

  end;


procedure TGEMLinkedList.SeekHead();
	begin
		Self.fCurrentNode := Self.fHead;
  end;


procedure TGEMLinkedList.SeekTail();
	begin
    Self.fCurrentNode := Self.fTail;
  end;


procedure TGEMLinkedList.SeekNext();
	begin
    Self.fCurrentNode := Self.fCurrentNode.Next;
  end;


procedure TGEMLinkedList.SeekLast();
	begin
    Self.fCurrentNode := Self.fCurrentNode.Last;
  end;

end.

