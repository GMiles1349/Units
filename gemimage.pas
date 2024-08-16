unit gemimage;

{$mode ObjFPC}{$H+}

interface

uses
  gemtypes, Neslib.Stb.Image, Neslib.Stb.ImageWrite,
  Classes, SysUtils;

type

  TGEMImage = class(TObject)
    private
      fWidth: Integer;
      fHeight: Integer;
      fPixel: PGEMColorI;
      fRowPtr: Array of PGEMColorI;
      fPixelCount: Integer;
      fDataSize: Integer;

      procedure Update(const aNewWidth, aNewHeight: Cardinal);

      function GetPixel(const X,Y: Integer): TGEMColorI;
      procedure SetPixel(const X,Y: Integer; Color: TGEMColorI);
      function GetData(): Pointer;

    public
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property Pixel[X,Y: Integer]: TGEMColorI read GetPixel write SetPixel;
      property PixelCount: Integer read fPixelCount;
      property Data: Pointer read GetData;
      property DataSize: Integer read fDataSize;

      constructor Create(const aWidth: Cardinal = 0; const aHeight: Cardinal = 0);
      constructor Create(const aFileName: String);
      constructor Create(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal);

      destructor Destroy(); override;

      procedure LoadFromFile(const aFileName: String);
      procedure LoadFromMemory(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal);
      procedure CopyFrom(var aImage: TGEMImage);
      procedure CopyFrom(var aImage: TGEMImage; aSrcRect, aDestRect: TGEMRectI);

      procedure SaveToFile(const aFileName: String);

      procedure Fill(const aColor: TGEMColorI);
      procedure Flip();
      procedure Mirror();
      procedure Invert();
      procedure Replace(const aOldColor, aNewColor: TGEMColorI; const aVariance: Single = 0; const aCompareAlpha: Boolean = False);

      procedure SetWidth(const aWidth: Cardinal);
      procedure SetHeight(const aHeight: Cardinal);
      procedure SetSize(const aWidth, aHeight: Cardinal);
      procedure Stretch(const aWidth, aHeight: Cardinal);

  end;

implementation

constructor TGEMImage.Create(const aWidth: Cardinal = 0; const aHeight: Cardinal = 0);
  begin
    inherited Create();
    Self.Update(aWidth, aHeight);
  end;

constructor TGEMImage.Create(const aFileName: String);
  begin
    inherited Create();
    Self.LoadFromFile(aFileName);
  end;

constructor TGEMImage.Create(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal);
  begin
    inherited Create();
    Self.LoadFromMemory(aData, aWidth, aHeight, aComponents);
  end;

destructor TGEMImage.Destroy();
  begin
    if Assigned(Self.fPixel) then begin
      FreeMemory(Self.fPixel);
    end;

    Finalize(Self.fRowPtr);

    inherited Destroy();
  end;

procedure TGEMImage.Update(const aNewWidth, aNewHeight: Cardinal);
var
I: Integer;
  begin

    if (aNewWidth = 0) or (aNewHeight = 0) then begin
      Self.fWidth := 0;
      Self.fHeight := 0;
    end;

    Self.fWidth := aNewWidth;
    Self.fHeight := aNewHeight;
    Self.fPixelCount := Self.fWidth * Self.fHeight;
    Self.fDataSize := Self.fPixelCount * 4;

    if Assigned(Self.fPixel) then begin
      FreeMemory(Self.fPixel);
    end;

    Self.fPixel := GetMemory(Self.fDataSize);

    SetLength(Self.fRowPtr, Self.fHeight);
    for I := 0 to Self.fHeight - 1 do begin
      Self.fRowPtr[I] := @Self.fPixel[I * Self.fWidth];
    end;
  end;

function TGEMImage.GetPixel(const X,Y: Integer): TGEMColorI;
var
Ptr: PGEMColorI;
  begin
    Ptr := @Self.fPixel[0];
    Ptr := Ptr + ((Self.fWidth * Y) + X);
    Exit(Ptr[0]);
  end;

procedure TGEMImage.SetPixel(const X,Y: Integer; Color: TGEMColorI);
var
Ptr: PGEMColorI;
  begin
    Ptr := @Self.fPixel[0];
    Ptr := Ptr + ((Self.fWidth * Y) + X);
    Ptr[0] := Color;
  end;

function TGEMImage.GetData(): Pointer;
  begin
    Exit(Pointer(@Self.fPixel[0]));
  end;

procedure TGEMImage.LoadFromFile(const aFileName: String);
var
W,H,C: Integer;
Ptr: PByte;
PathString: String;
  begin
    PathString := ExtractFilePath(aFileName);
    if PathString = '' then begin
      PathString := ExtractFilePath(ParamStr(0)) + aFileName;
    end else begin
      PathString := aFileName;
    end;

    if FileExists(PathString) = False then begin
      Self.Update(0, 0);
      Exit;
    end;

    Ptr := stbi_load(PAnsiChar(AnsiString(PathString)), W, H, C, 4);

    Self.Update(W, H);

    Move(Ptr[0], Self.fPixel[0], Self.fDataSize);

    stbi_image_free(Ptr);
  end;

procedure TGEMImage.LoadFromMemory(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal);
var
Ptr: PByte;
I: Integer;
  begin
    if (aWidth = 0) or (aHeight = 0) or (aComponents = 0) then begin
      Self.Update(0, 0);
      Exit();
    end;

    if (aComponents = 2) or (aComponents > 4) then begin
      Self.Update(0, 0);
      Exit();
    end;

    Ptr := PByte(aData);
    Self.Update(aWidth, aHeight);

    for I := 0 to (aWidth * aHeight) - 1 do begin

      case aComponents of
        1:
          begin
            Self.fPixel[I].Red := Ptr[0];
            Self.fPixel[I].Green := Ptr[0];
            Self.fPixel[I].Blue := Ptr[0];
            Self.fPixel[I].Alpha := 255;
            Ptr := Ptr + 1;
          end;

        3:
          begin
            Self.fPixel[I].Red := Ptr[0];
            Self.fPixel[I].Green := Ptr[1];
            Self.fPixel[I].Blue := Ptr[2];
            Self.fPixel[I].Alpha := 255;
            Ptr := Ptr + 3;
          end;

        4:
          begin
            Move(Ptr[I * 4], Self.fPixel[I], 4);
          end;
      end;

    end;

    Ptr := nil;
  end;

procedure TGEMImage.CopyFrom(var aImage: TGEMImage);
  begin
    Self.Update(aImage.Width, aImage.Height);
    Move(aImage.fPixel[0], Self.fPixel[0], Self.fDataSize);
  end;

procedure TGEMImage.CopyFrom(var aImage: TGEMImage; aSrcRect, aDestRect: TGEMRectI);
  begin

  end;

procedure TGEMImage.SaveToFile(const aFileName: String);
var
FilePath: String;
FileName: String;
Ext: String;
Ret: LongBool;
  begin
    FilePath := ExtractFilePath(aFileName);
    FileName := ExtractFileName(aFileName);
    Ext := LowerCase(ExtractFileExt(aFileName));
    Ext := Ext[2..High(Ext)];

    if FilePath = '' then begin
      FilePath := ExtractFilePath(ParamStr(0));
    end else begin
      if FileExists(FilePath) = False then begin
        // Exit;
      end;
    end;

    if Ext = 'bmp' then begin
      Ret := stbi_write_bmp(PAnsiChar(AnsiString(FilePath + FileName)), Self.fWidth, Self.fHeight, 4, @Self.fPixel[0]);
    end else if Ext = 'png' then begin
      Ret := stbi_write_png(PAnsiChar(AnsiString(FilePath + FileName)), Self.fWidth, Self.fHeight, 4, @Self.fPixel[0], 0);
    end else if Ext = 'tga' then begin
      Ret := stbi_write_tga(PAnsiChar(AnsiString(FilePath + FileName)), Self.fWidth, Self.fHeight, 4, @Self.fPixel[0]);
    end else if Ext = 'hdr' then begin
      Ret := stbi_write_hdr(PAnsiChar(AnsiString(FilePath + FileName)), Self.fWidth, Self.fHeight, 4, @Self.fPixel[0]);
    end else if (Ext = 'jpg') or (Ext = 'jpeg') then begin
      Ret := stbi_write_jpg(PAnsiChar(AnsiString(FilePath + FileName)), Self.fWidth, Self.fHeight, 4, @Self.fPixel[0], 100);
    end;

    if Ret = False then begin
      WriteLn('Failed to save image ' + aFileName);
    end;
  end;

procedure TGEMImage.Fill(const aColor: TGEMColorI);
var
I: Integer;
  begin
    for I := 0 to Self.fPixelCount - 1 do begin
      Self.fPixel[I] := aColor;
    end;
  end;

procedure TGEMImage.Flip();
var
I: Integer;
SrcPtr: PByte;
EndPtr: PByte;
TempPtr: PByte;
MoveSize: Integer;
  begin
    if (Self.fWidth = 0) or (Self.fHeight = 0) then Exit();

    MoveSize := Self.fWidth * 4;
    TempPtr := GetMemory(MoveSize);

    SrcPtr := Self.GetData();
    EndPtr := SrcPtr;
    EndPtr := EndPtr + ((Self.fWidth * 4) * (Self.fHeight - 1));

    for I := 0 to trunc(Self.fHeight / 2) do begin
      Move(SrcPtr[0], TempPtr[0], MoveSize);
      Move(EndPtr[0], SrcPtr[0], MoveSize);
      Move(TempPtr[0], EndPtr[0], MoveSize);
      Inc(SrcPtr, MoveSize);
      Dec(EndPtr, MoveSize);
    end;

    FreeMemory(TempPtr);
  end;

procedure TGEMImage.Mirror();
var
TempColor: TGEMColorI;
I, Z, P1, P2: Integer;
  begin
    if (Self.fWidth = 0) or (Self.fHeight = 0) then Exit();

    for Z := 0 to Self.fHeight - 1 do begin
      P1 := Z * Self.fWidth;
      P2 := P1 + (Self.fWidth - 1);
      for I := 0 to trunc(Self.fWidth / 2) do begin
        TempColor := Self.fPixel[P1];
        Self.fPixel[P1] := Self.fPixel[P2];
        Self.fPixel[P2] := TempColor;
        P1 := P1 + 1;
        P2 := P2 - 1;
      end;
    end;
  end;

procedure TGEMImage.Invert();
var
I: Integer;
  begin
    for I := 0 to Self.fPixelCount - 1 do begin
      Self.fPixel[I] := Inverse(Self.fPixel[I]);
    end;
  end;

procedure TGEMImage.Replace(const aOldColor, aNewColor: TGEMColorI; const aVariance: Single = 0; const aCompareAlpha: Boolean = False);
var
I: Integer;
Ptr: PGEMColorI;
  begin
    Ptr := Self.fPixel;
    for I := 0 to Self.PixelCount -1 do begin
      if ColorCompare(Ptr[I], aOldColor, aVariance, aCompareAlpha) then begin
        Ptr[I] := aNewColor;
      end;
    end;
  end;

procedure TGEMImage.SetWidth(const aWidth: Cardinal);
var
MoveWidth: Integer;
MoveSize: Integer;
OrgData: PGEMColorI;
OrgPos: Integer;
I: Integer;
  begin

    if aWidth = 0 then begin
      Self.Update(0, 0);
      Exit();
    end;

    if aWidth < Self.fWidth then begin
      MoveWidth := aWidth;
    end else begin
      MoveWidth := Self.fWidth;
    end;

    MoveSize := MoveWidth * 4;

    OrgData := GetMemory((Self.fHeight * MoveWidth) * 4);
    OrgPos := 0;

    for I := 0 to Self.fHeight - 1 do begin
      Move(Self.fPixel[I * Self.fWidth], OrgData[OrgPos], MoveSize);
      OrgPos := OrgPos + MoveWidth;
    end;

    Self.Update(aWidth, Self.fHeight);
    OrgPos := 0;

    for I := 0 to Self.fHeight -1  do begin
      Move(OrgData[OrgPos], Self.fPixel[I * Self.fWidth], MoveSize);
      OrgPos := OrgPos + MoveWidth;
    end;

    FreeMemory(OrgData);
  end;

procedure TGEMImage.SetHeight(const aHeight: Cardinal);
var
MoveHeight, MoveSize: Integer;
OrgData: PGEMColorI;
OrgPos: Integer;
I: Integer;
  begin

    if aHeight = 0 then begin
      Self.Update(0,0);
      Exit();
    end;

    if aHeight < Self.fHeight then begin
      MoveHeight := aHeight;
    end else begin
      MoveHeight := Self.fHeight;
    end;

    MoveSize := Self.fWidth * 4;

    OrgData := GetMemory((Self.fWidth * MoveHeight) * 4);
    OrgPos := 0;
    for I := 0 to MoveHeight - 1 do begin
      Move(Self.fPixel[Self.fWidth * I], OrgData[OrgPos], MoveSize);
      OrgPos := OrgPos + Self.fWidth;
    end;

    Self.Update(Self.fWidth, aHeight);
    OrgPos := 0;

    for I := 0 to MoveHeight - 1 do begin
      Move(OrgData[OrgPos], Self.fPixel[Self.fWidth * I], MoveSize);
      OrgPos := OrgPos + Self.fWidth;
    end;

    FreeMemory(OrgData);

  end;

procedure TGEMImage.SetSize(const aWidth, aHeight: Cardinal);
var
MoveWidth, MoveHeight, MoveSize: Integer;
OrgData: PGEMColorI;
OrgPos: Integer;
I: Integer;
  begin

    if (aWidth = 0) or (aHeight = 0) then begin
      Self.Update(0, 0);
      Exit();
    end;

    if aWidth < Self.fWidth then begin
      MoveWidth := aWidth;
    end else begin
      MoveWidth := Self.fWidth;
    end;

    if aHeight < Self.fHeight then begin
      MoveHeight := aHeight;
    end else begin
      MoveHeight := Self.fHeight;
    end;

    MoveSize := MoveWidth * 4;
    OrgData := GetMemory((MoveWidth * MoveHeight) * 4);
    OrgPos := 0;

    for I := 0 to MoveHeight - 1 do begin
      Move(Self.fPixel[I * Self.fWidth], OrgData[OrgPos], MoveSize);
      OrgPos := OrgPos + MoveWidth;
    end;

    Self.Update(aWidth, aHeight);
    OrgPos := 0;

    for I := 0 to MoveHeight - 1 do begin
      Move(OrgData[OrgPos], Self.fPixel[I * Self.fWidth], MoveSize);
      OrgPos := OrgPos + MoveWidth;
    end;

    FreeMemory(OrgData);
  end;

procedure TGEMImage.Stretch(const aWidth, aHeight: Cardinal);
var
OrgData: PGEMColorI;
OrgPos: Integer;
OrgWidth, OrgHeight: Integer;
I: Integer;
SrcRatioX, SrcRatioY: Single;
SrcPosX, SrcPosY, DestPosX, DestPosY: Single;
  begin

    if (aWidth = 0) or (aHeight = 0) then begin
      Self.Update(0, 0);
      Exit();
    end;

    OrgData := GetMemory(Self.fDataSize);
    Move(Self.fPixel[0], OrgData[0], Self.fDataSize);

    OrgWidth := Self.fWidth;
    OrgHeight := Self.fHeight;

    SrcRatioX := Self.fWidth / aWidth;
    SrcRatioY := Self.fHeight / aHeight;

    SrcPosX := 0;
    SrcPosY := 0;
    DestPosX := 0;
    DestPosY := 0;

    Self.Update(aWidth, aHeight);

    for I := 0 to Self.fPixelCount - 1 do begin
      OrgPos := (trunc(SrcPosY) * OrgWidth) + trunc(SrcPosX);
      Move(OrgData[OrgPos], Self.fPixel[I], 4);

      DestPosX := DestPosX + 1;
      if DestPosX >= Self.fWidth then begin
        DestPosY := DestPosY + 1;
        DestPosX := 0;
        SrcPosY := DestPosY * SrcRatioY;
      end;

      SrcPosX := DestPosX * SrcRatioX;
    end;

  end;

end.

