unit GEMRasterizer;

{$ifdef FPC}
	{$mode ObjFPC}{$H+}
	{$modeswitch ADVANCEDRECORDS}
	{$modeswitch AUTODEREF}
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
  GEMTypes, GEMImageUtil, GEMUtil, GEMMath,
  Classes, SysUtils;

type
  TGEMRasterSurface = class;
  TGEMRasterizer = class;

  PGEMRasterTriangle = ^TGEMRasterTriangle;
  TGEMRasterTriangle = record
  	private
    	V: Array [0..2] of PGEMVec2;
      Top, Bottom, Middle: Byte;
      MiddleIsLeft: Byte;
      FlatBottom: Boolean;
      Inv: Array [0..2] of Double;

    public
    	class operator := (const aPoints: specialize TArray<PGEMVec2>): TGEMRasterTriangle;
      class operator := (const aPoints: Pointer): TGEMRasterTriangle;

      procedure Setup();
  end;

  TGEMRasterSurface = class(TPersistent)
    private
      fData: PByte;
      fDataSize: Cardinal;
      fRowPtr: Array of PByte;
    	fPixelCount: Cardinal;
      fWidth, fHeight: Cardinal;

      fClearColor: TGEMColorI;

      procedure DefineData();

    public
      property Data: PByte read fData;
      property DataSize: Cardinal read fDataSize;
      property PixelCount: Cardinal read fPixelCount;
      property Width: Cardinal read fWidth;
      property Height: Cardinal read fHeight;
      property ClearColor: TGEMColorI read fClearColor;

      constructor Create(aWidth, aHeight: Cardinal);
      constructor Create(aFileName: String);

      procedure SetClearColor(aColor: TGEMColorI);
      procedure SetAlpha(Value: Byte);
      procedure SetWidth(const aWidth: Cardinal);
      procedure SetHeight(const aHeight: Cardinal);
      procedure SetSize(const aWidth, aHeight: Cardinal);

      procedure Clear();
      procedure Clear(aColor: TGEMColorI);
      procedure SetPixel(const X, Y: Cardinal; const aColor: TGEMColorI); overload; DEBUG_INLINE
      procedure ReplaceColor(const aOldColor, aNewColor: TGEMColorI);

      procedure Blit(const aDest: TGEMRasterSurface; const aDestX, aDestY, aSrcX, aSrcY, aSrcWidth, aSrcHeight: Integer);
      procedure StretchBlit(const aDest: TGEMRasterSurface; const aDestX, aDestY, aDestWidth, aDestHeight, aSrcX, aSrcY, aSrcWidth, aSrcHeight: Integer);
      procedure DrawCircle(const aCenter: TGEMVec2; const aRadius: Single; const aColor: TGEMColorI);

  end;


  TGEMRasterizer = class(TPersistent)
    private
    	class var fTarget: TGEMRasterSurface;
  		class var fAlphaBlending: Boolean;

      class var CurVertex: Integer;
      class var CurTriangle: Integer;
      class var Vertex: Array [0..999] of TGEMVec2;
    	class var Triangle: Array [0..999] of TGEMRasterTriangle;

      constructor Create();

    public
			class property Target: TGEMRasterSurface read fTarget write fTarget;
      class property AlphaBlending: Boolean read fAlphaBlending;

      class procedure EnableAlphaBlending(aEnable: Boolean = True);

      class procedure SubmitTriangle(const V1, V2, V3: TGEMVec2);
      class procedure Flush();
  end;

implementation

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRasterTriangle
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

class operator TGEMRasterTriangle.:= (const aPoints: specialize TArray<PGEMVec2>): TGEMRasterTriangle;
	begin
  	Result.V[0] := aPoints[0];
    Result.V[1] := aPoints[1];
    Result.V[2] := aPoints[2];
    Result.SetUp();
  end;

class operator TGEMRasterTriangle.:= (const aPoints: Pointer): TGEMRasterTriangle;
var
Ptr: PGEMRasterTriangle;
  begin
  	Ptr := aPoints;
    Result.V[0] := @Ptr[0];
    Result.V[1] := @Ptr[1];
    Result.V[2] := @Ptr[2];
    Result.SetUp();
  end;

procedure TGEMRasterTriangle.Setup();
	begin


  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRasterSurface
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)


constructor TGEMRasterSurface.Create(aWidth, aHeight: Cardinal);
	begin
  	fWidth := aWidth;
    fHeight := aHeight;
    if (aWidth = 0) or (aHeight = 0) then begin
      fWidth := 0;
      fHeight := 0;
    end;

    Self.fData := GetMemory( (Self.fWidth * Self.fHeight) * 4);
    DefineData();

    fClearColor := ColorI(0,0,0);
    Clear();
  end;

constructor TGEMRasterSurface.Create(aFileName: String);
var
w,h,c: Integer;
	begin
  	Self.fData := @PByte(gemImageLoad(aFileName, @w, @h, @c))[0];
    Self.fWidth := w;
    Self.fHeight := h;

    if (w = 0) or (h = 0) then begin
      fWidth := 0;
      fHeight := 0;
    end;
    DefineData();
  end;

procedure TGEMRasterSurface.DefineData();
var
I: Integer;
Pos: Integer;
	begin
    fDataSize := (fWidth * fHeight) * 4;
    fPixelCount := fWidth * fHeight;

    SetLength(fRowPtr, fHeight);

    Pos := 0;
    for I := 0 to fHeight - 1 do begin
    	fRowPtr[I] := @fData[Pos];
      Inc(Pos, fWidth * 4);
  	end;
  end;

procedure TGEMRasterSurface.SetClearColor(aColor: TGEMColorI);
	begin
  	fClearColor := aColor;
  end;

procedure TGEMRasterSurface.SetAlpha(Value: Byte);
var
I: Integer;
  begin
    I := 0;
    while I < fDataSize do begin
    	Self.fData[I + 3] := Value;
      Inc(I, 4);
    end;
  end;

procedure TGEMRasterSurface.SetWidth(const aWidth: Cardinal);
	begin
  	gemImageResize(Self.fData, Self.Width, Self.Height, aWidth, Self.Height);
    Self.fWidth := aWidth;
  end;

procedure TGEMRasterSurface.SetHeight(const aHeight: Cardinal);
	begin
  	gemImageResize(Self.fData, Self.fWidth, Self.fHeight, Self.fWidth, aHeight);
    Self.fHeight := aHeight;
  end;

procedure TGEMRasterSurface.SetSize(const aWidth, aHeight: Cardinal);
	begin
  	gemImageResizeFill(Self.fData, Self.fWidth, Self.fHeight, aWidth, aHeight, [255,0,0,255]);
    Self.fWidth := aWidth;
    Self.fHeight := aHeight;
  end;

procedure TGEMRasterSurface.Clear();
	begin
  	Clear(fClearColor);
	end;

procedure TGEMRasterSurface.Clear(aColor: TGEMColorI);
var
I: Integer;
Ptr: PGEMColorI;
	begin

    Ptr := PGEMColorI(@fData[0]);

    for I := 0 to fPixelCount - 1 do begin
    	Ptr[0] := aColor;
      Inc(Ptr);
    end;

  end;

procedure TGEMRasterSurface.SetPixel(const X, Y: Cardinal; const aColor: TGEMColorI);
var
Ptr: PByte;
  begin
  	Ptr := fRowPtr[Y];
    Ptr := Ptr + (X * 4);
    Move(aColor, Ptr[0], 4);
  end;

procedure TGEMRasterSurface.ReplaceColor(const aOldColor, aNewColor: TGEMColorI);
var
I,Z: Integer;
SColor, DColor: PGEMColorI;
	begin

    SColor := PGEMColorI(Self.fData);
    for I := 0 to Self.fPixelCount - 1 do begin
    	if SColor[I].Compare(aOldColor, 0, False) then begin
      	SColor[I] := aNewColor;
      end;
    end;

  end;

procedure TGEMRasterSurface.Blit(const aDest: TGEMRasterSurface; const aDestX, aDestY, aSrcX, aSrcY, aSrcWidth, aSrcHeight: Integer);
var
RetDest, RetSrc: PByte;
RetDestWidth, RetDestHeight, RetSrcWidth, RetSrcHeight: Integer;
	begin

    // save existing blit values
    RetDest := GEM_BLIT_DEST_PTR;
    RetSrc := GEM_BLIT_SRC_PTR;
    RetDestWidth := GEM_BLIT_DEST_WIDTH;
    RetDestHeight := GEM_BLIT_DEST_HEIGHT;
    RetSrcWidth := GEM_BLIT_SRC_WIDTH;
    RetSrcHeight := GEM_BLIT_SRC_HEIGHT;

    gemImageSetBlitDest(aDest.Data, aDest.Width, aDest.Height);
    gemImageSetBlitSrc(Self.Data, Self.Width, Self.Height);
    gemImageBlit(aDestX, aDestY, aSrcX, aSrcY, aSrcWidth, aSrcHeight);

    // restore blit values
    gemImageSetBlitDest(RetDest, RetDestWidth, RetDestHeight);
    gemImageSetBlitSrc(RetSrc, RetSrcWidth, RetSrcHeight);

  end;

procedure TGEMRasterSurface.StretchBlit(const aDest: TGEMRasterSurface; const aDestX, aDestY, aDestWidth, aDestHeight, aSrcX, aSrcY, aSrcWidth, aSrcHeight: Integer);
var
RetDest, RetSrc: PByte;
RetDestWidth, RetDestHeight, RetSrcWidth, RetSrcHeight: Integer;
	begin

    // save existing blit values
    RetDest := GEM_BLIT_DEST_PTR;
    RetSrc := GEM_BLIT_SRC_PTR;
    RetDestWidth := GEM_BLIT_DEST_WIDTH;
    RetDestHeight := GEM_BLIT_DEST_HEIGHT;
    RetSrcWidth := GEM_BLIT_SRC_WIDTH;
    RetSrcHeight := GEM_BLIT_SRC_HEIGHT;

    gemImageSetBlitDest(aDest.Data, aDest.Width, aDest.Height);
    gemImageSetBlitSrc(Self.Data, Self.Width, Self.Height);
    gemImageBlit(aDestX, aDestY, aDestWidth, aDestHeight, aSrcX, aSrcY, aSrcWidth, aSrcHeight);

    // restore blit values
    gemImageSetBlitDest(RetDest, RetDestWidth, RetDestHeight);
    gemImageSetBlitSrc(RetSrc, RetSrcWidth, RetSrcHeight);

  end;

procedure TGEMRasterSurface.DrawCircle(const aCenter: TGEMVec2; const aRadius: Single; const aColor: TGEMColorI);
var
Bounds: TGEMRectF;
NewLeft, NewRight, NewTop, NewBottom: Integer;
Dist: Single;
I, Z: Integer;
Pos: Integer;
	begin
		Bounds := RectF(aCenter, aRadius * 2, aRadius * 2);
    NewLeft := trunc(Bounds.Left);
    NewRight := trunc(Bounds.Right);
    NewTop := trunc(Bounds.Top);
    NewBottom := trunc(Bounds.Bottom);
    if NewLeft < 0 then NewLeft := 0;
    if NewRight >= Self.Width then NewRight := Self.Width - 1;
    if NewTop < 0 then NewTop := 0;
    if NewBottom > Self.Height - 1 then NewBottom := Self.Height - 1;

    // no alpha blending
    if TGEMRasterizer.AlphaBlending = False then begin
      for Z := NewTop to NewBottom do begin
        for I := NewLeft to NewRight do begin

          Dist := Distance(I, Z, aCenter.X, aCenter.Y);
          if Dist > aRadius then Continue;

          Pos := ((Z * Self.Width) + I) * 4;

          Move(aColor, fData[Pos], 4);

        end;
  	  end;

    // alpha blending
    end else begin

    	for Z := NewTop to NewBottom do begin
        for I := NewLeft to NewRight do begin

          Dist := Distance(I, Z, aCenter.X, aCenter.Y);
          if Dist > aRadius then Continue;

          Pos := ((Z * Self.Width) + I) * 4;

          AlphaBlend(@aColor, @Self.fData[Pos]);

        end;
  	  end;

    end;

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                TGEMRasterizer
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMRasterizer.Create();
	begin

  end;

class procedure TGEMRasterizer.EnableAlphaBlending(aEnable: Boolean = True);
	begin
  	fAlphaBlending := aEnable;
  end;

class procedure TGEMRasterizer.SubmitTriangle(const V1, V2, V3: TGEMVec2);
	begin
  	Vertex[CurVertex] := V1;
    Vertex[CurVertex + 1] := V2;
    Vertex[CurVertex + 2] := V3;

    Triangle[CurTriangle] := [@Vertex[CurVertex], @Vertex[CurVertex + 1], @Vertex[CurVertex + 2]];

    Inc(CurVertex, 3);
    Inc(CurTriangle, 1);
  end;

class procedure TGEMRasterizer.Flush();
var
I,X,Y: Integer;
CurTri: PGEMRasterTriangle;
v0, v1, v2, p: TGEMVec2;
MinX, MaxX, MinY, Maxy: Integer;
A01, A12, A20, B01, B12, B20: Integer;
w0_row, w1_row, w2_row: Integer;
w0, w1, w2: Integer;
  begin

    CurTri := @Self.Triangle[0];
    v0 := CurTri.V[0]^;
    v1 := CurTri.V[1]^;
    v2 := CurTri.V[2]^;

  	// Bounding box and clipping as before
    MinX := Trunc(Smallest([v0.X, v1.X, v2.X]));
    MaxX := Trunc(Biggest([v0.X, v1.X, v2.X]));
    MinY := Trunc(Smallest([v0.Y, v1.Y, v2.Y]));
    MaxY := Trunc(Biggest([v0.Y, v1.Y, v2.Y]));

    MinX := trunc(Biggest([MinX, 0]));
    MaxX := trunc(Smallest([MaxX, Target.Width - 1]));
    MinY := trunc(Biggest([MinY, 0]));
    MaxY := trunc(Smallest([MaxY, Target.Height - 1]));

    // Triangle setup
    A01 := trunc(v0.y - v1.y);
    A12 := trunc(v1.y - v2.y);
    A20 := trunc(v2.y - v0.y);
    B01 := trunc(v1.x - v0.x);
    B12 := trunc(v2.x - v1.x);
    B20 := trunc(v0.x - v2.x);

    // Barycentric coordinates at minX/minY corner
    p := Vec2(MinX, MinY);
    w0_row := trunc(EdgeFunction(v0, v1, p));
    w1_row := trunc(EdgeFunction(v1, v2, p));
    w2_row := trunc(EdgeFunction(v2, v0, p));

    // Rasterize
    for Y := MinY to MaxY do begin
        // Barycentric coordinates at start of row
        w0 := w0_row;
        w1 := w1_row;
        w2 := w2_row;

        for X := MinX to MaxX do begin
            // If p is on or inside all edges, render pixel.
            if (w0 >= 0) and (w1 >= 0) and (w2 >= 0) then begin
                Target.SetPixel(X,Y, gem_white);
        		end;

            // One step to the right
            w0 := w0 + A12;
            w1 := w1 + A20;
            w2 := w2 + A01;
        end;

        // One row step
        w0_row := w0_row + B12;
        w1_row := w1_row + B20;
        w2_row := w2_row +B01;
    end;

  end;

end.

