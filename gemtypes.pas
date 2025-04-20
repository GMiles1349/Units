unit GEMTypes;

{$ifdef FPC}
	{$mode objFPC}{$H+}
	{$modeswitch ADVANCEDRECORDS}
	{$modeswitch AUTODEREF}
{$endif}

{$i gemoptimizations.Inc}

interface

uses
  {$ifndef FPC}
  	System.SysUtils, Math.Vectors,
  {$else}
  	SysUtils,
  {$endif}
  Types, Classes, Math;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Enums
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type TGEMVectorComponent = (VX = 0, VY = 1, VZ = 2);


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Colors
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type
    PGEMColorF = ^TGEMColorF;
    TGEMColorF = packed record
    public
      Red,Green,Blue,Alpha: Single;
      function Inverse(): TGEMColorf;
      function ToString(): String;
      procedure Lighten(AValue: Single);
      function ToGrey(): TGEMColorF;
  end;


  type
    PGEMColorI = ^TGEMColorI;
    TGEMColorI = record
    public
      Red,Green,Blue,Alpha: Byte;
      function Inverse(): TGEMColorf;
      function ToString(): String;
      function ToGrey(): TGEMColorI;
      function Compare(const aComColor: TGEMColorI; const aVariance: Single; const aCompareAlpha: Boolean = False): Boolean;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Rects
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PGEMRectI = ^TGEMRectI;
    TGEMRectI = record
    private
      fX,fY,fZ,fLeft,fTop,fRight,fBottom,fWidth,fHeight: Integer;

    public
      property X: Integer read fX;
      property Y: Integer read fY;
      property Z: Integer read fZ;
      property Left: Integer read fLeft;
      property Right: Integer read fRight;
      property Top: Integer read fTop;
      property Bottom: Integer read fBottom;
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property X1: Integer read fLeft;
      property X2: Integer read fRight;
      property Y1: Integer read fTop;
      property Y2: Integer read fBottom;

    	{$ifndef FPC}
      class operator Initialize(out Dest: TGEMRectI);
      {$else}
      class operator Initialize(var Dest: TGEMRectI);
      {$endif}

      procedure Update(AFrom: Integer);
      procedure SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
      procedure SetX(AX: Single);
      procedure SetY(AY: Single);
      procedure SetLeft(ALeft: Single);
      procedure SetRight(ARight: Single);
      procedure SetTop(ATop: Single);
      procedure SetBottom(ABottom: Single);
      procedure SetTopLeft(ALeft, ATop: Single);
      procedure SetTopRight(ARight, ATop: Single);
      procedure SetBottomRight(ARight, ABottom: Single);
      procedure SetBottomLeft(ALeft, ABottom: Single);
      procedure SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
      procedure SetWidth(AWidth: Single; AFrom: Integer = 0);
      procedure SetHeight(AHeight: Single; AFrom: Integer = 0);
      procedure Grow(AIncWidth,AIncHeight: Single);
      procedure Stretch(APerWidth,APerHeight: Single);
      procedure FitInRect(ARect: TGEMRectI);
      procedure Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);

      function RandomSubRect(): TGEMRectI;
  end;


  type
    PGEMRectF = ^TGEMRectF;
    TGEMRectF = record
    private
      fX,fY,fZ,fLeft,fTop,fRight,fBottom,fWidth,fHeight: Single;

    public
      property X: Single read fX;
      property Y: Single read fY;
      property Z: Single read fZ;
      property Left: Single read fLeft;
      property Right: Single read fRight;
      property Top: Single read fTop;
      property Bottom: Single read fBottom;
      property Width: Single read fWidth;
      property Height: Single read fHeight;
      property X1: Single read fLeft;
      property X2: Single read fRight;
      property Y1: Single read fTop;
      property Y2: Single read fBottom;

    	{$ifndef FPC}
      class operator Initialize (out Dest: TGEMRectF);
      {$else}
      class operator Initialize (var Dest: TGEMRectF);
      {$endif}

      procedure Update(AFrom: Integer);
      procedure SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
      procedure SetX(AX: Single);
      procedure SetY(AY: Single);
      procedure SetZ(AZ: Single);
      procedure SetLeft(ALeft: Single);
      procedure SetRight(ARight: Single);
      procedure SetTop(ATop: Single);
      procedure SetBottom(ABottom: Single);
      procedure SetTopLeft(ALeft,ATop: Single);
      procedure SetTopRight(ARight,ATop: Single);
      procedure SetBottomLeft(ALeft,ABottom: Single);
      procedure SetBottomRight(ARight,ABottom: Single);
      procedure SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
      procedure Grow(AIncWidth,AIncHeight: Single);
      procedure Stretch(APerWidth,APerHeight: Single);
      procedure SetWidth(AWidth: Single; AFrom: Integer = 0);
      procedure SetHeight(AHeight: Single; AFrom: Integer = 0);
      procedure Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);

      function RandomSubRect(): TGEMRectF;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Vectors
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PGEMVec2 = ^TGEMVec2;
    TGEMVec2 =  record
    X,Y: Single;

    {$ifndef FPC}
    class operator Add(A,B: TGEMVec2): TGEMVec2;
    class operator Subtract(A,B: TGEMVec2): TGEMVec2;
    class operator Multiply(A: TGEMVec2; B: Single): TGEMVec2;
    class operator Divide(A: TGEMVec2; B: Single): TGEMVec2;
    class operator Negative(A: TGEMVec2): TGEMVec2;
    {$else}
    class operator +(A,B: TGEMVec2): TGEMVec2;
    class operator -(A,B: TGEMVec2): TGEMVec2;
    class operator *(A: TGEMVec2; B: Single): TGEMVec2;
    class operator /(A: TGEMVec2; B: Single): TGEMVec2;
    class operator -(A: TGEMVec2): TGEMVec2;
    {$endif}

    procedure Translate(AValues: TGEMVec2);
    function ToString(APrecision: Cardinal = 0): String;
  end;


  type
    PGEMVec3 = ^TGEMVec3;
    TGEMVec3 =  packed record
    private
      function GetNormal(): TGEMVec3;
      function GetLength(): Single;

    public
      X,Y,Z: Single;

      property Normal: TGEMVec3 read GetNormal;
      property Length: Single read GetLength;

      {$ifndef FPC}
      class operator Add(A,B: TGEMVec3): TGEMVec3;
      class operator Add(A: TGEMVec3; B: Single): TGEMVec3;
      class operator Subtract(A,B: TGEMVec3): TGEMVec3;
      class operator Subtract(A: TGEMVec3; B: Single): TGEMVec3;
      class operator Divide(A: TGEMVec3; B: Single): TGEMVec3;
      class operator Divide(A: Single; B: TGEMVec3): TGEMVec3;
      class operator Multiply(A: TGEMVec3; B: Single): TGEMVec3;
      class operator Multiply(A,B: TGEMVec3): TGEMVec3;
      class operator Negative(A: TGEMVec3): TGEMVec3;
      {$else}
      class operator +(A,B: TGEMVec3): TGEMVec3;
      class operator +(A: TGEMVec3; B: Single): TGEMVec3;
      class operator -(A,B: TGEMVec3): TGEMVec3;
      class operator -(A: TGEMVec3; B: Single): TGEMVec3;
      class operator /(A: TGEMVec3; B: Single): TGEMVec3;
      class operator /(A: Single; B: TGEMVec3): TGEMVec3;
      class operator *(A: TGEMVec3; B: Single): TGEMVec3;
      class operator *(A,B: TGEMVec3): TGEMVec3;
      class operator -(A: TGEMVec3): TGEMVec3;
      {$endif}

      procedure Negate();
      procedure Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0); overload;
      procedure Translate(AValues: TGEMVec3); overload;
      procedure Rotate(AX,AY,AZ: Single);
      procedure Cross(AVec: TGEMVec3);
      function Dot(AVec: TGEMVec3): Single;
      function GetTargetVector(ATarget: TGEMVec3): TGEMVec3;
      function toNDC(ADispWidth, ADispHeight: Single): TGEMVec3;

      {$ifndef FPC}
      function Swizzle(AComponents: TArray<TGEMVectorComponent>): TGEMVec3;
      {$else}
      function Swizzle(AComponents: specialize TArray<TGEMVectorComponent>): TGEMVec3;
      {$endif}

  end;


  {$A4}
  type
    PGEMVec4 = ^TGEMVec4;
    TGEMVec4 =  packed record
    X,Y,Z,W: Single;
  end;
  {$A8}


  type
    PGEMVertex = ^TGEMVertex;
    TGEMVertex = packed record
    public
      Vector: TGEMVec3;
      Color: TGEMColorF;
      TexCoord: TGEMVec2;
      Normal: TGEMVec4;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMMat4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PGEMMat4 = ^TGEMMat4;
    TGEMMat4 = record

    	private

      	M: Array [0..3, 0..3] of Single;

        // getters
        function GetVal(const A,B: Cardinal): Single;
      	function GetRow(const Index: Cardinal): TGEMVec4;
        function GetColumn(const Index: Cardinal): TGEMVec4;

        // setters
        procedure SetVal(const A: Cardinal; const B: Cardinal; const aValue: Single);
        procedure SetRow(const Index: Cardinal; const aValues: TGEMVec4);
        procedure SetColumn(const Index: Cardinal; const aValues: TGEMVec4);

    	public

        property E[A, B: Cardinal]: Single read GetVal write SetVal; default;
        property AX: Single read M[0,0] write M[0,0];
        property AY: Single read M[1,0] write M[1,0];
        property AZ: Single read M[2,0] write M[2,0];
        property AW: Single read M[3,0] write M[3,0];
        property BX: Single read M[0,1] write M[0,1];
        property BY: Single read M[1,1] write M[1,1];
        property BZ: Single read M[2,1] write M[2,1];
        property BW: Single read M[3,1] write M[3,1];
        property CX: Single read M[0,2] write M[0,2];
        property CY: Single read M[1,2] write M[1,2];
        property CZ: Single read M[2,2] write M[2,2];
        property CW: Single read M[3,2] write M[3,2];
        property DX: Single read M[0,3] write M[0,3];
        property DY: Single read M[1,3] write M[1,3];
        property DZ: Single read M[2,3] write M[2,3];
        property DW: Single read M[3,3] write M[3,3];
        property Row[Index: Cardinal]: TGEMVec4 read GetRow write SetRow;
        property Column[Index: Cardinal]: TGEMVec4 read GetColumn write SetColumn;

        {$ifndef FPC}
        class operator Initialize(out Dest: TGEMMat4);
        class operator Multiply(A: TGEMMat4; B: TGEMMat4): TGEMMat4; overload;
        class operator Multiply(A: TGEMMat4; B: TGEMVec4): TGEMVec4; overload;
        class operator Implicit(A: Array of Single): TGEMMat4;
        {$else}
        class operator Initialize(var Dest: TGEMMat4);
        class operator *(A: TGEMMat4; B: TGEMMat4): TGEMMat4; overload;
        class operator *(A: TGEMMat4; B: TGEMVec4): TGEMVec4; overload;
        class operator :=(A: Array of Single): TGEMMat4;
        {$endif}

        procedure Zero();
        procedure SetIdentity();
        {$ifndef FPC}
        procedure Fill(AValues: TArray<Single>);
        {$else}
        procedure Fill(AValues: specialize TArray<Single>);
        {$endif}

      	procedure Negate();
        procedure Inverse();
        procedure Scale(AFactor: Single);
        procedure Transpose();
        procedure MakeTranslation(X: Single = 0; Y: Single = 0; Z: Single = 0); overload;
        procedure MakeTranslation(AValues: TGEMVec3); overload;
        procedure Translate(X: Single = 0; Y: Single = 0; Z: Single = 0); overload;
        procedure Translate(AValues: TGEMVec3); overload;
        procedure Rotate(X: Single = 0; Y: Single = 0; Z: Single = 0); overload;
        procedure Rotate(AValues: TGEMVec3); overload;
        procedure MakeScale(X, Y, Z: Single);
        procedure Perspective(AFOV, Aspect, ANear, AFar: Single; VerticalFOV: Boolean = True);
        procedure Ortho(ALeft,ARight,ABottom,ATop,ANear,AFar: Single);
        procedure LookAt(AFrom,ATo,AUp: TGEMVec3; const aFlipY: Boolean = False);

  end;


  type TGEMCylinder = record
    private
      fRadius: Single;
      fHeight: Single;
      fCenter: TGEMVec3;
      fBottomCenter: TGEMVec3;
      fTopCenter: TGEMVec3;
      fUp: TGEMVec3;

    public
      procedure SetBottomCenter(const ABottomCenter: TGEMVec3);
      procedure SetCenter(const ACenter: TGEMVec3);
      procedure SetHeight(const AHeight: Single);
      procedure SetRadius(const ARadius: Single);
      procedure SetTopCenter(const ATopCenter: TGEMVec3);
      procedure SetUpVector(const AUpVector: TGEMVec3);

      property Radius: Single read fRadius write SetRadius;
      property Height: Single read fHeight write SetHeight;
      property Center: TGEMVec3 read fCenter write SetCenter;
      property Top: TGEMVec3 read fTopCenter write SetTopCenter;
      property Bottom: TGEMVec3 read fBottomCenter write SetBottomCenter;

      constructor Create(ACenter: TGEMVec3; AUpVector: TGEMVec3; ARadius, AHeight: Single);

      procedure Translate(AValue: TGEMVec3);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMPlane
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type TGEMPlane = record
    Normal: TGEMVec3;
    Distance: Single;

    constructor Create(P1: TGEMVec3; ANormal: TGEMVec3);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMFrustum
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type TGEMFrustum = record
    type TGEMFrustumFaces = record
      Top,Bottom,Left,Right,Near,Far: TGEMPlane;
    end;

    private
      Faces: TGEMFrustumFaces;
    public

      // view culling
      function isInViewSphere(APosition: TGEMVec3; ARadius: Single): Boolean;

      {$ifndef FPC}
      function OnorForwardSphere(const [ref] AFace: TGEMPlane; var ACenter: TGEMVec3; var ARadius: Single): Boolean;
      {$else}
      function OnorForwardSphere(constref AFace: TGEMPlane; var ACenter: TGEMVec3; var ARadius: Single): Boolean;
      {$endif}
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMCamera
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type TGEMCamera = class
    private
      fPosition: TGEMVec3;
      fNDCPos: TGEMVec3;
      fDirection: TGEMVec3;
      fUp: TGEMVec3;
      fRight: TGEMVec3;
      fTarget: TGEMVec3;
      fViewNear: Single;
      fViewDistance: Single;
      fFOV: Single;
      fFOVVerticle: Boolean;
      fCameraType: Integer;
      fViewport: TGEMRectF;
      fView: TGEMMat4;
      fProjection: TGEMMat4;
      fFrustum: TGEMFrustum;
      fAngles: TGEMVec3;
      fVerticleFlip: Boolean;

      procedure GetDirection();
      procedure GetRight();
      procedure GetUp();
      procedure GetNewAngles();
      procedure ConstructFrustum();

    public
      property Position: TGEMVec3 read fPosition;
      property Direction: TGEMVec3 read fDirection;
      property Up: TGEMVec3 read fUp;
      property Right: TGEMVec3 read fRight;
      property Target: TGEMVec3 read fTarget;
      property ViewNear: Single read fViewNear;
      property ViewDistance: Single read fViewDistance;
      property FOV: Single read fFOV;
      property FOVVerticle: Boolean read fFOVVerticle;
      property CameraType: Integer read fCameraType;
      property Viewport: TGEMRectF read fViewport;
      property ViewMatrix: TGEMMat4 read fView;
      property ProjectionMatrix: TGEMMat4 read fProjection;
      property Angles: TGEMVec3 read fAngles;
      property Frustum: TGEMFrustum read fFrustum;

      constructor Create();

      procedure GetProjection();

      procedure Set2DCamera();
      procedure Set3DCamera();
      procedure SetViewport(ABounds: TGEMRectF; AViewNear: Single = 0; AViewFar: Single = 1);
      procedure SetViewDistance(AViewDistance: Single);
      procedure SetPosition(APos: TGEMVec3);
      procedure SetTarget(ATarget: TGEMVec3);
      procedure SetDirection(ADirection: TGEMVec3);
      procedure SetFOV(AValue: Single; AVerticleFOV: Boolean = true);
      procedure Translate(AValues: TGEMVec3);
      procedure Rotate(AValues: TGEMVec3);
      procedure LockVerticleFlip(AEnable: Boolean = True);

      // view culling
      function SphereInView(APosition: TGEMVec3; ARadius: Single): Boolean;

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Helper Types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  {* Rects *}
  type TGEMRectIHelper = record helper for TGEMRectI
    private
      function GetCenter(): TGEMVec3;
      function GetTopLeft(): TGEMVec3;
      function GetTopRight(): TGEMVec3;
      function GetBottomLeft(): TGEMVec3;
      function GetBottomRight(): TGEMVec3;

    public
      property Center: TGEMVec3 read GetCenter;
      property TopLeft: TGEMVec3 read GetTopLeft;
      property TopRight: TGEMVec3 read GetTopRight;
      property BottomLeft: TGEMVec3 read GetBottomLeft;
      property BottomRight: TGEMVec3 read GetBottomRight;

      {$ifndef FPC}
      class operator Implicit(A: TGEMRectF): TGEMRectI;
      class operator Implicit(A: TRect): TGEMRectI;
      class operator Add(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
      class operator Subtract(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
      {$endif}

      function toVectors(): specialize TArray<TGEMVec3>;
      procedure Assign(ARectF: TGEMRectF);
      procedure ScaleToFit(AFitRect: TGEMRectF);
  end;


  type TGEMRectFHelper = record helper for TGEMRectF
    private
      function GetCenter(): TGEMVec3;
      function GetTopLeft(): TGEMVec3;
      function GetTopRight(): TGEMVec3;
      function GetBottomLeft(): TGEMVec3;
      function GetBottomRight(): TGEMVec3;

    public
      property Center: TGEMVec3 read GetCenter;
      property TopLeft: TGEMVec3 read GetTopLeft;
      property TopRight: TGEMVec3 read GetTopRight;
      property BottomLeft: TGEMVec3 read GetBottomLeft;
      property BottomRight: TGEMVec3 read GetBottomRight;

      {$ifndef FPC}
      class operator Implicit(A: TGEMRectI): TGEMRectF;
      class operator Add(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
      class operator Subtract(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
      {$endif}

      function toVectors(): specialize TArray<TGEMVec3>;
      function toTexCoords(): specialize TArray<TGEMVec3>;
      procedure Assign(ARectI: TGEMRectI);
      procedure SetCenter(ACenter: TGEMVec3);
  end;


  {* Vectors *}
  type TGEMVec2Helper = record helper for TGEMVec2
    {$ifndef FPC}
    class operator Implicit(A: TPoint): TGEMVec2;
    class operator Implicit(A: TGEMVec3): TGEMVec2;
    class operator Implicit(A: TGEMVec4): TGEMVec2;
    class operator Explicit(A: TPoint): TGEMVEc2;
    class operator Explicit(A: TGEMVec3): TGEMVec2;
    class operator Explicit(A: TGEMVec4): TGEMVec2;
    class operator Add(A,B: TGEMVec2): TGEMVec2;
    class operator Equal(A,B: TGEMVec2): Boolean;
    class operator NotEqual(A,B: TGEMVec2): Boolean;
    {$endif}
  end;


  type TGEMVec3Helper = record helper for TGEMVec3
    {$ifndef FPC}
    class operator Implicit(A: TPoint): TGEMVec3;
    class operator Implicit(A: TGEMVec2): TGEMVec3;
    class operator Implicit(A: TGEMVec4): TGEMVec3;
    class operator Explicit(A: TGEMVec2): TGEMVec3;
    class operator Explicit(A: TGEMVec4): TGEMVec3;
    class operator Multiply(A: TGEMVec3; B: TGEMMat4): TGEMVec3;
    {$endif}
  end;

  type TGEMVec4Helper = record helper for TGEMVec4
    {$ifndef FPC}
    class operator Implicit(A: TGEMVec2): TGEMVec4;
    class operator Implicit(A: TGEMVec3): TGEMVec4;
    class operator Explicit(A: TGEMVec2): TGEMVec4;
    class operator Explicit(A: TGEMVec3): TGEMVec4;
    {$endif}
  end;


  {* Colors *}
  type TGEMColorFHelper = record helper for TGEMColorF
    public
    	{$ifndef FPC}
      class operator Equal(Color1: TGEMColorF; Color2: TGEMColorF): Boolean;
      class operator Equal(ColorF: TGEMColorF; ColorI: TGEMColorI): Boolean;
      class operator NotEqual(A,B: TGEMColorF): Boolean;
      class operator Implicit(ColorI: TGEMColorI): TGEMColorF;
      class operator Implicit(AData: Pointer): TGEMColorF;
      class operator Implicit(AColor: Cardinal): TGEMColorF;
      class operator Implicit(AColor: TGEMColorF): Cardinal;
      class operator Implicit(AVector: TGEMVec4): TGEMColorF;
      class operator Explicit(AData: Pointer): TGEMColorF;
      class operator Explicit(AVector: TGEMVec4): TGEMColorF;
      class operator Add(A,B: TGEMColorF): TGEMColorF;
      class operator Add(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
      class operator Subtract(A,B: TGEMColorF): TGEMColorF;
      class operator Subtract(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
      class operator Multiply(A: TGEMColorF; B: Single): TGEMColorF;
      {$endif}

      function toColorI(): TGEMColorI;
  end;

  type TGEMColorIHelper = record helper for TGEMColorI
    public
      {$ifndef FPC}
    	class operator Equal(Color1: TGEMColorI; Color2: TGEMColorI): Boolean;
      class operator Equal(ColorI: TGEMColorI; ColorF: TGEMColorF): Boolean;
      class operator Implicit(ColorF: TGEMColorF): TGEMColorI;
      class operator Implicit(AData: Pointer): TGEMColorI;
      class operator Implicit(AColor: Cardinal): TGEMColorI;
      class operator Implicit(AColor: TGEMColorI): Cardinal;
      class operator Explicit(AData: Pointer): TGEMColorI;
      class operator Add(A,B: TGEMColorI): TGEMColorI;
      class operator Add(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
      class operator Subtract(A,B: TGEMColorI): TGEMColorI;
      class operator Subtract(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
      class operator Multiply(A: TGEMColorI; B: Single): TGEMColorI;
      {$endif}

      function toColorF(): TGEMColorF;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Operators
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

// TGEMRectI
operator :=(A: TGEMRectF): TGEMRectI;
operator :=(A: TRect): TGEMRectI;
operator +(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
operator -(A: TGEMRectI; B: TGEMVec3): TGEMRectI;

// TGEMRectF
operator :=(A: TGEMRectI): TGEMRectF;
operator +(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
operator -(A: TGEMRectF; B: TGEMVec3): TGEMRectF;

// TGEMVec2
operator :=(A: TPoint): TGEMVec2;
operator :=(A: TGEMVec2): TPoint;
operator :=(A: TGEMVec3): TGEMVec2;
operator :=(A: TGEMVec4): TGEMVec2;
operator Explicit(A: TPoint): TGEMVEc2;
operator Explicit(A: TGEMVec3): TGEMVec2;
operator Explicit(A: TGEMVec4): TGEMVec2;
operator +(A,B: TGEMVec2): TGEMVec2;
operator =(A,B: TGEMVec2): Boolean;
operator <>(A,B: TGEMVec2): Boolean;

// TGEMVec3
operator :=(A: TPoint): TGEMVec3;
operator :=(A: TGEMVec2): TGEMVec3;
operator :=(A: TGEMVec4): TGEMVec3;
operator Explicit(A: TGEMVec2): TGEMVec3;
operator Explicit(A: TGEMVec4): TGEMVec3;
operator *(A: TGEMVec3; B: TGEMMat4): TGEMVec3;

// TGEMVec4
operator :=(A: TGEMVec2): TGEMVec4;
operator :=(A: TGEMVec3): TGEMVec4;
operator Explicit(A: TGEMVec2): TGEMVec4;
operator Explicit(A: TGEMVec3): TGEMVec4;

// TGEMColorF
operator =(Color1: TGEMColorF; Color2: TGEMColorF): Boolean;
operator =(ColorF: TGEMColorF; ColorI: TGEMColorI): Boolean;
operator <>(A,B: TGEMColorF): Boolean;
operator :=(ColorI: TGEMColorI): TGEMColorF;
operator :=(AData: Pointer): TGEMColorF;
operator :=(AColor: Cardinal): TGEMColorF;
operator :=(AColor: TGEMColorF): Cardinal;
operator :=(AVector: TGEMVec4): TGEMColorF;
operator Explicit(AData: Pointer): TGEMColorF;
operator Explicit(AVector: TGEMVec4): TGEMColorF;
operator +(A,B: TGEMColorF): TGEMColorF;
operator +(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
operator -(A,B: TGEMColorF): TGEMColorF;
operator -(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
operator *(A: TGEMColorF; B: Single): TGEMColorF;

// TGEMColorI
operator =(Color1: TGEMColorI; Color2: TGEMColorI): Boolean;
operator =(ColorI: TGEMColorI; ColorF: TGEMColorF): Boolean;
operator :=(ColorF: TGEMColorF): TGEMColorI;
operator :=(AData: Pointer): TGEMColorI;
operator :=(AColor: Cardinal): TGEMColorI;
operator :=(AColor: TGEMColorI): Cardinal;
operator Explicit(AData: Pointer): TGEMColorI;
operator +(A,B: TGEMColorI): TGEMColorI;
operator +(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
operator -(A,B: TGEMColorI): TGEMColorI;
operator -(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
operator *(A: TGEMColorI; B: Single): TGEMColorI;
operator *(A, B: TGEMColorI): TGEMColorI;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Procedures
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  {* Colors *}
  function ColorF(R,G,B: Single; A: Single = 1): TGEMColorF; overload;
  function ColorF(AColorI: TGEMColorI): TGEMColorF; overload;
  function ColorI(R,G,B: Single; A: Single = 255): TGEMColorI; overload;
  function ColorI(AColorF: TGEMColorF): TGEMColorI; overload;
  function GetColorIncrements(AStartColor, AEndColor: TGEMColorF; AIncrements: Cardinal): TGEMVec4;
  function ColorCompare(const AColor1, AColor2: TGEMColorF; const AVariance: Single = 0; const ACompareAlpha: Boolean = False): Boolean;
  function Luminance(const aColor: TGEMColorF): Single;
  function Inverse(const aColor: TGEMColorF; const aInvertAlpha: Boolean = False): TGEMColorF;

  {* Rects *}
  function RectI(ALeft,ATop,ARight,ABottom: Integer): TGEMRectI; overload;
  function RectI(ACenter: TGEMVec3; AWidth,AHeight: Single): TGEMRectI; overload;
  function RectI(ARect: TGEMRectF): TGEMRectI; overload;
  function RectIWH(ALeft,ATop,AWidth,AHeight: Single): TGEMRectI;

  function RectF(ALeft,ATop,ARight,ABottom: Single; aZ: Single = 0): TGEMRectF; overload;
  function RectF(ACenter: TGEMVec3; AWidth,AHeight: Single; aZ: Single = 0): TGEMRectF; overload;
  function RectF(ARect: TGEMRectI): TGEMRectF; overload;
  function RectFWH(ALeft,ATop,AWidth,AHeight: Single; aZ: Single = 0): TGEMRectF;

  function ScaleRect(ARect: TGEMRectF; AXRatio, AYRatio: Single): TGEMRectF;
  function FindRectOverlap(A,B: TGEMRectF): TGEMRectF;
  function CanFit(A,B: TGEMRectF): Boolean;
  function FitRectInRect(const A, B: TGEMRectF): TGEMRectF;

  {* Vectors *}
  function Vec2(AX: Single = 0; AY: Single = 0): TGEMVec2; overload;
  function Vec2(AVector: TGEMVec3): TGEMVec2; overload;
  function Vec3(AX: Single = 0; AY: Single = 0; AZ: Single = 0): TGEMVec3;
  function Vec4(AX: Single = 0; AY: Single = 0; AZ: Single = 0; AW: Single = 0): TGEMVec4;
  function Vertex(AVector: TGEMVec3; ATexCoord: TGEMVec3; AColor: TGEMColorF; ANormal: TGEMVec3): TGEMVertex;

  function Cross(AVec1, AVec2: TGEMVec3): TGEMVec3;
  function Dot(AVec1, AVec2: TGEMVec4): Single;
  function VectorLength(AVec: TGEMVec3): Single;
  function Normal(AVec: TGEMVec3): TGEMVec3;
  procedure Normalize(var AVec: TGEMVec3); overload;
  procedure Normalize(var AVec: TGEMVec2); overload;
  function Direction(APosition: TGEMVec3; ATarget: TGEMVec3): TGEMVec3;
  function Right(AUpVector: TGEMVec3; ADirectionVector: TGEMVec3): TGEMVec3;
  function Up(ADirectionVector: TGEMVec3; ARightVector: TGEMVec3): TGEMVec3;
  function SignedDistance(AVector1, AVector2: TGEMVec3): Single;
  procedure ScaleCoord(var AVectors: specialize TArray<TGEMVec3>;  AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
  procedure ScaleNDC(var AVectors: Array of TGEMVec3;  AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
  procedure FlipVerticle(var AVectors: specialize TArray<TGEMVec3>);
  procedure FlipHorizontal(var AVectors: specialize TArray<TGEMVec3>);
  function NDC(const AVector: TGEMVec3; const AWidth, AHeight, ADepth: Integer): TGEMVec3;

  {* Matrices *}
  function MatrixAdjoint(AMatrix: TGEMMat4): TGEMMat4; inline;
  function MatrixInverse(AMatrix: TGEMMat4): TGEMMat4; inline;
  function MatrixDeterminant(AMatrix: TGEMMat4): Single; inline;
  function MatrixScale(AMatrix: TGEMMat4; AFactor: Single): TGEMMat4; inline;
  function MatrixNegate(AMatrix: TGEMMat4): TGEMMat4; inline;
  function MatrixTranspose(AMatrix: TGEMMat4): TGEMMat4; inline;

  {* Cylinder *}
  function Cylinder(ACenter,AUp: TGEMVec3; ARadius,AHeight: Single): TGEMCylinder;

  {* Math *}
  function Distance(APoint1, APoint2: TGEMVec3): Single;
  function GetAngle(AStart, AEnd: TGEMVec2): Single;
  function InRect(AVec: TGEMVec3; ARect: TGEMRectF): Boolean;
  function RectCollision(ARect1,ARect2: TGEMRectF): Boolean;
  function InTriangle(const ACheckPoint: TGEMVec3; const T1,T2,T3: TGEMVec3): Boolean;
  function CircleRectCollision(ACircle: TGEMVec3; ARectangle: TGEMRectF): Boolean;
  function CircleCollision(ACirc1, ACirc2: TGEMVec3; ARadius1, ARadius2: Float): Boolean;
  function LineIntersect(Line1Start, Line1End, Line2Start, LIne2End: TGEMVec3; out AIntersection: TGEMVec3): Boolean;
  function LineRectIntersect(LineStart, LineEnd: TGEMVec3; ARect: TGEMRectF; out AIntersection: specialize TArray<TGEMVec3>): Boolean;
  function LinePlaneIntersect(L1,L2,PP,PN: TGEMVec3; out AIntersect: TGEMVec3): Boolean;
  function CylinderCollision(const ACylinder1, ACylinder2: TGEMCylinder): Boolean;
  function DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3: Single): Single;
  function EdgeFunction(constref V0, V1, P: TGEMVec2): Single;

  {* Transformations *}
  function TransformToView(out AVector: TGEMVec3; ALeft, ATop, ARight, ABottom, ANear, AFar: Single): TGEMVec3;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            Variables and Constants
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

const

  Epsilon: Double = 4.9406564584124654418e-324;

  // Size Constants
  ColorISize: Integer = 4;
  ColorFSize: Integer = 16;

  // colors Integer
  GEM_empty: TGEMColorI =         (Red: 0; Green: 0; Blue: 0; Alpha: 0);
  GEM_white: TGEMColorI =         (Red: 255; Green: 255; Blue: 255; Alpha: 255);
  GEM_black: TGEMColorI =         (Red: 0; Green: 0; Blue: 0; Alpha: 255);

  GEM_grey: TGEMColorI =          (Red: 128; Green: 128; Blue: 128; Alpha: 255);
  GEM_light_grey: TGEMColorI =    (Red: 191; Green: 191; Blue: 191; Alpha: 255);
  GEM_dark_grey: TGEMColorI =     (Red: 75; Green: 75; Blue: 75; Alpha: 255);

  GEM_red: TGEMColorI =           (Red: 255; Green: 0; Blue: 0; Alpha: 255);
  GEM_ligh_red: TGEMColorI =      (Red: 255; Green: 125; Blue: 128; Alpha: 255);
  GEM_dark_red: TGEMColorI =      (Red: 128; Green: 0; Blue: 0; Alpha: 255);

  GEM_yellow: TGEMColorI =        (Red: 255; Green: 255; Blue: 0; Alpha: 255);
  GEM_light_yellow: TGEMColorI =  (Red: 255; Green: 255; Blue: 128; Alpha: 255);
  GEM_dark_yellow: TGEMColorI =   (Red: 128; Green: 128; Blue: 0; Alpha: 255);

  GEM_blue: TGEMColorI =          (Red: 0; Green: 0; Blue: 255; Alpha: 255);
  GEM_light_blue: TGEMColorI =    (Red: 128; Green: 128; Blue: 255; Alpha: 255);
  GEM_dark_blue: TGEMColorI =     (Red: 0; Green: 0; Blue: 255; Alpha: 255);

  GEM_green: TGEMColorI =         (Red: 0; Green: 255; Blue: 0; Alpha: 255);
  GEM_light_green: TGEMColorI =   (Red: 128; Green: 255; Blue: 128; Alpha: 255);
  GEM_dark_green: TGEMColorI =    (Red: 0; Green: 128; Blue: 0; Alpha: 255);

  GEM_orange: TGEMColorI =        (Red: 255; Green: 128; Blue: 0; Alpha: 255);
  GEM_light_orange: TGEMColorI =  (Red: 255; Green: 190; Blue: 128; Alpha: 255);
  GEM_dark_orange: TGEMColorI =   (Red: 128; Green: 64; Blue: 0; Alpha: 255);

  GEM_brown: TGEMColorI =         (Red: 128; Green: 64; Blue: 0; Alpha: 255);
  GEM_light_brown: TGEMColorI =   (Red: 180; Green: 90; Blue: 0; Alpha: 255);
  GEM_dark_brown: TGEMColorI =    (Red: 96; Green: 48; Blue: 0; Alpha: 255);

  GEM_purple: TGEMColorI =        (Red: 128; Green: 0; Blue: 128; Alpha: 255);
  GEM_cyan: TGEMColorI =          (Red: 0; Green: 255; Blue: 255; Alpha: 255);
  GEM_magenta: TGEMColorI =       (Red: 255; Green: 0; Blue: 255; Alpha: 255);
  GEM_pink: TGEMColorI =          (Red: 255; Green: 196; Blue: 196; Alpha: 255);

  // colors float
  GEM_empty_f: TGEMColorF =         (Red: 0 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 0 / 255);
  GEM_white_f: TGEMColorF =         (Red: 255 / 255; Green: 255 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_black_f: TGEMColorF =         (Red: 0 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 255 / 255);

  GEM_grey_f: TGEMColorF =          (Red: 128 / 255; Green: 128 / 255; Blue: 128 / 255; Alpha: 255 / 255);
  GEM_light_grey_f: TGEMColorF =    (Red: 75 / 255; Green: 75 / 255; Blue: 75 / 255; Alpha: 255 / 255);
  GEM_dark_grey_f: TGEMColorF =     (Red: 225 / 255; Green: 225 / 255; Blue: 225 / 255; Alpha: 255 / 255);

  GEM_red_f: TGEMColorF =           (Red: 0 / 255; Green: 0 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_ligh_red_f: TGEMColorF =      (Red: 128 / 255; Green: 125 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_dark_red_f: TGEMColorF =      (Red: 0 / 255; Green: 0 / 255; Blue: 128 / 255; Alpha: 255 / 255);

  GEM_yellow_f: TGEMColorF =        (Red: 0 / 255; Green: 255 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_light_yellow_f: TGEMColorF =  (Red: 128 / 255; Green: 255 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_dark_yellow_f: TGEMColorF =   (Red: 0 / 255; Green: 128 / 255; Blue: 128 / 255; Alpha: 255 / 255);

  GEM_blue_f: TGEMColorF =          (Red: 255 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 255 / 255);
  GEM_light_blue_f: TGEMColorF =    (Red: 255 / 255; Green: 128 / 255; Blue: 128 / 255; Alpha: 255 / 255);
  GEM_dark_blue_f: TGEMColorF =     (Red: 128 / 255; Green: 0 / 255; Blue: 0 / 255; Alpha: 255 / 255);

  GEM_green_f: TGEMColorF =         (Red: 0 / 255; Green: 255 / 255; Blue: 0 / 255; Alpha: 255 / 255);
  GEM_light_green_f: TGEMColorF =   (Red: 128 / 255; Green: 255 / 255; Blue: 128 / 255; Alpha: 255 / 255);
  GEM_dark_green_f: TGEMColorF =    (Red: 0 / 255; Green: 128 / 255; Blue: 0 / 255; Alpha: 255 / 255);

  GEM_orange_f: TGEMColorF =        (Red: 0 / 255; Green: 128 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_light_orange_f: TGEMColorF =  (Red: 128 / 255; Green: 190 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_dark_orange_f: TGEMColorF =   (Red: 0 / 255; Green: 64 / 255; Blue: 128 / 255; Alpha: 255 / 255);

  GEM_brown_f: TGEMColorF =         (Red: 0 / 255; Green: 64 / 255; Blue: 128 / 255; Alpha: 255 / 255);
  GEM_light_brown_f: TGEMColorF =   (Red: 0 / 255; Green: 90 / 255; Blue: 180 / 255; Alpha: 255 / 255);
  GEM_dark_brown_f: TGEMColorF =    (Red: 0 / 255; Green: 48 / 255; Blue: 96 / 255; Alpha: 255 / 255);

  GEM_purple_f: TGEMColorF =        (Red: 128 / 255; Green: 0 / 255; Blue: 128 / 255; Alpha: 255 / 255);
  GEM_cyan_f: TGEMColorF =          (Red: 255 / 255; Green: 255 / 255; Blue: 0 / 255; Alpha: 255 / 255);
  GEM_magenta_f: TGEMColorF =       (Red: 255 / 255; Green: 0 / 255; Blue: 255 / 255; Alpha: 255 / 255);
  GEM_pink_f: TGEMColorF =          (Red: 196 / 255; Green: 196 / 255; Blue: 255 / 255; Alpha: 255 / 255);

  // rects
  from_center: Integer = 0;
  from_left: Integer  = 1;
  from_top: Integer  = 2;
  from_right: Integer  = 3;
  from_bottom: Integer  = 4;

  // other
  camera_type_2D: Integer = 0;
  camera_type_3D: Integer = 1;

implementation

uses
	GEMMath; // for access to TGEMInstance and GEM state object


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Operators
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}



{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Functions
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function ColorF(R,G,B: Single; A: Single = 1): TGEMColorF;
  begin
    Result.Red := ClampF(R);
    Result.Green := ClampF(G);
    Result.Blue := ClampF(B);
    Result.Alpha := ClampF(A);
  end;

function ColorF(AColorI: TGEMColorI): TGEMColorF;
  begin
    Result := AColorI.toColorF;
  end;

function ColorI(R,G,B: Single; A: Single = 255): TGEMColorI;
  begin
    Result.Red := ClampI(R);
    Result.Green := ClampI(G);
    Result.Blue := ClampI(B);
    Result.Alpha := ClampI(A);
  end;

function ColorI(AColorF: TGEMColorF): TGEMColorI;
  begin
    Result := AColorF.toColorI;
  end;


function GetColorIncrements(AStartColor, AEndColor: TGEMColorF; AIncrements: Cardinal): TGEMVec4;
var
RedChange,GreenChange,BlueChange,AlphaChange: Single;
RedDiff,GreenDiff,BlueDiff,AlphaDiff: Single;
  begin
    RedDiff := AEndColor.Red - AStartColor.Red;
    GreenDiff := AEndColor.Green - AStartColor.Green;
    BlueDiff := AEndColor.Blue - AStartColor.Blue;
    AlphaDiff := AEndColor.Alpha - AStartColor.Alpha;
    RedChange := RedDiff / AIncrements;
    GreenChange := GreenDiff / AIncrements;
    BlueChange := BlueDiff / AIncrements;
    AlphaChange := AlphaDiff / AIncrements;
    Result := Vec4(RedChange,GreenChange,BlueChange,AlphaChange);
  end;

function ColorCompare(const AColor1, AColor2: TGEMColorF; const AVariance: Single = 0; const ACompareAlpha: Boolean = False): Boolean;
  begin
    Result := True;
    if abs(AColor1.Red - AColor2.Red) > AVariance then Exit(False);
    if abs(AColor1.Green - AColor2.Green) > AVariance then Exit(False);
    if abs(AColor1.Blue - AColor2.Blue) > AVariance then Exit(False);
    if ACompareAlpha then begin
      if abs(AColor1.Alpha - AColor2.Alpha) > AVariance then Exit(False);
    end;
  end;

function Luminance(const aColor: TGEMColorF): Single;
  begin
    Exit( (aColor.Red * 0.2126) + (aColor.Green * 0.7152) + (aColor.Blue * 0.0722) );
  end;

function Inverse(const aColor: TGEMColorF; const aInvertAlpha: Boolean = False): TGEMColorF;
  begin
    Result.Red := 1 - aColor.Red;
    Result.Green := 1 - aColor.Green;
    Result.Blue := 1 - aColor.Blue;
    if aInvertAlpha then Result.Alpha := 1 - aColor.Alpha else Result.Alpha := 1;
  end;

function RectI(ALeft,ATop,ARight,ABottom: Integer): TGEMRectI;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fRight := ARight;
    Result.fBottom := ABottom;
    Result.fWidth := ARight - ALeft + 1;
    Result.fHeight := ABottom - ATop + 1;
    Result.fX := ALeft + trunc(Result.fWidth / 2);
    Result.fY := ATop + trunc(Result.fHeight / 2);
  end;

function RectI(ACenter: TGEMVec3; AWidth,AHeight: Single): TGEMRectI;
  begin
    Result.fWidth := trunc(AWidth);
    Result.fHeight := trunc(AHeight);
    Result.SetCenter(ACenter.X, ACenter.Y, ACenter.Z);
  end;

function RectI(ARect: TGEMRectF): TGEMRectI;
  begin
    Result.fWidth := trunc(ARect.Width);
    Result.fHeight := trunc(ARect.Height);
    Result.SetCenter(ARect.X, ARect.Y, ARect.Z);
  end;

function RectIWH(ALeft,ATop,AWidth,AHeight: single): TGEMRectI;
  begin
    Result.fLeft := Trunc(ALeft);
    Result.fTop := Trunc(ATop);
    Result.fWidth := Trunc(AWidth);
    Result.fHeight := Trunc(AHeight);
    Result.fRight := Trunc(ALeft + (AWidth));
    Result.fBottom := Trunc(ATop + (AHeight));
    Result.fX := Trunc(ALeft + (AWidth / 2));
    Result.fY := Trunc(ATop + (AHeight / 2));
  end;

function RectF(ALeft,ATop,ARight,ABottom: Single; aZ: Single = 0): TGEMRectF;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fRight := ARight;
    Result.fBottom := ABottom;
    Result.fWidth := ARight - ALeft;
    Result.fHeight := ABottom - ATop;
    Result.fX := ALeft + (Result.fWidth / 2);
    Result.fY := ATop + (Result.fHeight / 2);
    Result.fZ := aZ;
  end;

 function RectF(ACenter: TGEMVec3; AWidth,AHeight: Single; aZ: Single = 0): TGEMRectF;
  begin
    Result.fWidth := (AWidth);
    Result.fHeight := (AHeight);
    Result.SetCenter(ACenter);
  end;

function RectF(ARect: TGEMRectI): TGEMRectF;
  begin

  end;

function RectFWH(ALeft,ATop,AWidth,AHeight: Single; aZ: Single = 0): TGEMRectF;
  begin
    Result.fLeft := ALeft;
    Result.fTop := ATop;
    Result.fWidth := AWidth;
    Result.fHeight := AHeight;
    Result.fRight := ALeft + (AWidth);
    Result.fBottom := ATop + (AHeight);
    Result.fX := ALeft + (AWidth / 2);
    Result.fY := ATop + (AHeight / 2);
    Result.fZ := aZ;
  end;

function ScaleRect(ARect: TGEMRectF; AXRatio, AYRatio: Single): TGEMRectF;
var
NewX,NewY,NewWidth,NewHeight: Single;
  begin
    NewX := ARect.Left * AXRatio;
    NewY := ARect.Top * AYRatio;
    NewWidth := ARect.width * AXRatio;
    NewHeight := ARect.Height * AYRatio;
    Result := RectFWH(NewX,NewY,NewWidth,NewHeight);
  end;

function FindRectOverlap(A,B: TGEMRectF): TGEMRectF;
var
NewLeft, NewRight, NewTop, NewBottom: Single;
	begin
    if RectCollision(A,B) = False then Exit(RectF(0,0,0,0));

    NewLeft := Smallest([A.Left, B.Left]);
    NewRight := Biggest([A.Right, B.Right]);
    NewTop := Smallest([A.Top, B.Top]);
    NewBottom := Biggest([A.Bottom, B.Bottom]);

    Exit(RectF(NewLeft, NewTop, NewRight, NewBottom));
  end;

function CanFit(A,B: TGEMRectF): Boolean;
  begin
    if (A.Left >= B.Left) and
       (A.Top >= B.Top) and
       (A.Right <= B.Right) and
       (A.Bottom <= B.Bottom) then begin
        Exit(True);
    end else begin
      Exit(False);
    end;
  end;

function FitRectInRect(const A, B: TGEMRectF): TGEMRectF;
var
Ratio: Single;
Aspect: Single;
NewWidth, NewHeight: Single;
  begin

    Aspect := B.Width / B.Height;

    if Aspect >= 1 then begin

      if B.Width >= A.Width then begin
        Ratio := A.Width / B.Width;

        if B.Height * Ratio > A.Height then begin
          Ratio := A.Height / B.Height;
        end;

      end else begin

        Ratio := A.Width / B.Width;

        if B.Height * Ratio > A.Height then begin
          Ratio := A.Height / B.Height;
        end;

      end;

    end else begin

      if B.Height >= A.Height then begin
        Ratio := A.Height / B.Height;

        if B.Width * Ratio > A.Width then begin
          Ratio := A.Width / B.Width;
        end;

      end else begin

        Ratio := A.Height / B.Height;

        if B.Width * Ratio > A.Width then begin
          Ratio := A.Width / B.Width;
        end;

      end;

    end;

    Result.SetSize(B.Width * Ratio, B.Height * Ratio);
    Result.SetCenter(A.Center);
  end;

{* Vectors *}
function Vec2(AX: Single = 0; AY: Single = 0): TGEMVec2;
  begin
    Result.X := AX;
    Result.Y := AY;
  end;

function Vec2(AVector: TGEMVec3): TGEMVec2;
  begin
    Result.X := AVector.X;
    Result.Y := AVector.Y;
  end;

function Vec3(AX: Single = 0; AY: Single = 0; AZ: Single = 0): TGEMVec3;
  begin
    Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
  end;

function Vec4(AX: Single = 0; AY: Single = 0; AZ: Single = 0; AW: Single = 0): TGEMVec4;
  begin
    Result.X := AX;
    Result.Y := AY;
    Result.Z := AZ;
    Result.W := AW;
  end;

function Vertex(AVector: TGEMVec3; ATexCoord: TGEMVec3; AColor: TGEMColorF; ANormal: TGEMVec3): TGEMVertex;
  begin
    Result.Vector := AVector;
    Result.TexCoord := ATexCoord;
    Result.Color := AColor;
    Result.Normal := ANormal;
  end;

function Cross(AVec1, AVec2: TGEMVec3): TGEMVec3;
  begin
    Result.X := (AVec1.Y * AVec2.Z) - (AVec1.Z * AVec2.Y);
    Result.Y := (AVec1.Z * AVec2.X) - (AVec1.X * AVec2.Z);
    Result.Z := (AVec1.X * AVec2.Y) - (AVec1.Y * AVec2.X);
  end;

function Dot(AVec1, AVec2: TGEMVec4): Single;
  begin
    Result := (AVec1.X * AVec2.X) + (AVec1.Y * AVec2.Y) + (AVec1.Z * AVec2.Z) + (AVec1.W * AVec2.W);
  end;

function VectorLength(AVec: TGEMVec3): Single;
  begin
    Result := Sqrt( (AVec.X * AVec.X) + (AVec.Y * AVec.Y) + (AVec.Z * AVec.Z) );
  end;

function Normal(AVec: TGEMVec3): TGEMVec3;
  begin
    Result := AVec;
    Normalize(Result);
  end;

procedure Normalize(var AVec: TGEMVec3);
var
Len: Single;
  begin
    Len := VectorLength(AVec);
    AVec.X := AVec.X / Len;
    AVec.Y := AVec.Y / Len;
    AVec.Z := AVec.Z / Len;
    if IsNan(AVec.X) then AVec.X := 0;
    if IsNan(AVec.Y) then AVec.Y := 0;
    if IsNan(AVec.Z) then AVec.Z := 0;
  end;

procedure Normalize(var AVec: TGEMVec2);
var
Len: Single;
  begin
    Len := VectorLength(AVec);
    AVec.X := AVec.X / Len;
    AVec.Y := AVec.Y / Len;
    if IsNan(AVec.X) then AVec.X := 0;
    if IsNan(AVec.Y) then AVec.Y := 0;
  end;

function Direction(APosition: TGEMVec3; ATargeT: TGEMVec3): TGEMVec3;
  begin
    Result := Normal(APosition - ATarget);
  end;

function Right(AUpVector: TGEMVec3; ADirectionVector: TGEMVec3): TGEMVec3;
  begin
    Result := Normal(Cross(AUpVector,ADirectionVector));
  end;

function Up(ADirectionVector: TGEMVec3; ARightVector: TGEMVec3): TGEMVec3;
  begin
    Result := Cross(ADirectionVector, ARightVector);
  end;

function SignedDistance(AVector1, AVector2: TGEMVec3): Single;
  begin
    Result := VectorLength(AVector1 - AVector2) * Sign(Dot(AVector1, AVector2));
  end;

procedure ScaleCoord(var AVectors: specialize TArray<TGEMVec3>; AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
var
Len: Integer;
I: Integer;
  begin
    Len := Length(AVectors);

    for I := 0 to Len - 1 do begin
      AVectors[i].X := AVectors[i].X / AWidth;
      AVectors[i].Y := AVectors[i].Y / AHeight;
      AVectors[i].Z := AVectors[i].Z / ADepth;
    end;

  end;

procedure ScaleNDC(var AVectors: Array of TGEMVec3; AWidth: Single = 0; AHeight: Single = 0; ADepth: Single = 0);
var
Len: Integer;
I: Integer;
  begin
    Len := Length(AVectors);

    for I := 0 to Len - 1 do begin
      AVectors[i].X := -1 + ((AVectors[i].X / AWidth) * 2);
      AVectors[i].Y := -1 + ((AVectors[i].Y / AHeight) * 2);
      AVectors[i].Z := -1 + ((AVectors[i].Z / ADepth) * 2);
    end;

  end;

procedure FlipVerticle(var AVectors: specialize TArray<TGEMVec3>);
var
Low,High,Middle,Diff: Single;
I: Integer;
  begin

    Low := AVectors[0].Y;
    High := Low;

    for I := 1 to Length(AVectors) - 1 do begin
      if AVectors[i].Y < Low then Low := AVectors[i].Y;
      if AVectors[i].Y > High then High := AVectors[i].Y;
    end;

    Middle := Low + ((High - Low) / 2);

    for I := 0 to Length(AVectors) - 1 do begin
      Diff := AVectors[i].Y - Middle;
      AVectors[i].Y := Middle + (Diff * -1);
    end;

  end;

procedure FlipHorizontal(var AVectors: specialize TArray<TGEMVec3>);
var
Low,High,Middle,Diff: Single;
I: Integer;
  begin

    Low := 0;
    High := 0;

    for I := 0 to Length(AVectors) - 1 do begin
      if AVectors[i].X < Low then Low := AVectors[i].X;
      if AVectors[i].X > High then High := AVectors[i].X;
    end;

    Middle := Low + ((High - Low) / 2);

    for I := 0 to Length(AVectors) - 1 do begin
      Diff := AVectors[i].X - Middle;
      AVectors[i].X := Middle + (Diff * -1);
    end;

  end;

function NDC(const AVector: TGEMVec3; const AWidth, AHeight, ADepth: Integer): TGEMVec3;
  begin
    Result.X := -1 + ((AVector.X / AWidth) * 2);
    Result.Y := -1 + ((AVector.Y / AHeight) * 2);
    Result.Z := AVector.Z / ADepth;
  end;

{* Matrices *}
function MatrixAdjoint(AMatrix: TGEMMat4): TGEMMat4;
var
a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4: Single;
  begin
    a1 := AMatrix.M[0,0];
    b1 := AMatrix.M[0,1];
    c1 := AMatrix.M[0,2];
    d1 := AMatrix.M[0,3];
    a2 := AMatrix.M[1,0];
    b2 := AMatrix.M[1,1];
    c2 := AMatrix.M[1,2];
    d2 := AMatrix.M[1,3];
    a3 := AMatrix.M[2,0];
    b3 := AMatrix.M[2,1];
    c3 := AMatrix.M[2,2];
    d3 := AMatrix.M[2,3];
    a4 := AMatrix.M[3,0];
    b4 := AMatrix.M[3,1];
    c4 := AMatrix.M[3,2];
    d4 := AMatrix.M[3,3];

    Result.M[0,0] := DetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
    Result.M[1,0] := -DetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
    Result.M[2,0] := DetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
    Result.M[3,0] := -DetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

    Result.M[0,1] := -DetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
    Result.M[1,1] := DetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
    Result.M[2,1] := -DetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
    Result.M[3,1] := DetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

    Result.M[0,2] := DetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
    Result.M[1,2] := -DetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
    Result.M[2,2] := DetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
    Result.M[3,2] := -DetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

    Result.M[0,3] := -DetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
    Result.M[1,3] := DetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
    Result.M[2,3] := -DetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
    Result.M[3,3] := DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
  end;


function MatrixInverse(AMatrix: TGEMMat4): TGEMMat4;
var
Det: Single;
Default: TGEMMat4;
  begin
    Det := MatrixDeterminant(AMatrix);
    if Abs(Det) < Epsilon then
      Result := Default
    else
      Result := MatrixScale(MatrixAdjoint(AMatrix), 1/ Det);
  end;


function MatrixDeterminant(AMatrix: TGEMMat4): Single;
  begin
    Result :=
      AMatrix.M[0,0] * DetInternal(AMatrix.M[1,1], AMatrix.M[2,1], AMatrix.M[3,1], AMatrix.M[1,2],
      AMatrix.M[2,2], AMatrix.M[3,2], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      - AMatrix.M[0,1] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,2], AMatrix.M[2,2],
      AMatrix.M[3,2], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      + AMatrix.M[0,2] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,1], AMatrix.M[2,1],
      AMatrix.M[3,1], AMatrix.M[1,3], AMatrix.M[2,3], AMatrix.M[3,3])
      - AMatrix.M[0,3] * DetInternal(AMatrix.M[1,0], AMatrix.M[2,0], AMatrix.M[3,0], AMatrix.M[1,1], AMatrix.M[2,1],
      AMatrix.M[3,1], AMatrix.M[1,2], AMatrix.M[2,2], AMatrix.M[3,2]);
  end;


function MatrixScale(AMatrix: TGEMMat4; AFactor: Single): TGEMMat4;
var
I: Integer;
  begin
    for I := 0 to 2 do
    begin
      Result.M[I,0] := AMatrix.M[I,0] * AFactor;
      Result.M[I,1] := AMatrix.M[I,1] * AFactor;
      Result.M[I,2] := AMatrix.M[I,2] * AFactor;
      Result.M[I,3] := AMatrix.M[I,3] * AFactor;
    end;
  end;


function MatrixNegate(AMatrix: TGEMMat4): TGEMMat4;
var
I,Z: Integer;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        Result.M[I,Z] := -AMatrix.M[I,Z];
      end;
    end;
  end;

function MatrixTranspose(AMatrix: TGEMMat4): TGEMMat4;
  begin
    Result := AMatrix;
    Result.Transpose();
  end;

function Cylinder(ACenter,AUp: TGEMVec3; ARadius,AHeight: Single): TGEMCylinder;
  begin
    Result.fRadius := ARadius;
    Result.fHeight := AHeight;
    Result.fUp := AUp;
    Result.SetCenter(ACenter);
  end;

function Distance(APoint1, APoint2: TGEMVec3): Single;
  begin
    Result := Sqrt( IntPower(APoint1.X - APoint2.X, 2) + IntPower(APoint1.Y - APoint2.Y, 2) + IntPower(APoint1.Z - APoint2.Z, 2) );
  end;

function GetAngle(AStart, AEnd: TGEMVec2): Single;
  begin
    Result := ArcTan2(AEnd.Y - AStart.Y, AEnd.X - AStart.X);
  end;

function InRect(AVec: TGEMVec3; ARect: TGEMRectF): Boolean;
  begin
    Result := False;

    if (Avec.X >= ARect.Left) and
      (AVec.X <= ARect.Right) and
      (AVec.Y >= ARect.Top) and
      (AVec.Y <= ARect.Bottom) then begin
        Result := True;
    end;
  end;

function RectCollision(ARect1,ARect2: TGEMRectF): Boolean;
var
DiffWidth,ComWidth: Single;
  begin
    Result := False;

    DiffWidth := abs(ARect1.X - ARect2.X);
    ComWidth := (ARect1.Width / 2) + (ARect2.Width / 2);
    if DiffWidth < ComWidth then begin

      DiffWidth := abs(ARect1.Y- ARect2.Y);
      ComWidth := (ARect1.Height / 2) + (ARect2.Height / 2);
      if DiffWidth < ComWidth then begin
        Result := True;
      end;
    end;
  end;

function InTriangle(const ACheckPoint: TGEMVec3; const T1,T2,T3: TGEMVec3): Boolean;
var
A,B,C: Single;
  begin
    //Result := False;
    //
    //a := ((T2.Y - T3.Y)*(ACheckPoint.X - T3.X) + (T3.X - T2.X)*(ACheckPoint.Y - T3.Y)) / ((T2.Y - T3.Y)*(T1.x - T3.X) + (T3.X - T2.X)*(T1.Y - T3.Y));
    //b := ((T3.Y - T1.Y)*(ACheckPoint.X - T3.X) + (T1.x - T3.X)*(ACheckPoint.Y - T3.Y)) / ((T2.Y - T3.Y)*(T1.x - T3.X) + (T3.X - T2.X)*(T1.Y - T3.Y));
    //c := 1 - a - b;
    //
    //if (A >= 0) and (A <= 1) and (B >= 0) and (B <= 1) and (C >= 0) and (C <= 1) then begin
    //  Result := True;
    //end;

    Result := (EdgeFunction(T1, T2, ACheckPoint) > 0) and (EdgeFunction(T2, T3, ACheckPoint) > 0) and (EdgeFunction(T3, T1, ACheckPoint) > 0);
  end;


function CircleRectCollision(ACircle: TGEMVec3; ARectangle: TGEMRectF): Boolean;
// ACircle is represented by a TGEMVec3 in that X and Y represent the center of the circle
// and Z represents the radius of the circle;
var
Closest: TGEMVec2;
  begin
    result := false;
    // first, check if the center of the circle is in the rectangle
    if InRect(ACircle, ARectangle) then begin
      result := true;
      exit;
    end;

    // if not, calculate closest point of rectangle to center of circle
    // if closest point is within Radius distance, we have collision
    Closest.X := Max(ARectangle.X1,Min(ACircle.X, ARectangle.X2));
    Closest.Y := Max(ARectangle.Y1,Min(ACircle.Y, ARectangle.Y2));

    if Distance(Closest, TGEMVec2(ACircle)) <= ACircle.Z then begin
      Result := true;
    end;
  end;

function CircleCollision(ACirc1, ACirc2: TGEMVec3; ARadius1, ARadius2: Float): Boolean;
  begin
    Result := False;
    if VectorLength((Vec2(ACirc1) - Vec2(ACirc2))) <= ARadius1 + ARadius2 then Result := True;
  end;

function LineIntersect(Line1Start, Line1End, Line2Start, LIne2End: TGEMVec3; out AIntersection: TGEMVec3): Boolean;
var
uA, uB: Single;
  begin

    Result := false;

    uA := ((Line2End.X-Line2Start.X)*(Line1Start.Y-Line2Start.Y) -
          (Line2End.Y-Line2Start.Y)*(Line1Start.X-Line2Start.X)) / ((Line2End.Y-Line2Start.Y)*(Line1End.X-Line1Start.x) -
          (Line2End.X-Line2Start.X)*(Line1End.Y-Line1Start.Y));

    uB := ((Line1end.X-Line1Start.X)*(Line1Start.Y-Line2Start.Y) -
          (Line1end.Y-Line1Start.Y)*(Line1Start.X-Line2Start.X)) / ((Line2End.Y-Line2Start.Y)*(Line1End.X-Line1Start.X) -
          (Line2End.X-Line2Start.X)*(Line1End.y-Line1Start.y));

    if (uA >= 0) and (uA <= 1) and (uB >= 0) and (uB <= 1) then begin
      Result := True;
      AIntersection.X := Line1Start.X + (uA * (Line1End.X-Line1Start.X));
      AIntersection.Y := Line1Start.Y + (uA * (Line1End.y-Line1Start.Y));
    end;
  end;


function LineRectIntersect(LineStart, LineEnd: TGEMVec3; ARect: TGEMRectF; out AIntersection: specialize TArray<TGEMVec3>): Boolean;
var
RectPoint1, RectPoint2: TGEMVec3;
I: Integer;
CurDist: Single;
OutPoint: TGEMVec3;
SendPoints: specialize TArray<TGEMVec3>;
OldDist: Single;
  begin

    Result := False;
    CurDist := 0;
    OldDist := 0;

    for I := 0 to 3 do begin

      case I of

        0: // left
          begin
            RectPoint1 := ARect.TopLeft;
            RectPoint2 := ARect.BottomLeft;
          end;

        1: // right
          begin
            RectPoint1 := Arect.TopRight;
            RectPoint2 := Arect.BottomRight;
          end;

        2: // top
          begin
            RectPoint1 := ARect.TopLeft;
            RectPoint2 := ARect.TopRight;
          end;

        3: // bottom
          begin
            RectPoint1 := ARect.BottomLeft;
            RectPoint2 := ARect.BottomRight;
          end;

      end;


      if LineIntersect(LineStart,LineEnd,RectPoint1,RectPoint2,OutPoint) then begin
        Result := True;
        SetLength(SendPoints, Length(SendPoints) + 1);
        SendPoints[High(SendPoints)] := OutPoint;
      end;

    end;


    AIntersection := SendPoints;

  end;


function LinePlaneIntersect(L1,L2,PP,PN: TGEMVec3; out AIntersect: TGEMVec3): Boolean;
var
U,W: TGEMVec3;
DotVal: Single;
Fac: Single;
  begin
    // p0, p1: Define the line.
    // p_co, p_no: define the plane:
    // p_co Is a point on the plane (plane coordinate).
    // p_no Is a normal vector defining the plane direction;
    // (does not need to be normalized).

    // Return a Vector or None (when the intersection can't be found).

    Result := false;

    U := L2 - L1;
    DotVal := Dot(PN, U);

    if (abs(DotVal) > epsilon) then begin
        // The factor of the point between p0 -> p1 (0 - 1)
        // if 'fac' is between (0 - 1) the point intersects with the segment.
        // Otherwise:
        //  < 0.0: behind p0.
        //  > 1.0: infront of p1.
        W := L1 - PP;
        Fac := -Dot(PN, W) / DotVal;

        if (Fac < 0) or (Fac > 1) then begin
          result := false;
          Exit;
        end;

        U := U * Fac;
        AIntersect := L1 + U;
        Result := True;

    end else begin
      //The segment is parallel to plane.
      Result := False;
    end;
  end;


function CylinderCollision(const ACylinder1, ACylinder2: TGEMCylinder): Boolean;
var
CheckC1, CheckC2: TGEMCylinder;
OutPoint: TGEMVec3;
CheckPoint: TGEMVec3;
ComWidth: Single;
Right: TGEMVec3;
  begin
    Result := False;

    CheckC1 := ACylinder1;
    CheckC2 := ACylinder2;

    CheckC2.SetUpVector(CheckC2.fUp - (CheckC1.fUp * Dot(CheckC2.fUp, CheckC1.fUp)) );
    CheckC1.SetUpVector(Vec3(0,1,0));

    Right := Vec3(0,0,CheckC2.fUp.Y);

    CheckPoint := CheckC1.Top;

    if LinePlaneIntersect(CheckC2.Bottom, CheckC2.Top, CheckC1.Top, CheckC1.fUp, OutPoint) = False then begin
      CheckPoint := CheckC1.Bottom;
      if LinePlaneIntersect(CheckC2.Bottom, CheckC2.Top, CheckC1.Bottom, CheckC1.fUp, OutPoint) = False then begin
        Exit;
      end;
    end;

    ComWidth := CheckC1.Radius + CheckC2.Radius;
    if Distance(OutPoint, CheckPoint) <= ComWidth then begin
      Result := True;
    end;

  end;


function DetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3: Single): Single;
  begin
    Result := a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) + c1 * (a2 * b3 - a3 * b2);
  end;


function EdgeFunction(constref V0, V1, P: TGEMVec2): Single;
	begin
  	Exit( ((P.X - V0.X) * (V1.Y - V0.Y)) - ((P.Y - V0.Y) * (V1.X - V0.X)) );
  end;


function TransformToView(out AVector: TGEMVec3; ALeft, ATop, ARight, ABottom, ANear, AFar: Single): TGEMVec3;
  begin

    // calculating the point on viewport
    Result.X := 0.5 * (AVector.X + 1) * (ARight - ALeft);
    Result.Y := 0.5 * (AVector.Y + 1) * (ABottom - ATop);
    Result.Z := 0.5 * (AVector.Z + 1) * (AFar - ANear);

    AVector := Result;
  end;



{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMColorF
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TGEMColorF.Inverse: TGEMColorF;
  begin
    Result.Red := 1 - Self.Red;
    Result.Green := 1 - Self.Green;
    Result.Blue := 1 - Self.Blue;
  end;

function TGEMColorF.ToString: String;
  begin
    Result := Self.Red.ToString + ', ' + Self.Green.ToString + ', ' + Self.Blue.ToString + ', ' + Self.Alpha.ToString;
  end;

procedure TGEMColorF.Lighten(AValue: Single);
var
Brightness: Single;
  begin
    // TO-DO
  end;

function TGEMColorF.ToGrey(): TGEMColorF;
var
Value: Single;
  begin
    Value := ClampF((Self.Red * 0.2126) + (Self.Green * 0.7152) + (Self.Blue * 0.0722));
    Result := ColorF(Value, Value, Value, Self.Alpha);
  end;

function TGEMColorFHelper.toColorI: TGEMColorI;
  begin
    Result.Red := ClampI(Self.Red * 255);
    Result.Green := ClampI(Self.Green * 255);
    Result.Blue := ClampI(Self.Blue * 255);
    Result.Alpha := ClampI(Self.Alpha * 255);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Equal(Color1: TGEMColorF; Color2: TGEMColorF): Boolean;
{$else}
operator =(Color1: TGEMColorF; Color2: TGEMColorF): Boolean;
{$endif}
var
Diff: Single;
  begin
    Result := False;

    // exit and return false if any components fall outside of thresholdrange
    //Diff := abs(Color1.Red - Color2.Red);
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs(COlor1.Green - Color2.Green);
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs(COlor1.Blue - Color2.Blue);
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs(COlor1.Alpha - Color2.Alpha);
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Result := True;

  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Equal(ColorF: TGEMColorF; ColorI: TGEMColorI): Boolean;
{$else}
operator =(ColorF: TGEMColorF; ColorI: TGEMColorI): Boolean;
{$endif}
var
Diff: Single;
  begin
    Result := False;

    //// exit and return false if any components fall outside of thresholdrange
    //Diff := abs((ColorF.Red * 255) - ColorI.Red) / 255;
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs((ColorF.Green * 255) - ColorI.Green) / 255;
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs((ColorF.Blue * 255) - ColorI.Blue) / 255;
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Diff := abs((ColorF.Alpha * 255) - ColorI.Alpha) / 255;
    //if Diff > GEM.ColorCompareThreshold then exit;
    //
    //Result := True;

  end;

{$ifndef FPC}
class operator TGEMColorFHelper.NotEqual(A,B: TGEMColorF): Boolean;
{$else}
operator <>(A,B: TGEMColorF): Boolean;
{$endif}
  begin
    Result := False;
    if (A.Red <> B.Red) or (A.Green <> B.Green) or (A.Blue <> B.Blue) or (A.Alpha <> B.Alpha) then begin
      Result := True;
    end;
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Implicit(ColorI: TGEMColorI): TGEMColorF;
{$else}
operator :=(ColorI: TGEMColorI): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(ColorI.Red / 255);
    Result.Green := ClampF(ColorI.Green / 255);
    Result.Blue := ClampF(ColorI.Blue / 255);
    Result.Alpha := ClampF(ColorI.Alpha / 255);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Implicit(AData: Pointer): TGEMColorF;
{$else}
operator :=(AData: Pointer): TGEMColorF;
{$endif}
  begin
    Move(AData^, Result, ColorFSize);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Implicit(AColor: Cardinal): TGEMColorF;
{$else}
operator :=(AColor: Cardinal): TGEMColorF;
{$endif}
var
Ptr: PByte;
  begin
    // convert 32 bit integer value into ColorI. This assumes a COLORREF created from
    // the RGB windows macro

    // Set Pointer to the interger
    Ptr := @AColor;

    // Assign each byte to the corresponding field of TGEMColorI;
    Result.Red := (Ptr[0]) / 255;
    Result.Green := (Ptr[1]) / 255;
    Result.Blue := (Ptr[2]) / 255;
    Result.Alpha := (Ptr[3]) / 255
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Implicit(AColor: TGEMColorF): Cardinal;
{$else}
operator :=(AColor: TGEMColorF): Cardinal;
{$endif}
var
RPtr: PByte;
  begin
    // convert TGEMColorF to 32 bit Uint
    RPtr := @Result;
    RPtr[0] := trunc(AColor.Red * 255);
    RPtr[1] := trunc(AColor.Green * 255);
    RPtr[2] := trunc(AColor.Blue * 255);
    RPtr[3] := trunc(AColor.Alpha * 255);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Implicit(AVector: TGEMVec4): TGEMColorF;
{$else}
operator :=(AVector: TGEMVec4): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(AVector.X);
    Result.Green := ClampF(AVector.Y);
    Result.Blue := ClampF(AVector.Z);
    Result.Alpha := ClampF(AVector.W);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Explicit(AData: Pointer): TGEMColorF;
{$else}
operator Explicit(AData: Pointer): TGEMColorF;
{$endif}
  begin
    Move(AData^, Result, ColorFSize);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Explicit(AVector: TGEMVec4): TGEMColorF;
{$else}
operator Explicit(AVector: TGEMVec4): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(AVector.X);
    Result.Green := ClampF(AVector.Y);
    Result.Blue := ClampF(AVector.Z);
    Result.Alpha := ClampF(AVector.W);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Add(A,B: TGEMColorF): TGEMColorF;
{$else}
operator +(A,B: TGEMColorF): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(A.Red + B.Red);
    Result.Green := ClampF(A.Green + B.Green);
    Result.Blue := ClampF(A.Blue + B.Blue);
    Result.Alpha := ClampF(A.Alpha + B.Alpha);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Add(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
{$else}
operator +(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(A.Red + B.X);
    Result.Green := ClampF(A.Green + B.Y);
    Result.Blue := ClampF(A.Blue + B.Z);
    Result.Alpha := ClampF(A.Alpha + B.W);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Subtract(A,B: TGEMColorF): TGEMColorF;
{$else}
operator -(A,B: TGEMColorF): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(A.Red - B.Red);
    Result.Green := ClampF(A.Green - B.Green);
    Result.Blue := ClampF(A.Blue - B.Blue);
    Result.Alpha := ClampF(A.Alpha - B.Alpha);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Subtract(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
{$else}
operator -(A: TGEMColorF; B: TGEMVec4): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(A.Red - B.X);
    Result.Green := ClampF(A.Green - B.Y);
    Result.Blue := ClampF(A.Blue - B.Z);
    Result.Alpha := ClampF(A.Alpha - B.W);
  end;

{$ifndef FPC}
class operator TGEMColorFHelper.Multiply(A: TGEMColorF; B: Single): TGEMColorF;
{$else}
operator *(A: TGEMColorF; B: Single): TGEMColorF;
{$endif}
  begin
    Result.Red := ClampF(A.Red * B);
    Result.Green := ClampF(A.Green * B);
    Result.Blue := ClampF(A.Blue * B);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMColorI
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TGEMColorI.Inverse: TGEMColorF;
  begin
    Result.Red := 255 - Self.Red;
    Result.Green := 255 - Self.Green;
    Result.Blue := 255 - Self.Blue;
  end;

function TGEMColorI.ToString: String;
  begin
    Result := Self.Red.ToString + ', ' + Self.Green.ToString + ', ' + Self.Blue.ToString + ', ' + Self.Alpha.ToString;
  end;

function TGEMColorI.ToGrey(): TGEMColorI;
var
Value: Single;
  begin
    Value := ClampI((Self.Red * 0.2126) + (Self.Green * 0.7152) + (Self.Blue * 0.0722));
    Result := ColorI(Value, Value, Value, Self.Alpha);
  end;

function TGEMColorI.Compare(const aComColor: TGEMColorI; const aVariance: Single; const aCompareAlpha: Boolean = False): Boolean;
var
LowVal, HighVal: Integer;
	begin

    Result := True;

    LowVal := trunc(aComColor.Red * (1 - aVariance));
    HighVal := trunc(aComColor.Red * (1 + aVariance));

    if (Self.Red < LowVal) or (Self.Red > HighVal) then Exit(False);

    LowVal := trunc(aComColor.Green * (1 - aVariance));
    HighVal := trunc(aComColor.Green * (1 + aVariance));

    if (Self.Green < LowVal) or (Self.Green > HighVal) then Exit(False);

    LowVal := trunc(aComColor.Blue * (1 - aVariance));
    HighVal := trunc(aComColor.Blue * (1 + aVariance));

    if (Self.Blue < LowVal) or (Self.Blue > HighVal) then Exit(False);


    if aCompareAlpha = True then begin

      LowVal := trunc(aComColor.Alpha * (1 - aVariance));
      HighVal := trunc(aComColor.Alpha * (1 + aVariance));

      if (Self.Alpha < LowVal) or (Self.Alpha > HighVal) then Exit(False);

  	end;

	end;


function TGEMColorIHelper.toColorF: TGEMColorF;
  begin
    Result.Red := ClampF(Self.Red / 255);
    Result.Green := ClampF(Self.Green / 255);
    Result.Blue := ClampF(Self.Blue / 255);
    Result.Alpha := ClampF(Self.Alpha / 255);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Equal(Color1: TGEMColorI; Color2: TGEMColorI): Boolean;
{$else}
operator =(Color1: TGEMColorI; Color2: TGEMColorI): Boolean;
{$endif}
var
Diff: Single;
  begin

  Result := False;

  // exit and return false if any components fall outside of thresholdrange
  //Diff := Abs(Color1.Red - Color2.Red) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(Color1.Green - Color2.Green) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(Color1.Blue - Color2.Blue) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(Color1.Alpha - Color2.Alpha) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Result := True;

  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Equal(ColorI: TGEMColorI; ColorF: TGEMColorF): Boolean;
{$else}
operator =(ColorI: TGEMColorI; ColorF: TGEMColorF): Boolean;
{$endif}
var
Diff: Single;
  begin

  Result := False;

  // exit and return false if any components fall outside of thresholdrange
  //Diff := Abs(ColorI.Red - (ColorF.Red * 255)) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(ColorI.Green - (ColorF.Green * 255)) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(ColorI.Blue - (ColorF.Blue * 255)) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Diff := Abs(ColorI.Alpha - (ColorF.Alpha * 255)) / 255;
  //if Diff > GEM.ColorCompareThreshold then exit;
  //
  //Result := True;

  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Implicit(ColorF: TGEMColorF): TGEMColorI;
{$else}
operator :=(ColorF: TGEMColorF): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(ColorF.Red * 255);
    Result.Green := ClampI(ColorF.Green * 255);
    Result.Blue := ClampI(ColorF.Blue * 255);
    Result.Alpha := ClampI(ColorF.Alpha * 255);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Implicit(AData: Pointer): TGEMColorI;
{$else}
operator :=(AData: Pointer): TGEMColorI;
{$endif}
  begin
    Move(AData^, Result, ColorISize);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Implicit(AColor: Cardinal): TGEMColorI;
{$else}
operator :=(AColor: Cardinal): TGEMColorI;
{$endif}
var
Ptr: PByte;
  begin
    // convert 32 bit integer value into ColorI. This assumes a COLORREF created from
    // the RGB windows macro

    // Set Pointer to the interger
    Ptr := @ AColor;

    // Assign each byte to the corresponding field of TGEMColorI;
    Result.Red := Ptr[0];
    Result.Green := Ptr[1];
    Result.Blue := Ptr[2];
    Result.Alpha := Ptr[3];
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Implicit(AColor: TGEMColorI): Cardinal;
{$else}
operator :=(AColor: TGEMColorI): Cardinal;
{$endif}
var
RPtr: PByte;
  begin
    // convert TGEMColorF to 32 bit Uint
    RPtr := @Result;
    Move(AColor, RPtr[0], 4);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Explicit(AData: Pointer): TGEMColorI;
{$else}
operator Explicit(AData: Pointer): TGEMColorI;
{$endif}
  begin
    Move(AData^, Result, ColorISize);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Add(A,B: TGEMColorI): TGEMColorI;
{$else}
operator +(A,B: TGEMColorI): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(A.Red + B.Red);
    Result.Green := ClampI(A.Green + B.Green);
    Result.Blue := ClampI(A.Blue + B.Blue);
    Result.Alpha := ClampI(A.Alpha + B.Alpha);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Add(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
{$else}
operator +(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(A.Red + B.X);
    Result.Green := ClampI(A.Green + B.Y);
    Result.Blue := ClampI(A.Blue + B.Z);
    Result.Alpha := ClampI(A.Alpha + B.W);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Subtract(A,B: TGEMColorI): TGEMColorI;
{$else}
operator -(A,B: TGEMColorI): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(A.Red - B.Red);
    Result.Green := ClampI(A.Green - B.Green);
    Result.Blue := ClampI(A.Blue - B.Blue);
    Result.Alpha := ClampI(A.Alpha - B.Alpha);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Subtract(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
{$else}
operator -(A: TGEMColorI; B: TGEMVec4): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(A.Red - B.X);
    Result.Green := ClampI(A.Green - B.Y);
    Result.Blue := ClampI(A.Blue - B.Z);
    Result.Alpha := ClampI(A.Alpha - B.W);
  end;

{$ifndef FPC}
class operator TGEMColorIHelper.Multiply(A: TGEMColorI; B: Single): TGEMColorI;
{$else}
operator *(A: TGEMColorI; B: Single): TGEMColorI;
{$endif}
  begin
    Result.Red := ClampI(A.Red * B);
    Result.Green := ClampI(A.Green * B);
    Result.Blue := ClampI(A.Blue * B);
  end;

operator *(A, B: TGEMColorI): TGEMColorI;
var
Per: Single;
  begin
    Per := B.Alpha / 255;
    Result.Red := trunc((A.Red * (B.Red * Per)) / 255);
    Result.Green := trunc((A.Green * (B.Green * Per)) / 255);
    Result.Blue := trunc((A.Blue * (B.Blue * Per)) / 255);
    Result.Alpha := A.Alpha;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMRectI
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$ifndef FPC}
class operator TGEMRectI.Initialize(out Dest: TGEMRectI);
{$else}
class operator TGEMRectI.Initialize(var Dest: TGEMRectI);
{$endif}
	begin
    Dest.fLeft := 0;
    Dest.fRight := 0;
    Dest.fTop := 0;
    Dest.fBottom := 0;
    Dest.fWidth := 0;
    Dest.fHeight := 0;
    Dest.fX := 0;
    Dest.fY := 0;
    dest.fZ := 0;
  end;

procedure TGEMRectI.Update(AFrom: Integer);
// AFrom expects a constant value of from_center, from_left, from_top, from_right, from_bottom
  begin
    case AFrom of

      0: // from_center
        begin
          Self.fLeft := Self.fX - trunc(Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
          Self.fTop := Self.fY - trunc(Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      1: // from_left
        begin
          Self.fX := Self.fLeft + trunc(Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
        end;

      2: // from_top
        begin
          Self.fY := Self.fTop + trunc(Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      3: // from_right
        begin
          Self.fX := Self.fRight - trunc(Self.fWidth / 2);
          Self.fLeft := Self.fRight - (Self.fWidth);
        end;

      4: //from_bottom
        begin
          Self.fY := Self.fBottom - trunc(Self.fHeight / 2);
          Self.fTop := Self.fBottom - (Self.fHeight);
        end;


    end;

  end;

procedure TGEMRectI.SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Self.fX := trunc(AX);
    Self.fY := trunc(AY);
    Self.fZ := trunc(AZ);
    Self.Update(from_center);
  end;

procedure TGEMRectI.SetX(AX: Single);
  begin
    Self.fX := trunc(AX);
    Self.Update(from_center);
  end;

procedure TGEMRectI.SetY(AY: Single);
  begin
    Self.fY := trunc(AY);
    Self.Update(from_center);
  end;

procedure TGEMRectI.SetLeft(ALeft: Single);
  begin
    Self.fLeft := trunc(ALeft);
    Self.Update(from_left);
  end;

procedure TGEMRectI.SetRight(ARight: Single);
  begin
    Self.fRight := trunc(ARight);
    Self.Update(from_right);
  end;

procedure TGEMRectI.SetTop(ATop: Single);
  begin
    Self.fTop := trunc(ATop);
    Self.Update(from_top);
  end;

procedure TGEMRectI.SetBottom(ABottom: Single);
  begin
    Self.fBottom := trunc(ABottom);
    Self.Update(from_bottom);
  end;

procedure TGEMRectI.SetTopLeft(ALeft: Single; ATop: Single);
  begin
      Self.SetCenter(ALeft + (Self.Width / 2), ATop + (Self.Height / 2), Self.Z);
  end;

procedure TGEMRectI.SetTopRight(ARight: Single; ATop: Single);
  begin
      Self.SetCenter(ARight - (Self.Width / 2), ATop + (Self.Height / 2), Self.Z);
  end;

procedure TGEMRectI.SetBottomRight(ARight: Single; ABottom: Single);
  begin
    Self.SetCenter(ARight - (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z);
  end;

procedure TGEMRectI.SetBottomLeft(ALeft: Single; ABottom: Single);
  begin
    Self.SetCenter(ALeft + (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z);
  end;

procedure TGEMRectI.SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := trunc(AWidth);
    Self.fHeight := trunc(AHeight);
    Self.Update(AFrom);
  end;

procedure TGEMRectI.SetWidth(AWidth: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := trunc(AWidth);
    Self.Update(AFrom);
  end;

procedure TGEMRectI.SetHeight(AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fHeight := trunc(AHeight);
    Self.Update(AFrom);
  end;

procedure TGEMRectI.Grow(AIncWidth,AIncHeight: Single);
  begin
    Inc(Self.fWidth,trunc(AIncWidth));
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Inc(Self.fHeight,trunc(AIncHeight));
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TGEMRectI.Stretch(APerWidth,APerHeight: Single);
  begin
    Self.fWidth := RoundF(Self.fWidth * APerWidth);
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Self.fHeight := RoundF(Self.fHeight * APerHeight);
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TGEMRectI.FitInRect(ARect: TGEMRectI);
var
NewLeft,NewTop,NewRight,NewBottom: Integer;
  begin
    NewLeft := Self.Left;
    NewTop := Self.Top;
    NewRight := Self.Right;
    NewBottom := Self.Bottom;

    if (Self.Left >= ARect.Left) and (Self.Right <= ARect.Right) and (Self.Top >= ARect.Top) and (Self.Bottom <= ARect.Bottom) then begin
      Exit;
    end;

    If Self.Left < ARect.Left then NewLeft := ARect.Left;
    if Self.Right > ARect.Right then NewRight := Arect.Right;
    if Self.Top < ARect.Top then NewTop := ARect.Top;
    if Self.Bottom > ARect.Bottom then NewBottom := ARect.Bottom;

    Self := RectI(NewLeft, NewTop, NewRight, NewBottom);

  end;

procedure TGEMRectI.Translate(AX,AY,AZ: Single);
  begin
    Inc(Self.fX, trunc(AX));
    Inc(Self.fY, trunc(AY));
    Inc(Self.fZ, trunc(AZ));
    Self.Update(from_center);
  end;


function TGEMRectI.RandomSubRect: TGEMRectI;
var
L,R,T,B: Integer;
  begin
    R := trunc(Rnd(Self.Right));
    L := trunc(Rnd(R));
    B := trunc(Rnd(Self.Bottom));
    T := trunc(Rnd(B));
    Result := RectI(L,T,R,B);
  end;

{$ifndef FPC}
class operator TGEMRectIHelper.Implicit(A: TGEMRectF): TGEMRectI;
{$else}
operator :=(A: TGEMRectF): TGEMRectI;
{$endif}
  begin
    Result.fX := trunc(A.X);
    Result.fY := trunc(A.Y);
    Result.fZ := trunc(A.Z);
    Result.fWidth := trunc(A.Width);
    Result.fHeight := trunc(A.Height);
    Result.fLeft := trunc(A.Left);
    Result.fTop := trunc(A.Top);
    Result.fRight := trunc(A.Right);
    Result.fBottom := trunc(A.Bottom);
  end;

{$ifndef FPC}
class operator TGEMRectIHelper.Implicit(A: TRect): TGEMRectI;
{$else}
operator :=(A: TRect): TGEMRectI;
{$endif}
  begin
    Result := RectI(A.Left, A.Top, A.Right, A.Bottom);
  end;

{$ifndef FPC}
class operator TGEMRectIHelper.Add(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
{$else}
operator +(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
{$endif}
  begin
    Result := A;
    Result.Translate(B.X, B.Y, B.Z);
  end;

{$ifndef FPC}
class operator TGEMRectIHelper.Subtract(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
{$else}
operator -(A: TGEMRectI; B: TGEMVec3): TGEMRectI;
{$endif}
  begin
    Result := A;
    Result.Translate(-B.X, -B.Y, -B.Z);
  end;

function TGEMRectIHelper.GetCenter: TGEMVec3;
  begin
    Result := Vec3(Self.fX, Self.fY, Self.fZ);
  end;

function TGEMRectIHelper.GetTopLeft(): TGEMVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fTop, Self.fZ);
  end;

function TGEMRectIHelper.GetTopRight(): TGEMVec3;
  begin
    Result := Vec3(Self.fRight, Self.fTop, Self.fZ);
  end;

function TGEMRectIHelper.GetBottomLeft(): TGEMVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fBottom, Self.fZ);
  end;

function TGEMRectIHelper.GetBottomRight(): TGEMVec3;
  begin
    Result := Vec3(Self.fRight, Self.fBottom, Self.fZ);
  end;

function TGEMRectIHelper.toVectors: specialize TArray<TGEMVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec3(Self.Left, Self.Top, Self.Z);
    Result[1] := Vec3(Self.Right, Self.Top, Self.Z);
    Result[2] := Vec3(Self.Right, Self.Bottom, Self.Z);
    Result[3] := Vec3(Self.Left, Self.Bottom, Self.Z);
  end;

procedure TGEMRectIHelper.Assign(ARectF: TGEMRectF);
  begin
    Self.fLeft := trunc(ARectF.Left);
    Self.fTop := trunc(ARectF.Top);
    self.fRight := trunc(ARectF.Right);
    Self.fBottom := trunc(ARectF.Bottom);
    Self.fWidth := trunc(ARectF.Width);
    Self.fHeight := trunc(ARectF.Height);
    Self.fX := trunc(ARectF.X);
    Self.fY := trunc(ARectF.Y);
  end;


procedure TGEMRectIHelper.ScaleToFit(AFitRect: TGEMRectF);
var
NewWidth,NewHeight: Integer;
WidthPer,HeightPer: Single;
Success: Boolean;
  begin

    Success := False;
    NewWidth := Self.Width;
    NewHeight := Self.Height;

    if NewWidth < AFitRect.Width then begin
      WidthPer := NewWidth * ((Self.Width / NewWidth));
      NewWidth := trunc(NewWidth * WidthPer) ;
      NewHeight := trunc(NewHeight * WidthPer);
    end;

    if NewHeight < AFitRect.Height then begin
      HeightPer := NewHeight * ((Self.Height / NewHeight));
      NewHeight := trunc(NewHeight * HeightPer);
      NewWidth := trunc(NewWidth * HeightPer);
    end;

    repeat

      if NewWidth > AFitRect.Width then begin
        WidthPer := AFitRect.Width / NewWidth;
        NewWidth := trunc(AFitRect.Width);
        NewHeight := trunc(NewHeight * WidthPer);
      end;

      if NewHeight > AFitRect.Height then begin
        HeightPer := AFitRect.Height / NewHeight;
        NewHeight := trunc(AFitRect.Height);
        NewWidth := trunc(NewWidth * HeightPer);
      end;

      if (NewWidth <= AFitRect.Width) and (NewHeight <= AFitRect.Height) then begin
        Success := True;
      end;

    until Success = True;

    Self.SetSize(NewWidth,NewHeight,from_center);


  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMRectF
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$ifndef FPC}
class operator TGEMRectF.Initialize(out Dest: TGEMRectF);
{$else}
class operator TGEMRectF.Initialize(var Dest: TGEMRectF);
{$endif}
	begin
    Dest.fLeft := 0;
    Dest.fRight := 0;
    Dest.fTop := 0;
    Dest.fBottom := 0;
    Dest.fWidth := 0;
    Dest.fHeight := 0;
    Dest.fX := 0;
    Dest.fY := 0;
    dest.fZ := 0;
  end;

procedure TGEMRectF.Update(AFrom: Integer);
  begin

    case AFrom of

      0: // from_center
        begin
          Self.fLeft := Self.fX - (Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
          Self.fTop := Self.fY - (Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      1: // from_left
        begin
          Self.fX := Self.fLeft + (Self.fWidth / 2);
          Self.fRight := Self.fLeft + (Self.fWidth);
        end;

      2: // from_top
        begin
          Self.fY := Self.fTop + (Self.fHeight / 2);
          Self.fBottom := Self.fTop + (Self.fHeight);
        end;

      3: // from_right
        begin
          Self.fX := Self.fRight - (Self.fWidth / 2);
          Self.fLeft := Self.fRight - (Self.fWidth);
        end;

      4: //from_bottom
        begin
          Self.fY := Self.fBottom - (Self.fHeight / 2);
          Self.fTop := Self.fBottom - (Self.fHeight);
        end;


    end;

  end;

procedure TGEMRectF.SetCenter(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Self.fX := AX;
    Self.fY := AY;
    Self.fZ := AZ;
    Self.Update(from_center);
  end;

procedure TGEMRectF.SetX(AX: Single);
  begin
    Self.fX := AX;
    Self.Update(from_center);
  end;

procedure TGEMRectF.SetY(AY: Single);
  begin
    Self.fY := AY;
    Self.Update(from_center);
  end;

procedure TGEMRectF.SetZ(AZ: Single);
  begin
    Self.fZ := AZ;
    Self.Update(from_center);
  end;

procedure TGEMRectF.SetLeft(ALeft: Single);
  begin
    Self.fLeft := ALeft;
    Self.Update(from_left);
  end;

procedure TGEMRectF.SetRight(ARight: Single);
  begin
    Self.fRight := ARight;
    Self.Update(from_right);
  end;

procedure TGEMRectF.SetTop(ATop: Single);
  begin
    Self.fTop := ATop;
    Self.Update(from_top);
  end;

procedure TGEMRectF.SetBottom(ABottom: Single);
  begin
    Self.fBottom := ABottom;
    Self.Update(from_bottom);
  end;

procedure TGEMRectF.SetTopLeft(ALeft: Single; ATop: Single);
  begin
    Self.SetCenter(Vec3(ALeft + (Self.Width / 2), ATop + (Self.Height / 2), Self.Z));
  end;

procedure TGEMRectF.SetTopRight(ARight: Single; ATop: Single);
  begin
    Self.SetCenter(Vec3(ARight - (Self.Width / 2), ATop + (Self.Height / 2), Self.Z));
  end;

procedure TGEMRectF.SetBottomLeft(ALeft: Single; ABottom: Single);
  begin
    Self.SetCenter(Vec3(ALeft + (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z));
  end;

procedure TGEMRectF.SetBottomRight(ARight: Single; ABottom: Single);
  begin
    Self.SetCenter(Vec3(ARight - (Self.Width / 2), ABottom - (Self.Height / 2), Self.Z));
  end;

procedure TGEMRectF.SetSize(AWidth,AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := AWidth;
    Self.fHeight := AHeight;
    Self.Update(AFrom);
  end;

procedure TGEMRectF.SetWidth(AWidth: Single; AFrom: Integer = 0);
  begin
    Self.fWidth := AWidth;
    Self.Update(AFrom);
  end;

procedure TGEMRectF.SetHeight(AHeight: Single; AFrom: Integer = 0);
  begin
    Self.fHeight := AHeight;
    Self.Update(AFrom);
  end;

procedure TGEMRectF.Grow(AIncWidth,AIncHeight: Single);
  begin
    IncF(Self.fWidth,AIncWidth);
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    IncF(Self.fHeight,AIncHeight);
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TGEMRectF.Stretch(APerWidth,APerHeight: Single);
  begin
    Self.fWidth := Self.fWidth * APerWidth;
      if Self.fWidth < 0 then begin
        Self.fWidth := 0;
      end;

    Self.fHeight := Self.fHeight * APerHeight;
      if Self.fHeight < 0 then begin
        Self.fHeight := 0;
      end;

    Self.Update(from_center);
  end;

procedure TGEMRectF.Translate(AX,AY,AZ: Single);
  begin
    IncF(Self.fX, AX);
    IncF(Self.fY, AY);
    IncF(Self.fZ, AZ);
    Self.Update(from_center);
  end;

function TGEMRectF.RandomSubRect: TGEMRectF;
var
L,R,T,B: Single;
  begin
    R := Rnd(Self.Width - 1);
    L := Rnd(R);
    B := Rnd(Self.Height - 1);
    T := Rnd(B);
    Result := GEMTypes.RectF(L,T,R,B);
  end;

{$ifndef FPC}
class operator TGEMRectFHelper.Implicit(A: TGEMRectI): TGEMRectF;
{$else}
operator :=(A: TGEMRectI): TGEMRectF;
{$endif}
  begin
    Result.fX := (A.X);
    Result.fY := (A.Y);
    Result.fZ := (A.Z);
    Result.fWidth := (A.Width);
    Result.fHeight := (A.Height);
    Result.fLeft := (A.Left);
    Result.fTop := (A.Top);
    Result.fRight := (A.Right);
    Result.fBottom := (A.Bottom);
  end;

{$ifndef FPC}
class operator TGEMRectFHelper.Add(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
{$else}
operator +(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
{$endif}
  begin
    Result := A;
    Result.Translate(B.X, B.Y, B.Z);
  end;

{$ifndef FPC}
class operator TGEMRectFHelper.Subtract(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
{$else}
operator -(A: TGEMRectF; B: TGEMVec3): TGEMRectF;
{$endif}
  begin
    Result := A;
    Result.Translate(-B.X, -B.Y, B.Z);
  end;

function TGEMRectFHelper.GetCenter: TGEMVec3;
  begin
    Result := Vec3(Self.fX, Self.fY, Self.fZ);
  end;

function TGEMRectFHelper.GetTopLeft(): TGEMVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fTop, Self.fZ);
  end;

function TGEMRectFHelper.GetTopRight(): TGEMVec3;
  begin
    Result := Vec3(Self.fRight, Self.fTop, Self.fZ);
  end;

function TGEMRectFHelper.GetBottomLeft(): TGEMVec3;
  begin
    Result := Vec3(Self.fLeft, Self.fBottom, Self.fZ);
  end;

function TGEMRectFHelper.GetBottomRight(): TGEMVec3;
  begin
    Result := Vec3(Self.fRight, Self.fBottom, Self.fZ);
  end;

procedure TGEMRectFHelper.SetCenter(ACenter: TGEMVec3);
  begin
    Self.fX := ACenter.X;
    Self.fY := ACenter.Y;
    Self.fZ := ACenter.Z;
    Self.Update(from_center);
  end;

function TGEMRectFHelper.toVectors: specialize TArray<TGEMVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec3(Self.Left, Self.Top, Self.fZ);
    Result[1] := Vec3(Self.Right, Self.Top, Self.fZ);
    Result[2] := Vec3(Self.Right, Self.Bottom, Self.fZ);
    Result[3] := Vec3(Self.Left, Self.Bottom, Self.fZ);
  end;

function TGEMRectFHelper.toTexCoords(): specialize TArray<TGEMVec3>;
  begin
    SetLength(Result,4);
    Result[0] := Vec2(Self.Left / Self.Width, Self.Top / Self.Height);
    Result[1] := Vec2(Self.Right / Self.Width, Self.Top / Self.Height);
    Result[2] := Vec2(Self.Right / Self.Width, Self.Bottom / Self.Height);
    Result[3] := Vec2(Self.Left / Self.Width, Self.Bottom / Self.Height);
  end;

procedure TGEMRectFHelper.Assign(ARectI: TGEMRectI);
  begin
    Self.fLeft := (ARectI.Left);
    Self.fTop := (ARectI.Top);
    self.fRight := (ARectI.Right);
    Self.fBottom := (ARectI.Bottom);
    Self.fWidth := (ARectI.Width);
    Self.fHeight := (ARectI.Height);
    Self.fX := (ARectI.X);
    Self.fY := (ARectI.Y);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMVec2
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TGEMVec2.Translate(AValues: TGEMVec2);
  begin
    Self.X := Self.X + AValues.X;
    Self.Y := Self.Y + AValues.Y;
  end;

function TGEMVec2.ToString(APrecision: Cardinal = 0): String;
  begin
    Result := Self.X.ToString(TFloatFormat.ffFixed, APrecision, 0)  + ', ' + Self.Y.ToString(TFloatFormat.ffFixed, APrecision, 0);
  end;

{$ifndef FPC}
class operator TGEMVec2.Add(A,B: TGEMVec2): TGEMVec2;
{$else}
class operator TGEMVec2.+(A,B: TGEMVec2): TGEMVec2;
{$endif}
	begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2.Subtract(A,B: TGEMVec2): TGEMVec2;
{$else}
class operator TGEMVec2.-(A,B: TGEMVec2): TGEMVec2;
{$endif}
	begin
    Result.X := A.X - B.X;
    Result.Y := A.Y - B.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2.Multiply(A: TGEMVec2; B: Single): TGEMVec2;
{$else}
class operator TGEMVec2.*(A: TGEMVec2; B: Single): TGEMVec2;
{$endif}
  begin
    Result.X := A.X * B;
    Result.Y := A.Y * B;
  end;

{$ifndef FPC}
class operator TGEMVec2.Divide(A: TGEMVec2; B: Single): TGEMVec2;
{$else}
class operator TGEMVec2./(A: TGEMVec2; B: Single): TGEMVec2;
{$endif}
  begin
    Result.X := A.X / B;
    Result.Y := A.Y / B;
  end;

{$ifndef FPC}
class operator TGEMVec2.Negative(A: TGEMVec2): TGEMVec2;
{$else}
class operator TGEMVec2.-(A: TGEMVec2): TGEMVec2;
{$endif}
  begin
    Result.X := -Result.X;
    Result.Y := -Result.Y;
  end;


{$ifndef FPC}
class operator TGEMVec2Helper.Implicit(A: TPoint): TGEMVEc2;
{$else}
operator :=(A: TPoint): TGEMVEc2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Implicit(A: TPoint): TGEMVEc2;
{$else}
operator :=(A: TGEMVec2): TPoint;
{$endif}
  begin
    Result.X := trunc(A.X);
    Result.Y := trunc(A.Y);
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Implicit(A: TGEMVec3): TGEMVec2;
{$else}
operator :=(A: TGEMVec3): TGEMVec2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Implicit(A: TGEMVec4): TGEMVec2;
{$else}
operator :=(A: TGEMVec4): TGEMVec2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Explicit(A: TPoint): TGEMVEc2;
{$else}
operator Explicit(A: TPoint): TGEMVEc2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Explicit(A: TGEMVec3): TGEMVec2;
{$else}
operator Explicit(A: TGEMVec3): TGEMVec2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Explicit(A: TGEMVec4): TGEMVec2;
{$else}
operator Explicit(A: TGEMVec4): TGEMVec2;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Add(A,B: TGEMVec2): TGEMVec2;
{$else}
operator +(A,B: TGEMVec2): TGEMVec2;
{$endif}
  begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.Equal(A,B: TGEMVec2): Boolean;
{$else}
operator =(A,B: TGEMVec2): Boolean;
{$endif}
  begin
    Result := (A.X = B.X) and (A.Y = B.Y);
  end;

{$ifndef FPC}
class operator TGEMVec2Helper.NotEqual(A,B: TGEMVec2): Boolean;
{$else}
operator <>(A,B: TGEMVec2): Boolean;
{$endif}
  begin
    Result := (A.X <> B.X) or (A.Y <> B.Y);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMVec3
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$ifndef FPC}
class operator TGEMVec3Helper.Implicit(A: TPoint): TGEMVec3;
{$else}
operator :=(A: TPoint): TGEMVec3;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
  end;

{$ifndef FPC}
class operator TGEMVec3Helper.Implicit(A: TGEMVec2): TGEMVec3;
{$else}
operator :=(A: TGEMVec2): TGEMVec3;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
  end;

{$ifndef FPC}
class operator TGEMVec3Helper.Implicit(A: TGEMVec4): TGEMVec3;
{$else}
operator :=(A: TGEMVec4): TGEMVec3;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3Helper.Explicit(A: TGEMVec2): TGEMVec3;
{$else}
operator Explicit(A: TGEMVec2): TGEMVec3;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
  end;

{$ifndef FPC}
class operator TGEMVec3Helper.Explicit(A: TGEMVec4): TGEMVec3;
{$else}
operator Explicit(A: TGEMVec4): TGEMVec3;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3Helper.Multiply(A: TGEMVec3; B: TGEMMat4): TGEMVec3;
{$else}
operator *(A: TGEMVec3; B: TGEMMat4): TGEMVec3;
{$endif}
  begin
    Result := B * A;
  end;

{$ifndef FPC}
class operator TGEMVec3.Add(A,B: TGEMVec3): TGEMVec3;
{$else}
class operator TGEMVec3.+(A,B: TGEMVec3): TGEMVec3;
{$endif}
	begin
    Result.X := A.X + B.X;
    Result.Y := A.Y + B.Y;
    Result.Z := A.Z + B.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3.Add(A: TGEMVec3; B: Single): TGEMVec3;
{$else}
class operator TGEMVec3.+(A: TGEMVec3; B: Single): TGEMVec3;
{$endif}
  begin
    Result.X := A.X + B;
    Result.Y := A.Y + B;
    Result.Z := A.Z + B;
  end;

{$ifndef FPC}
class operator TGEMVec3.Subtract(A,B: TGEMVec3): TGEMVec3;
{$else}
class operator TGEMVec3.-(A,B: TGEMVec3): TGEMVec3;
{$endif}
  begin
    Result.X := A.X - B.X;
    Result.Y := A.Y - B.Y;
    Result.Z := A.Z - B.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3.Subtract(A: TGEMVec3; B: Single): TGEMVec3;
{$else}
class operator TGEMVec3.-(A: TGEMVec3; B: Single): TGEMVec3;
{$endif}
  begin
    Result.X := A.X - B;
    Result.Y := A.Y - B;
    Result.Z := A.Z - B;
  end;

{$ifndef FPC}
class operator TGEMVec3.Divide(A: TGEMVec3; B: Single): TGEMVec3;
{$else}
class operator TGEMVec3./(A: TGEMVec3; B: Single): TGEMVec3;
{$endif}
  begin
    Result.X := A.X / B;
    Result.Y := A.Y / B;
    Result.Z := A.Z / B;
  end;

{$ifndef FPC}
class operator TGEMVec3.Divide(A: Single; B: TGEMVec3): TGEMVec3;
{$else}
class operator TGEMVec3./(A: Single; B: TGEMVec3): TGEMVec3;
{$endif}
  begin
    Result.X := A / B.X;
    Result.Y := A / B.Y;
    Result.Z := A / B.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3.Multiply(A: TGEMVec3; B: Single): TGEMVec3;
{$else}
class operator TGEMVec3.*(A: TGEMVec3; B: Single): TGEMVec3;
{$endif}
  begin
    Result.X := A.X * B;
    Result.Y := A.Y * B;
    Result.Z := A.Z * B;
  end;

{$ifndef FPC}
class operator TGEMVec3.Multiply(A,B: TGEMVec3): TGEMVec3;
{$else}
class operator TGEMVec3.*(A,B: TGEMVec3): TGEMVec3;
{$endif}
  begin
    Result.X := A.X * B.X;
    Result.Y := A.Y * B.Y;
    Result.Z := A.Z * B.Z;
  end;

{$ifndef FPC}
class operator TGEMVec3.Negative(A: TGEMVec3): TGEMVec3;
{$else}
class operator TGEMVec3.-(A: TGEMVec3): TGEMVec3;
{$endif}
  begin
    Result.X := -A.X;
    Result.Y := -A.Y;
    Result.Z := -A.Z;
  end;

function TGEMVec3.GetNormal: TGEMVec3;
var
TVec: TGEMVec3;
  begin
    TVec := Self;
    Normalize(TVec);
    Result := TVec;
  end;

function TGEMVec3.GetLength: Single;
  begin
    Result := GEMTypes.VectorLength(Self);
  end;

procedure TGEMVec3.Negate();
  begin
    Self.X := -Self.X;
    Self.Y := -Self.Y;
    Self.Z := -Self.Z;
  end;

procedure TGEMVec3.Translate(AX: Single = 0; AY: Single = 0; AZ: Single = 0);
  begin
    Incf(Self.X, AX);
    Incf(Self.Y, AY);
    Incf(Self.Z, AZ);
  end;

procedure TGEMVec3.Translate(AValues: TGEMVec3);
  begin
    Incf(Self.X, AValues.X);
    Incf(Self.Y, AValues.Y);
    Incf(Self.Z, AValues.Z);
  end;

procedure TGEMVec3.Rotate(AX,AY,AZ: Single);
  begin

  end;

procedure TGEMVec3.Cross(AVec: TGEMVec3);
  begin
    Self := GEMTypes.Cross(Self, AVec);
  end;

function TGEMVec3.Dot(AVec: TGEMVec3): Single;
  begin
    Result := GEMTypes.Dot(Self,AVec);
  end;

function TGEMVec3.GetTargetVector(ATarget: TGEMVec3): TGEMVec3;
  begin
    Result := GEMTypes.Normal(Self - ATarget);
  end;

function TGEMVec3.toNDC(ADispWidth, ADispHeight: Single): TGEMVec3;
  begin
    Result.X := -1 + ((Self.X / ADispWidth) * 2);
    Result.Y := -1 + ((Self.Y / ADispHeight) * 2);
  end;

function TGEMVec3.Swizzle(AComponents: specialize TArray<TGEMVectorComponent>): TGEMVec3;
var
I: Integer;
Vals: Array [0..2] of Single;
  begin
    Result := Vec3(0,0,0);

    for I := 0 to  trunc( Smallest( [High(AComponents), 2] )) do begin

      case AComponents[i] of
        VX: Vals[i] := Self.X;
        VY: Vals[i] := Self.Y;
        VZ: Vals[i] := Self.Z;
      end;

    end;

    Result := Vec3(Vals[0], Vals[1], Vals[2]);

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMVec4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

{$ifndef FPC}
class operator TGEMVec4Helper.Implicit(A: TGEMVec2): TGEMVec4;
{$else}
operator :=(A: TGEMVec2): TGEMVec4;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
    Result.W := 0;
  end;

{$ifndef FPC}
class operator TGEMVec4Helper.Implicit(A: TGEMVec3): TGEMVec4;
{$else}
operator :=(A: TGEMVec3): TGEMVec4;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
    Result.W := 0;
  end;

{$ifndef FPC}
class operator TGEMVec4Helper.Explicit(A: TGEMVec2): TGEMVec4;
{$else}
operator Explicit(A: TGEMVec2): TGEMVec4;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := 0;
    Result.W := 0;
  end;

{$ifndef FPC}
class operator TGEMVec4Helper.Explicit(A: TGEMVec3): TGEMVec4;
{$else}
operator Explicit(A: TGEMVec3): TGEMVec4;
{$endif}
  begin
    Result.X := A.X;
    Result.Y := A.Y;
    Result.Z := A.Z;
    Result.W := 0;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMVertex
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMMat4
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TGEMMat4.GetVal(const A,B: Cardinal): Single;
	begin
  	Exit(Self.M[A,B]);
  end;

function TGEMMat4.GetRow(const Index: Cardinal): TGEMVec4;
	begin
  	Result := Vec4(Self.M[0,Index], Self.M[1,Index], Self.M[2,Index], Self.M[3,Index]);
  end;

function TGEMMat4.GetColumn(const Index: Cardinal): TGEMVec4;
	begin
  	Result := Vec4(Self.M[Index,0], Self.M[Index,1], Self.M[Index,2], Self.M[Index,3]);
  end;

procedure TGEMMat4.SetVal(const A: Cardinal; const B: Cardinal; const aValue: Single);
	begin
  	Self.M[A,B] := aValue;
  end;

procedure TGEMMat4.SetRow(const Index: Cardinal; const aValues: TGEMVec4);
	begin
  	Self.M[0,Index] := aValues.X;
    Self.M[1,Index] := aValues.Y;
    Self.M[2,Index] := aValues.Z;
    Self.M[3,Index] := aValues.W;
  end;

procedure TGEMMat4.SetColumn(const Index: Cardinal; const aValues: TGEMVec4);
	begin
  	Self.M[Index,0] := aValues.X;
    Self.M[Index,1] := aValues.Y;
    Self.M[Index,2] := aValues.Z;
    Self.M[Index,3] := aValues.W;
  end;

{$ifndef FPC}
class operator TGEMMat4.Initialize(out Dest: TGEMMat4);
{$else}
class operator TGEMMat4.Initialize(var Dest: TGEMMat4);
{$endif}
	begin
    Dest.SetIdentity();
  end;

{$ifndef FPC}
class operator TGEMMat4.Multiply(A: TGEMMat4; B: TGEMMat4): TGEMMat4;
{$else}
class operator TGEMMat4.*(A: TGEMMat4; B: TGEMMat4): TGEMMat4;
{$endif}
var
I,J,K: Integer;
Sum: Single;
  begin

    for I := 0 to 3 do begin
      for J := 0 to 3 do begin

        Sum := 0;
        for K := 0 to 3 do begin
          Sum := Sum + (A.M[K,J] * B.M[I,K]);
        end;

        Result.M[I,J] := Sum;

      end;
    end;

  end;


{$ifndef FPC}
class operator TGEMMat4.Multiply(A: TGEMMat4; B: TGEMVec4): TGEMVec4;
{$else}
class operator TGEMMat4.*(A: TGEMMat4; B: TGEMVec4): TGEMVec4;
{$endif}
  begin
    //Result.X := ((A.M[0,0] * B.X) + (A.M[1,0] * B.X) + (A.M[2,0] * B.X)) + A.M[3,0];
    //Result.Y := ((A.M[0,1] * B.Y) + (A.M[1,1] * B.Y) + (A.M[2,1] * B.Y)) + A.M[3,1];
    //Result.Z := ((A.M[0,2] * B.Z) + (A.M[1,2] * B.Z) + (A.M[2,2] * B.Z)) + A.M[3,2];
    //Result.W := ((A.M[0,3] * B.W) + (A.M[1,3] * B.W) + (A.M[2,3] * B.W)) + A.M[3,3];

    //Result.X := ((A.M[0,0] * B.X) + (A.M[0,1] * B.X) + (A.M[0,2] * B.X)) + A.M[0,3];
    //Result.Y := ((A.M[1,0] * B.Y) + (A.M[1,1] * B.Y) + (A.M[1,2] * B.Y)) + A.M[1,3];
    //Result.Z := ((A.M[2,0] * B.Z) + (A.M[2,1] * B.Z) + (A.M[2,2] * B.Z)) + A.M[2,3];
    //Result.W := ((A.M[3,0] * B.W) + (A.M[3,1] * B.W) + (A.M[3,2] * B.W)) + A.M[3,3];

    Result.X := Dot(B, A.Row[0]);
    Result.Y := Dot(B, A.Row[1]);
    Result.Z := Dot(B, A.Row[2]);
    Result.W := Dot(B, A.Row[3]);
  end;


{$ifndef FPC}
class operator TGEMMat4.Implicit(A: Array of Single): TGEMMat4;
{$else}
class operator TGEMMat4.:=(A: Array of Single): TGEMMat4;
{$endif}
var
Len,I,Z,R: Integer;
  begin

    if Length(A) > 16 then begin
      Len := 16;
    end else begin
      Len := Length(A);
    end;

    R := 0;
    I := 0;
    Z := 0;

    while R < Len do begin
        Result.M[I,Z] := A[R];

        Inc(R);

        Inc(I);
        if I > 3 then begin
          I := 0;
          Inc(Z);
        end;
    end;

  end;

procedure TGEMMat4.Zero();
var
I: Integer;
  begin
    for I := 0 to 3 do begin
      Self.M[I,0] := 0;
      Self.M[I,1] := 0;
      Self.M[I,2] := 0;
      Self.M[I,3] := 0;
    end;
  end;

procedure TGEMMat4.SetIdentity();
var
I,Z: Integer;
  begin

    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin

        if I = z then begin
          Self.M[I,Z] := 1;
        end else begin
          Self.M[I,Z] := 0;
        end;

      end;
    end;

  end;


procedure TGEMMat4.Fill(AValues: specialize TArray<Single>);
var
I,Z: Integer;
  begin

    for Z := 0 to 3 do begin
      for  I := 0 to 3 do begin

        Self.M[Z,I] := AValues[ (Z * 4) + I];

      end;
    end;

  end;

procedure TGEMMat4.Negate();
var
I,Z: Integer;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        Self.M[I,Z] := -Self.M[I,Z];
      end;
    end;
  end;

procedure TGEMMat4.Inverse();
  begin
    Self := MatrixInverse(Self);
  end;

procedure TGEMMat4.Scale(AFactor: Single);
  begin
    Self := MatrixScale(Self,AFactor);
  end;

procedure TGEMMat4.Transpose();
var
I,Z: Integer;
TempMat: TGEMMat4;
  begin
    for I := 0 to 3 do begin
      for Z := 0 to 3 do begin
        TempMat.M[I,Z] := Self.M[Z,I];
      end;
    end;

    Self := TempMat;
  end;

procedure TGEMMat4.MakeTranslation(X: Single = 0; Y: Single = 0; Z: Single = 0);
  begin
    Self.SetIdentity();
    Self.AW := X;
    Self.BW := Y;
    Self.CW := Z;
  end;

procedure TGEMMat4.MakeTranslation(AValues: TGEMVec3);
  begin
    Self.SetIdentity();
    Self.M[3,0] := AValues.X;
    Self.M[3,1] := AValues.Y;
    Self.M[3,2] := AValues.Z;
  end;

procedure TGEMMat4.Translate(X: Single = 0; Y: Single = 0; Z: Single = 0);
  begin
    Self.AW := Self.AW + X;
    Self.BW := Self.BW + Y;
    Self.CW := Self.CW + Z;
  end;

procedure TGEMMat4.Translate(AValues: TGEMVec3);
  begin
    Self.AW := Self.AW + AValues.X;
    Self.BW := Self.BW + AValues.Y;
    Self.CW := Self.CW + AValues.Z;
  end;

procedure TGEMMat4.Rotate(X: Single = 0; Y: Single = 0; Z: Single = 0);
var
XMat,YMat,ZMat: TGEMMat4;
  begin
    Self.SetIdentity();
    XMat.SetIdentity();
    YMat.SetIdentity();
    ZMat.SetIdentity();

    if X <> 0 then begin
      XMat.BY := cos(X);
      XMat.BZ := -sin(X);
      XMat.CY := sin(X);
      XMat.CZ := cos(X);
    end;

    if Y <> 0 then begin
      YMat.AX := cos(Y);
      YMat.AZ := sin(Y);
      YMat.CX := -sin(Y);
      YMat.CZ := cos(Y);
    end;

    if Z <> 0 then begin
      ZMat.AX := cos(Z);
      ZMat.AY := -sin(Z);
      ZMat.BX := sin(Z);
      ZMat.BY := cos(Z);
    end;

    Self := XMat * YMat * ZMat;

  end;

procedure TGEMMat4.Rotate(AValues: TGEMVec3);
  begin
    Self.Rotate(AValues.X, AValues.Y, AValues.Z);
  end;


procedure TGEMMat4.MakeScale(X, Y, Z: Single);
  begin

    Self.SetIdentity();
    Self.AX := -1 + ((1 / X) * 2);
    Self.AY := -1 + ((1 / Y) * 2);
    Self.AZ := -1 + ((1 / Z) * 2);

  end;

procedure TGEMMat4.Perspective(AFOV, Aspect, ANear, AFar: Single; VerticalFOV: Boolean = True);
var
YScale,XScale: Single;
  begin

    AFOV := AFOV * (Pi / 180);

    if VerticalFOV = False then begin
      XScale := 1 / Tan(AFOV / 2);
      YScale := XScale / Aspect;
    end else begin
      YScale := 1 / Tan(AFOV / 2);
      XScale := YScale / Aspect;
    end;

    Self.M[0,0] := XScale;
    Self.M[1,0] := 0;
    Self.M[2,0] := 0;
    Self.M[3,0] := 0;

    Self.M[0,1] := 0;
    Self.M[1,1] := YScale;
    Self.M[2,1] := 0;
    Self.M[3,1] := 0;

    Self.M[0,2] := 0;
    Self.M[1,2] := 0;
    Self.M[2,2] := AFar / (ANear - AFar);
    Self.M[3,2] := (AFar * ANear) / (ANear - AFar);

    Self.M[0,3] := 0;
    Self.M[1,3] := 0;
    Self.M[2,3] := -1;
    Self.M[3,3] := 0;

  end;

procedure TGEMMat4.Ortho(ALeft,ARight,ABottom,ATop,ANear,AFar: Single);
  begin
    Self.SetIdentity();
    Self.M[0,0] := 2 / (ARight - ALeft);
    Self.M[1,1] := 2 / (ABottom - ATop);
    Self.M[2,2] := -2 / (AFar - ANear);
    Self.M[3,0] := ((ALeft + ARight) / (ALeft - ARight));
    Self.M[3,1] := ((ATop + ABottom) / (ATop - ABottom));
    Self.M[3,2] := ((ANear + AFar) / (AFar - ANear));
  end;

procedure TGEMMat4.LookAt(AFrom,ATo,AUp: TGEMVec3; const aFlipY: Boolean = False);
var
Right,NewUp,Direction: TGEMVec3;
TransMat: TGEMMat4;
  begin

    Direction := Normal(AFrom - ATo);
    Right := Cross(Direction, AUp);
    Normalize(Right);
    NewUp := Cross(Direction, Right);

    if aFlipY = False then begin
    	NewUp.Negate();
    end;

    Normalize(NewUp);

    Self := [Right.X, Right.Y, Right.Z, 0,
             NewUp.X, NewUp.Y, NewUp.Z, 0,
             Direction.X, Direction.Y, Direction.Z, 0,
             0,       0,       0,           1];

    TransMat.MakeTranslation(-AFrom);

    Self := Self * TransMat;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMCylinder
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMCylinder.Create(ACenter: TGEMVec3; AUpVector: TGEMVec3; ARadius: Single; AHeight: Single);
  begin
    Self.fRadius := ARadius;
    Self.fHeight := AHeight;
    Self.fUp := AUpVector;
    Self.SetCenter(ACenter);
  end;

procedure TGEMCylinder.Translate(AValue: TGEMVec3);
  begin
    Self.Center := Self.Center + AValue;
  end;

procedure TGEMCylinder.SetBottomCenter(const ABottomCenter: TGEMVec3);
  begin
    fBottomCenter := ABottomCenter;
    fCenter := ABottomCenter + (fUp * (fHeight / 2));
    fTopCenter := ABottomCenter + (fUp * fHeight);
  end;

procedure TGEMCylinder.SetCenter(const ACenter: TGEMVec3);
  begin
    fCenter := ACenter;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

procedure TGEMCylinder.SetHeight(const AHeight: Single);
  begin
    fHeight := AHeight;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

procedure TGEMCylinder.SetRadius(const ARadius: Single);
  begin
    fRadius := ARadius;
  end;

procedure TGEMCylinder.SetTopCenter(const ATopCenter: TGEMVec3);
  begin
    fTopCenter := ATopCenter;
    fCenter := ATopCenter - (fUp * (fHeight / 2));
    fBottomCenter := ATopCenter - (fUp * fHeight);
  end;

procedure TGEMCylinder.SetUpVector(const AUpVector: TGEMVec3);
  begin
    Self.fUp := AUpVector;
    fBottomCenter := fCenter - (fUp * (fHeight / 2));
    fTopCenter := fCenter + (fUp * (fHeight / 2));
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMPlane
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMPlane.Create(P1: TGEMVec3; ANormal: TGEMVec3);
  begin
    Self.Normal := ANormal.Normal;
    Self.Distance := Dot(P1,Normal.Normal);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMFrustum
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}
function TGEMFrustum.isInViewSphere(APosition: TGEMVec3; ARadius: Single): Boolean;
  begin
    Result := False;
    if (Self.OnorForwardSphere(Self.Faces.Left, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Right, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Far, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Near, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Top, APosition, ARadius)) and
       (Self.OnorForwardSphere(Self.Faces.Bottom, APosition, ARadius)) then begin
          Result := True;
    end;
  end;


{$ifndef FPC}
function TGEMFrustum.OnorForwardSphere(const [ref] AFace: TGEMPlane; var ACenter: TGEMVec3; var ARadius: Single): Boolean;
{$else}
function TGEMFrustum.OnorForwardSphere(constref AFace: TGEMPlane; var ACenter: TGEMVec3; var ARadius: Single): Boolean;
{$endif}
	begin
    result := Dot(AFace.Normal, ACenter) - AFace.Distance > -ARadius;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMCamera
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMCamera.Create();
  begin
    Self.SetViewport(RectFWH(0,0,800,600));
    Self.Set2DCamera();
    Self.fFOV := 60;
    Self.fFOVVerticle := True;
    Self.SetPosition(Vec3(0,0,0));
    Self.SetTarget(Vec3(0,0,1));
    Self.fVerticleFlip := True;
  end;

procedure TGEMCamera.GetDirection();
  begin
    Self.fDirection := Normal(Self.fPosition - Self.fTarget);
  end;

procedure TGEMCamera.GetRight();
  begin
    Self.fRight := Normal(Cross(Vec3(0,1,0), Self.Direction));
  end;

procedure TGEMCamera.GetUp();
  begin
    Self.fUp := Cross(Self.Direction, Self.Right);
  end;

procedure TGEMCamera.GetNewAngles();
  begin
    Self.fAngles.Z := ArcTan(Self.Direction.Y / Self.Direction.X);
  end;


procedure TGEMCamera.ConstructFrustum();
var
HalfVSide,HalfHSide: Single;
FrontMultFar: TGEMVec3;
  begin
    HalfVSide := Self.ViewDistance * Tan(Radians(Self.fFOV) / 2);
    HalfHSide := HalfVSide * (Self.Viewport.width / Self.ViewPort.Height);
    FrontMultFar := -Self.Direction * Self.ViewDistance;

    Self.fFrustum.Faces.Near := TGEMPlane.Create(Self.Position + (-Self.Direction * Self.ViewNear), -Self.Direction);

    Self.fFrustum.Faces.Far := TGEMPlane.Create((Self.Position + frontMultFar), Self.Direction);

    Self.fFrustum.Faces.Right := TGEMPlane.Create(Self.Position,
                            Cross(frontMultFar - Self.Right * HalfHSide, Self.Up));

    Self.fFrustum.Faces.Left := TGEMPlane.Create(Self.Position,
                            Cross(Self.Up,frontMultFar + Self.Right * halfHSide));

    Self.fFrustum.Faces.Top := TGEMPlane.Create(Self.Position,
                            Cross(Self.Right, frontMultFar - Self.Up * halfVSide));

    Self.fFrustum.Faces.Bottom := TGEMPlane.Create(Self.Position,
                            Cross(frontMultFar + Self.Up * halfVSide, Self.Right));
  end;

procedure TGEMCamera.GetProjection();
  begin

    case Self.fCameraType of

      0:
        begin
          Self.ProjectionMatrix.Ortho(Self.ViewPort.Left, Self.ViewPort.Right, Self.ViewPort.Bottom, Self.ViewPort.Top, Self.fViewNear, Self.ViewDistance);
          Self.ViewMatrix.SetIdentity();
        end;

      1:
        begin
          Self.fProjection.Perspective(Self.FOV, Self.fViewport.Width / Self.fViewPort.Height, Self.fViewNear, Self.fViewDistance, Self.FOVVerticle);
          Self.fView.LookAt(Self.Position, Self.Target, Self.Up, True);
        end;

    end;

    Self.ConstructFrustum();

  end;

procedure TGEMCamera.Set2DCamera();
  begin
    Self.fCameraType := camera_type_2D;
    Self.GetProjection();
  end;

procedure TGEMCamera.Set3DCamera();
  begin
    Self.fCameraType := camera_type_3D;
    Self.GetProjection();
  end;

procedure TGEMCamera.SetViewport(ABounds: TGEMRectF; AViewNear: Single = 0; AViewFar: Single = 1);
  begin
    Self.fViewport := ABounds;
    Self.fViewNear := AViewNear;
    Self.fViewDistance := aViewFar;
    Self.GetProjection();
  end;

procedure TGEMCamera.SetViewDistance(AViewDistance: Single);
  begin
    Self.fViewDistance := AViewDistance;
    Self.GetProjection();
  end;

procedure TGEMCamera.SetPosition(APos: TGEMVec3);
  begin
    Self.fPosition := APos;
  end;

procedure TGEMCamera.SetTarget(ATarget: TGEMVec3);
  begin
    Self.fTarget := ATarget;
    Self.GetDirection();
    Self.GetNewAngles();
    Self.GetRight();
    Self.GetUp();
    Self.GetProjection();
  end;

procedure TGEMCamera.SetDirection(ADirection: TGEMVec3);
  begin
    Self.fDirection := ADirection;
    Self.SetTarget(Self.Position - Self.Direction);
  end;

procedure TGEMCamera.SetFOV(AValue: Single; AVerticleFOV: Boolean = true);
  begin
    Self.fFOV := AValue;
    Self.fFOVVerticle := AVerticleFOV;
    Self.GetProjection();
  end;

procedure TGEMCamera.Translate(AValues: TGEMVec3);
  begin
    Self.fPosition := Self.fPosition + AValues;
    Self.SetTarget(Self.Position - Self.Direction);
  end;

procedure TGEMCamera.Rotate(AValues: TGEMVec3);
  begin

    if Self.fCameraType = camera_type_2d then exit;

    Self.fAngles := Self.fAngles + AValues;
    ClampRadians(Self.fAngles.X);
    ClampRadians(Self.fAngles.Y);
    ClampRadians(Self.fAngles.Z);

    if Self.fVerticleFlip = True then begin
      if Self.fAngles.X > ((Pi / 2) * 0.99) then begin
        Self.fAngles.X := ((Pi / 2) * 0.99);
      end;
      if Self.fAngles.X < (-(Pi / 2) * 0.99) then begin
        Self.fAngles.X := (-(Pi / 2) * 0.99)
      end;
    end;

    Self.fDirection.X := (cos(Self.fAngles.Y) * cos(Self.fAngles.X));
    Self.fDirection.Y := sin(Self.fAngles.X);
    Self.fDirection.Z := (sin(Self.fAngles.Y) * cos(Self.fAngles.X));

    Self.fTarget := (Self.Position - (Self.Direction * 10));
    Self.GetRight();
    Self.GetUp();
    Self.GetProjection();
  end;

procedure TGEMCamera.LockVerticleFlip(AEnable: Boolean = True);
  begin
    Self.fVerticleFlip := AEnable;
  end;

function TGEMCamera.SphereInView(APosition: TGEMVec3; ARadius: Single): Boolean;
  begin
    Result := Self.fFrustum.isInViewSphere(APosition, ARadius);
  end;



end.
