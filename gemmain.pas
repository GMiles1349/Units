unit GEMMain;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
  {$modeswitch ADVANCEDRECORDS}
  {$modeswitch TYPEHELPERS}
{$endif}

{$ifopt D+}
	{$OPTIMIZATION OFF}
	{$INLINE OFF}
{$else}
  {$OPTIMIZATION ON}
  {$OPTIMIZATION FASTMATH}
  {$OPTIMIZATION REGVAR}
{$endif}

interface

uses
  GEMTypes, GEMUtil, GEMImageUtil, GEMMath,
  Classes, SysUtils, Process, Linux, Unix, UnixType, X, XLib, XUtil, KeySym, GL, GLX, glad_gl;

type

  TGEMKeyProc = procedure(aKey: Byte; aSymbol: TKeySym; aShift, aControl: Boolean);
  TGEMMouseButtonProc = procedure (aButton: Byte; aPosition: TGEMVec2; aShift, aControl: Boolean);
  TGEMMouseMoveProc = procedure (aButtons: Array of Byte; aPosition: TGEMVec2; aShift, aControl: Boolean);
  TGEMSizeProc = procedure(aWidth, aHeight: Cardinal);

  TGEMState = class;
  TGEMRenderTarget = class;
  TGEMRenderTexture = class;
  TGEMOpenGLWindow = class;
  TGEMSprite = class;
  TGEMTexture = class;
  TGEMKeyboard = class;
  TGEMMouse = class;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMDrawCommand
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMDrawCommand = ^TGEMDrawCommand;
  TGEMDrawCommand = record
  	Count: GLUint;
    InstanceCount: GLUint;
    FirstIndex: GLUint;
    BaseVertex: GLUint;
    BaseInstance: GLUint;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMVertex
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMVertex = ^TGEMVertex;
  TGEMVertex = record
  	Position: TGEMVec3;
    Color: TGEMColorF;
    TexCoord: TGEMVec3;
    Normal: TGEMVec3;
    Index: GLUint;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMUniform
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMUniform = ^TGEMUniform;
  TGEMUniform = record
  	UniformName: String;
    Location: GLInt;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMProgram
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMProgram = ^TGEMProgram;
  TGEMProgram = record
    public
      ProgramName: String;
      ProgramID: GLUint;
      VertexShader: GLUint;
      FragmentShader: GLUint;
      Uniform: Array of TGEMUniform;

      function CreateShader(const aShaderName: String): Boolean;
      procedure GetUniforms();
      function Location(const aName: String): GLInt;
  end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMState
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMState = ^TGEMState;
  TGEMState = class(TPersistent)
    private
    const
    	MaxBufferSize: GLInt = 512000;

  	var
    	// cached vertices, commands, elements
    	CurrentTarget: TGEMRenderTarget;
    	Vertex: Array of TGEMVertex;
      VertexCount: GLInt;
      Command: Array of TGEMDrawCommand;
      CommandCount: GLInt;
      Element: Array of GLUint;
      ElementCount: GLInt;
      CommandTexture: Array [0..999] of GLUint;
      TextureSlot: Array of GLUint;
      TextureSlotCount: GLInt;
      RotMat: Array [0..999] of TGEMMat4;
      TransMat: Array [0..999] of TGEMMat4;

      // OGL Objects
      VAO: GLUint;
      VBO: GLUint;
      TextureSSBO: GLUint;
      EBO: GLUint;
      RotSSBO: GLUInt;
      TransSSBO: GLUint;
      Programs: Array of TGEMProgram;
      CurrentProgram: PGEMProgram;
      fTexUnit: Array of GLUint;

      // OGL State/Info
      MajorVersion, MinorVersion: GLInt;
      MaxSamplers: GLInt;
      MaxCombinedTextureUnits: GLInt;
      MaxVertices: GLInt;
      MaxFramebufferWidth: GLInt;
      MaxFramebufferHeight: GLInt;

      // Debug
      fDebugString: Array of String;
      fDebugStringCount: GLInt;

      // cameras
      fDefaultCamera: TGEMCamera;
      fCurrentCamera: TGEMCamera;

      // User Configurable State
      fBlendEnabled: Boolean;
      fDepthEnabled: Boolean;

      // User Objects
      fTextures: Array of TGEMTexture;

      constructor Create();
      destructor Destroy();
      procedure Init();
      procedure QueryGLInfo();
			procedure LoadShaders();
			procedure UseProgram(const aShaderName: String);

			procedure BindTexture(const aTextureUnit: GLUint; var aTexture: TGEMTexture); overload;
			procedure BindTexture(const aTextureUnit: GLUint; const aHandle: GLUint); overload;
			procedure UnBindAll();

    public
      property Camera: TGEMCamera read fCurrentCamera;
      property BlendEnabled: Boolean read fBlendEnabled;
      property DepthEnabled: Boolean read fDepthEnabled;

      // Drawing/Display
      procedure Flush();
      procedure ResetDraw();

      // Factories
      procedure GenTexture(var aTexture: TGEMTexture; const aFileName: String = ''; const aWidth: GLUint = 0; const aHeight: GLUint = 0);

      // Factories, but like, destroying
      procedure DeleteTexture(var aTexture: TGEMTexture);

      // camera
      procedure UseCamera(var aCamera: TGEMCamera);
      procedure UseDefaultCamera();

      // set states
      procedure EnableBlend(const aEnable: Boolean = True);
      procedure EnableDepth(const aEnable: Boolean = True);

  end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRenderTarget
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMRenderTarget = ^TGEMRenderTarget;
  TGEMRenderTarget = class(TPersistent)
  	private
    	fBounds: TGEMRectI;
      fClearColor: TGEMColorF;
      fFrameBuffer: GLInt;
			fTexture2D: GLInt;
			fCopyTexture: GLInt;
			fDepthBuffer: GLInt;

      constructor Create(const aWidth, aHeight: GLUint);
      procedure SetupFramebuffer();
      procedure UpdateSize();

      function GetWidth(): Cardinal;
			function GetHeight(): Cardinal;

    public
      property Width: Cardinal read GetWidth;
      property Height: Cardinal read GetHeight;

      procedure DrawSprite(aSprite: TGEMSprite);
      procedure DrawCirlce(const aCenter: TGEMVec3; const aRadius: GLFloat; const aBorderWidth: GLFloat; const aFillColor, aBorderColor: TGEMColorF);

      procedure SaveToFile(const aFileName: String);

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRenderTexture
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

  PGEMRenderTexture = ^TGEMRenderTexture;
  TGEMRenderTexture = class(TGEMRenderTarget)
  	private
    	fTexture: GLInt;

    public
			constructor Create(const aWidth, aHeight: GLUint);

  end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMOpenGLWindow
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMOpenGLWindow = ^TGEMOpenGLWindow;
  TGEMOpenGLWindow = class(TGEMRenderTarget)
  	private
    class var
    	fDisplay: PDisplay;
  		fWindowHandle: TWindow;
      fScreen: Integer;

  	var
      fContext: GLXContext;
      fOpen: Boolean;
      fTitle: String;
    	fMouse: TGEMMouse;
      fKeyboard: TGEMKeyboard;
      fEvent: TXEvent;
      fGC: TGC;
      fExtents: Array [0..3] of clong;

      // gl
      fGL_MajorVersion: Integer;
      fGL_MinorVersion: Integer;
      fGL_ProfileBit: Integer;

      // callbacks
      fSizeProc: TGEMSizeProc;

      procedure UpdateExtents();

      function GetX(): Integer;
      function GetY(): Integer;

    public
      property Open: Boolean read fOpen;
      property X: Integer read GetX;
      property Y: Integer read GetY;
      property Title: String read fTitle;
      property KeyBoard: TGEMKeyboard read fKeyboard;
      property Mouse: TGEMMouse read fMouse;
      property BorderWidth: clong read fExtents[0];
      property CaptionHeight: clong read fExtents[2];

      constructor Create(aWidth, aHeight: Cardinal; aTitle: String);

      procedure Close();
      procedure PollEvents();
      procedure Display();
      procedure Clear();
      procedure Clear(aBackColor: TGEMColorF);

      procedure SetTitle(aTitle: String);
      procedure SetWidth(const aWidth: Integer);
      procedure SetHeight(const aHeight: Integer);
      procedure SetSize(const aWidth, aHeight: Integer);
      procedure SetLeft(const aLeft: Integer);
      procedure SetTop(const aTop: Integer);
      procedure SetPosition(const aLeft, aTop: Integer);

      procedure SetSizeProc(aProc: TGEMSizeProc);

	end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMTexture
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMTexture = ^TGEMTexture;
  TGEMTexture = class(TObject)
  	private
    	fHandle: GLUint;
      fWidth: GLUint;
      fHeight: GLUint;
      fDataSize: GLUint;

      constructor Create(const aFileName: String); overload;
      constructor Create(const aWidth, aHeight: GLUint); overload;
      destructor Destroy();
			procedure Free();

    public
    	property Handle: GLUint read fHandle;
      property Width: GLUint read fWidth;
      property Height: GLUint read fHeight;
      property DataSize: GLUint read fDataSize;

      procedure SaveToFile(const aFileName: String);

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                  TGEMSprite
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMSprite = ^TGEMSprite;
  TGEMSprite = class(TPersistent)
  	private
    	fTexture: TGEMTexture;
      fWidth, fHeight: GLUint;
      fCenter: TGEMVec3;
      fCorners: Array [0..3] of TGEMVertex;
      fAngles: TGEMVec3;
      fColorValues: TGEMColorF;

      procedure UpdatePosition();

			function GetOrgWidth(): GLUint;
			function GetOrgHeight(): GLUint;

    public
    	property Texture: TGEMTexture read fTexture;
      property Width: GLUint read fWidth;
      property Height: GLUint read fHeight;
      property OrgWidth: GLUint read GetOrgWidth;
      property OrgHeight: GLUint read GetOrgHeight;
      property Center: TGEMVec3 read fCenter;
      property TopLeft: TGEMVec3 read fCorners[0].Position;
      property TopRight: TGEMVec3 read fCorners[1].Position;
      property BottomRight: TGEMVec3 read fCorners[2].Position;
      property BottomLeft: TGEMVec3 read fCorners[3].Position;
      property AngleX: GLFloat read fAngles.X;
      property AngleY: GLFloat read fAngles.Y;
      property AngleZ: GLFloat read fAngles.Z;
      property Angles: TGEMVec3 read fAngles;
      property ColorValues: TGEMColorF read fColorValues;

      constructor Create(const aTexture: TGEMTexture);
      constructor Create(const aWidth, aHeight: GLUint); overload;

      procedure SetTexture(aTexture: TGEMTexture);
      procedure SetCenter(const aCenter: TGEMVec3);
      procedure Translate(const aVector: TGEMVec3);

      procedure SetWidth(const aWidth: GLUint);
      procedure SetHeight(const aHeight: GLUint);
      procedure SetSize(const aWidth, aHeight: GLUint);

      procedure SetAngleX(const aAngle: GLFloat);
      procedure SetAngleY(const aAngle: GLFloat);
      procedure SetAngleZ(const aAngle: GLFloat);
      procedure SetAngles(const aAngles: TGEMVec3);

      procedure SetColorValues(const aValues: TGEMColorF);

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMKeyboard
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMKeyboard = ^TGEMKeyboard;
  TGEMKeyboard = class(TPersistent)
  	private
     	fKey: Array [0..255] of Byte;
      fLeftShift, fRightShift: Byte;
      fLeftControl, fRightControl: Byte;

      // Callbacks
			fKeyPressProc: TGEMKeyProc;
      fKeyDownProc: TGEMKeyProc;
      fKeyUpProc: TGEMKeyProc;


      function GetKey(Index: Byte): Byte;
      function GetShift(): Boolean;
      function GetControl(): Boolean;

      procedure HandleKey(aKeyCode: UInt32; aState: UInt32);

    public
      property Key[Index: Byte]: Byte read GetKey;
      property Shift: Boolean read GetShift;
      property Control: Boolean read GetControl;

      procedure SetKeyPressProc(aProc: TGEMKeyProc);
      procedure SetKeyDownProc(aProc: TGEMKeyProc);
      procedure SetKeyUpProc(aProc: TGEMKeyProc);

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                TGEMMouse
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	PGEMMouse = ^TGEMMouse;
  TGEMMouse = class(TPersistent)
  	private
    	fPosition: TGEMVec2;
      fLastPosition: TGEMVec2;
      fDiffPosition: TGEMVec2;
      fLockedPosition: TGEMVec2;
      fScreenPosition: TGEMVec2;
      fButton: Array [0..9] of Byte;
      fLocked: Boolean;
      fInWindow: Boolean;

      // Callbacks
      fButtonDownProc: TGEMMouseButtonProc;
      fButtonUpProc: TGEMMouseButtonProc;
      fMouseMoveProc: TGEMMouseMoveProc;
      fWindowLeaveProc: TGEMMouseMoveProc;
      fWindowEnterProc: TGEMMouseMoveProc;

      function GetButton(Index: Byte): Byte;

			procedure HandleMove(X, Y: Integer);
			procedure HandleButton(aButton: Byte; aState: Byte);
			procedure HandleLeave();
			procedure HandleEnter();

    public
      property Position: TGEMVec2 read fPosition;
      property X: GLFloat read fPosition.X;
      property Y: GLFloat read fPosition.Y;
      property LastPosition: TGEMVec2 read fLastPosition;
      property DiffPosition: TGEMVec2 read fDiffPosition;
      property LockedPosition: TGEMVec2 read fLockedPosition;
      property ScreenPosition: TGEMVec2 read fScreenPosition;
      property Button[Index: Byte]: Byte read GetButton;
      property Locked: Boolean read fLocked;
      property InWindow: Boolean read fInWindow;

      procedure SetButtonDownProc(aProc: TGEMMouseButtonProc);
      procedure SetButtonUpProc(aProc: TGEMMouseButtonProc);
      procedure SetMouseMoveProc(aProc: TGEMMouseMoveProc);
      procedure SetWindowLeaveProc(aProc: TGEMMouseMoveProc);
      procedure SetWindowEnterProc(aProc: TGEMMouseMoveProc);

  end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   Functions
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

	// Debug
  procedure gemSendGLDebugMessage(const aMessage: String);
  procedure gemDebugProc(source: GLenum; typ: GLenum; id: GLuint; severity: GLenum; length: GLsizei; message: PGLchar; userParam: pointer); stdcall;

  function TGEMXErrorHandler(aDisplay: PDisplay; aErrorEvent: PXErrorEvent): Integer; cdecl;
  function CreateProgram(const aVertexPath, aFragmentPath: String): GLInt;
  procedure LoadShader(var aShader: GLUint; const aFileName: String);

  function FX(const Value, aFBWidth: GLFloat): GLFloat;
  function FY(const Value, aFBHeight: GLFloat): GLFloat;

  procedure RotateVertices(var aVertices: Array of TGEMVertex; const aAngles: TGEMVec3; const aOrigin: TGEMVec3);
  procedure TranslateVertices(var aVertices: Array of TGEMVertex; const aValues: TGEMVec3);

var
  GEM: TGEMState;
	Win: TGEMOpenGLWindow;
	EXEPath: String;

const
  gem_left_button: Byte = 1;
  gem_middle_button: Byte = 2;
  gem_right_button: Byte = 3;
  gem_X_button_1: Byte = 8;
  gem_X_button_2: Byte = 9;

implementation

procedure gemSendGLDebugMessage(const aMessage: String);
	begin
  	glDebugMessageInsert(GL_DEBUG_SOURCE_APPLICATION, GL_DEBUG_TYPE_OTHER, 0, GL_DEBUG_SEVERITY_NOTIFICATION, Length(aMessage), PGLChar(aMessage));
  end;

procedure gemDebugProc(source: GLenum; typ: GLenum; id: GLuint; severity: GLenum; length: GLsizei; message: PGLchar; userParam: pointer); stdcall;
var
MessageString: String;
	begin

    MessageString := '--------------------------------------------------------------' + sLineBreak +
    								 '!OpenGL ERROR!' + sLineBreak +
                     'SOURCE: ';


    Case source of
    	GL_DEBUG_SOURCE_API:
        begin
        	MessageString := MessageString + 'API/OpenGL' + sLineBreak;
        end;

      GL_DEBUG_SOURCE_WINDOW_SYSTEM:
        begin
        	MessageString := MessageString + 'Window System' + sLineBreak;
        end;

    	GL_DEBUG_SOURCE_SHADER_COMPILER:
        begin
          MessageString := MessageString + 'Shader Compiler' + sLineBreak;
        end;

      GL_DEBUG_SOURCE_THIRD_PARTY:
        begin
          MessageString := MessageString + 'Third Party/External Interception' + sLineBreak;
        end;

      GL_DEBUG_SOURCE_APPLICATION:
      	begin
          MessageString := MessageString + 'Application' + sLineBreak;
        end;

      GL_DEBUG_SOURCE_OTHER:
      	begin
          MessageString := MessageString + 'Other' + sLineBreak;
        end;

      else
     		MessageString := MessageString + 'Unknown' + sLineBreak;
    end;


    MessageString := MessageString + 'TYPE: ';

    case typ of
    	GL_DEBUG_TYPE_ERROR:
        begin
        	MessageString := MessageString + 'Error' + sLineBreak;
        end;

      GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
        begin
          MessageString := MessageString + 'Deprecated Behavior' + sLineBreak;
        end;

      GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
        begin
          MessageString := MessageString + 'Undefined Behavior' + sLineBreak;
        end;

      GL_DEBUG_TYPE_PORTABILITY:
        begin
          MessageString := MessageString + 'Portability' + sLineBreak;
        end;

      GL_DEBUG_TYPE_PERFORMANCE:
        begin
          MessageString := MessageString + 'Performance' + sLineBreak;
        end;

      GL_DEBUG_TYPE_MARKER:
        begin
          MessageString := MessageString + 'Marker' + sLineBreak;
        end;

      GL_DEBUG_TYPE_PUSH_GROUP:
        begin
          MessageString := MessageString + 'Group Push' + sLineBreak;
        end;

      GL_DEBUG_TYPE_POP_GROUP:
        begin
          MessageString := MessageString + 'Group Pop' + sLineBreak;
        end;

      GL_DEBUG_TYPE_OTHER:
        begin
          MessageString := MessageString + 'Other' + sLineBreak;
        end;
    end;


    MessageString := MessageString + 'SEVERITY: ';

    case severity of
    	GL_DEBUG_SEVERITY_HIGH:
    		begin
        	MessageString := MessageString + 'High' + sLineBreak;
        end;

      GL_DEBUG_SEVERITY_MEDIUM:
    		begin
        	MessageString := MessageString + 'Medium' + sLineBreak;
        end;

      GL_DEBUG_SEVERITY_LOW:
    		begin
        	MessageString := MessageString + 'Low' + sLineBreak;
        end;

      GL_DEBUG_SEVERITY_NOTIFICATION:
    		begin
        	MessageString := MessageString + 'Notification' + sLineBreak;
        end;

    end;

  	MessageString := MessageString + message + sLineBreak;

    MessageString := MessageString + '--------------------------------------------------------------';

   	WriteLn(MessageString);

  end;

function TGEMXErrorHandler(aDisplay: PDisplay; aErrorEvent: PXErrorEvent): Integer; cdecl;
	begin
   WriteLn('Error');
  end;


function CreateProgram(const aVertexPath, aFragmentPath: String): GLInt;
var
VS, FS: GLUint;
Success: GLInt;
	begin
  	Result := glCreateProgram();
    VS := glCreateShader(GL_VERTEX_SHADER);
    FS := glCreateShader(GL_FRAGMENT_SHADER);
    LoadShader(VS, aVertexPath);
    LoadShader(FS, aFragmentPath);
    glAttachShader(Result, VS);
    glAttachShader(Result, FS);
    glLinkProgram(Result);
    glGetProgramiv(Result, GL_LINK_STATUS, @Success);
    glDeleteShader(VS);
    glDeleteShader(FS);
    if Success = GL_FALSE then begin
      glDeleteProgram(Result);
      Result := 0;
    end;
  end;


procedure LoadShader(var aShader: GLUint; const aFileName: String);
var
InfoLog: Array [0..511] of AnsiChar;
Buff: PByte;
BuffSize: GLInt;
Success: GLInt;
	begin
    Initialize(Buff);
  	BuffSize := gemReadFile(aFileName, Buff);
    glShaderSource(aShader, 1, @Buff, @BuffSize);
    glCompileShader(aShader);
    glGetShaderiv(aShader, GL_COMPILE_STATUS, @Success);

    FreeMemory(Buff);

    if (Success = 0) then begin
      Initialize(InfoLog);
    	glGetShaderInfoLog(aShader, 512, nil, @InfoLog);
    end;
  end;


function FX(const Value, aFBWidth: GLFloat): GLFloat;
	begin
  	Exit( -1 + ((Value / aFBWidth) * 2) );
  end;


function FY(const Value, aFBHeight: GLFloat): GLFloat;
	begin
  	Exit( -1 + ((Value / aFBHeight) * 2) );
  end;

procedure RotateVertices(var aVertices: Array of TGEMVertex; const aAngles: TGEMVec3; const aOrigin: TGEMVec3);
var
MinX, MaxX, MinY, MaxY, MinZ, MaxZ: GLFloat;
Center: TGEMVec3;
I: Integer;
RotMat: TGEMMat4;
OrgMat: TGEMMat4;
TransMat: TGEMMat4;
	begin

    MinX := aVertices[0].Position.X;
    MinY := aVertices[0].Position.Y;
    MinZ := aVertices[0].Position.Z;
    MaxX := aVertices[0].Position.X;
    MaxY := aVertices[0].Position.Y;
    MaxZ := aVertices[0].Position.Z;

    for I := 1 to High(aVertices) do begin
    	MinX := Smallest([MinX, aVertices[I].Position.X]);
      MinY := Smallest([MinY, aVertices[I].Position.Y]);
      MinZ := Smallest([MinZ, aVertices[I].Position.Z]);
      MaxX := Biggest([MaxX, aVertices[I].Position.X]);
      MaxY := Biggest([MaxY, aVertices[I].Position.Y]);
      MaxZ := Biggest([MaxZ, aVertices[I].Position.Z]);
    end;

    Center := Vec3(Median(MinX, MaxX),
                   Median(MinY, MaxY),
                   Median(MinZ, MaxZ));

    TransMat.MakeTranslation(-Center);
    OrgMat.MakeTranslation(Vec3(0,0,0));
    RotMat.Rotate(aAngles);

    for I := 0 to High(aVertices) do begin
      aVertices[I].Position.Translate(-Center);
    	aVertices[I].Position := RotMat * aVertices[I].Position;
      aVertices[I].Position.Translate(Center);
    end;

  end;

procedure TranslateVertices(var aVertices: Array of TGEMVertex; const aValues: TGEMVec3);
var
I: Integer;
  begin
  	for I := 0 to High(aVertices) do begin
    	aVertices[I].Position.Translate(aValues);
    end;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMProgram
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

function TGEMProgram.CreateShader(const aShaderName: String): Boolean;
	begin

    Result := True;

    // Clean up old shaders and programs if they exist
    if Self.VertexShader <> 0 then begin
    	glDeleteShader(Self.VertexShader);
    end;

    if Self.FragmentShader <> 0 then begin
    	glDeleteShader(Self.FragmentShader);
    end;

    if Self.ProgramID <> 0 then begin
    	glDeleteProgram(Self.ProgramID);
    end;

    Self.ProgramName := aShaderName;

    Self.ProgramID := CreateProgram(EXEPath + 'Shaders/' + aShaderName + '.vert', EXEPath + 'Shaders/' + aShaderName + '.frag');
    if Self.ProgramID = 0 then begin
      Self.ProgramName := aShaderName;
      Result := False;
    end;

    Self.GetUniforms();
  end;

function TGEMProgram.Location(const aName: String): GLInt;
var
I: Integer;
	begin

    if Length(Self.Uniform) = 0 then Exit(-1);

    for I := 0 to High(Self.Uniform) do begin
    	if Self.Uniform[I].UniformName = aName then begin
      	Exit(Self.Uniform[I].Location);
      end;
    end;

  end;

procedure TGEMProgram.GetUniforms();
var
UCount: GLInt;
MaxName: GLInt;
NameLength: GLInt;
USize: GLInt;
UType: GLEnum;
UName: Array [0..99] of Char;
I,R: Integer;
	begin
    SetLength(Self.Uniform, 0);
    glGetProgramIV(Self.ProgramID, GL_ACTIVE_UNIFORMS, @UCount);

    if UCount = 0 then Exit();

    glGetProgramIV(Self.ProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, @MaxName);
    SetLength(Self.Uniform, UCount);
    for I := 0 to UCount - 1 do begin
    	glGetActiveUniform(Self.ProgramID, I, MaxName, @NameLength, @USize, @UType, @UName);
      Self.Uniform[I].UniformName := UName;
      Self.Uniform[I].Location := glGetUniformLocation(Self.ProgramID, @UName[0]);
    end;

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                   TGEMState
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMState.Create();
	begin
  	Self.CurrentTarget := nil;

  	Initialize(Self.Vertex);
    Self.VertexCount := 0;

    Initialize(Self.Command);
    Self.CommandCount := 0;
  end;

destructor TGEMState.Destroy();
	begin

    	while Length(Self.fTextures) > 0 do begin
      	Self.DeleteTexture(Self.fTextures[0]);
      end;

    Inherited;
  end;

procedure TGEMState.Init();
var
MaxStructs: GLInt;
I: Integer;
	begin
    Self.QueryGLInfo();
    Self.LoadShaders();

    SetLength(Self.fTexUnit, Self.MaxCombinedTextureUnits);
    FillByte(Self.fTexUnit[0], Length(Self.fTexUnit) * 4, 0);

    SetLength(Self.TextureSlot, Length(Self.fTexUnit));
    Self.TextureSlotCount := 0;

    MaxStructs := trunc(Self.MaxBufferSize / SizeOf(TGEMVertex));

    SetLength(Self.Vertex, MaxStructs);
    SetLength(Self.Element, MaxStructs);
    SetLength(Self.Command, MaxStructs);

  	glGenVertexArrays(1, @Self.VAO);
    glBindVertexArray(Self.VAO);

    glGenBuffers(1, @Self.VBO);
    glBindBuffer(GL_ARRAY_BUFFER, Self.VBO);
    glBufferData(GL_ARRAY_BUFFER, SizeOf(TGEMVertex) * MaxStructs, nil, GL_STREAM_DRAW);

    glGenBuffers(1, @Self.EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Self.EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, SizeOf(GLInt) * MaxStructs, nil, GL_STREAM_DRAW);

    glGenBuffers(1, @Self.RotSSBO);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.RotSSBO);
    glBufferData(GL_SHADER_STORAGE_BUFFER, SizeOf(TGEMMat4) * 999, nil, GL_STREAM_DRAW);

    glGenBuffers(1, @Self.TransSSBO);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, Self.TransSSBO);
    glBufferData(GL_SHADER_STORAGE_BUFFER, SizeOf(TGEMMat4) * 999, nil, GL_STREAM_DRAW);
  end;

procedure TGEMState.QueryGLInfo();
	begin
  	glGetIntegerv(GL_MAJOR_VERSION, @Self.MajorVersion);
    glGetIntegerv(GL_MINOR_VERSION, @Self.MinorVersion);
    glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, @Self.MaxCombinedTextureUnits);
    glGetIntegerv(GL_MAX_ELEMENTS_VERTICES, @Self.MaxVertices);
    glGetIntegerv(GL_MAX_FRAMEBUFFER_WIDTH, @Self.MaxFramebufferWidth);
    glGetIntegerv(GL_MAX_FRAMEBUFFER_HEIGHT, @Self.MaxFramebufferHeight);
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, @Self.MaxSamplers);
  end;

procedure TGEMState.LoadShaders();
var
Dir: TGEMDirectory;
VertCount: Integer;
VertList: Array of String;
I: Integer;
SName: String;
	begin
  	if gemIsDirectory(EXEPath + 'Shaders/') = False then Exit;

    Dir.Path := EXEPath + 'Shaders/';

    Initialize(VertList);
    SetLength(VertList, 0);

    for I := 0 to Dir.FileCount - 1 do begin
    	if Pos('.vert', Dir.Files[I]) <> 0 then begin
        SetLength(VertList, Length(VertList) + 1);
        VertList[High(VertList)] := Dir.Files[I];
      end;
    end;

    VertCount := Length(VertList);
    if VertCount = 0 then Exit;

    for I := 0 to VertCount - 1 do begin
    	SName := gemRemoveFileExtension(VertList[I]);
      if Dir.HasFile(SName + '.frag') = False then Exit;
      SetLength(Self.Programs, Length(Self.Programs) + 1);
      if Self.Programs[High(Self.Programs)].CreateShader(SName) = False then begin
        SetLength(Self.Programs, Length(Self.Programs) - 1);
      end;
    end;
  end;

procedure TGEMState.UseProgram(const aShaderName: String);
var
I: Integer;
	begin
    if Self.CurrentProgram <> nil then begin
  		if Self.CurrentProgram^.ProgramName = aShaderName then Exit;
    end;

    for I := 0 to High(Self.Programs) do begin
    	if Self.Programs[I].ProgramName = aShaderName then begin
      	Self.CurrentProgram := @Self.Programs[I];
        glUseProgram(Self.Programs[I].ProgramID);
        Exit();
      end;
    end;

  end;

procedure TGEMState.BindTexture(const aTextureUnit: GLUint; var aTexture: TGEMTexture); overload;
	begin
  	Self.BindTexture(aTextureUnit, aTexture.fHandle);
  end;

procedure TGEMState.BindTexture(const aTextureUnit: GLUint; const aHandle: GLUint); overload;
	begin
  	if aTextureUnit > High(Self.fTexUnit) then Exit();
    if Self.fTexUnit[aTextureUnit] = aHandle then Exit();
    Self.fTexUnit[aTextureUnit] := aHandle;
    glActiveTexture(GL_TEXTURE0 + aTextureUnit);
    glBindTexture(GL_TEXTURE_2D, aHandle);
  end;

procedure TGEMState.UnBindAll();
var
I: Integer;
	begin
    for I := 0 to High(Self.fTexUnit) do begin
    	glActiveTexture(GL_TEXTURE0 + I);
      glBindTexture(GL_TEXTURE_2D, 0);
    end;
  end;

procedure TGEMState.GenTexture(var aTexture: TGEMTexture; const aFileName: String = ''; const aWidth: GLUint = 0; const aHeight: GLUint = 0);
// if aFileName is used, then aWidth and aHeight are ignored, unless the aFileName a valid file name
	begin
    if aFileName <> '' then begin
      if gemFileExists(aFileName) then begin
      	aTexture := TGEMTexture.Create(aFileName);
      end;
    end;

    if Assigned(aTexture) = False then begin
    	aTexture := TGEMTexture.Create(aWidth, aHeight);
    end;

    SetLength(Self.fTextures, Length(Self.fTextures) + 1);
    Self.fTextures[High(Self.fTextures)] := aTexture;

  end;


procedure TGEMState.DeleteTexture(var aTexture: TGEMTexture);
var
I: Integer;
TPos: Integer;
	begin
    if Assigned(aTexture) = False then Exit();

    for I := 0 to High(Self.fTextures) do begin
    	if Self.fTextures[I] = aTexture then begin
        TPos := I;
        Break;
      end;
    end;

    aTexture.Destroy();
    aTexture := nil;

    Delete(Self.fTextures, TPos, 1);

  end;

procedure TGEMState.Flush();
var
TexList: Array [0..31] of GLUint;
I: GLUint;
	begin

    if Self.CurrentTarget = nil then Exit;

    glViewPort(0,0,Self.CurrentTarget.Width, Self.CurrentTarget.Height);

    glBindVertexArray(Self.VAO);
    glBindFramebuffer(GL_FRAMEBUFFER, Self.CurrentTarget.fFrameBuffer);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Self.EBO);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, SizeOf(GLInt) * Self.ElementCount, @Self.Element[0]);

    glBindBuffer(GL_ARRAY_BUFFER, Self.VBO);
    glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(TGEMVertex) * Self.VertexCount, @Self.Vertex[0]);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), Pointer(0));
    glEnableVertexAttribArray(0); // position

    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), Pointer(12));
    glEnableVertexAttribArray(1); // color

    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), Pointer(28));
    glEnableVertexAttribArray(2); // tex coords

    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), Pointer(40));
    glEnableVertexAttribArray(3); // normal

    glVertexAttribPointer(4, 1, GL_UNSIGNED_INT, GL_FALSE, SizeOf(TGEMVertex), Pointer(52));
    glEnableVertexAttribArray(4); // draw index

    // rotation matrix SSBO
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, GEM.RotSSBO);
    glBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, SizeOf(TGEMMat4) * 100, @GEM.RotMat);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, GEM.RotSSBO);

    // translation matrix SSBO
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, GEM.TransSSBO);
    glBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, SizeOf(TGEMMat4) * 100, @GEM.TransMat);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, GEM.TransSSBO);

    for I := 0 to 31 do begin
    	GEM.BindTexture(I, GEM.TextureSlot[0]);
    end;

    Self.UseProgram('Default');

    glUniform1iv(Self.CurrentProgram^.Location('Tex[0]'), 32, @Gem.TextureSlot[0]);
    glUniformMatrix4fv(Self.CurrentProgram^.Location('ProjMat'), 1, GL_FALSE, @Self.fCurrentCamera.ProjectionMatrix);
    glUniformMatrix4fv(Self.CurrentProgram^.Location('ViewMat'), 1, GL_FALSE, @Self.fCurrentCamera.ViewMatrix);

    glMultidrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, @Self.Command[0], Self.CommandCount, 0);

    glInvalidateBufferData(GEM.VBO);
    glInvalidateBufferData(GEM.RotSSBO);
    glInvalidateBufferData(GEM.TransSSBO);

    Self.ResetDraw();

  end;

procedure TGEMState.ResetDraw();
var
I: GLInt;
	begin

    Self.TextureSlotCount := 0;
    for I := 0 to Self.MaxCombinedTextureUnits - 1 do begin
    	Self.TextureSlot[I] := 0;
    end;

    for I := 0 to Self.CommandCount - 1 do begin
    	Self.CommandTexture[I] := 0;
    end;

  	Self.VertexCount := 0;
    Self.ElementCount := 0;
    Self.CommandCount := 0;
    Self.TextureSlotCount := 0;

  end;

procedure TGEMState.UseCamera(var aCamera: TGEMCamera);
	begin
  	if aCamera = nil then begin
      Self.fCurrentCamera := Self.fDefaultCamera;
    	Exit();
    end else begin
    	Self.fCurrentCamera := aCamera;
    end;
  end;

procedure TGEMState.UseDefaultCamera();
	begin
  	Self.fCurrentCamera := Self.fDefaultCamera;
  end;

procedure TGEMState.EnableBlend(const aEnable: Boolean = True);
	begin
  	if aEnable = Self.fBlendEnabled then Exit();

    Self.fBlendEnabled := aEnable;
    if Self.CommandCount <> 0 then Self.Flush();


    if aEnable then begin
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    end else begin
    	glDisable(GL_BLEND);
    end;
  end;

procedure TGEMState.EnableDepth(const aEnable: Boolean = True);
	begin
  	if aEnable = Self.fDepthEnabled then Exit();

    Self.fDepthEnabled := aEnable;
    if Self.CommandCount <> 0 then Self.Flush();


    if aEnable then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
			glDepthFunc(GL_LEQUAL);
    end else begin
    	glDisable(GL_DEPTH_TEST);
      glDepthMask(GL_FALSE);
    end;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRenderTarget
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMRenderTarget.Create(const aWidth, aHeight: GLUint);
	begin
  	inherited Create();
		fBounds := RectIWH(0,0,aWidth,aHeight);
  end;

procedure TGEMRenderTarget.SetUpFramebuffer();
var
FBStatus: GLEnum;
	begin
  	glGenFramebuffers(1, @Self.fFrameBuffer);

    glGenTextures(1, @Self.fTexture2D);
    glBindTexture(GL_TEXTURE_2D, Self.fTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    gltexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    glGenTextures(1, @Self.fCopyTexture);
    glBindTexture(GL_TEXTURE_2D, Self.fCopyTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    gltexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    glGenTextures(1, @Self.fDepthBuffer);
    glBindTexture(GL_TEXTURE_2D, Self.fDepthBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, Self.Width, Self.Height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    gltexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
    glBindTexture(GL_TEXTURE_2D, 0);

    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Self.fTexture2D, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, Self.fCopyTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer, 0);

    FBStatus := glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if FBStatus <> GL_FRAMEBUFFER_COMPLETE then begin
    	FBStatus := FBstatus;
    end;

  end;

procedure TGEMRenderTarget.UpdateSize();
	begin
  	GEM.BindTexture(0, Self.fTexture2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    GEM.BindTexture(0, Self.fDepthBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, Self.Width, Self.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    GEM.BindTexture(0,0);
  end;

function TGEMRenderTarget.GetWidth(): Cardinal;
	begin
  	Exit(fBounds.Width);
  end;

function TGEMRenderTarget.GetHeight(): Cardinal;
	begin
  	Exit(fBounds.Height);
	end;

procedure TGEMRenderTarget.DrawSprite(aSprite: TGEMSprite);
var
I: GLInt;
Ver: Array [0..3] of TGEMVertex;
C: GLInt;
  begin

  end;

procedure TGEMRenderTarget.DrawCirlce(const aCenter: TGEMVec3; const aRadius: GLFloat; const aBorderWidth: GLFloat; const aFillColor, aBorderColor: TGEMColorF);
var
I, C: GLInt;
Ver: Array [0..3] of TGEMVertex;
Box: TGEMRectF;
  begin

  end;

procedure TGEMRenderTarget.SaveToFile(const aFileName: String);
var
Buff: PByte;
DataSize: GLInt;
	begin

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMRenderTexture
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMRenderTexture.Create(const aWidth, aHeight: GLUint);
	begin
  	inherited Create(aWidth, aHeight);
    Self.SetupFramebuffer();
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMOpenGLWindow
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMOpenGLWindow.Create(aWidth, aHeight: Cardinal; aTitle: String);
var
Attribs: Array of Integer;
ContextAttribs: Array of Integer;
SWA: TXSetWindowAttributes;
CMap: TXColorMap;
FBConfig: PGLXFBConfig;
FBCount: Integer;
VI: PXVisualInfo;
Visuals: Array of TXVisualInfo;
I: Integer;
RetBool: TBoolResult;
	begin

		inherited Create(aWidth, aHeight);

  	Win := Self;
    fOpen := True;
    fTitle := aTitle;
    fMouse := TGEMMouse.Create();
    fKeyboard := TGEMKeyboard.Create();

    fDisplay := XOpenDisplay(nil);

    XSetErrorHandler(@TGEMXErrorHandler);

    Initialize(Attribs);
    Attribs := [GLX_X_RENDERABLE    , 1,
                GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
                GLX_RENDER_TYPE     , GLX_RGBA_BIT,
                GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
                GLX_RED_SIZE        , 8,
                GLX_GREEN_SIZE      , 8,
                GLX_BLUE_SIZE       , 8,
                GLX_ALPHA_SIZE      , 8,
                GLX_DEPTH_SIZE      , 24,
                GLX_STENCIL_SIZE    , 8,
                GLX_DOUBLEBUFFER    , 1,
                //GLX_SAMPLE_BUFFERS  , 1,
                //GLX_SAMPLES         , 4,
                None];

    FBConfig := glxChooseFBConfig(fDisplay, DefaultScreen(fDisplay), @Attribs[0], FBCount);

    Initialize(Visuals);
    SetLength(Visuals, FBCount);

    for I := 0 to FBCount - 1 do begin
    	VI := glxGetVisualFromFBConfig(fDisplay, FBConfig[I]);
      Visuals[I] := VI^;
  	end;

    CMap := XCreateColorMap(fDisplay, RootWindow(fDisplay, Visuals[0].screen), Visuals[0].visual, AllocNone);
    SWA.ColorMap := CMap;
    SWA.background_pixmap := NONE;
    SWA.border_pixel := 0;
    SWA.event_mask := ButtonPressMask or ButtonReleaseMask or ColormapChangeMask or EnterWindowMask or LeaveWindowMask or ExposureMask or FocusChangeMask
      or KeyPressMask or KeyReleaseMask or PointerMotionMask
      or PropertyChangeMask or StructureNotifyMask or VisibilityChangeMask;

    fWindowHandle := XCreateWindow(fDisplay, RootWindow(fDisplay, Visuals[0].screen), 0, 0, aWidth, aHeight, 0,
    	Visuals[0].depth, InputOutput, Visuals[0].visual, CWBorderPixel or CWColorMap or CWEventMask, @SWA);

    XStoreName(fDisplay, fWindowHandle, PAnsiChar(aTitle));
    XMapWindow(fDisplay, fWindowHandle);

    Initialize(ContextAttribs);
    ContextAttribs := [GLX_CONTEXT_MAJOR_VERSION_ARB, 4,
    								   GLX_CONTEXT_MINOR_VERSION_ARB, 5,
                       GLX_CONTEXT_PROFILE_MASK_ARB, GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
                       GLX_CONTEXT_FLAGS_ARB, GLX_CONTEXT_DEBUG_BIT_ARB,
                       NONE];

    fScreen := Visuals[0].screen;
    fContext := glxCreateContextAttribsARB(fDisplay, FBConfig[0], nil, True, @ContextAttribs[0]);
    fGC := XCreateGC(fDisplay, fWindowhandle, 0, nil);

    XSync(fDisplay, False);
    Sleep(10);

    RetBool := glxMakeCurrent(fDisplay, fWindowHandle, fContext);

    gladLoadGL(TLoadProc(glxGetProcAddressARB));

    Self.SetupFramebuffer();

    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(@gemDebugProc, nil);

    glViewPort(0, 0, aWidth, aHeight);
    glClearDepth(1);
    glClearColor(1, 0, 0, 1);

    glxSwapIntervalEXT(fDisplay, fWindowHandle, 0);

    GEM.Init();
    GEM.fDefaultCamera := TGEMCamera.Create();
    GEM.fCurrentCamera := GEM.fDefaultCamera;
    GEM.fDefaultCamera.Set2DCamera();
    GEM.fDefaultCamera.SetViewport(Self.fBounds, 0, 1000);
	end;

procedure TGEMOpenGLWindow.PollEvents();
var
RX, RY, RW, RC: Integer;
N1, N2, N3: Integer;
PeekEvent: TXEvent;
	begin

    if Self.Open = False then Exit;

    XQueryPointer(fDisplay, fWindowHandle, @RW, @RC, @RX, @RY, @N1, @N2, @N3);
    N1 := trunc(fMouse.fScreenPosition.X);
    N2 := trunc(fMouse.fScreenPosition.Y);
		fMouse.fScreenPosition.X := RX;
    fMouse.fScreenPosition.Y := RY;
  //
  //  if fMouse.fInWindow = False then begin
  //  	if (N1 <> RX) and (N2 <> RY) then begin
  //    	fMouse.HandleMove(trunc(fMouse.fPosition.X), trunc(fMouse.fPosition.Y));
  //    end;
  //  end;


    while XPending(fDisplay) <> 0 do begin

      XNextEvent(fDisplay, @fEvent);

      case fEvent._type of

        DestroyNotify:
        	begin
          	fOpen := False;
            glxDestroyContext(fDisplay, fContext);
            XCloseDisplay(fDisplay);
						Exit; // Leave message loop
          end;

        ConfigureNotify:
          begin
            if (Self.Width <> fEvent.xconfigure.width) or (Self.Height <> fEvent.xconfigure.height) then begin
            	fBounds.SetWidth(fEvent.xconfigure.width, FROM_LEFT);
              fBounds.SetHeight(fEvent.xconfigure.height, FROM_TOP);
              Self.UpdateSize();

            	if Assigned(fSizeProc) then begin
              	fSizeProc(fBounds.Width, fBounds.Height);
              end;
            end else begin
              UpdateExtents();
            	fBounds.SetTopLeft(fEvent.xconfigure.x, fEvent.xconfigure.y - fExtents[2]);
            end;
          end;

      	KeyPress:
          begin
          	fKeyBoard.HandleKey(fEvent.xkey.keycode, 1);
          end;

        KeyRelease:
        	begin
            XPeekEvent(fDisplay, @PeekEvent);

            if (PeekEvent._type = KeyPress) and (PeekEvent.xkey.time = fEvent.xkey.time) and (PeekEvent.xkey.keycode = fEvent.xkey.keycode) then begin
            	// ignore, it's an auto-repeat
            end else begin
          		fKeyBoard.HandleKey(fEvent.xkey.keycode, 0);
            end;
          end;

        MotionNotify:
          begin
          	fMouse.HandleMove(fEvent.xmotion.x, fEvent.xmotion.y);
          end;

        LeaveNotify:
          begin
          	fMouse.HandleLeave();
          end;

        EnterNotify:
          begin
          	fMouse.HandleEnter();
          end;

        ButtonPress:
          begin
          	fMouse.HandleButton(fEvent.xbutton.button, 1);
          end;

        ButtonRelease:
          begin
          	fMouse.HandleButton(fEvent.xbutton.button, 0);
          end;

      end;

  	end;

    XFlush(fDisplay);

	end;

procedure TGEMOpenGLWindow.UpdateExtents();
var
FrameAtom: TAtom;
TypeReturn: TAtom;
FormatReturn: cint;
ItemsReturn, BytesAfterReturn: culong;
PropReturn: PChar;
	begin

    FrameAtom := XInternAtom(fDisplay, '_NET_FRAME_EXTENTS', True);

    XGetWindowProperty(fDisplay, fWindowHandle, FrameAtom, 0, 4, False, AnyPropertyType, @TypeReturn,
      @FormatReturn, @ItemsReturn, @BytesAfterReturn, @PropReturn);

    Move(PropReturn[0], fExtents[0], SizeOf(clong) * 4);

  end;

function TGEMOpenGLWindow.GetX(): Integer;
	begin
    if Self.Open = false then Exit(0);
  	Exit(fBounds.Left);
  end;

function TGEMOpenGLWindow.GetY(): Integer;
	begin
    if Self.Open = False then Exit(0);
  	Exit(fBounds.Top);
  end;

procedure TGEMOpenGLWindow.Close();
  begin
    if Self.Open = False then Exit;
    XDestroyWindow(fDisplay, fWindowHandle);
  end;

procedure TGEMOpenGLWindow.Clear();
	begin
    if Self.Open = False then Exit;

    glBindFrameBuffer(GL_FRAMEBUFFER, Self.fFramebuffer);
    glDepthMask(GL_TRUE);
    glClearDepth(1);
    glClearColor(0,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDepthMask(GLBoolean(GEM.fDepthEnabled));
	end;

procedure TGEMOpenGLWindow.Display();
var
Ver: Array [0..7] of TGEMVec3;
Buff: PByte;
DSize: Integer;
	begin
    if Self.Open = False then Exit;

    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);

    glBindFrameBuffer(GL_FRAMEBUFFER, 0);

    Ver[0] := Vec3(-1, -1, 0);
    Ver[1] := Vec3(1, -1, 0);
    Ver[2] := Vec3(1, 1, 0);
    Ver[3] := Vec3(-1, 1, 0);

    Ver[4] := Vec3(0, 0, 0);
    Ver[5] := Vec3(1, 0, 0);
    Ver[6] := Vec3(1, 1, 0);
    Ver[7] := Vec3(0, 1, 0);

    glViewPort(0,0,Self.Width,Self.Height);

    GEM.BindTexture(0, Self.fTexture2D);

    glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(TGEMVec3) * 8, @Ver[0]);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, Pointer(0));
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, Pointer(48));
    glEnableVertexAttribArray(1);

    GEM.UseProgram('RenderTargetFlip');

    glUniform1i(GEM.CurrentProgram^.Location('SrcTex'), 0);

    glDrawArrays(GL_QUADS, 0, 4);

    glInvalidateBufferData(GEM.VBO);

  	glxSwapBuffers(fDisplay, fWindowHandle);
	end;

procedure TGEMOpenGLWindow.SetSizeProc(aProc: TGEMSizeProc);
	begin
    if Self.fOpen = False then Exit;
  	fSizeProc := aProc;
  end;

procedure TGEMOpenGLWindow.SetTitle(aTitle: String);
var
TC: Array of Char;
I: Integer;
RetVal: cint;
OutString: String;
	begin
    if Self.Open = False then Exit;
  	Self.fTitle := aTitle;

    SetLength(TC, Length(aTitle));
    for I := 0 to High(TC) do begin
    	TC[I] := aTitle[I + 1];
  	end;

    RetVal := XStoreName(fDisplay, fWindowHandle, Pchar(aTitle));

    XFlush(fDisplay);
	end;

procedure TGEMOpenGLWindow.SetWidth(const aWidth: Integer);
var
OutWidth: Cardinal;
	begin

    if aWidth < 0 then begin
      OutWidth := 0;
    end else begin
    	OutWidth := aWidth;
    end;

  	XResizeWindow(fDisplay, fWindowHandle, OutWidth, Self.Height);
  end;

procedure TGEMOpenGLWindow.SetHeight(const aHeight: Integer);
var
OutHeight: Cardinal;
	begin

    if aHeight < 0 then begin
      OutHeight := 0;
    end else begin
      OutHeight := aHeight;
    end;

  	XResizeWindow(fDisplay, fWindowHandle, Self.Width, OutHeight);
  end;

procedure TGEMOpenGLWindow.SetSize(const aWidth, aHeight: Integer);
var
OutWidth, OutHeight: Cardinal;
	begin

    if aWidth < 0 then begin
      OutWidth := 0;
    end else begin
      OutWidth := aWidth;
    end;

    if aHeight < 0 then begin
      OutHeight := 0;
    end else begin
      OutHeight := aHeight;
    end;

  	XResizeWindow(fDisplay, fWindowHandle, OutWidth, OutHeight);
  end;

procedure TGEMOpenGLWindow.SetLeft(const aLeft: Integer);
	begin
  	XMoveWindow(fDisplay, fWindowHandle, aLeft, fBounds.Top);
  end;

procedure TGEMOpenGLWindow.SetTop(const aTop: Integer);
	begin
  	XMoveWindow(fDisplay, fWindowHandle, fBounds.Left, aTop);
  end;

procedure TGEMOpenGLWindow.SetPosition(const aLeft, aTop: Integer);
	begin
  	XMoveWindow(fDisplay, fWindowHandle, aLeft, aTop);
  end;

procedure TGEMOpenGLWindow.Clear(aBackColor: TGEMColorF);
	begin
  	glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDepthMask(GL_TRUE);
    glClearDepth(1);
    glClearColor(aBackColor.Red, aBackColor.Green, aBackColor.Blue, aBackColor.Alpha);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                TGEMTexture
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMTexture.Create(const aFileName: String);
var
Buff: PByte;
W,H,C: Integer;
	begin
  	fHandle := 0;
    fWidth := 0;
    fHeight := 0;
    fDataSize := 0;


    if (W = 0) or (H = 0) then Exit();

    Buff := gemImageLoad(aFileName, @W, @H, @C);

    glGenTextures(1, @Self.fHandle);
    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, @Buff[0]);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    gltexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    Self.fWidth := W;
    Self.fHeight := H;
    Self.fDataSize := (Self.fWidth * Self.fHeight) * 4;

    FreeMemory(Buff);
  end;


constructor TGEMTexture.Create(const aWidth, aHeight: GLUint);
var
W,H: GLUint;
Buff: Pointer;
DSize: Integer;
	begin
    if aWidth = 0 then W := 1 else W := aWidth;
    if aHeight = 0 then H := 1 else H := aHeight;

    DSize := (W * H) * 4;
    Buff := GetMemory(DSize);
    FillByte(Buff^, DSize, 0);

    glGenTextures(1, @Self.fHandle);
    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, Buff);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    gltexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    Self.fWidth := W;
    Self.fHeight := H;
    Self.fDataSize := (Self.fWidth * Self.fHeight) * 4;

    FreeMemory(Buff);
  end;


destructor TGEMTexture.Destroy();
	begin
    glDeleteTextures(1, @Self.fHandle);
    Inherited;
  end;


procedure TGEMTexture.Free();
	begin

  end;

procedure TGEMTexture.SaveToFile(const aFileName: String);
var
Buff: PByte;
RetTex: GLUint;
	begin

  end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                 TGEMSprite
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMSprite.Create(const aTexture: TGEMTexture);
	begin
    Self.fTexture := nil;
    Self.fCenter := Vec3(0,0,0);
    FillByte(Self.fCorners[0], SizeOf(TGEMVertex) * 4, 0);
    Self.fWidth := 0;
    Self.fHeight := 0;

    Self.SetColorValues(gem_white_f);

    if Assigned(aTexture) = False then Exit();
    if (aTexture.fDataSize = 0) then Exit();

    Self.SetTexture(aTexture);
  end;

constructor TGEMSprite.Create(const aWidth, aHeight: GLUint);
	begin
  	Self.fTexture := nil;
    Self.fCenter := Vec3(0,0,0);
    FillByte(Self.fCorners[0], SizeOf(TGEMVertex) * 4, 0);
    Self.fWidth := aWidth;
    Self.fHeight := aHeight;

    Self.SetColorValues(gem_white_f);
    Self.UpdatePosition();
  end;

function TGEMSprite.GetOrgWidth(): GLUint;
	begin
    if Self.fTexture <> nil then begin
      Exit(Self.fTexture.fWidth);
    end else begin
      Exit(0);
    end;
  end;

function TGEMSprite.GetOrgHeight(): GLUint;
	begin
    if Self.fTexture <> nil then begin
      Exit(Self.fTexture.fHeight);
    end else begin
      Exit(0);
    end;
  end;

procedure TGEMSprite.UpdatePosition();
var
RotMat: TGEMMat4;
HWidth, HHeight: GLFloat;
	begin
    HWidth := (Self.fWidth / 2);
    HHeight := (Self.fHeight / 2);
    RotMat.Rotate(Self.fAngles);

    Self.fCorners[0].Position := Vec3(-HWidth, -HHeight, 0) + Self.fCenter;
    Self.fCorners[1].Position := Vec3(HWidth, -HHeight, 0) + Self.fCenter;
    Self.fCorners[2].Position := Vec3(HWidth, HHeight, 0) + Self.fCenter;
    Self.fCorners[3].Position := Vec3(-HWidth, HHeight, 0) + Self.fCenter;
  end;

procedure TGEMSprite.SetTexture(aTexture: TGEMTexture);
	begin
  	if Assigned(aTexture) then begin
    	Self.fTexture := aTexture;
      Self.fWidth := aTexture.Width;
      Self.fHeight := aTexture.Height;
      Self.fCorners[0].TexCoord := Vec3(0, 0, 0);
      Self.fCorners[1].TexCoord := Vec3(1, 0, 0);
      Self.fCorners[2].TexCoord := Vec3(1, 1, 0);
      Self.fCorners[3].TexCoord := Vec3(0, 1, 0);
    end else begin
      Self.fTexture := nil;
      Self.fWidth := 0;
      Self.fHeight := 0;
    end;

    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetCenter(const aCenter: TGEMVec3);
var
OldCenter: TGEMVec3;
Dif: TGEMVec3;
	begin

    OldCenter := Self.fCenter;
    Self.fCenter := aCenter;

    Dif := aCenter - OldCenter;
    Self.fCorners[0].Position.Translate(Dif);
    Self.fCorners[1].Position.Translate(Dif);
    Self.fCorners[2].Position.Translate(Dif);
    Self.fCorners[3].Position.Translate(Dif);
  end;

procedure TGEMSprite.Translate(const aVector: TGEMVec3);
var
Dif: TGEMVec3;
	begin
  	Self.SetCenter(Self.fCenter + aVector);
  end;

procedure TGEMSprite.SetWidth(const aWidth: GLUint);
	begin
  	Self.fWidth := aWidth;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetHeight(const aHeight: GLUint);
	begin
  	Self.fHeight := aHeight;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetSize(const aWidth, aHeight: GLUint);
	begin
  	Self.fWidth := aWidth;
    Self.fHeight := aHeight;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetAngleX(const aAngle: GLFloat);
	begin
  	Self.fAngles.X := aAngle;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetAngleY(const aAngle: GLFloat);
	begin
  	Self.fAngles.Y := aAngle;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetAngleZ(const aAngle: GLFloat);
	begin
    Self.fAngles.Z := aAngle;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetAngles(const aAngles: TGEMVec3);
	begin
    Self.fAngles := aAngles;
    Self.UpdatePosition();
  end;

procedure TGEMSprite.SetColorValues(const aValues: TGEMColorF);
var
I: GLInt;
  begin
    Self.fColorValues := aValues;

  	for I := 0 to 3 do begin
    	Self.fCorners[I].Color := aValues;
    end;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                 TGEMKeyboard
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

function TGEMKeyboard.GetKey(Index: Byte): Byte;
	begin
  	Exit(fKey[Index]);
  end;

function TGEMKeyboard.GetShift(): Boolean;
	begin
  	Exit(fLeftShift + fRightShift > 0);
	end;

function TGEMKeyboard.GetControl(): Boolean;
	begin
  	Exit(fLeftControl + fRightControl > 0);
  end;

procedure TGEMKeyboard.HandleKey(aKeyCode: UInt32; aState: UInt32);
var
OldState: UInt32;
Sym: TKeySym;
  begin

    case Sym of
			XK_SHIFT_L:
        begin
        	fLeftShift := aState;
        end;

      XK_SHIFT_R:
        begin
       		fRightShift := aState;
        end;

      XK_CONTROL_L:
        begin
        	fLeftControl := aState;
        end;

      XK_CONTROL_R:
        begin
        	fRightControl := aState;
      	end;

    end;

    OldState := fKey[aKeyCode];
    Sym := XKeycodeToKeySym(TGEMOpenGLWindow.fDisplay, aKeyCode, 0);

    case aState of
      0: // handle key up
  			begin
        	fKey[aKeyCode] := aState;
          if Assigned(fKeyUpProc) then begin
            fKeyUpProc(aKeyCode, Sym, Shift, Control);
          end;
        end;

      1: // handle key press, key down
      	begin

          // keydown, works for key repeat
          if Assigned(fKeyDownProc) then begin
            fKeyDownProc(aKeyCode, Sym, Shift, Control);
          end;

          if fKey[aKeyCode] = 0 then begin
            fKey[aKeyCode] := 1;
            if Assigned(fKeyPressProc) then begin
              fKeyPressProc(aKeyCode, Sym, Shift, Control);
            end;
          end;

        end;

    end;

	end;

procedure TGEMKeyboard.SetKeyPressProc(aProc: TGEMKeyProc);
	begin
  	fKeyPressProc := aProc;
  end;

procedure TGEMKeyboard.SetKeyDownProc(aProc: TGEMKeyProc);
	begin
  	fKeyDownProc := aProc;
  end;

procedure TGEMKeyboard.SetKeyUpProc(aProc: TGEMKeyProc);
	begin
  	fKeyUpProc := aProc;
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                                TGEMMouse
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

function TGEMMouse.GetButton(Index: Byte): Byte;
	begin
  	Exit(fButton[Index]);
	end;

procedure TGEMMouse.HandleMove(X, Y: Integer);
	begin
    Self.fDiffPosition.X := X - Self.fPosition.X;
    Self.fDiffPosition.Y := Y - Self.fPosition.Y;
  	fPosition.X := X;
    fPosition.Y := Y;

    if Assigned(fMouseMoveProc) then begin
    	fMouseMoveProc(fButton, fPosition, Win.Keyboard.Shift, Win.Keyboard.Control);
    end;
  end;

procedure TGEMMouse.HandleButton(aButton: Byte; aState: Byte);
	begin
    fButton[aButton] := aState;

    case aState of
    	0:
        begin
        	if Assigned(fButtonUpProc) then begin
          	fButtonUpProc(aButton, fPosition, Win.Keyboard.Shift, Win.Keyboard.Control);
          end;
      	end;

      1:
        begin
        	if Assigned(fButtonDownProc) then begin
          	fButtonDownProc(aButton, fPosition, Win.Keyboard.Shift, Win.Keyboard.Control);
          end;
        end;
  	end;

  end;

procedure TGEMMouse.HandleLeave();
	begin
  	fInWindow := False;
    if Assigned(fWindowLeaveProc) then begin
    	fWindowLeaveProc(fButton, fPosition, Win.Keyboard.Shift, Win.Keyboard.Control);
    end;
  end;

procedure TGEMMouse.HandleEnter();
	begin
  	fInWindow := True;
    if Assigned(fWindowEnterProc) then begin
    	fWindowEnterProc(fButton, fPosition, Win.Keyboard.Shift, Win.Keyboard.Control);
    end;
	end;

procedure TGEMMouse.SetButtonDownProc(aProc: TGEMMouseButtonProc);
	begin
  	fButtonDownProc := aProc;
  end;

procedure TGEMMouse.SetButtonUpProc(aProc: TGEMMouseButtonProc);
	begin
  	fButtonUpProc := aProc;
  end;

procedure TGEMMouse.SetMouseMoveProc(aProc: TGEMMouseMoveProc);
	begin
  	fMouseMoveProc := aProc;
  end;

procedure TGEMMouse.SetWindowLeaveProc(aProc: TGEMMouseMoveProc);
	begin

  end;

procedure TGEMMouse.SetWindowEnterProc(aProc: TGEMMouseMoveProc);
	begin

  end;


initialization
	begin
  	EXEPath := ExtractFilePath(ParamStr(0));
    GEM := TGEMState.Create();
  end;


finalization
	begin
  	GEM.Destroy();
    GEM := nil;
  end;

end.

