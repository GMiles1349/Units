unit gemdrawbuffers;

{$mode delphi}{$H+}
{$modeswitch advancedrecords}

{$i gemoptimizations.Inc}

interface

uses
  glad_gl,
  Classes, SysUtils;

type

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             Class Forward Decs
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawBuffers = class;

  PGEMDrawVBO = ^TGEMDrawVBO;
  TGEMDrawVBO = class;

  PGEMDrawSSBO = ^TGEMDrawSSBO;
  TGEMDrawSSBO = class;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawBuffers
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawBuffers = class(TPersistent)
    private
      fVAO: GLUint;
      fVBO: Array of TGEMDrawVBO;
      fSSBO: Array of TGEMDrawSSBO;
      fCurrentVBO: TGEMDrawVBO;
      fCurrentSSBO: TGEMDrawSSBO;
      fVBOIndex: Integer;
      fSSBOIndex: Integer;

      function GetVBO(Index: Cardinal): TGEMDrawVBO;
      function GetSSBO(Index: Cardinal): TGEMDrawSSBO;
      function GetVBOCount(): GLUint;
      function GetSSBOCount(): GLUint;
      function GetMemoryReserved(): GLUint;
      function GetMemoryUsed(): GLUint;

    public
      property VBO[Index: Cardinal]: TGEMDrawVBO read GetVBO;
      property SSBO[Index: Cardinal]: TGEMDrawSSBO read GetSSBO;
      property CurrentVBO: TGEMDrawVBO read fCurrentVBO;
      property CurrentSSBO: TGEMDrawSSBO read fCurrentSSBO;
      property VBOCount: GLUint read GetVBOCount;
      property SSBOCount: GLUint read GetSSBOCount;
      property MemoryReserved: GLUint read GetMemoryReserved;
      property MemoryUsed: GLUint read GetMemoryUsed;

      constructor Create();

      procedure NextVBO(const aBindTarget: GLEnum = GL_ARRAY_BUFFER);
      procedure NextSSBO(const aBindBase: GLInt);
      procedure NextArrayBuffer();
      procedure NextElementBuffer();
      procedure NextIndirectBuffer();
      procedure UnUseAll();
      procedure AttribPointer(const aIndex: GLUint; const aSize: GLInt; const aType: GLEnum; const aNormalized: GLBoolean; const aStride: GLSizei; const aOffset: GLUint);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TGEMDrawVBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawVBO = class(TPersistent)
    private
      fHandle: GLUint;
      fSize: GLUint;
      fUSedSize: GLUint;
      fInUse: Boolean;
      fBindTarget: GLEnum;

      procedure ReSize(const aNewSize: GLUint);

    public
      property Handle: GLUint read fHandle;
      property Size: GLUint read fSize;
      property UsedSize: GLUint read fUsedSize;
      property InUse: Boolean read fInUse;

      constructor Create(const aBindTarget: GLEnum = GL_ARRAY_BUFFER);
      procedure Use(const aBindTarget: GLEnum = 0);
      procedure UnUse();
      procedure SubData(const aOffSet: GLUint; const aSize: GLUint; const aData: Pointer);
      procedure SetBindTarget(const aTarget: GLEnum);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TGEMDrawSSBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawSSBO = class(TPersistent)
    private
      fHandle: GLUint;
      fSize: GLUint;
      fUSedSize: GLUint;
      fInUse: Boolean;
      fBindBase: GLInt;
      fPointer: Pointer;

      procedure ReSize(const aNewSize: GLUint);

    public
      property Handle: GLUint read fHandle;
      property Size: GLUint read fSize;
      property UsedSize: GLUint read fUsedSize;
      property InUse: Boolean read fInUse;

      constructor Create();
      procedure Use(const aBindBase: GLInt = -1);
      procedure UnUse();
      procedure SubData(const aOffSet: GLUint; const aSize: GLUint; const aData: Pointer);
      procedure SetBindBase(const aBindBase: GLInt);
  end;



const
  GEM_MIN_BUFFER_SIZE: GLUint = 64000;

implementation

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawBuffers
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawBuffers.Create();
var
I: Integer;
  begin
    inherited Create();
    glGenVertexArrays(1, @Self.fVAO);
    glBindVertexArray(Self.fVAO);
    Self.fVBOIndex := 0;
    Self.fSSBOIndex := 0;

    SetLength(Self.fVBO, 5);
    SetLength(Self.fSSBO, 5);
    for I := 0 to 4 do begin
      Self.fVBO[I] := TGEMDrawVBO.Create();
      Self.fSSBO[I] := TGEMDrawSSBO.Create();
    end;

  end;

function TGEMDrawBuffers.GetVBO(Index: Cardinal): TGEMDrawVBO;
  begin
    Result := nil;
    if Index <= High(Self.fVBO) then begin
      Result := Self.fVBO[Index];
    end;
  end;

function TGEMDrawBUffers.GetSSBO(Index: Cardinal): TGEMDrawSSBO;
  begin
    Result := nil;
    if Index <= High(Self.fSSBO) then begin
      Result := Self.fSSBO[Index];
    end;
  end;

function TGEMDrawBuffers.GetVBOCount();
  begin
    Exit(Length(Self.fVBO));
  end;

function TGEMDrawBuffers.GetSSBOCount();
  begin
    Exit(Length(Self.fSSBO));
  end;

function TGEMDrawBuffers.GetMemoryReserved(): GLUint;
var
I: Integer;
  begin
    Result := 0;
    for I := 0 to High(Self.fVBO) do begin
      Result := Result + Self.fVBO[I].Size;
    end;
  end;

function TGEMDrawBuffers.GetMemoryUsed(): GLUint;
var
I: Integer;
  begin
    Result := 0;
    for I := 0 to High(Self.fVBO) do begin
      Result := Result + Self.fVBO[I].UsedSize;
    end;
  end;

procedure TGEMDrawBuffers.NextVBO(const aBindTarget: GLEnum = GL_ARRAY_BUFFER);
var
I,R: Integer;
Index: Integer;
  begin
    Index := -1;
    R:= Self.fVBOIndex + 1;

    for I := 0 to High(Self.fVBO) do begin
      if R > High(Self.fVBO) then begin
        R := 0;
      end;

      if Self.fVBO[R].InUse = False then begin
        Self.fVBO[R].Use(aBindTarget);
        Self.fCurrentVBO := Self.fVBO[R];
        Index := R;
        Self.fVBOIndex := R;
        break;
      end;

      Inc(R);
    end;

    if Index <> -1 then begin
      Exit();
    end else begin
      Index := Length(Self.fVBO);
      SetLength(Self.fVBO, Index + 1);
      Self.fVBO[Index] := TGEMDrawVBO.Create(aBindTarget);
      Self.fVBO[Index].Use(aBindTarget);
      Self.fCurrentVBO := Self.fVBO[Index];
      Self.fVBOIndex := High(Self.fVBO);
    end;
  end;

procedure TGEMDrawBuffers.NextSSBO(const aBindBase: GLInt);
var
I, R: Integer;
Index: Integer;
  begin
    Index := -1;
    R := Self.fSSBOIndex + 1;

    for I := 0 to High(Self.fSSBO) do begin
      if R > High(Self.fSSBO) then begin
        R := 0;
      end;

      if Self.fSSBO[R].InUse = False then begin
        Self.fSSBO[R].Use(aBindBase);
        Self.fCurrentSSBO := Self.fSSBO[R];
        Index := R;
        Self.fSSBOIndex := R;
        break;
      end;

      Inc(R);
    end;

    if Index <> -1 then begin
      Exit();
    end else begin
      Index := Length(Self.fSSBO);
      SetLength(Self.fSSBO, Index + 1);
      Self.fSSBO[Index] := TGEMDrawSSBO.Create();
      Self.fSSBO[Index].Use(aBindBase);
      Self.fCurrentSSBO := Self.fSSBO[Index];
      Self.fSSBOIndex := High(Self.fSSBO);
    end;
  end;

procedure TGEMDrawBuffers.NextArrayBuffer();
  begin
    Self.NextVBO(GL_ARRAY_BUFFER);
  end;

procedure TGEMDrawBuffers.NextElementBuffer();
  begin
    Self.NextVBO(GL_ELEMENT_ARRAY_BUFFER);
  end;

procedure TGEMDrawBuffers.NextIndirectBuffer();
  begin
    Self.NextVBO(GL_DRAW_INDIRECT_BUFFER);
  end;

procedure TGEMDrawBuffers.UnUseAll();
var
I: Integer;
  begin
    for I := 0 to High(Self.fVBO) do begin
      Self.fVBO[I].UnUse();
    end;

    for I := 0 to High(Self.fSSBO) do begin
      Self.fSSBO[I].UnUse();
    end;
  end;

procedure TGEMDrawBuffers.AttribPointer(const aIndex: GLUint; const aSize: GLInt; const aType: GLEnum; const aNormalized: GLBoolean; const aStride: GLSizei; const aOffset: GLUint);
  begin
    glEnableVertexAttribArray(aIndex);
    glVertexAttribPointer(aIndex, aSize, aType, aNormalized, aStride, Pointer(aOffset));
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TGEMDrawVBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawVBO.Create(const aBindTarget: GLEnum = GL_ARRAY_BUFFER);
  begin
    inherited Create();

    Self.fBindTarget := aBindTarget;

    glGenBuffers(1, @Self.fHandle);
    glBindBuffer(aBindTarget, Self.fHandle);
    glBufferData(aBindTarget, GEM_MIN_BUFFER_SIZE, nil, GL_STREAM_DRAW);
    glBindBuffer(aBindTarget, 0);

    Self.fSize := GEM_MIN_BUFFER_SIZE;
    Self.fUSedSize := 0;
    Self.fInUse := False;
  end;

procedure TGEMDrawVBO.Resize(const aNewSize: GLUint);
var
Ptr: PByte;
  begin
    if aNewSize <= Self.fSize then Exit();

    if Self.fUsedSize = 0 then begin
      glNamedBufferData(Self.fHandle, aNewSize, nil, GL_STREAM_DRAW);
      Exit();
    end;

    Ptr := GetMemory(aNewSize);
    glGetBufferSubData(Self.fBindTarget, 0, Self.fUsedSize, Ptr);
    glNamedBufferData(Self.fHandle, aNewSize, Ptr, GL_STREAM_DRAW);
    FreeMemory(Ptr);
    Self.fSize := aNewSize;
  end;

procedure TGEMDrawVBO.Use(const aBindTarget: GLEnum = 0);
  begin
    Self.fInUse := True;

    if aBindTarget <> 0 then begin
      Self.fBindTarget := aBindTarget;
    end;

    glBindBuffer(Self.fBindTarget, Self.fHandle);
  end;

procedure TGEMDrawVBO.UnUse();
  begin
    Self.fInUse := False;
    Self.fUSedSize := 0;
    glInvalidateBufferData(Self.fHandle);
  end;

procedure TGEMDrawVBO.SubData(const aOffSet: GLUint; const aSize: GLUint; const aData: Pointer);
  begin
    if Self.fUSedSize + aSize > Self.fSize then begin
      Self.ReSize(Self.fUsedSize + aSize);
    end;

    glNamedBufferSubData(Self.fHandle, Self.fUsedSize, aSize, aData);
    Self.fUsedSize := Self.fUsedSize + aSize;
    //glNamedBufferData(Self.fHandle, aSize, aData, GL_DYNAMIC_DRAW);
  end;

procedure TGEMDrawVBO.SetBindTarget(const aTarget: GLEnum);
  begin
    Self.fBindTarget := aTarget;
    glBindBuffer(Self.fBindTarget, 0);
    glBindBuffer(Self.fBindTarget, Self.fHandle);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                  TGEMDrawSSBO
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawSSBO.Create();
  begin
    inherited Create();

    Self.fBindBase := 0;
    Self.fSize := GEM_MIN_BUFFER_SIZE;
    Self.fUSedSize := 0;
    Self.fInUse := False;

    glGenBuffers(1, @Self.fHandle);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.fHandle);
    glNamedBufferData(Self.fHandle, GEM_MIN_BUFFER_SIZE, nil, GL_STREAM_DRAW);
  end;

procedure TGEMDrawSSBO.Resize(const aNewSize: GLUint);
var
Ptr: PByte;
  begin
    if aNewSize <= Self.fSize then Exit();

    if Self.fUsedSize = 0 then begin
      glNamedBufferData(Self.fHandle, aNewSize, nil, GL_STREAM_DRAW);
      Exit();
    end;

    Ptr := GetMemory(aNewSize);
    glGetNamedBufferSubData(Self.fHandle, 0, Self.fUsedSize, Ptr);

    glNamedBufferData(Self.fHandle, aNewSize, Ptr, GL_STREAM_DRAW);

    FreeMemory(Ptr);
    Self.fSize := aNewSize;
  end;

procedure TGEMDrawSSBO.Use(const aBindBase: GLInt = -1);
  begin
    Self.fInUse := True;

    if aBindBase <> -1 then begin
      Self.fBindBase := aBindBase;
    end;

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, Self.fBindBase, Self.fHandle);
  end;

procedure TGEMDrawSSBO.UnUse();
  begin
    Self.fInUse := False;
    Self.fUSedSize := 0;
     glInvalidateBufferData(Self.fHandle);
  end;

procedure TGEMDrawSSBO.SubData(const aOffSet: GLUint; const aSize: GLUint; const aData: Pointer);
  begin
    if Self.fUSedSize + aSize > Self.fSize then begin
      Self.ReSize(Self.fUsedSize + aSize);
    end;

    glNamedBufferSubData(Self.fHandle, Self.fUsedSize, aSize, aData);
    Self.fUsedSize := Self.fUsedSize + aSize;
    //glNamedBufferData(Self.fHandle, aSize, aData, GL_DYNAMIC_DRAW);
  end;

procedure TGEMDrawSSBO.SetBindBase(const aBindBase: GLInt);
  begin
    Self.fBindBase := aBindBase;
    glBindBufferBase(GL_UNIFORM_BUFFER, aBindBase, Self.fHandle);
  end;

end.

