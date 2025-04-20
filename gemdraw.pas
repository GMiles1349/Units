unit gemdraw;

{$mode delphi}{$H+}
{$modeswitch advancedrecords}

{$i gemoptimizations.Inc}

interface

uses
  gemdrawbuffers, gemdrawshaders, gemutil, gemarray, gemtypes, gemmath, gemimage, gemfreetype,
  glfw, glad_gl,
  Classes, SysUtils, Linux, BaseUnix, Math;

type

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Enums
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMSizeOp = (GEM_DESTROY = 0, GEM_CROP, GEM_STRETCH);
  TGEMSortOrder = (GEM_SORT_ASCENDING = 0, GEM_SORT_DESCENDING);

  TGEMErrorCode =
    // error types
    (GEM_INVALID_VALUE = 0,
    // error reasons
     GEM_NIL_EXPECTED, GEM_OBJECT_EXPECTED, GEM_NON_ZERO_EXPECTED,
     GEM_VALUE_TOO_LARGE, GEM_VALUE_TOO_SMALL,
    // error severity
     GEM_NOTIFY, GEM_WARNING, GEM_FATAL);

  { Used for test functions, e.g. depth and stencil testing.
    All enums share the value of their OpenGL enum equivalents,
    i.e. GEM_FUNC_# = GL_# (GEM_FUNC_NEVER = GL_NEVER) }
  TGEMTestFunc = (GEM_FUNC_NEVER = GL_NEVER,
                  GEM_FUNC_LESS = GL_LESS,
                  GEM_FUNC_LEQUAL = GL_LEQUAL,
                  GEM_FUNC_GREATER = GL_GREATER,
                  GEM_FUNC_GEQUAL = GL_GEQUAL,
                  GEM_FUNC_EQUAL = GL_EQUAL,
                  GEM_FUNC_NOTEQUAL = GL_NOTEQUAL,
                  GEM_FUNC_ALWAYS = GL_ALWAYS);

  { Used for stencil test ops
    All enums share the value of their OpenGL enum equivalents,
    i.e. GEM_OP_# = GL_# (GEM_OP_KEEP = GL_KEEP) }
  TGEMStencilOp = (GEM_OP_KEEP = GL_KEEP,
                   GEM_OP_ZERO = GL_ZERO,
                   GEM_OP_REPLACE = GL_REPLACE,
                   GEM_OP_INCR = GL_INCR,
                   GEM_OP_INCR_WRAP = GL_INCR_WRAP,
                   GEM_OP_DECR = GL_DECR,
                   GEM_OP_DECR_WARP = GL_DECR_WRAP,
                   GEM_OP_INVERT = GL_INVERT);

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             Class Forward Decs
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawState = class;
  TGEMDrawKeyboard = class;
  TGEMDrawMouse = class;
  TGEMDrawJoystick = class;
  TGEMDrawImage = class;
  TGEMDrawTexture = class;
  TGEMDrawSprite = class;
  TGEMDrawRenderTarget = class;
  TGEMDrawWindow = class;
  TGEMDrawRenderTexture = class;
  TGEMDrawFontAtlas = class;
  TGEMDrawFont = class;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMError
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawError = record
    public
      ErrorType: TGEMErrorCode;
      ErrorReason: TGEMErrorCode;
      ErrorSeverity: TGEMErrorCode;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             Callback proc types
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  { general }
  TGEMDrawProc = procedure();

  { state }
  TGEMDrawErrorProc = procedure(const aError: TGEMDrawError);

  { window }
  TGEMDrawWindowCloseProc = procedure();

  { key }
  TGEMDrawKeyProc = procedure(aKey, aScanCode, aMods: Integer);

  { mouse }
  TGEMDrawMouseMoveProc = procedure(X, Y: Double);
  TGEMDrawMouseButtonProc = procedure(Button, Mods: Integer);


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawConstants
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawConstants = record
    public
      const GEM_KEY_MOD_SHIFT = 1;
      const GEM_KEY_MOD_CONTROL = 2;
      const GEM_KEY_MOD_ALT = 4;
      const GEM_KEY_MOD_SUPER = 8;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawCommand
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawCommand = packed record
    Count: GLUint;
    InstanceCount: GLUint;
    FirstIndex: GLUint;
    BaseVertex: GLInt;
    BaseInstance: GLUint;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawParams
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawParams = packed record
    Translation: TGEMVec4;
    Rotation: TGEMVec4;
    Scale: TGEMVec4;
    ColorValues: TGEMColorF;
    ColorOverlay: TGEMColorF;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawInfo
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawInfo = packed record
    Index: Cardinal;
    Z: Single;
    ElementStart: Cardinal;
    ElementCount: Cardinal;
    VertexStart: Cardinal;
    VertexCount: Cardinal;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             TGEMStencilParams
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawStencilParams = record
    Func: TGEMTestFunc;
    Ref: Integer;
    Mask: Cardinal;
    StencilFailOp: TGEMStencilOp;
    StencilDepthFailOp: TGEMStencilOp;
    StencilDepthPassOp: TGEMStencilOp;

    class operator Initialize(var Dest: TGEMDrawStencilParams);
    constructor Create(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal;
      const aStencilFailOp, aStencilDepthFailOp, aStencilDepthPassOp: TGEMStencilOp);
    procedure SetParams(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal;
      const aStencilFailOp, aStencilDepthFailOp, aStencilDepthPassOp: TGEMStencilOp);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawState
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawState = class(TPersistent)
    private
      fConstants: TGEMDrawConstants;
      fInitialized: Boolean;
      fMonitor: PGLFWMonitor;
      fVideoMode: PGLFWVidMode;
      fMonitorSize: TPoint;
      fMonitorDPI: TPoint;
      fWindow: TGEMDrawWindow;
      fKeyboard: TGEMDrawKeyboard;
      fMouse: TGEMDrawMouse;
      fJoystick: Array [0..15] of TGEMDrawJoystick;
      fImageLoadPath: String;
      fSprite: TGEMDrawSprite;

      // GL state
      fVSyncEnabled: Boolean;
      fBlendingEnabled: Boolean;
      fDepthTestEnabled: Boolean;
      fClearDepthValue: Single;
      fStencilTestEnabled: Boolean;
      fClearStencilValue: Cardinal;
      fStencilValue: Cardinal;
      fStencilParams: TGEMDrawStencilParams;
      fColorMask: Array [0..3] of Byte;
      fLinearSamplingEnabled: Boolean;
      fAnisotropicFilteringEnabled: Boolean;
      fDrawSortingEnabled: Boolean;
      fAnisotropicSamples: Cardinal;
      fDepthLow, fDepthHigh: Single;
      fDrawSortOrder: TGEMSortOrder;
      fSampler: GLUint;
      fBufferSampler: GLUint;
      fDrawingText: Boolean;

      fGreyScaleEnabled: Boolean;
      fColorValues: TGEMColorF;

      // state variables
      fGLMajorVersion: Integer;
      fGLMinorVersion: Integer;
      fMaxShaderStorageBlocks: Integer;
      fMaxShaderStorageBufferBindings: Integer;
      fDoubleBuffered: Integer;
      fMaxDrawBuffers: Integer;
      fMaxFramebufferWidth: Integer;
      fMaxFramebufferHeight: Integer;
      fMaxTextureSize: Integer;
      fMaxTextureImageUnits: Integer;
      fMaxVertexAttribs: Integer;
      fMaxViewportDims: Array [0..1] of Integer;
      fMaxElementIndex: Integer;
      fMaxAnisotropicSamples: Integer;

      fScreenWidth: Integer;
      fScreenHeight: Integer;
      fRefreshRate: Integer;
      fWorkArea: TGEMRectI;

      // created objects
      fImages: TGEMArray<TGEMDrawImage>;
      fTextures: TGEMArray<TGEMDrawTexture>;
      fSprites: TGEMArray<TGEMDrawSprite>;
      fRenderTextures: TGEMArray<TGEMDrawRenderTexture>;

      // callback procs
      fErrorCount: Integer;
      fError: TGEMDrawError;
      fErrorProc: TGEMDrawErrorProc;

      // matrices
      Perspective: TGEMMat4;
      View: TGEMMat4;

      // draw buffers
      DrawType: String;
      Buffers: TGEMDrawBuffers;
      CurrentTarget: TGEMDrawRenderTarget;
      CommandCount: GLInt;
      ElementCount: GLInt;
      VertexCount: GLInt;
      TexturesUsed: GLInt; // number of textures bound
      DrawCommand: Array of TGEMDrawCommand;
      ElementBuffer: Array of GLUint;
      TextureSlot: Array of GLUint; // texture handles to be bound, 0 is reserved for nothing
      TextureUsing: Array of GLInt; // texture slot used by draw command, 0 is reserved for nothing
      Vertex: Array of TGEMVertex;
      ID: Array of GLUint;
      Params: Array of TGEMDrawParams;
      DrawInfo: Array of TGEMDrawInfo;

      fShaders: TGEMDrawShaders;

      procedure ErrOut(const aErrorType: TGEMErrorCode; const aErrorReason: TGEMErrorCode; const aErrorSeverity: TGEMErrorCode);
      procedure InitShaders();
      procedure GetGLInfo();
      procedure GetMonitorPhysSize();
      procedure InitSampler();
      procedure MakeEBO();
      procedure SetTarget(aTarget: TGEMDrawRenderTarget);
      procedure CheckBatch(const aVerticesExpected, aElementsExpected, aTextureExpected: GLUint);
      procedure DrawBatch(const aCurrentInstance, aInstanceCount: Integer);
      procedure DrawLight();
      procedure ResetBatch();
      procedure BindTexture(const aTexture: TGEMDrawTexture; const aTarget: GLInt = 0);
      procedure UnbindAllTextures();
      function FindTextureSlot(const aTextureHandle: GLUint): Integer;
      procedure QuickSortDrawInfoAscending(L, R: Integer);
      procedure QuickSortDrawInfoDescending(L, R: Integer);
      procedure ReOrderDraws();
      procedure UpdateColorMasks();

      procedure AddImage(var aImage: TGEMDrawImage);
      procedure AddTexture(var aTexture: TGEMDrawTexture);
      procedure AddSprite(var aSprite: TGEMDrawSprite);
      procedure AddRenderTexture(var aRenderTexture: TGEMDrawRenderTexture);

      procedure RemoveImage(var aImage: TGEMDrawImage);
      procedure RemoveTexture(var aTexture: TGEMDrawTexture);
      procedure RemoveSprite(var aSprite: TGEMDrawSprite);
      procedure RemoveRenderTexture(var aRenderTexture: TGEMDrawRenderTexture);

      function GetJoystick(const Index: Cardinal): TGEMDrawJoystick;
      procedure UpdateJoysticks();

    public
      property Constants: TGEMDrawConstants read fConstants;
      property Initialized: Boolean read fInitialized;
      property Keyboard: TGEMDrawKeyboard read fKeyboard;
      property Mouse: TGEMDrawMouse read fMouse;
      property Joystick [Index: Cardinal]: TGEMDrawJoystick read GetJoystick;
      property ImageLoadPath: String read fImageLoadPath;
      property ScreenWidth: Integer read fScreenWidth;
      property ScreenHeight: Integer read fScreenHeight;
      property MonitorSize: TPoint read fMonitorSize;
      property RefreshRate: Integer read fRefreshRate;
      property WorkArea: TGEMRectI read fWorkArea;
      property VSyncEnabled: Boolean read fVSyncEnabled;
      property BlendingEnabled: Boolean read fBlendingEnabled;
      property DepthTestEnabled: Boolean read fDepthTestEnabled;
      property ClearDepthValue: Single read fClearDepthValue;
      property StencilTestEnabled: Boolean read fStencilTestEnabled;
      property ClearStencilValue: Cardinal read fClearStencilValue;
      property StencilValue: Cardinal read fStencilValue;
      property StencilParams: TGEMDrawStencilParams read fStencilParams;
      property RedMask: Byte read fColorMask[0];
      property GreenMask: Byte read fColorMask[1];
      property BlueMask: Byte read fColorMask[2];
      property AlphaMask: Byte read fColorMask[3];
      property LinearSamplingEnabled: Boolean read fLinearSamplingEnabled;
      property AnisotropicFilteringEnabled: Boolean read fAnisotropicFilteringEnabled;
      property DrawSortingEnabled: Boolean read fDrawSortingEnabled;
      property AnisotropicSamples: Cardinal read fAnisotropicSamples;
      property GreyScaleEnabled: Boolean read fGreyScaleEnabled;
      property DrawSortOrder: TGEMSortOrder read fDrawSortOrder;
      property ColorValues: TGEMColorF read fColorValues;
      property TextureCount: UInt64 read fTextures.fSize;
      property ImageCount: UInt64 read fImages.fSize;

      { lifetime management }

      // INFO: Must call TGEMDrawState.Init() after creation
      constructor Create();
      destructor Destroy(); override;
      function Init(var aWindow: TGEMDrawWindow; const aWidth, aHeight: Cardinal; const aTitle: String = 'gemDraw Window'): Integer;
      procedure Terminate();

      { callback proc handling }

      procedure SetErrorProc(const aProc: TGEMDrawErrorProc);

      { joysticks }
      { INFO: Checks for and updates the Present state of joysticks
        INFO: Returns the number of joysticks found }
      function QueryJoysticks(): Cardinal;

      { utility }

      function GetErrorString(constref aErrorCode: TGEMErrorCode): String;

      procedure Flush();
      procedure SetImageLoadPath(const aPath: String);
      procedure EnableVSync(const aEnable: Boolean = True);
      procedure EnableBlending(const aEnable: Boolean = True);
      procedure EnableDepthTest(const aEnable: Boolean = True);
      procedure EnableStencilTest(const aEnable: Boolean= True);
      procedure EnableLinearSampling(const aEnable: Boolean = True);
      procedure EnableGreyScale(const aEnable: Boolean = True);

      { INFO: Triggers implicit batch flush }
      procedure EnableAnisotropicFiltering(const aEnable: Boolean = True);

      { INFO: Triggers implicit batch flush
        INFO: Ascending = near to far, Descending = far to near }
      procedure EnableDrawSorting(const aEnable: Boolean = True);

      { INFO: Triggers implicit batch flush if anisotropic filtering enabled
        INFO: One (1) sample equates to no filtering }
      procedure SetAnisotropicSamples(const aSamples: Cardinal);

      { INFO: Triggers implicit batch flush if draw sorting enabled
        INFO: Ascending = near to far, Descending = far to near }
      procedure SetDrawSortOrder(const aOrder: TGEMSortOrder);

      { INFO: Triggers implicit batch flush if draw sorting enabled
        Returns the sort order that was toggled to }
      function ToggleDrawSortOrder(): TGEMSortOrder;

      { INFO: Triggers implicit batch flush if depth testing enabled
        INFO: When depth testing is enabled, objects drawn with a Z value outside of aLow and aHigh will not be rendered }
      procedure SetDepthRange(const aLow, aHigh: Single);
      procedure SetClearDepthValue(const aValue: Single);

      { INFO: Triggers implicit batch flush if stencil testing enabled
        INFO: Sets the value to written to the stencil buffer }
      procedure SetStencilValue(const aValue: Cardinal);

      { INFO: Sets the value that Render Target stencil buffer is cleared to }
      procedure SetClearStencilValue(const aValue: Cardinal);

      { INFO: Triggers implicit batch flush if stencil testing enabled
        INFO: Determines how stencil testing is conducted
        -aFunc: Method of stencil testing
        -aRef: Reference value that is compared to the value to be written
        -aMask: Mask that is ANDed with aRef and stored stencil values after testing }
      procedure SetStencilFunction(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal);

      { INFO: Triggers implicit batch flush if stencil testing enabled
        INFO: Determines what is written to the stencil buffer after stencil testing
        -aStencilFail: Action to take if the stencil test fails
        -aDepthFail: Action to take if the stencil and depth tests fail
        -aDepthPass: Action to take if stencil and depth tests pass }
      procedure SetStencilOp(const aStencilFail, aDepthFail, aDepthPass: TGEMStencilOp);

      { INFO: Triggers implicit batch flush if stencil testing enabled
        INFO: Uses the values stored in aParams to call
        SetStencilFunction and SetStencilOp }
      procedure SetStencilParams(const aParams: TGEMDrawStencilParams);

      { INFO: Triggers implicit batch flush if stencil testing enabled
        INFO: Resets all stenciling values and parameters to their initial values
        resulting in all stencil testing passing and nothing being written to stencil buffers
        - Stencil clear value = 0
        - Stencil write value = 0
        - Test func = GEM_FUNC_ALWAYS
        - Test ref = 0
        - Test mask = 1
        - Stencil op fail = GEM_OP_KEEP
        - Stencil depth fail op = GEM_OP_KEEP
        - Stencil depth pass op = GEM_OP_KEEP }
      procedure ResetStencil();

      { INFO: Triggers implicit batch flush }
      procedure SetRedMask(const aMask: Byte);
      { INFO: Triggers implicit batch flush }
      procedure SetGreenMask(const aMask: Byte);
      { INFO: Triggers implicit batch flush }
      procedure SetBlueMask(const aMask: Byte);
      { INFO: Triggers implicit batch flush }
      procedure SetAlphaMask(const aMask: Byte);
      { INFO: Triggers implicit batch flush }
      procedure SetColorMasks(const aMask: TGEMColorI);

      { INFO: Triggers implicit batch flush
        INFO: Rendered objects will have their color values multiplied by aValues.RGB }
      procedure SetColorValues(const aValues: TGEMColorF);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             TGEMDrawKeyboard
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawKeyboard = class(TPersistent)
    private
      fKeyState: packed Array [0..400] of Byte;
      fEnabled: Boolean;

      fKeyDownProc: TGEMDrawKeyProc;
      fKeyUpProc: TGEMDrawKeyProc;

      constructor Create();

      function GetKeyState(const Index: Integer): Byte;
      procedure ReceiveKey(const Key, ScanCode, Action, Mods: Integer);

    public
      property KeyState[Index: Integer]: Byte read GetKeyState;
      property Enabled: Boolean read fEnabled;

      procedure SetKeyDownProc(const aProc: TGEMDrawKeyProc);
      procedure SetKeyUpProc(const aProc: TGEMDrawKeyProc);
      procedure SetEnabled(const aEnabled: Boolean = True);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                              TGEMDrawMouse
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawMouse = class(TPersistent)
    private
      fButtonState: packed Array [0..9] of Byte;
      fPosition: TGEMVec2;
      fLastPosition: TGEMVec2;
      fMoveDist: Single;
      fVisible: Boolean;
      fEnabled: Boolean;
      fSkipMoveProc: Boolean;

      fMoveProc: TGEMDrawMouseMoveProc;
      fButtonDownProc: TGEMDrawMouseButtonProc;
      fBUttonUpProc: TGEMDrawMouseButtonProc;

      constructor Create();

      function GetButtonState(const Index: Byte): Byte;
      procedure ReceivePosition(const X, Y: Double);
      procedure ReceiveButton(const Button, Action, Mods: Integer);

    public
      property ButtonState[Index: Byte]: Byte read GetButtonState;
      property Position: TGEMVec2 read fPosition;
      property LastPosition: TGEMVec2 read fLastPosition;
      property MoveDist: Single read fMoveDist;
      property Visible: Boolean read fVisible;
      property Enabled: Boolean read fEnabled;

      procedure SetVisible(const aVisible: Boolean = True);
      procedure SetEnabled(const aEnabled: Boolean = True);
      procedure CenterInWindow(const aCallMoveProc: Boolean = True);
      procedure SetPosition(const aPosition: TGEMVec2; const aCallMoveProc: Boolean = True);

      procedure SetMoveProc(const aProc: TGEMDrawMouseMoveProc);
      procedure SetButtonDownProc(const aProc: TGEMDrawMouseButtonProc);
      procedure SetButtonUpProc(const aProc: TGEMDrawMouseButtonProc);

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                              TGEMDrawJoystick
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawJoystick = class
    private
      fJoystickName: String;
      fGamepadName: String;
      fGUID: String;
      fPresent: Integer;
      fBattery: Single;
      fIndex: Integer;
      fNumSticks: Integer;
      fNumButtons: Integer;
      fDeadZoneThreshold: Single;

      State: GLFWGamepadState;
      fLeftStick: TGEMVec2;
      fRightStick: TGEMVec2;
      fLeftTrigger: Single;
      fRightTrigger: Single;
      fButton: Array [0..63] of Integer;

      constructor Create();

      procedure Init();
      procedure UpdatePresent(const aPresent: Integer);
      procedure QueryState();

      function GetButton(const Index: Integer): Integer;

    public
      property Present: Integer read fPresent;
      property Battery: Single read fBattery;
      property Index: Integer read fIndex;
      property NumSticks: Integer read fNumSticks;
      property NumButtons: Integer read fNumButtons;
      property DeadZoneThreshold: Single read fDeadZoneThreshold;
      property LeftStick: TGEMVec2 read fLeftStick;
      property RightStick: TGEMVec2 read fRightStick;
      property LeftTrigger: Single read fLeftTrigger;
      property RightTrigger: Single read fRightTrigger;
      property DPadLeft: Integer read fButton[GLFW_GAMEPAD_BUTTON_DPAD_LEFT];
      property DPadRight: Integer read fButton[GLFW_GAMEPAD_BUTTON_DPAD_RIGHT];
      property DPadUp: Integer read fButton[GLFW_GAMEPAD_BUTTON_DPAD_UP];
      property DPadDown: Integer read fButton[GLFW_GAMEPAD_BUTTON_DPAD_DOWN];
      property ButtonA: Integer read fButton[GLFW_GAMEPAD_BUTTON_A];
      property ButtonB: Integer read fButton[GLFW_GAMEPAD_BUTTON_B];
      property ButtonX: Integer read fButton[GLFW_GAMEPAD_BUTTON_X];
      property ButtonY: Integer read fButton[GLFW_GAMEPAD_BUTTON_Y];
      property ButtonCross: Integer read fButton[GLFW_GAMEPAD_BUTTON_CROSS];
      property ButtonCircle: Integer read fButton[GLFW_GAMEPAD_BUTTON_CIRCLE];
      property ButtonSquare: Integer read fButton[GLFW_GAMEPAD_BUTTON_SQUARE];
      property ButtonTriangle: Integer read fButton[GLFW_GAMEPAD_BUTTON_TRIANGLE];
      property LeftBumper: Integer read fButton[GLFW_GAMEPAD_BUTTON_LEFT_BUMPER];
      property RightBumper: Integer read fButton[GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER];
      property LeftThumb: Integer read fButton[GLFW_GAMEPAD_BUTTON_LEFT_THUMB];
      property RightThumb: Integer read fButton[GLFW_GAMEPAD_BUTTON_RIGHT_THUMB];
      property Back: Integer read fButton[GLFW_GAMEPAD_BUTTON_BACK];
      property Start: Integer read fButton[GLFW_GAMEPAD_BUTTON_START];
      property Guide: Integer read fButton[GLFW_GAMEPAD_BUTTON_GUIDE];
      property Button[Index: Integer]: Integer read GetButton;

      procedure SetDeadZoneThreshold(const aThreshold: Single);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawImage
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawImage = class(TGEMImage)
    private

    public
      constructor Create(const aWidth: Cardinal = 0; const aHeight: Cardinal = 0); overload;
      constructor Create(const aFileName: String); overload;
      constructor Create(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal); overload;
      constructor Create(var aTexture: TGEMDrawTexture); overload;

      procedure LoadFromFile(const aFileName: String); overload;
      procedure CopyFromTexture(aTexture: TGEMDrawTexture);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                              TGEMDrawTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawTexture = class(TPersistent)
    private
      fHandle: GLUint;
      fBounds: TGEMRectI;
      fType: GLUint; //0 = color, 1 = depth
      fMipMaps: GLUint; //0 = no, 1 = yes

      constructor CreateDepth(const aWidth, aHeight: GLUint);
      constructor CreateColorBuffer(const aWidth, aHeight: GLUint);
      procedure Init(const aWidth, aHeight: GLUint);
      procedure GenMipMaps();

    public
      property Handle: GLUint read fHandle;
      property Bounds: TGEMRectI read fBounds;
      property Width: GLInt read fBounds.fWidth;
      property Height: GLInt read fBounds.fHeight;

      constructor Create(); overload;
      constructor Create(const aWidth, aHeight: GLUint); overload;
      constructor Create(const aImage: TGEMDrawImage); overload;
      constructor Create(const aFileName: String); overload;
      constructor Create(var aTexture: TGEMDrawTexture; const aSourceBounds: TGEMRectI); overload;
      constructor Create(aRenderTarget: TGEMDrawRenderTarget; const aSourceBounds: TGEMRectI); overload;

      procedure LoadFromImage(const aImage: TGEMDrawImage);
      procedure LoadFromFile(const aFileName: String);
      procedure LoadFromTexture(var aTexture: TGEMDrawTexture; const aSourceBounds: TGEMRectI);
      procedure LoadFromRenderTarget(aRenderTarget: TGEMDrawRenderTarget; const aSourceBounds: TGEMRectI);

      procedure SetSize(const aWidth, aHeight: GLUint; const aOP: TGEMSizeOp = GEM_DESTROY);
      procedure SaveToFile(const aFileName: String; const aSaveMipMaps: Boolean = False);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawSprite
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawSprite = class(TPersistent)
    private
      fTexture: TGEMDrawTexture;
      fBounds: TGEMRectF;
      fTextureRect: TGEMRectI;
      fRotations: TGEMVec3;
      fColorValues: TGEMColorF;
      fColorOverlay: TGEMColorF;

    public
      property Texture: TGEMDrawTexture read fTexture;
      property Bounds: TGEMRectF read fBounds;
      property TexureRect: TGEMRectI read fTextureRect;
      property Rotations: TGEMVec3 read fRotations;
      property RotationX: Single read fRotations.X;
      property RotationY: Single read fRotations.Y;
      property RotationZ: Single read fRotations.Z;
      property ColorValues: TGEMColorF read fColorValues;
      property ColorOverlay: TGEMColorF read fColorOverlay;
      property Opacity: Single read fColorValues.Alpha;

      constructor Create(); overload;
      constructor Create(aTexture: TGEMDrawTexture); overload;

      procedure SetTexture(aTexture: TGEMDrawTexture);
      procedure SetTextureRect(const aRect: TGEMRectI);
      procedure SetColorValues(const aValues: TGEMColorF);
      procedure SetOpacity(const aOpacity: Single);
      procedure SetColorOverlay(const aOverlay: TGEMColorF);
      procedure SetRotations(const aRotations: TGEMVec3);
      procedure SetRotationX(const aRotation: Single);
      procedure SetRotationY(const aRotation: Single);
      procedure SetRotationZ(const aRotation: Single);
      procedure Rotate(const aRotations: TGEMVec3);

      procedure ResetColors();
      procedure ResetRotations();
      procedure ResetSize();
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            TGEMDrawRenderTarget
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawRenderTarget = class(TPersistent)
    private
      fBounds: TGEMRectI;
      fClearColor: TGEMColorF;
      fFBO: GLUint;
      fColorBuffer: TGEMDrawTexture;
      fBackBuffer: TGEMDrawTexture;
      fDepthBuffer: TGEMDrawTexture;
      fAttachedTexture: TGEMDrawTexture;

      constructor Create(const aWidth, aHeight: GLUint);
      procedure InitBuffers();
      procedure AttachDepthBuffer();
      procedure DetachDepthBuffer();

    public
      property Bounds: TGEMRectI read fBounds;
      property ClearColor: TGEMColorF read fClearColor;

      procedure Clear(); overload;
      procedure Clear(const aClearColor: TGEMColorF);
      procedure SetClearColor(const aColor: TGEMColorF);
      procedure AttachTexture(var aTexture: TGEMDrawTexture);
      procedure DetachTexture();

      procedure Blit(aDest: TGEMDrawRenderTarget; const aSourceRect, aDestRect: TGEMRectI);
      procedure Pixelate(const aBounds: TGEMRectI; const aPixelSize: Single);
      procedure Blur(const aBounds: TGEMRectI; const aRadius: Cardinal = 1);

      procedure DrawTriangle(constref aP1, aP2, aP3: TGEMVec3; constref aColor: TGEMColorF);
      procedure DrawRectangle(constref aBounds: TGEMRectF; constref aColor: TGEMColorF); overload;
      procedure DrawRectangle(constref aBounds: TGEMRectF; constref aBorderWidth: Single; constref aColor, aBorderColor: TGEMColorF); overload;
      procedure DrawRoundedRectangle(constref aBounds: TGEMRectF; constref aBorderWidth: Single; constref aColor, aBorderColor: TGEMColorF);
      procedure DrawLine(constref aP1, aP2: TGEMVec3; constref aWidth: Single; constref aColor: TGEMColorF);
      procedure DrawRoundedLine(constref aP1, aP2: TGEMVec3; constref aWidth: Single; constref aColor: TGEMColorF);
      procedure DrawCircle(constref aCenter: TGEMVec3; constref aRadius: Single; constref aColor: TGEMColorF);
      procedure DrawWedge(constref aCenter: TGEMVec3; constref aRadius, aStartAngle, aEndAngle: Single; constref aColor: TGEMColorF);
      procedure DrawTexture(var aTexture: TGEMDrawTexture; constref aBounds: TGEMRectF);
      procedure DrawSprite(var aSprite: TGEMDrawSprite);
      procedure DrawLight(const aCenter: TGEMVec3; const aRadius: Single; const aColor: TGEMColorI);
      procedure DrawText(aFont: TGEMDrawFont; const aCharSize: Cardinal; const aText: String; const aPosition: TGEMVec3; const aColor: TGEMColorF);

      procedure SaveToFile(const aFileName: String);
      procedure SaveDepthToFile(const aFileName: String);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             TGEMDrawWindow
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawWindow = class(TGEMDrawRenderTarget)
    private
      fHandle: PGLFWWindow;
      fShouldClose: Boolean;
      fTitle: String;
      fFrameLeft, fFrameTop, fFrameRight, fFrameBottom: Integer; // size of frame sides;
      fFrameBounds: TGEMRectI;
      fMaximized: Boolean;
      fMinimized: Boolean;
      fFullScreen: Boolean;
      fHasTitleBar: Boolean;

      // callback procs
      fResizeProc: TGEMDrawProc;

      constructor Create(const aWidth, aHeight: GLUint; const aTitle: String);
      procedure UpdateFrameSize();

    public
      property Title: string read fTitle;
      property FrameBounds: TGEMRectI read fFrameBounds;
      property Maximized: Boolean read fMaximized;
      property Minimized: Boolean read fMinimized;
      property FullScreen: Boolean read fFullScreen;
      property HasTitleBar: Boolean read fHasTitleBar;

      procedure Finish();
      procedure Update();
      procedure Close();
      procedure SetTitle(const aTitle: String);
      procedure SetPosition(const aPosition: TGEMVec2);
      procedure SetLeft(const aLeft: GLFLoat);
      procedure SetTop(const aTop: GLFloat);
      procedure SetMaximized(const aMaximized: Boolean = True);
      procedure SetMinimized(const aMinimized: Boolean = True);
      procedure SetHasTitleBar(const aHasTitleBar: Boolean = True);

      procedure SetResizeProc(const aProc: TGEMDrawProc);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                          TGEMDrawRenderTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawRenderTexture = class(TGEMDrawRenderTarget)
    private

    public
      constructor Create(const aWidth, aHeight: GLUint);
      procedure SetSize(const aWidth, aHeight: Cardinal);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            TGEMDrawFontCharacter
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawFontCharacter = record
    private
      Index: Integer;
      Symbol: Char;
      Position: TGEMVec2;
      Width: Cardinal;
      Height: Cardinal;
      BearingX: Single;
      BearingY: Single;
      Advance: Single;
      Kerning: Array [0..255] of Single;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            TGEMDrawFontAtlas
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawFontAtlas = class(TPersistent)
    private
      fOwner: TGEMDrawFont;
      fTexture: TGEMDrawTexture;
      Character: Array [0..255] of TGEMDrawFontCharacter;
      fOrigin: Cardinal;
      fWidth: Cardinal;
      fHeight: Cardinal;
      fGlyphs: Cardinal;
      Face: PFT_Face;

      constructor Create(aOwner: TGEMDrawFont; const aFilePath: String);
      procedure GetKernings();

    public
      property Width: Cardinal read fWidth;
      property Height: Cardinal read fHeight;
      property Origin: Cardinal read fOrigin;
      property Glyphs: Cardinal read fGlyphs;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawFont
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMDrawFont = class(TPersistent)
    private
      fValid: Boolean;
      fFontName: String;
      fFilePath: String;
      fAtlas: TGEMDrawFontAtlas;

    public
      property Valid: Boolean read fValid;
      property FontName: String read fFontName;
      property FilePath: String read fFilePath;
      property Atlas: TGEMDrawFontAtlas read fAtlas;

      constructor Create(const aFilePath: String);

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Global Functions
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  function gemDrawStart(var aDrawState: TGEMDrawState): Integer;

(*----------------------------------------------------------------------------*)
implementation
var
  DrawState: TGEMDrawState; // reference state object
  Window: TGEMDrawWindow;  // reference state window object
  CurrentProgram: TGEMDrawProgram;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               Unit local procs
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

 { OpenGL Debug Callback }
procedure gemOpenGLDebugProc(source: GLenum; errortype: GLenum; id: GLUint; severity: GLenum; messagelength: GLsizei; message: PChar; userparam: Pointer); cdecl;
var
SourceString: String;
TypeString: String;
SeverityString: String;
  begin

    if severity = GL_DEBUG_SEVERITY_NOTIFICATION then Exit();

    case Ord(source) of
      Ord(GL_DEBUG_SOURCE_API): SourceString :=             'GL_DEBUG_SOURCE_API';
      Ord(GL_DEBUG_SOURCE_WINDOW_SYSTEM): SourceString :=   'GL_DEBUG_SOURCE_WINDOW_SYSTEM';
      Ord(GL_DEBUG_SOURCE_SHADER_COMPILER): SourceString := 'GL_DEBUG_SOURCE_SHADER_COMPILER';
      Ord(GL_DEBUG_SOURCE_THIRD_PARTY): SourceString :=     'GL_DEBUG_SOURCE_THIRD_PARTY';
      Ord(GL_DEBUG_SOURCE_APPLICATION): SourceString :=     'GL_DEBUG_SOURCE_APPLICATION';
      Ord(GL_DEBUG_SOURCE_OTHER): SourceString :=           'GL_DEBUG_SOURCE_OTHER';
    end;

    case Ord(errortype) of
      Ord(GL_DEBUG_TYPE_ERROR): TypeString :=               'GL_DEBUG_TYPE_ERROR';
      Ord(GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR): TypeString := 'GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR';
      Ord(GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR): TypeString :=  'GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR';
      Ord(GL_DEBUG_TYPE_PORTABILITY): TypeString :=         'GL_DEBUG_TYPE_PORTABILITY';
      Ord(GL_DEBUG_TYPE_PERFORMANCE): TypeString :=         'GL_DEBUG_TYPE_PERFORMANCE';
      Ord(GL_DEBUG_TYPE_MARKER): TypeString :=              'GL_DEBUG_TYPE_MARKER';
      Ord(GL_DEBUG_TYPE_PUSH_GROUP): TypeString :=          'GL_DEBUG_TYPE_PUSH_GROUP';
      Ord(GL_DEBUG_TYPE_POP_GROUP): TypeString :=           'GL_DEBUG_TYPE_POP_GROUP';
      Ord(GL_DEBUG_TYPE_OTHER): TypeString :=               'GL_DEBUG_TYPE_OTHER';
    end;

    case Ord(severity) of
      Ord(GL_DEBUG_SEVERITY_HIGH): SeverityString :=         'GL_DEBUG_SEVERITY_HIGH';
      Ord(GL_DEBUG_SEVERITY_MEDIUM): SeverityString :=       'GL_DEBUG_SEVERITY_MEDIUM';
      Ord(GL_DEBUG_SEVERITY_LOW): SeverityString :=          'GL_DEBUG_SEVERITY_LOW';
      Ord(GL_DEBUG_SEVERITY_NOTIFICATION): SeverityString := 'GL_DEBUG_SEVERITY_NOTIFICATION';
    end;

    WriteLn('-----------------------------------------------------------------');
    WriteLn('OPENGL ERROR');
    WriteLn('Source: ' + SourceString);
    WriteLn('Type: ' + TypeString);
    WriteLn('Severity: ' + SeverityString);
    WriteLn(message);
    WriteLn();

  end;

 { GLFW callback procs }

 { GLFW error }

procedure gemDrawGLFWErrorProc(error_code: Integer; const description: PChar); cdecl;
  begin
    WriteLn(description);
  end;

 { Window }

procedure gemDrawWindowCloseProc(window: PGLFWWindow); cdecl;
  begin
    DrawState.fInitialized := False;
  end;

procedure gemDrawWindowPosProc(window: PGLFWWindow; x, y: GLInt); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    DrawState.fWindow.fFrameBounds.SetLeft(x);
    DrawState.fWindow.fFrameBounds.SetTop(y);

    DrawState.fWindow.UpdateFrameSize();
  end;

procedure gemDrawWindowMaximizeProc(window: PGLFWWindow; maximized: Integer); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    case maximized of
      0:
        begin
          DrawState.fWindow.fMaximized := False;
        end;

      1:
        begin
          DrawState.fWindow.fMaximized := True;
        end;
    end;
  end;

procedure gemDrawWindowMinimizeProc(window: PGLFWWindow; minimized: Integer); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    case minimized of
      0:
        begin
          DrawState.fWindow.fMinimized := False;
        end;

      1:
        begin
          DrawState.fWindow.fMinimized := True;
        end;
    end;
  end;

procedure gemDrawWindowSizeProc(window: PGLFWWindow; x, y: Integer); cdecl;
var
l, t, r, b: GLInt;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    DrawState.fWindow.fBounds := RectI(0, 0, x - 1, y - 1);
    DrawState.fWindow.fFrameBounds.SetSize(x, y);

    glfwGetWindowPos(DrawState.fWindow.fHandle, @l, @t);
    DrawState.fWindow.fFrameBounds.SetTopLeft(l, t);
    glfwGetWindowFrameSize(DrawState.fWindow.fHandle, @DrawState.fWindow.fFrameLeft,
                                                      @DrawState.fWindow.fFrameTop,
                                                      @DrawState.fWindow.fFrameRight,
                                                      @DrawState.fWindow.fFrameBottom);
    DrawState.fWindow.UpdateFrameSize();
    if DrawState.CurrentTarget = DrawState.fWindow then begin
      glViewPort(0, 0, DrawState.fWindow.Bounds.Width, DrawState.fWindow.Bounds.Height);
      DrawState.Perspective.Ortho(0, DrawState.fWindow.Bounds.Right, 0, DrawState.fWindow.Bounds.Bottom, DrawState.fDepthHigh, DrawState.fDepthLow);
    end;

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

    glfwGetFramebufferSize(DrawState.fWindow.fHandle, @l, @t);
  end;

procedure gemDrawWindowFocusProc(window: PGLFWWindow; focused: Integer); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    case focused of
      0:
        begin

        end;

      1:
        begin
          DrawState.fWindow.fMinimized := False;
        end;
    end;
  end;

 { Keys Input }

procedure gemDrawKeyProc(window: PGLFWWindow; key, scancode, action, mods: Integer); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    DrawState.Keyboard.ReceiveKey(key, scancode, action, mods);
  end;

 { Mouse }

procedure gemDrawMousePosProc(window: PGLFWWindow; xpos, ypos: Double); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    DrawState.Mouse.ReceivePosition(xpos, ypos);
  end;

procedure gemDrawMouseButtonProc(window: PGLFWWindow; button, action, mods: Integer); cdecl;
  begin
    if glfwWindowShouldClose(DrawState.fWindow.fHandle) = 1 then Exit();

    DrawState.fMouse.ReceiveButton(button, action, mods);
  end;

 { Joystick }

procedure gemDrawJoystickProc(jid: Integer; event: Integer);
  begin
    case event of
      GLFW_CONNECTED:
        begin
          DrawState.Joystick[jid].UpdatePresent(1);
        end;

      GLFW_DISCONNECTED:
        begin
          DrawState.Joystick[jid].UpdatePresent(0);
        end;
    end;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Global Procs
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function gemDrawStart(var aDrawState: TGEMDrawState): Integer;
  begin
    if Assigned(DrawState) then Exit(0);
    if Assigned(aDrawState) then Exit(0);

    aDrawState := TGEMDrawState.Create();
    DrawState := aDrawState;
  end;

function gemCheckTextureBindings(): TArray<Integer>;
var
I: Integer;
  begin
    SetLength(Result, DrawState.fMaxTextureImageUnits);
    for I := 0 to High(Result) do begin
      glActiveTexture(GL_TEXTURE0 + I);
      glGetIntegerv(GL_TEXTURE_BINDING_2D, @Result[I]);
    end;
  end;

function gemUnsignSDF(const aSource: Pointer; const aWidth, aHeight: Cardinal): Pointer;
var
Buff: PByte;
DPtr: PByte;
SPtr: PInt8;
PixelCount: Integer;
I: Integer;
  begin

    PixelCount := aWidth * aHeight;
    Buff := GetMemory(PixelCount * 4);
    DPtr := @Buff[0];
    SPtr := @aSource^;

    for I := 0 to PixelCount - 1 do begin

      DPtr[0] := 0;
      DPtr[1] := 0;
      DPtr[2] := 0;
      DPtr[3] := 255;

      if SPtr[0] < 0 then begin
        DPtr[0] := 255;
      end else if SPtr[0] > 0 then begin
        DPtr[1] := SPtr[0] * 2;
      end else begin
        DPtr[3] := 0;
      end;

      Inc(SPtr, 1);
      Inc(DPtr, 4);
    end;

    Result := Buff;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             TGEMDrawStencilParams
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TGEMDrawStencilParams.Initialize(var Dest: TGEMDrawStencilParams);
  begin
    Dest.Func := GEM_FUNC_ALWAYS;
    Dest.Ref := 0;
    Dest.Mask := 1;
    Dest.StencilFailOp := GEM_OP_KEEP;
    Dest.StencilDepthFailOp := GEM_OP_KEEP;
    Dest.StencilDepthPassOp := GEM_OP_KEEP;
  end;

constructor TGEMDrawStencilParams.Create(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal; const aStencilFailOp, aStencilDepthFailOp, aStencilDepthPassOp: TGEMStencilOp);
  begin
    Self.Func := aFunc;
    Self.Ref := aRef;
    Self.Mask := aMask;
    Self.StencilFailOp := aStencilFailOp;
    Self.StencilDepthFailOp := aStencilDepthFailOp;
    Self.StencilDepthPassOp := aStencilDepthPassOp;
  end;

procedure TGEMDrawStencilParams.SetParams(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal; const aStencilFailOp, aStencilDepthFailOp, aStencilDepthPassOp: TGEMStencilOp);
  begin
    Self.Func := aFunc;
    Self.Ref := aRef;
    Self.Mask := aMask;
    Self.StencilFailOp := aStencilFailOp;
    Self.StencilDepthFailOp := aStencilDepthFailOp;
    Self.StencilDepthPassOp := aStencilDepthPassOp;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                 TGEMDrawState
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TGEMDrawState.ErrOut(const aErrorType: TGEMErrorCode; const aErrorReason: TGEMErrorCode; const aErrorSeverity: TGEMErrorCode);
  begin
    Self.fError.ErrorType := aErrorType;
    Self.fError.ErrorReason := aErrorReason;
    Self.fError.ErrorSeverity := aErrorSeverity;

    if Assigned(Self.fErrorProc) then begin
      Self.fErrorProc(Self.fError);
    end;

    Inc(Self.fErrorCount);
  end;

constructor TGEMDrawState.Create();
  begin
    inherited Create();
    fInitialized := False;

    Self.CommandCount := 0;
    SetLength(Self.DrawCommand, 10000);
    SetLength(Self.ElementBuffer, 120000);
    SetLength(Self.TextureUsing, 10000);
    SetLength(Self.Params, 10000);
    SetLength(Self.DrawInfo, 10000);
    SetLength(Self.Vertex, 80000);
    SetLength(Self.ID, 80000);
    SetLength(Self.TextureSlot, 32);
    FillByte(Self.TextureSlot[0], 4 * 32, 0);

    Self.fColorValues := gem_white;
    Self.DrawType := 'default';

    Self.fAnisotropicSamples := 1;
  end;

destructor TGEMDrawState.Destroy();
  begin
    Self.fWindow.Free();
    Self.fKeyboard.Free();
    Self.fMouse.Free();
    inherited Destroy();
  end;

procedure TGEMDrawState.Terminate();
  begin
    Self.fInitialized := False;
    glfwDestroyWindow(Self.fWindow.fHandle);
    glfwTerminate();
  end;

procedure TGEMDrawState.SetErrorProc(const aProc: TGEMDrawErrorProc);
  begin
    Self.fErrorProc := aProc;
  end;

function TGEMDrawState.QueryJoysticks(): Cardinal;
var
I: Integer;
Ret: Integer;
  begin
    Result := 0;

    for I := 0 to 15 do begin
      Ret := glfwJoystickPresent(GLFW_JOYSTICK_1 + I);
      Result := Result + Ret;
      Self.fJoystick[I].UpdatePresent(Ret);
    end;
  end;

function TGEMDrawState.Init(var aWindow: TGEMDrawWindow; const aWidth, aHeight: Cardinal; const aTitle: String = 'gemDraw Window'): Integer;
var
I: Integer;
Ret: GLInt;
l,t,w,h: GLInt;
  begin

    Result := 0;

    if Assigned(aWindow) then Exit(0);
    if fInitialized then Exit(0);

    Ret := glfwInit();
    if Ret <> 1 then Exit(0);

    fInitialized := True;

    aWindow:= TGEMDrawWindow.Create(aWidth, aHeight, aTitle);

    Self.fWindow := aWindow;
    Window := aWindow;
    glfwShowWindow(Self.fWindow.fHandle);

    Self.fKeyboard := TGEMDrawKeyboard.Create();
    Self.fMouse := TGEMDrawMouse.Create();

    for I := 0 to 15 do begin
      Self.fJoystick[I] := TGEMDrawJoystick.Create();
      Self.fJoystick[I].fIndex := I;
    end;

    Self.QueryJoysticks();

    Self.fMonitor := glfwGetPrimaryMonitor();
    Self.fVideoMode := glfwGetVideoMode(Self.fMonitor);

    Self.fScreenWidth := Self.fVideoMode^.Width;
    Self.fScreenHeight := Self.fVideoMode^.Height;
    Self.fRefreshRate := Self.fVideoMode^.refreshRate;

    glfwGetMonitorWorkArea(Self.fMonitor, @l, @t, @w, @h);
    Self.fWorkArea := RectIWH(l, t, w, h);

    glfwGetMonitorPhysicalSize(Self.fMonitor, @Self.fMonitorSize.X, @Self.fMonitorSize.Y);
    Self.fMonitorDPI.X := trunc(Self.fScreenWidth / (Self.fMonitorSize.X / 25.4));
    Self.fMonitorDPI.Y := trunc(Self.fScreenHeight / (Self.fMonitorSize.Y / 25.4));

    glfwSwapInterval(0);

    glDebugMessageCallback(@gemOpenGLDebugProc, nil);

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
    glStencilFunc(GL_EQUAL, 0, 1);
    glDisable(GL_BLEND);
    glEnable(GL_DEBUG_OUTPUT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    Self.GetGLInfo();
    Self.InitShaders();
    Self.InitSampler();

    Self.Buffers := TGEMDrawBuffers.Create();
    Self.MakeEBO();

    Self.fImageLoadPath := ExtractFilePath(ParamStr(0));
    Self.fSprite := TGEMDrawSprite.Create();

    Exit(1);
  end;

procedure TGEMDrawState.AddImage(var aImage: TGEMDrawImage);
  begin
    if Self.fImages.FindFirst(aImage) <> -1 then begin
      Self.fImages.PushBack(aImage);
    end;
  end;

procedure TGEMDrawState.AddTexture(var aTexture: TGEMDrawTexture);
  begin
    if Self.fTextures.FindFirst(aTexture) <> -1 then begin
      Self.fTextures.PushBack(aTexture);
    end;
  end;

procedure TGEMDrawState.AddSprite(var aSprite: TGEMDrawSprite);
  begin
    if Self.fSprites.FindFirst(aSprite) <> -1 then begin
      Self.fSprites.PushBack(aSprite);
    end;
  end;

procedure TGEMDrawState.AddRenderTexture(var aRenderTexture: TGEMDrawRenderTexture);
  begin
    if Self.fRenderTextures.FindFirst(aRenderTexture) <> -1 then begin
      Self.fRenderTextures.PushBack(aRenderTexture);
    end;
  end;

procedure TGEMDrawState.RemoveImage(var aImage: TGEMDrawImage);
  begin
    Self.fImages.DeleteFirst(aImage);
  end;

procedure TGEMDrawState.RemoveTexture(var aTexture: TGEMDrawTexture);
  begin
    Self.fTextures.DeleteFirst(aTexture);
  end;

procedure TGEMDrawState.RemoveSprite(var aSprite: TGEMDrawSprite);
  begin
    Self.fSprites.DeleteFirst(aSprite);
  end;

procedure TGEMDrawState.RemoveRenderTexture(var aRenderTexture: TGEMDrawRenderTexture);
  begin
    Self.fRenderTextures.DeleteFirst(aRenderTexture);
  end;

function TGEMDrawState.GetJoystick(const Index: Cardinal): TGEMDrawJoystick;
  begin
    if Index >= 16 then Exit(nil);
    Exit(Self.fJoystick[Index]);
  end;

procedure TGEMDrawState.UpdateJoysticks();
var
I: Integer;
  begin
    for I := 0 to 15 do begin
      if Self.fJoystick[I].fPresent = 1 then begin
        Self.fJoystick[I].QueryState();
      end;
    end;
  end;

function TGEMDrawState.GetErrorString(constref aErrorCode: TGEMErrorCode): String;
  begin
    Result := '';

    case Ord(aErrorCode) of

      // types
      Ord(TGEMErrorCode.GEM_INVALID_VALUE): Exit('GEM_INVALID_VALUE');

      // reasons
      Ord(TGEMErrorCode.GEM_NIL_EXPECTED): Exit('GEM_NIL_EXPECTED');
      Ord(TGEMErrorCode.GEM_OBJECT_EXPECTED): Exit('GEM_OBJECT_EXPECTED');

      // severity
      Ord(TGEMErrorCode.GEM_NOTIFY): Exit('GEM_NOTIFY');
      Ord(TGEMErrorCode.GEM_WARNING): Exit('GEM_WARNING');
      Ord(TGEMErrorCode.GEM_FATAL): Exit('GEM_FATAL');

    end;
  end;

procedure TGEMDrawState.InitShaders();
var
EXEPath: String;
  begin
    EXEPath := ExtractFilePath(ParamStr(0));

    Self.fShaders := TGEMDrawShaders.Create();
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'default');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'default depth blend');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'display');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'pixelate');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'swirl');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'blit');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'light');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'blur');
    Self.fShaders.LoadProgram(EXEPath + 'Shaders/', 'text');
  end;

procedure TGEMDrawState.GetGLInfo();
var
CPtr: PChar;
Vender: PChar;
Renderer: PChar;
Version: PChar;
GLSLVersion: PChar;
Ext: Array of String;
I: Integer;
  begin
    glGetIntegerV(GL_MAJOR_VERSION, @Self.fGLMajorVersion);
    glGetIntegerV(GL_MINOR_VERSION, @Self.fGLMinorVersion);
    glGetIntegerV(GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS, @Self.fMaxShaderStorageBlocks);
    glGetIntegerV(GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS, @Self.fMaxShaderStorageBufferBindings);
    glGetIntegerV(GL_DOUBLEBUFFER, @Self.fDoubleBuffered);
    glGetIntegerV(GL_MAX_DRAW_BUFFERS, @Self.fMaxDrawBuffers);
    glGetIntegerV(GL_MAX_FRAMEBUFFER_WIDTH, @Self.fMaxFramebufferWidth);
    glGetIntegerV(GL_MAX_FRAMEBUFFER_HEIGHT, @Self.fMaxFramebufferHeight);
    glGetIntegerV(GL_MAX_TEXTURE_SIZE, @Self.fMaxTextureSize);
    glGetIntegerV(GL_MAX_TEXTURE_IMAGE_UNITS, @Self.fMaxTextureImageUnits);
    glGetIntegerV(GL_MAX_VERTEX_ATTRIBS, @Self.fMaxVertexAttribs);
    glGetIntegerV(GL_MAX_VIEWPORT_DIMS, @Self.fMaxViewportDims[0]);
    glGetIntegerV(GL_MAX_ELEMENT_INDEX, @Self.fMaxElementIndex);
    glGetIntegerV(GL_MAX_TEXTURE_MAX_ANISOTROPY, @Self.fMaxAnisotropicSamples);
  end;

procedure TGEMDrawState.GetMonitorPhysSize();
  begin

  end;

procedure TGEMDrawState.InitSampler();
var
I: Integer;
  begin
    glGenSamplers(1, @Self.fSampler);
    glSamplerParameteri(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAX_ANISOTROPY, 1);

    glGenSamplers(1, @Self.fBufferSampler);
    glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MAX_ANISOTROPY, 1);


    for I := 0 to Self.fMaxTextureImageUnits - 1 do begin
      glBindSampler(I, Self.fSampler);
    end;
  end;

procedure TGEMDrawState.MakeEBO();
var
I: Integer;
E: Array [0..5] of GLUint;
  begin

    E[0] := 0;
    E[1] := 3;
    E[2] := 1;
    E[3] := 1;
    E[4] := 3;
    E[5] := 2;

    SetLength(Self.ElementBuffer, 6 * 100000);

    for I := 0 to 99999 do begin
      Self.ElementBuffer[(I * 6) + 0] := E[0] + ((I * 3) + I);
      Self.ElementBuffer[(I * 6) + 1] := E[1] + ((I * 3) + I);
      Self.ElementBuffer[(I * 6) + 2] := E[2] + ((I * 3) + I);
      Self.ElementBuffer[(I * 6) + 3] := E[3] + ((I * 3) + I);
      Self.ElementBuffer[(I * 6) + 4] := E[4] + ((I * 3) + I);
      Self.ElementBuffer[(I * 6) + 5] := E[5] + ((I * 3) + I);
    end;
  end;

procedure TGEMDrawState.SetTarget(aTarget: TGEMDrawRenderTarget);
var
Buffs: Array [0..1] of GLEnum;
  begin
    if Self.CurrentTarget = aTarget then begin
      Exit();
    end;

    Self.DrawBatch(0,0);
    Self.CurrentTarget := aTarget;

    glBindFramebuffer(GL_FRAMEBUFFER, Self.CurrentTarget.fFBO);

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT1;
    glDrawBuffers(2, @Buffs);

    if aTarget <> nil then begin
      Self.Perspective.Ortho(0, aTarget.Bounds.Right, aTarget.Bounds.Bottom, 0, 0, 1);
      glViewPort(0, 0, aTarget.Bounds.Width, aTarget.Bounds.Height);
    end;
  end;

procedure TGEMDrawState.CheckBatch(const aVerticesExpected, aElementsExpected, aTextureExpected: GLUint);
var
I: Integer;
  begin
    if Self.CommandCount >= High(Self.Params) then begin
      Self.DrawBatch(0,0);
    end;

    if Self.VertexCount + aVerticesExpected >= High(Self.Vertex) then begin
      Self.DrawBatch(0,0);
      Exit();
    end;

    if Self.ElementCount + aElementsExpected >= High(Self.ElementBuffer) then begin
      Self.DrawBatch(0,0);
      Exit();
    end;

    if aTextureExpected = 32 then Exit();

    if Self.TexturesUsed < Self.fMaxTextureImageUnits then begin
      Exit();
    end else begin
      for I := 1 to High(Self.TextureSlot) do begin
        if Self.TextureSlot[I] = aTextureExpected then begin
          Exit();
        end;
      end;
      Self.DrawBatch(0,0);
    end;
  end;

procedure TGEMDrawState.DrawBatch(const aCurrentInstance, aInstanceCount: Integer);
var
I: Cardinal;
L: Integer;
U: Array [0..31] of Cardinal;
  begin
    if Self.DrawType = 'light' then begin
      Self.DrawLight();
      Exit();
    end;

    if Self.CommandCount = 0 then Exit();

    // check sorting
    if Self.fDrawSortingEnabled then begin;

      if Self.fDrawSortOrder = GEM_SORT_DESCENDING then Self.QuickSortDrawInfoDescending(0, Self.CommandCount - 1)
      else Self.QuickSortDrawInfoAscending(0, Self.CommandCount -1);

      Self.ReOrderDraws();
    end;


    Self.Perspective.Ortho(0, Self.CurrentTarget.Bounds.Right, Self.CurrentTarget.Bounds.Bottom, 0, Self.fDepthHigh, Self.fDepthLow);
    glViewPort(0, 0, Self.CurrentTarget.Bounds.Width, Self.CurrentTarget.Bounds.Height);

    if Self.fDepthTestEnabled then begin
      glEnable(GL_DEPTH_TEST);
      glDepthMask(GL_TRUE);
      glDepthFunc(GL_LEQUAL);
    end else begin
      glDisable(GL_DEPTH_TEST);
      glDepthMask(GL_FALSE);
      glDepthFunc(GL_ALWAYS);
    end;

    Self.Buffers.NextElementBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(GLUint) * Self.ElementCount, @Self.ElementBuffer[0]);

    Self.Buffers.NextIndirectBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMDrawCommand), @Self.DrawCommand[0]);

    Self.Buffers.NextArrayBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVertex) * Self.VertexCount, @Self.Vertex[0]);
    Self.Buffers.AttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 0);
    Self.Buffers.AttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 12);
    Self.Buffers.AttribPointer(2, 2, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 28);

    Self.Buffers.NextArrayBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(GLUint) * Self.VertexCount, @Self.ID[0]);
    glEnableVertexAttribArray(3);
    glVertexAttribIPointer(3, 1, GL_UNSIGNED_INT, 0, Pointer(0));

    if Self.fDrawingText = False then begin

      if (Self.fBlendingEnabled) and (Self.fDepthTestEnabled) then begin
        DrawState.fShaders.UseProgram('default depth blend');
      end else begin
        DrawState.fShaders.UseProgram('default');
      end;

    end else begin
      DrawState.fShaders.UseProgram('text');
    end;

    CurrentProgram := Self.fShaders.CurrentProgram;

    // textures
    glBindTextureUnit(0, 0);
    if Self.TexturesUsed <> 0 then begin
      for I := 1 to Self.TexturesUsed do begin
        glBindTextureUnit(I, Self.TextureSlot[I]);
        glUniform1i(CurrentProgram.UniformLocation('tex[0]') + I, Integer(I));
      end;
    end;

    Self.Buffers.NextSSBO(0);
    Self.Buffers.CurrentSSBO.SubData(0, SizeOf(TGEMDrawParams) * Self.CommandCount, @Self.Params[0]);

    Self.Buffers.NextSSBO(2);
    Self.Buffers.CurrentSSBO.SubData(0, 4 * Self.CommandCount, @Self.TextureUsing[0]);

    glUniformMatrix4fv(CurrentProgram.UniformLocation('Perspective'), 1, GL_FALSE, @Self.Perspective);
    glUniformMatrix4fv(CurrentProgram.UniformLocation('View'), 1, GL_FALSE, @Self.View);
    glUniform1i(CurrentProgram.UniformLocation('greyscale'), Self.fGreyScaleEnabled.ToInteger());
    glUniform3fv(CurrentProgram.UniformLocation('statecolorvalues'), 1, @Self.fColorValues.Red);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, Pointer(0), 1, SizeOf(TGEMDrawCommand));

    Self.ResetBatch();
  end;

procedure TGEMDrawState.DrawLight();
var
I: Cardinal;
L: Integer;
U: Array [0..31] of Cardinal;
  begin

    if Self.CommandCount = 0 then Exit();

    Self.Perspective.Ortho(0, Self.CurrentTarget.Bounds.Right, Self.CurrentTarget.Bounds.Bottom, 0, Self.fDepthLow, Self.fDepthHigh);
    glViewPort(0, 0, Self.CurrentTarget.Bounds.Width, Self.CurrentTarget.Bounds.Height);

    if Self.fDepthTestEnabled then begin
      glDisable(GL_DEPTH_TEST);
      glDepthMask(GL_FALSE);
      glDepthFunc(GL_LEQUAL);
    end else begin
      glDisable(GL_DEPTH_TEST);
      glDepthMask(GL_FALSE);
    end;

    Self.Buffers.NextElementBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(GLUint) * Self.ElementCount, @Self.ElementBuffer[0]);

    Self.Buffers.NextIndirectBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMDrawCommand), @Self.DrawCommand[0]);

    Self.Buffers.NextArrayBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVertex) * Self.VertexCount, @Self.Vertex[0]);
    Self.Buffers.AttribPointer(0, 3, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 0);
    Self.Buffers.AttribPointer(1, 4, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 12);
    Self.Buffers.AttribPointer(2, 2, GL_FLOAT, GL_FALSE, SizeOf(TGEMVertex), 28);

    Self.Buffers.NextArrayBuffer();
    Self.Buffers.CurrentVBO.SubData(0, SizeOf(GLUint) * Self.VertexCount, @Self.ID[0]);
    glEnableVertexAttribArray(3);
    glVertexAttribIPointer(3, 1, GL_UNSIGNED_INT, 0, Pointer(0));

    Self.fShaders.UseProgram('light');
    CurrentProgram := Self.fShaders.CurrentProgram;

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, Self.CurrentTarget.fColorBuffer.fHandle);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, Self.CurrentTarget.fDepthBuffer.fHandle);

    Self.Buffers.NextSSBO(0);
    Self.Buffers.CurrentSSBO.SubData(0, SizeOf(TGEMDrawParams) * Self.CommandCount, @Self.Params[0]);

    glUniformMatrix4fv(CurrentProgram.UniformLocation('Perspective'), 1, GL_FALSE, @Self.Perspective);
    glUniformMatrix4fv(CurrentProgram.UniformLocation('View'), 1, GL_FALSE, @Self.View);
    glUniform1i(CurrentProgram.UniformLocation('Source'), 0);
    glUniform1i(CurrentProgram.UniformLocation('Depth'), 1);

    glPointSize(10);
    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, Pointer(0), 1, SizeOf(TGEMDrawCommand));

    Self.ResetBatch();
  end;

procedure TGEMDrawState.ResetBatch();
  begin
    Self.CommandCount := 0;
    Self.VertexCount := 0;
    Self.ElementCount := 0;
    Self.TexturesUsed := 0;

    Self.DrawCommand[0].Count := 0;
    Self.DrawCommand[0].InstanceCount := 0;

    FillDWord(Self.TextureSlot[0], Self.fMaxTextureImageUnits, 0);

  end;

procedure TGEMDrawState.BindTexture(const aTexture: TGEMDrawTexture; const aTarget: GLInt = 0);
  begin
    glActiveTexture(GL_TEXTURE + aTarget);
    glBindTexture(GL_TEXTURE_2D, aTexture.fHandle);
  end;

procedure TGEMDrawState.UnbindAllTextures();
var
I: Integer;
  begin
    for I := 0 to Self.fMaxTextureImageUnits - 1 do begin
      glActiveTexture(GL_TEXTURE0 + I);
      glBindTexture(GL_TEXTURE_2D, 0);
    end;
  end;

function TGEMDrawState.FindTextureSlot(const aTextureHandle: GLUint): Integer;
var
I: Integer;
  begin

  end;

procedure TGEMDrawState.QuickSortDrawInfoAscending(L, R: Integer);
var
i, j, pivot: Integer;
temp: TGEMDrawInfo;
  begin
    i := L;
    j := R;
    pivot := (L + R) div 2; // choose pivot element

    while i <= j do begin
      while Self.DrawInfo[i].Z < Self.DrawInfo[pivot].Z do
        Inc(i);
      while  Self.DrawInfo[j].Z > Self.DrawInfo[pivot].Z do
        Dec(j);
      if i <= j then
      begin
        temp := Self.DrawInfo[i];
        Self.DrawInfo[i] := Self.DrawInfo[j];
        Self.DrawInfo[j] := temp;

        Inc(i);
        Dec(j);
      end;
    end;

    if L < j then
      Self.QuickSortDrawInfoAscending(L, j);
    if i < R then
      Self.QuickSortDrawInfoAscending(i, R);
  end;

procedure TGEMDrawState.QuickSortDrawInfoDescending(L, R: Integer);
var
i, j, pivot: Integer;
temp: TGEMDrawInfo;
  begin
    i := L;
    j := R;
    pivot := (L + R) div 2; // choose pivot element

    while i <= j do begin
      while Self.DrawInfo[i].Z > Self.DrawInfo[pivot].Z do
        Inc(i);
      while  Self.DrawInfo[j].Z < Self.DrawInfo[pivot].Z do
        Dec(j);
      if i <= j then
      begin
        temp := Self.DrawInfo[i];
        Self.DrawInfo[i] := Self.DrawInfo[j];
        Self.DrawInfo[j] := temp;

        Inc(i);
        Dec(j);
      end;
    end;

    if L < j then
      Self.QuickSortDrawInfoDescending(L, j);
    if i < R then
      Self.QuickSortDrawInfoDescending(i, R);
  end;

procedure TGEMDrawState.ReOrderDraws();
var
I: Integer;
ECount: Integer;
TempElement: Array of Cardinal;
  begin
    SetLength(TempElement, Self.ElementCount);

    ECount := 0;

    for I := 0 to Self.CommandCount - 1 do begin
      FillDWord(Self.ID[Self.DrawInfo[I].VertexStart], Self.DrawInfo[I].VertexCount, Self.DrawInfo[I].Index);

      Move(Self.ElementBuffer[Self.DrawInfo[I].ElementStart], TempElement[ECount], 4 * Self.DrawInfo[I].ElementCount);
      Inc(ECount, Self.DrawInfo[I].ElementCount);
    end;
    Move(TempElement[0], Self.ElementBuffer[0], 4 * Self.ElementCount);
  end;

procedure TGEMDrawState.UpdateColorMasks();
var
I: Integer;
  begin
    for I := 0 to 3 do begin
      Self.fColorMask[I] := Byte((Self.fColorMask[I] > 0).ToInteger);
    end;
    glColorMask(Self.fColorMask[0], Self.fColorMask[1], Self.fColorMask[2], Self.fColorMask[3]);
  end;

procedure TGEMDrawState.Flush();
  begin
    Self.DrawBatch(0,0);
  end;

procedure TGEMDrawState.SetImageLoadPath(const aPath: String);
  begin
    if gemFileExists(aPath) then begin
      Self.fImageLoadPath := aPath;
    end;
  end;

procedure TGEMDrawState.EnableVSync(const aEnable: Boolean = True);
  begin
    Self.fVSyncEnabled := aEnable;
    if aEnable then begin
      glfwSwapInterval(1);
    end else begin
      glfwSwapInterval(0);
    end;
  end;

procedure TGEMDrawState.EnableBlending(const aEnable: Boolean = True);
  begin
    if Self.fBlendingEnabled <> aEnable then begin
      Self.fBlendingEnabled := aEnable;
      if aEnable then begin
        glEnable(GL_BLEND);
      end else begin
        glDisable(GL_BLEND);
      end;
    end;
  end;

procedure TGEMDrawState.EnableDepthTest(const aEnable: Boolean = True);
  begin
    if Self.fDepthTestEnabled <> aEnable then begin
      Self.DrawBatch(0,0);
      Self.fDepthTestEnabled := aEnable;
      if aEnable then begin
        glEnable(GL_DEPTH_TEST);
      end else begin
        glDisable(GL_DEPTH_TEST);
      end;
    end;
  end;

procedure TGEMDrawState.EnableStencilTest(const aEnable: Boolean= True);
  begin
    if Self.fStencilTestEnabled <> aEnable then begin
        Self.DrawBatch(0,0);
        Self.fStencilTestEnabled := aEnable;
        if aEnable then begin
          glEnable(GL_STENCIL_TEST);
        end else begin
          glDisable(GL_STENCIL_TEST);
        end;
      end;
  end;

procedure TGEMDrawState.EnableLinearSampling(const aEnable: Boolean = True);
  begin
    if aEnable = Self.fLinearSamplingEnabled then Exit();

    Self.fLinearSamplingEnabled := aEnable;

    case aEnable of
      False:
        begin
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

          glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
          glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        end;

      True:
        begin
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

          glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
          glSamplerParameteri(Self.fBufferSampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        end;
    end;
  end;

procedure TGEMDrawState.EnableGreyScale(const aEnable: Boolean = True);
  begin
    if aEnable = Self.fGreyScaleEnabled then Exit();
    Self.DrawBatch(0,0);
    Self.fGreyScaleEnabled := aEnable;
  end;

procedure TGEMDrawState.EnableAnisotropicFiltering(const aEnable: Boolean = True);
var
I: Integer;
  begin
    If aEnable = Self.fAnisotropicFilteringEnabled then Exit;

    Self.DrawBatch(0,0);
    Self.fAnisotropicFilteringEnabled := aEnable;

    case aEnable of
      True:
        begin
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAX_ANISOTROPY, Self.fAnisotropicSamples);
        end;

      False:
        begin
          glSamplerParameteri(Self.fSampler, GL_TEXTURE_MAX_ANISOTROPY, 1);
        end;
    end;
  end;

procedure TGEMDrawState.EnableDrawSorting(const aEnable: Boolean = True);
  begin
    if Self.fDrawSortingEnabled = aEnable then Exit();

    Self.DrawBatch(0, 0);
    Self.fDrawSortingEnabled := aEnable;
  end;

procedure TGEMDrawState.SetAnisotropicSamples(const aSamples: Cardinal);
  begin
    if Self.fAnisotropicSamples = aSamples then Exit();

    if Self.fAnisotropicFilteringEnabled then begin
      Self.DrawBatch(0,0);
    end;

    if aSamples < 1 then begin
      Self.fAnisotropicSamples := 1;
    end else if aSamples > Self.fMaxAnisotropicSamples then begin
      Self.fAnisotropicSamples := Self.fMaxAnisotropicSamples;
    end else begin
      Self.fAnisotropicSamples := aSamples;
    end;
  end;

procedure TGEMDrawState.SetDrawSortOrder(const aOrder: TGEMSortOrder);
  begin
    if Self.fDrawSortOrder = aOrder then Exit();

    if Self.fDrawSortingEnabled then begin
      Self.DrawBatch(0, 0);
    end;

    Self.fDrawSortOrder := aOrder;
  end;

function TGEMDrawState.ToggleDrawSortOrder(): TGEMSortOrder;
  begin
    if Self.fDrawSortOrder = GEM_SORT_ASCENDING then
      Self.fDrawSortOrder := GEM_SORT_DESCENDING
    else
      Self.fDrawSortOrder := GEM_SORT_ASCENDING;

    Exit(Self.fDrawSortOrder);
  end;

procedure TGEMDrawState.SetDepthRange(const aLow, aHigh: Single);
  begin
    if (aLow = Self.fDepthLow) and (aHigh = Self.fDepthHigh) then Exit();

    Self.DrawBatch(0,0);

    Self.fDepthLow := aLow;
    Self.fDepthHigh := aHigh;
  end;

procedure TGEMDrawState.SetClearDepthValue(const aValue: Single);
  begin
    if aValue > Self.fDepthHigh then begin
      Self.fClearDepthValue := Self.fDepthHigh;
    end else if aValue < Self.fDepthLow then begin
      Self.fClearDepthValue := Self.fDepthLow;
    end else begin
      Self.fClearDepthValue := aValue;
    end;
  end;

procedure TGEMDrawState.SetStencilValue(const aValue: Cardinal);
  begin
    Self.DrawBatch(0, 0);
    Self.fStencilValue := aValue;
    glStencilMask(aValue);
  end;

procedure TGEMDrawState.SetClearStencilValue(const aValue: Cardinal);
  begin
    Self.fClearStencilValue := aValue;
  end;

procedure TGEMDrawState.SetStencilFunction(const aFunc: TGEMTestFunc; const aRef: Integer; const aMask: Cardinal);
  begin
    Self.DrawBatch(0, 0);
    Self.fStencilParams.Func := aFunc;
    Self.fStencilParams.Ref := aRef;
    Self.fStencilParams.Mask := aMask;
    glStencilFunc(Ord(Self.fStencilParams.Func), Self.fStencilParams.Ref, Self.fStencilParams.Mask);
  end;

procedure TGEMDrawState.SetStencilOp(const aStencilFail, aDepthFail, aDepthPass: TGEMStencilOp);
  begin
    Self.DrawBatch(0, 0);
    Self.fStencilParams.StencilFailOp := aStencilFail;
    Self.fStencilParams.StencilDepthFailOp := aDepthFail;
    Self.fStencilParams.StencilDepthPassOp := aDepthPass;

    glStencilOp( Ord(Self.fStencilParams.StencilFailOp),
                 Ord(Self.fStencilParams.StencilDepthFailOp),
                 Ord(Self.fStencilParams.StencilDepthPassOp));
  end;

procedure TGEMDrawState.SetStencilParams(const aParams: TGEMDrawStencilParams);
  begin
    Self.SetStencilFunction(aParams.Func, aParams.Ref, aParams.Mask);
    Self.SetStencilOp(aParams.StencilFailOp, aParams.StencilDepthFailOp, aParams.StencilDepthPassOp);
  end;

procedure TGEMDrawState.ResetStencil();
  begin
    Self.DrawBatch(0, 0);
    Self.SetStencilValue(0);
    Self.SetClearStencilValue(0);
    Initialize(Self.fStencilParams);
    Self.SetStencilParams(Self.fStencilParams);
  end;

procedure TGEMDrawState.SetRedMask(const aMask: Byte);
  begin
    if Self.fColorMask[0] = aMask then Exit();
    Self.DrawBatch(0, 0);
    Self.fColorMask[0] := aMask;
    Self.UpdateColorMasks();
  end;

procedure TGEMDrawState.SetGreenMask(const aMask: Byte);
  begin
    if Self.fColorMask[1] = aMask then Exit();
    Self.DrawBatch(0, 0);
    Self.fColorMask[1] := aMask;
    Self.UpdateColorMasks();
  end;

procedure TGEMDrawState.SetBlueMask(const aMask: Byte);
  begin
    if Self.fColorMask[2] = aMask then Exit();
    Self.DrawBatch(0, 0);
    Self.fColorMask[2] := aMask;
    Self.UpdateColorMasks();
  end;

procedure TGEMDrawState.SetAlphaMask(const aMask: Byte);
  begin
    if Self.fColorMask[3] = aMask then Exit();
    Self.DrawBatch(0, 0);
    Self.fColorMask[3] := aMask;
    Self.UpdateColorMasks();
  end;

procedure TGEMDrawState.SetColorMasks(const aMask: TGEMColorI);
  begin
    Self.DrawBatch(0, 0);
    Move(aMask, Self.fColorMask, 4);
    Self.UpdateColorMasks();
  end;

procedure TGEMDrawState.SetColorValues(const aValues: TGEMColorF);
  begin
    Self.DrawBatch(0,0);
    Self.fColorValues := aValues;
    Self.fColorValues.Alpha := 1;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                             TGEMDrawKeyboard
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawKeyboard.Create();
  begin
    inherited Create();
    Self.fEnabled := True;
    FillByte(Self.fKeyState[0], 255, 0);
  end;

function TGEMDrawKeyboard.GetKeyState(const Index: Integer): Byte;
  begin
    Exit(Self.fKeyState[Index]);
  end;

procedure TGEMDrawKeyboard.ReceiveKey(const Key, ScanCode, Action, Mods: Integer);
  begin
    Self.fKeyState[Key] := Action;
    if Self.fEnabled = False then Exit();

    case Action of
      GLFW_PRESS:
        begin
          if Assigned(Self.fKeyDownProc) then begin
            Self.fKeyDownProc(Key, ScanCode, Mods);
          end;
        end;

      GLFW_RELEASE:
        begin
          if Assigned(Self.fKeyUpProc) then begin
            Self.fKeyUpProc(Key, ScanCode, Mods);
          end;
        end;
    end;
  end;

procedure TGEMDrawKeyboard.SetKeyDownProc(const aProc: TGEMDrawKeyProc);
  begin
    Self.fKeyDownProc := aProc;
  end;

procedure TGEMDrawKeyboard.SetKeyUpProc(const aProc: TGEMDrawKeyProc);
  begin
    Self.fKeyUpProc := aProc;
  end;

procedure TGEMDrawKeyboard.SetEnabled(const aEnabled: Boolean = True);
  begin
    Self.fEnabled := aEnabled;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawMouse
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawMouse.Create();
  begin
    inherited Create();

    Self.fEnabled := True;
    Self.fVisible := True;
  end;

function TGEMDrawMouse.GetButtonState(const Index: Byte): Byte;
  begin
    Exit(Self.fButtonState[Index]);
  end;

procedure TGEMDrawMouse.ReceivePosition(const X, Y: Double);
  begin
    Self.fLastPosition := Self.fPosition;
    Self.fPosition := Vec2(X, Y);
    Self.fMoveDist := VectorLength(Self.fPosition - Self.fLastPosition);
    if Self.fEnabled = False then begin
      Self.fSkipMoveProc := False;
      Exit();
    end;

    if Assigned(Self.fMoveProc) and (Self.fSkipMoveProc = False) then begin
      Self.fMoveProc(X, Y);
    end;

    Self.fSkipMoveProc := False;
  end;

procedure TGEMDrawMouse.ReceiveButton(const Button, Action, Mods: Integer);
  begin
    Self.fButtonState[Button] := Action;
    if Self.fEnabled = False then Exit();

    case Action of
      GLFW_PRESS:
        begin
          if AssigneD(Self.fButtonDownProc) then begin
            Self.fButtonDownProc(Button, Mods);
          end;
        end;

      GLFW_RELEASE:
        begin
          if Assigned(Self.fButtonUpProc) then begin
            Self.fButtonUpProc(Button, Mods);
          end;
        end;
    end;
  end;

procedure TGEMDrawMouse.SetVisible(const aVisible: Boolean = True);
  begin
    Self.fVisible := aVisible;

    if aVisible then begin
      glfwSetInputMode(DrawState.fWindow.fHandle, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    end else begin
      glfwSetInputMode(DrawState.fWindow.fHandle, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    end;
  end;

procedure TGEMDrawMouse.SetEnabled(const aEnabled: Boolean = True);
  begin
    Self.fEnabled := aEnabled;
  end;

procedure TGEMDrawMouse.CenterInWindow(const aCallMoveProc: Boolean = True);
var
X,Y: Double;
  begin
    Self.SetPosition(Vec2(Window.Bounds.Width / 2, Window.Bounds.Height / 2), aCallMoveProc);
  end;

procedure TGEMDrawMouse.SetPosition(const aPosition: TGEMVec2; const aCallMoveProc: Boolean = True);
  begin
    Self.fSkipMoveProc := not aCallMoveProc;
    glfwSetCursorPos(Window.fHandle, aPosition.X, aPosition.Y);
    gemDrawMousePosProc(Window.fHandle, aPosition.X, aPosition.Y);
  end;

procedure TGEMDrawMouse.SetMoveProc(const aProc: TGEMDrawMouseMoveProc);
  begin
    Self.fMoveProc := aProc;
  end;

procedure TGEMDrawMouse.SetButtonDownProc(const aProc: TGEMDrawMouseButtonProc);
  begin
    Self.fButtonDownProc := aProc;
  end;

procedure TGEMDrawMouse.SetButtonUpProc(const aProc: TGEMDrawMouseButtonProc);
  begin
    Self.fButtonUpProc := aProc;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawJoystick
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawJoystick.Create();
  begin

  end;

procedure TGEMDrawJoystick.Init();
var
Count: Integer;
pName: PChar;
  begin
    // get joystick name
    pName := glfwGetGamepadName(GLFW_JOYSTICK_1 + Self.fIndex);
    Self.fGamepadName := pName;

    pName := glfwGetJoystickName(GLFW_JOYSTICK_1 + Self.fIndex);
    Self.fJoystickName := pName;

    // get GUID
    pName := glfwGetJoystickGUID(GLFW_JOYSTICK_1 + Self.fIndex);
    Self.fGUID := pName;

    // get stick count
    glfwGetJoystickAxes(GLFW_JOYSTICK_1 + Self.fIndex, @Count);
    Self.fNumSticks := trunc(Count / 2);

    // get button count
    glfwGetJoystickButtons(GLFW_JOYSTICK_1 + Self.fIndex, @Count);
    Self.fNumButtons := Count;
  end;

procedure TGEMDrawJoystick.UpdatePresent(const aPresent: Integer);
  begin
    if aPresent = Self.fPresent then Exit();

    Self.fPresent := aPresent;
    if aPresent = 1 then begin
      Self.Init();
    end;
  end;

procedure TGEMDrawJoystick.QueryState();
var
I: Integer;
B: PByte;
Count: Integer;
RangeDiff: Single;
ABuff: Array [0..5] of Single;
  begin
    glfwGetGamepadState(GLFW_JOYSTICK_1 + Self.Index, @Self.State);

    for I := 0 to Self.fNumButtons - 1 do begin
      Self.fButton[I] := Ord(Self.State.Buttons[I]);
    end;

    RangeDiff := 1 - Self.fDeadZoneThreshold;

    Move(Self.State.axex[0], ABuff[0], 4 * 6);

    for I := 0 to 5 do begin
      if Abs(ABuff[I]) < Self.fDeadZoneThreshold then begin
        ABuff[I] := 0;
      end else begin
        ABuff[I] := ((Abs(ABuff[I]) - Self.fDeadZoneThreshold) / RangeDiff) * Sign(ABuff[I]);
      end;
    end;

    Self.fLeftStick.X := ABuff[0];
    Self.fLeftStick.Y := ABuff[1];
    Self.fRightStick.X := ABuff[2];
    Self.fRightStick.Y := ABuff[3];
    Self.fLeftTrigger := ABuff[4];
    Self.fRightTrigger := ABuff[5];
  end;

function TGEMDrawJoystick.GetButton(const Index: Integer): Integer;
  begin
    if (Index < 0) or (Index > Self.fNumButtons - 1) then Exit(0);
    Exit(Self.fButton[Index]);
  end;

procedure TGEMDrawJoystick.SetDeadZoneThreshold(const aThreshold: Single);
  begin
    if aThreshold = 0 then begin
      Self.fDeadZoneThreshold := 0;
    end else if aThreshold > 1 then begin
      Self.fDeadZoneThreshold := 1;
    end else begin
      Self.fDeadZoneThreshold := aThreshold;
    end;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMDrawImage
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawImage.Create(const aWidth: Cardinal = 0; const aHeight: Cardinal = 0);
  begin
    inherited Create(aWidth, aHeight);
    DrawState.AddImage(Self);
  end;

constructor TGEMDrawImage.Create(const aFileName: String);
var
UsePath: String;
  begin

    if Pos('/', aFileName) = 0 then begin
      UsePath := DrawState.ImageLoadPath + aFileName;
    end else begin
      UsePath := aFileName;
    end;

    inherited Create(UsePath);
    DrawState.AddImage(Self);
  end;

constructor TGEMDrawImage.Create(const aData: Pointer; const aWidth, aHeight, aComponents: Cardinal);
  begin
    inherited Create(aData, aWidth, aHeight, aComponents);
    DrawState.AddImage(Self);
  end;

constructor TGEMDrawImage.Create(var aTexture: TGEMDrawTexture);
  begin
    DrawState.AddImage(Self);
    if Assigned(aTexture) = False then begin
      inherited Create(0,0);
      Exit();
    end;

    inherited Create(aTexture.Width, aTexture.Height);
    glGetTextureImage(aTexture.fHandle, 0, GL_RGBA, GL_UNSIGNED_BYTE, Self.DataSize, Self.Data);
  end;

procedure TGEMDrawImage.LoadFromFile(const aFileName: String); overload;
var
UsePath: String;
  begin
    if Pos('/', aFileName) = 0 then begin
      UsePath := DrawState.ImageLoadPath + aFileName;
    end else begin
      UsePath := aFileName;
    end;

    inherited LoadFromFile(UsePath);
  end;

procedure TGEMDrawImage.CopyFromTexture(aTexture: TGEMDrawTexture);
var
BuffSize: Integer;
Buff: PByte;
  begin
    if Assigned(aTexture) = False then Exit();

    Self.SetSize(aTexture.Width, aTexture.Height);

    BuffSize := (aTexture.Width * aTexture.Height) * 4;
    Buff := GetMemory(BuffSize);
    glGetTextureImage(aTexture.fHandle, 0, GL_RGBA, GL_UNSIGNED_BYTE, BuffSize, Buff);

    Self.LoadFromMemory(Buff, aTexture.Width, aTexture.Height, 4);

    FreeMemory(Buff);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                              TGEMDrawTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TGEMDrawTexture.Init(const aWidth, aHeight: GLUint);
  begin
    Self.fBounds := RectIWH(0, 0, aWidth, aHeight);
    glGenTextures(1, @Self.fHandle);
    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    if Self.fType = 0 then begin
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, aWidth, aHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    end else if Self.fType = 1 then begin
      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
      glTexParameterI(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH32F_STENCIL8, aWidth, aHeight, 0, GL_DEPTH_STENCIL, GL_FLOAT_32_UNSIGNED_INT_24_8_REV, nil);
    end;

    glBindTexture(GL_TEXTURE_2D, 0);
  end;

procedure TGEMDrawTexture.GenMipMaps();
  begin
    if Self.fMipMaps = 0 then Exit();
    glGenerateTextureMipMap(Self.fHandle);
  end;

constructor TGEMDrawTexture.Create(); overload;
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;
    Self.Init(0, 0);
  end;

constructor TGEMDrawTexture.Create(const aWidth, aHeight: GLUint);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;
    Self.Init(aWidth, aHeight);
  end;

constructor TGEMDrawTexture.CreateDepth(const aWidth, aHeight: GLUint);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 1;
    Self.fMipMaps := 0;
    Self.Init(aWidth, aHeight);
  end;

constructor TGEMDrawTexture.CreateColorBuffer(const aWidth, aHeight: GLUint);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 0;
    Self.Init(aWidth, aHeight);
  end;

constructor TGEMDrawTexture.Create(const aImage: TGEMDrawImage);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;

    if Assigned(aImage) then begin
      Self.Init(aImage.Width, aImage.Height);
      Self.LoadFromImage(aImage);
    end else begin
      Self.Init(1,1);
    end;
  end;

constructor TGEMDrawTexture.Create(const aFileName: String);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;
    Self.Init(1,1);
    Self.LoadFromFile(aFileName);
  end;

constructor TGEMDrawTexture.Create(var aTexture: TGEMDrawTexture; const aSourceBounds: TGEMRectI);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;
    Self.Init(1,1);

    if Assigned(aTexture) and (CanFit(aSourceBounds, aTexture.Bounds)) then begin
      Self.LoadFromTexture(aTexture, aSourceBounds);
    end;
  end;

constructor TGEMDrawTexture.Create(aRenderTarget: TGEMDrawRenderTarget; const aSourceBounds: TGEMRectI);
  begin
    inherited Create();
    DrawState.AddTexture(Self);
    Self.fType := 0;
    Self.fMipMaps := 1;
    Self.Init(1,1);

    Self.LoadFromRenderTarget(aRenderTarget, aSourceBounds);
  end;

procedure TGEMDrawTexture.LoadFromImage(const aImage: TGEMDrawImage);
  begin
    if Self.fType = 1 then Exit();

    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, aImage.Width, aImage.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, aImage.Data);
    glBindTexture(GL_TEXTURE_2D, 0);

    Self.GenMipMaps();

    Self.fBounds := RectIWH(0, 0, aImage.Width, aImage.Height);
  end;

procedure TGEMDrawTexture.LoadFromFile(const aFileName: String);
var
DataImage: TGEMDrawImage;
  begin
    if Self.fType = 1 then Exit();

    DataImage := TGEMDrawImage.Create();
    DataImage.LoadFromFile(aFileName);

    // if image load fails, resize to empty 1x1 texture
    if DataImage.DataSize = 0 then begin
      Self.SetSize(1, 1);
      Exit();
    end;

    glBindTexture(GL_TEXTURE_2D, Self.fHandle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, DataImage.Width, DataImage.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, DataImage.Data);
    glBindTexture(GL_TEXTURE_2D, 0);

    Self.GenMipMaps();

    Self.fBounds := RectIWH(0, 0, DataImage.Width, DataImage.Height);

    DataImage.Free();
  end;

procedure TGEMDrawTexture.LoadFromTexture(var aTexture: TGEMDrawTexture; const aSourceBounds: TGEMRectI);
  begin
    if Assigned(aTexture) = False then Exit();
    if aTexture.fHandle = 0 then Exit();
    if Self.fType = 1 then Exit();

    Self.SetSize(aTexture.Width, aTexture.Height);
    glCopyImageSubData(aTexture.fHandle, GL_TEXTURE_2D, 0, aSourceBounds.Left, aSourceBounds.Top, 0,
      Self.fHandle, GL_TEXTURE_2D, 0, 0, 0, 0, aSourceBounds.Width, aSourceBounds.Height, 1);

    Self.GenMipMaps();
  end;

procedure TGEMDrawTexture.LoadFromRenderTarget(aRenderTarget: TGEMDrawRenderTarget; const aSourceBounds: TGEMRectI);
var
Ptr: PByte;
DS: Integer;
  begin
    if Assigned(aRenderTarget) = False then Exit();
    if aRenderTarget.fColorBuffer.fHandle = 0 then Exit();
    if Self.fType = 1 then Exit();

    DrawState.DrawBatch(0,0);
    Self.SetSize(aSourceBounds.Width, aSourceBounds.Height);

    glCopyTextureSubImage2D(Self.fHandle, 0, aSourcebounds.Left, aSourceBounds.Top, 0, 0, aSourceBounds.Width, aSourceBounds.Height);

    Self.GenMipMaps();
  end;

procedure TGEMDrawTexture.SetSize(const aWidth, aHeight: GLUint; const aOP: TGEMSizeOp = GEM_DESTROY);
var
W, H: GLInt;
DataImage: TGEMImage;
DataPtr: PByte;
  begin
    if (aWidth = Self.Width) and (aHeight = Self.Height) then Exit();
    if aWidth > 0 then W := aWidth else W := 1;
    if aHeight > 0 then H := aHeight else H := 1;

    DataPtr := nil;
    DataImage := nil;

    glBindTexture(GL_TEXTURE_2D, Self.fHandle);

    if aOP <> GEM_DESTROY then begin
      DataImage := TGEMDrawImage.Create();
      DataImage.SetSize(Self.Width, Self.Height);
      DataPtr := DataImage.Data;
      glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, DataImage.Data);

      if aOP = GEM_CROP then begin
        DataImage.SetSize(W, H);
      end else if aOP = GEM_STRETCH then begin
        DataImage.Stretch(W, H);
      end;
    end;

    if Self.fType = 0 then begin
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, DataPtr);
    end else begin
      glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH32F_STENCIL8, W, H, 0, GL_DEPTH_STENCIL, GL_FLOAT_32_UNSIGNED_INT_24_8_REV, nil);
    end;

    Self.GenMipMaps();

    glBindTexture(GL_TEXTURE_2D, 0);

    if Assigned(DataImage) then begin
      DataImage.Free();
    end;

    Self.fBounds := RectIWH(0, 0, W, H);
  end;

procedure TGEMDrawTexture.SaveToFile(const aFileName: String; const aSaveMipMaps: Boolean = False);
var
DataImage: TGEMDrawImage;
Data: Array of Single;
Ptr: PGEMColorI;
Val: Byte;
I,R: Integer;
IterCount: Integer;
UseWidth, UseHeight: Integer;
PostFix: String;
Path: String;
FileName: String;
ExtString: String;
  begin

    if aSaveMipMaps then begin
      IterCount := 7;
    end else begin
      IterCount := 1;
    end;

    UseWidth := Self.Width;
    UseHeight := Self.Height;

    for R := 0 to IterCount - 1 do begin
      DataImage := TGEMDrawImage.Create();
      DataImage.SetSize(UseWidth, UseHeight);

      if Self.fType = 0 then begin
        glBindTexture(GL_TEXTURE_2D, Self.fHandle);
        glGetTexImage(GL_TEXTURE_2D, R, GL_RGBA, GL_UNSIGNED_BYTE, DataImage.Data);
        glBindTexture(GL_TEXTURE_2D, 0);
      end else begin
        SetLength(Data, UseWidth * UseHeight);

        glBindTexture(GL_TEXTURE_2D, Self.fHandle);
        glGetTexImage(GL_TEXTURE_2D, R, GL_DEPTH_COMPONENT, GL_FLOAT, @Data[0]);
        glBindTexture(GL_TEXTURE_2D, 0);

        Ptr := PGEMColorI(DataImage.Data);

        for I := 0 to High(Data) do begin
          Val := trunc(Data[I] * 255);
          Ptr[I] := ColorI(Val, Val, Val);
        end;

      end;

      if aSaveMipMaps then begin
        PostFix := R.ToString;
      end else begin
        PostFix := '';
      end;

      Path := ExtractFilePath(aFileName);
      FileName := gemExtractFileName(aFileName, True);
      ExtString := aFileName[High(aFileName) - 3..High(aFileName)];
      Path := Path + FileName + PostFix + ExtString;

      DataImage.SaveToFile(Path);
      DataImage.Free();

      UseWidth := trunc(UseWidth / 2);
      UseHeight := trunc(UseHeight / 2);

      if (UseWidth < 1) or (UseHeight < 1) then Break;
    end;

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawSprite
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawSprite.Create();
  begin
    inherited Create();
    DrawState.AddSprite(Self);
    Self.fTexture := nil;
    Self.fBounds := RectF(0,0,0,0);
    Self.fColorOverlay := Vec4(0,0,0,0);
    Self.fColorValues := Vec4(1,1,1,1);
    Self.fRotations := Vec3(0,0,0);
  end;

constructor TGEMDrawSprite.Create(aTexture: TGEMDrawTexture);
  begin
    inherited Create();
    DrawState.AddSprite(Self);
    Self.fTexture := nil;
    Self.fBounds := RectF(0,0,0,0);
    Self.fColorOverlay := Vec4(0,0,0,0);
    Self.fColorValues := Vec4(1,1,1,1);
    Self.fRotations := Vec3(0,0,0);
    Self.SetTexture(aTexture);
  end;

procedure TGEMDrawSprite.SetTexture(aTexture: TGEMDrawTexture);
  begin
    if Assigned(aTexture) = False then Exit();

    Self.fTexture := aTexture;
    Self.fBounds.SetWidth(aTexture.Width, FROM_CENTER);
    Self.fBounds.SetHeight(aTexture.Height, FROM_CENTER);
    Self.fTextureRect := aTexture.Bounds;
  end;

procedure TGEMDrawSprite.SetTextureRect(const aRect: TGEMRectI);
var
nl, nr, nt, nb: Integer;
  begin
    if aRect.Left < 0 then nl := 0 else nl := aRect.Left;
    if aRect.Right > Self.Texture.Bounds.Right then nr := Self.Texture.Bounds.Right else nr := aRect.Right;
    if aRect.Top < 0 then nt := 0 else nt := aRect.Top;
    if aRect.Bottom > Self.Texture.Bounds.Bottom then nb := Self.Texture.Bounds.Bottom else nb := aRect.Bottom;

    Self.fTextureRect := RectI(nl, nt, nr, nb);

    Self.fBounds.SetSize(Self.fTextureRect.Width, Self.fTextureRect.Height);
  end;

procedure TGEMDrawSprite.SetColorValues(const aValues: TGEMColorF);
  begin
    Self.fColorValues := ColorF(aValues.Red, aValues.Green, aValues.Blue, Self.fColorValues.Alpha);
  end;

procedure TGEMDrawSprite.SetOpacity(const aOpacity: Single);     
  begin
    Self.fColorValues.Alpha := aOpacity;
  end;

procedure TGEMDrawSprite.SetColorOverlay(const aOverlay: TGEMColorF);
  begin
    Self.fColorOverlay := ColorF(aOverlay.Red, aOverlay.Green, aOverlay.Blue, 1);
  end;

procedure TGEMDrawSprite.SetRotations(const aRotations: TGEMVec3); 
  begin
    Self.fRotations := aRotations;
  end;

procedure TGEMDrawSprite.SetRotationX(const aRotation: Single);   
  begin
    Self.fRotations.X := aRotation;
  end;

procedure TGEMDrawSprite.SetRotationY(const aRotation: Single);   
  begin
    Self.fRotations.Y := aRotation;
  end;

procedure TGEMDrawSprite.SetRotationZ(const aRotation: Single);    
  begin
    Self.fRotations.Z := aRotation;
  end;

procedure TGEMDrawSprite.Rotate(const aRotations: TGEMVec3);
  begin
    Self.fRotations := Self.fRotations + aRotations;
    ClampRadians(Self.fRotations.X);
    ClampRadians(Self.fRotations.Y);
    ClampRadians(Self.fRotations.Z);
  end;

procedure TGEMDrawSprite.ResetColors();      
  begin
    Self.fColorValues := ColorF(1,1,1,1);
    Self.fColorOverlay := ColorF(0,0,0,0);
  end;

procedure TGEMDrawSprite.ResetRotations();
  begin
    Self.fRotations := Vec3(0,0,0);
  end;

procedure TGEMDrawSprite.ResetSize();
  begin
    Self.fBounds.SetSize(Self.fTexture.Width, Self.fTexture.Height, FROM_CENTER);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            TGEMDrawRenderTarget
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawRenderTarget.Create(const aWidth, aHeight: GLUint);
  begin
    inherited Create();
    Self.fBounds := RectIWH(0, 0, aWidth, aHeight);
  end;

procedure TGEMDrawRenderTarget.InitBuffers();
var
Success: GLInt;
  begin
    Self.fColorBuffer := TGEMDrawTexture.CreateColorBuffer(Self.Bounds.Width, Self.Bounds.Height);
    Self.fBackBuffer := TGEMDrawTexture.CreateColorBuffer(Self.Bounds.Width, Self.Bounds.Height);
    Self.fDepthBuffer := TGEMDrawTexture.CreateDepth(Self.Bounds.Width, Self.Bounds.Height);

    glGenFramebuffers(1, @Self.fFBO);
    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, Self.fColorBuffer.fHandle, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, Self.fBackBuffer.fHandle, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer.fHandle, 0);

    Success := glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if Success <> GL_FRAMEBUFFER_COMPLETE then begin
      WriteLn('Framebuffer incomplete');
    end;

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  end;

procedure TGEMDrawRenderTarget.AttachDepthBuffer();
  begin
    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, Self.fDepthBuffer.fHandle, 0);
  end;

procedure TGEMDrawRenderTarget.DetachDepthBuffer();
  begin
    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, 0, 0);
  end;

procedure TGEMDrawRenderTarget.Clear();
  begin
    Self.Clear(Self.fClearColor);
  end;

procedure TGEMDrawRenderTarget.Clear(const aClearColor: TGEMColorF);
var
Buffs: Array [0..1] of GLEnum;
ClearDepth: Single;
  begin
    DrawState.SetTarget(Self);

    glBindFrameBuffer(GL_FRAMEBUFFER, Self.fFBO);

    Buffs[0] := GL_COLOR_ATTACHMENT0;
    Buffs[1] := GL_COLOR_ATTACHMENT1;
    glDrawBuffers(2, @Buffs);

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glDepthMask(GL_TRUE);

    ClearDepth := (DrawState.fClearDepthValue - DrawState.fDepthLow) / (DrawState.fDepthHigh - DrawState.fDepthLow);
    glClearDepth(ClearDepth);

    glClearStencil(DrawState.fClearStencilValue);

    glClearColor(aClearColor.Red, aClearColor.Green, aClearColor.Blue, aClearColor.Alpha);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    if DrawState.DepthTestEnabled then begin
      glEnable(GL_DEPTH_TEST);
    end;

    if DrawState.StencilTestEnabled then begin
      glEnable(GL_STENCIL_TEST);
    end;
  end;

procedure TGEMDrawRenderTarget.SetClearColor(const aColor: TGEMColorF);
  begin
    Self.fClearColor := aColor;
  end;

procedure TGEMDrawRenderTarget.AttachTexture(var aTexture: TGEMDrawTexture);
  begin
    if Assigned(aTexture) = False then Exit();

    DrawState.DrawBatch(0,0);

    Self.fAttachedTexture := aTexture;
    glNamedFramebufferTexture(Self.fFBO, GL_COLOR_ATTACHMENT1, aTexture.fHandle, 0);
    Self.fBounds := RectIWH(0, 0, Smallest([Self.fColorBuffer.fBounds.Width, Self.fAttachedTexture.Bounds.Width]),
                                  Smallest([Self.fColorBuffer.fBounds.Height, Self.fAttachedTexture.Bounds.Height]));
  end;

procedure TGEMDrawRenderTarget.DetachTexture();
  begin
    DrawState.DrawBatch(0,0);
    glNamedFramebufferTexture(Self.fFBO, GL_COLOR_ATTACHMENT1, 0, 0);
    Self.fBounds := RectIWH(0, 0, Self.fColorBuffer.Bounds.Width, Self.fColorBuffer.Bounds.Height);
  end;

procedure TGEMDrawRenderTarget.Blit(aDest: TGEMDrawRenderTarget; const aSourceRect, aDestRect: TGEMRectI);
var
Ver: Array [0..3] of TGEMVec4;
Cor: Array [0..3] of TGEMVec4;
DC: TGEMDrawCommand;
E: Array [0..5] of GLUint;
TransMat: TGEMMat4;
PMat: TGEMMat4;
  begin
    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.DrawBatch(0, 0);

    glDepthMask(GL_TRUE);

    Ver[0] := aDestRect.TopLeft - aDestRect.Center;
    Ver[1] := aDestRect.TopRight - aDestRect.Center;
    Ver[2] := aDestRect.BottomRight - aDestRect.Center;
    Ver[3] := aDestRect.BottomLeft - aDestRect.Center;

    Cor[0] := Vec2(aSourceRect.Left / Self.Bounds.Width, aSourceRect.Top / Self.Bounds.Height);
    Cor[1] := Vec2(aSourceRect.Right / Self.Bounds.Width, aSourceRect.Top / Self.Bounds.Height);
    Cor[2] := Vec2(aSourceRect.Right / Self.Bounds.Width, aSourceRect.Bottom / Self.Bounds.Height);
    Cor[3] := Vec2(aSourceRect.Left / Self.Bounds.Width, aSourceRect.Bottom / Self.Bounds.Height);

    E[0] := 0;
    E[1] := 1;
    E[2] := 3;
    E[3] := 1;
    E[4] := 3;
    E[5] := 2;

    DC.BaseInstance := 0;
    DC.BaseVertex := 0;
    DC.Count := 6;
    DC.FirstIndex := 0;
    DC.InstanceCount := 1;

    TransMat.MakeTranslation(aDestRect.Center);
    glViewPort(0, 0, aDest.Bounds.Width, aDest.Bounds.Height);
    PMat.Ortho(0, aDest.Bounds.Right, aDest.Bounds.Bottom, 0, DrawState.fDepthHigh, DrawState.fDepthLow);

    glBindFramebuffer(GL_FRAMEBUFFER, aDest.fFBO);
    glBindSampler(0, DrawState.fBufferSampler);
    glBindSampler(1, DrawState.fBufferSampler);
    glBindTextureUnit(0, Self.fColorBuffer.fHandle);
    glBindTextureUnit(1, Self.fDepthBuffer.fHandle);

    DrawState.Buffers.NextElementBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, 32, @E[0]);

    DrawState.Buffers.NextIndirectBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMDrawCommand), @DC);

    DrawState.Buffers.NextArrayBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVec4) * 4, @Ver[0]);
    DrawState.Buffers.AttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);

    DrawState.Buffers.NextArrayBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVec4) * 4, @Cor[0]);
    DrawState.Buffers.AttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, 0);

    DrawState.fShaders.UseProgram('blit');

    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('Source'), 0);
    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('Depth'), 1);
    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('GreyScale'), DrawState.fGreyScaleEnabled.ToInteger());
    glUniform3fv(DrawState.fShaders.CurrentProgram.UniformLocation('StateColorValues'), 1, @DrawState.fColorValues.Red);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Perspective'), 1, GL_FALSE, @PMat);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('View'), 1, GL_FALSE, @DrawState.View);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Translation'), 1, GL_FALSE, @TransMat);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, Pointer(0), 1, 0);

    glBindSampler(0, DrawState.fSampler);
    glBindSampler(1, DrawState.fSampler);
    glBindTextureUnit(0, 0);
    glBindTextureUnit(1, 0);

    DrawState.CurrentTarget := nil;
  end;

procedure TGEMDrawRenderTarget.Pixelate(const aBounds: TGEMRectI; const aPixelSize: Single);
var
Ver: Array [0..3] of TGEMVec4;
Cor: Array [0..3] of TGEMVec4;
DC: TGEMDrawCommand;
E: Array [0..5] of GLUint;
TransMat: TGEMMat4;
DepthState: Boolean;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.DrawBatch(0 ,0);

    DepthState := DrawState.DepthTestEnabled;
    DrawState.EnableDepthTest(False);

    Ver[0] := aBounds.TopLeft - aBounds.Center;
    Ver[1] := aBounds.TopRight - aBounds.Center;
    Ver[2] := aBounds.BottomRight - aBounds.Center;
    Ver[3] := aBounds.BottomLeft - aBounds.Center;

    E[0] := 0;
    E[1] := 1;
    E[2] := 3;
    E[3] := 1;
    E[4] := 3;
    E[5] := 2;

    DC.BaseInstance := 0;
    DC.BaseVertex := 0;
    DC.Count := 6;
    DC.FirstIndex := 0;
    DC.InstanceCount := 1;

    TransMat.MakeTranslation(aBounds.Center);

    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFBO);
    glBindSampler(0, DrawState.fBufferSampler);
    glBindTextureUnit(0, Self.fColorBuffer.fHandle);

    DrawState.Buffers.NextElementBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, 32, @E[0]);

    DrawState.Buffers.NextIndirectBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMDrawCommand), @DC);

    DrawState.Buffers.NextArrayBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVec4) * 4, @Ver[0]);
    DrawState.Buffers.AttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);

    DrawState.fShaders.UseProgram('pixelate');

    glUniform1ui(DrawState.fShaders.CurrentProgram.UniformLocation('PixelSize'), trunc(abs(aPixelSize)));
    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('Source'), 0);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Perspective'), 1, GL_FALSE, @DrawState.Perspective);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('View'), 1, GL_FALSE, @DrawState.View);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Translation'), 1, GL_FALSE, @TransMat);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, Pointer(0), 1, 0);

    glBindSampler(0, DrawState.fSampler);

    DrawState.EnableDepthTest(DepthState);
  end;

procedure TGEMDrawRenderTarget.Blur(const aBounds: TGEMRectI; const aRadius: Cardinal = 1);
var
Ver: Array [0..3] of TGEMVec4;
Cor: Array [0..3] of TGEMVec4;
DC: TGEMDrawCommand;
E: Array [0..5] of GLUint;
TransMat: TGEMMat4;
CurDepthState: Boolean;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    CurDepthState := DrawState.BlendingEnabled;
    DrawState.EnableDepthTest(False);

    DrawState.DrawBatch(0 ,0);

    Ver[0] := aBounds.TopLeft - aBounds.Center;
    Ver[1] := aBounds.TopRight - aBounds.Center;
    Ver[2] := aBounds.BottomRight - aBounds.Center;
    Ver[3] := aBounds.BottomLeft - aBounds.Center;

    Cor[0] := Vec2(aBounds.Left / Self.Bounds.Width, aBounds.Top / Self.Bounds.Height);
    Cor[1] := Vec2(aBounds.Right / Self.Bounds.Width, aBounds.Top / Self.Bounds.Height);
    Cor[2] := Vec2(aBounds.Right / Self.Bounds.Width, aBounds.Bottom / Self.Bounds.Height);
    Cor[3] := Vec2(aBounds.Left / Self.Bounds.Width, aBounds.Bottom / Self.Bounds.Height);

    E[0] := 0;
    E[1] := 1;
    E[2] := 3;
    E[3] := 1;
    E[4] := 3;
    E[5] := 2;

    DC.BaseInstance := 0;
    DC.BaseVertex := 0;
    DC.Count := 6;
    DC.FirstIndex := 0;
    DC.InstanceCount := 1;

    TransMat.MakeTranslation(aBounds.Center);

    Self.fBackBuffer.LoadFromTexture(Self.fColorBuffer, Self.Bounds);

    glBindFramebuffer(GL_FRAMEBUFFER, Self.fFBO);
    glBindSampler(0, DrawState.fBufferSampler);
    glBindTextureUnit(0, Self.fBackBuffer.fHandle);

    DrawState.Buffers.NextElementBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, 32, @E[0]);

    DrawState.Buffers.NextIndirectBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMDrawCommand), @DC);

    DrawState.Buffers.NextArrayBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVec4) * 4, @Ver[0]);
    DrawState.Buffers.AttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);

    DrawState.Buffers.NextArrayBuffer();
    DrawState.Buffers.CurrentVBO.SubData(0, SizeOf(TGEMVec4) * 4, @Cor[0]);
    DrawState.Buffers.AttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, 0);

    DrawState.fShaders.UseProgram('blur');

    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('txr'), 0);
    glUniform1i(DrawState.fShaders.CurrentProgram.UniformLocation('r'), Integer(aRadius));
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Perspective'), 1, GL_FALSE, @DrawState.Perspective);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('View'), 1, GL_FALSE, @DrawState.View);
    glUniformMatrix4fv(DrawState.fShaders.CurrentProgram.UniformLocation('Translation'), 1, GL_FALSE, @TransMat);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, Pointer(0), 1, 0);

    glBindSampler(0, DrawState.fSampler);

    DrawState.EnableDepthTest(CurDepthState);
  end;

procedure TGEMDrawRenderTarget.DrawTriangle(constref aP1, aP2, aP3: TGEMVec3; constref aColor: TGEMColorF);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
Center: TGEMVec3;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(3, 3, 32);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    Center := Vec3( (aP1.X + aP2.X + aP3.X) / 3,
                    (aP1.Y + aP2.Y + aP3.Y) / 3,
                    (aP1.Z + aP2.Z + aP3.Z) / 3);

    DrawState.Vertex[VCount + 0].Vector := aP1 - Center;
    DrawState.Vertex[VCount + 1].Vector := aP2 - Center;
    DrawState.Vertex[VCount + 2].Vector := aP3 - Center;

    DrawState.Vertex[VCount + 0].Color := aColor;
    DrawState.Vertex[VCount + 1].Color := aColor;
    DrawState.Vertex[VCount + 2].Color := aColor;

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 1;
    DrawState.ElementBuffer[ECount + 2] := VCount + 2;

    DrawState.Params[CCount].ColorValues := ColorF(1,1,1,1);
    DrawState.Params[CCount].ColorOverlay := ColorF(0,0,0,1);
    DrawState.Params[CCount].Rotation := Vec4(0,0,0,0);
    DrawState.Params[CCount].Scale := Vec4(1, 1, 1, 1);
    DrawState.Params[CCount].Translation := Center;

    DrawState.TextureUsing[CCount] := 32;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 3;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := 3;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := Min(aP1.Z, Min(aP2.Z, aP3.Z));
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := 3;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 3);
    Inc(DrawState.ElementCount, 3);

  end;

procedure TGEMDrawRenderTarget.DrawRectangle(constref aBounds: TGEMRectF; constref aColor: TGEMColorF);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(4, 6, 32);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    DrawState.Vertex[VCount + 0].Vector := Vec4(-0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 1].Vector := Vec4(0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 2].Vector := Vec4(0.5, 0.5, 0, 1);
    DrawState.Vertex[VCount + 3].Vector := Vec4(-0.5, 0.5, 0, 1);

    DrawState.Vertex[VCount + 0].Color := aColor;
    DrawState.Vertex[VCount + 1].Color := aColor;
    DrawState.Vertex[VCount + 2].Color := aColor;
    DrawState.Vertex[VCount + 3].Color := aColor;

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;
    DrawState.ID[VCount + 3] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 3;
    DrawState.ElementBuffer[ECount + 2] := VCount + 1;
    DrawState.ElementBuffer[ECount + 3] := VCount + 1;
    DrawState.ElementBuffer[ECount + 4] := VCount + 3;
    DrawState.ElementBuffer[ECount + 5] := VCount + 2;

    DrawState.Params[CCount].ColorValues := Vec4(1,1,1,1);
    DrawState.Params[CCount].ColorOverlay := Vec4(0,0,0,1);
    DrawState.Params[CCount].Rotation := Vec4(0,0,0,0);
    DrawState.Params[CCount].Scale := Vec4(aBounds.Width, aBounds.Height, 1, 1);
    DrawState.Params[CCount].Translation := aBounds.Center;

    DrawState.TextureUsing[CCount] := 32;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 6;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := 6;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := aBounds.Z;
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := 4;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 4);
    Inc(DrawState.ElementCount, 6);
  end;

procedure TGEMDrawRenderTarget.DrawRectangle(constref aBounds: TGEMRectF; constref aBorderWidth: Single; constref aColor, aBorderColor: TGEMColorF);
var
NewRect: TGEMRectF;
  begin
    // fill
    NewRect := RectF(aBounds.Left + aBorderWidth,
                     aBounds.Top + aBorderWidth,
                     aBounds.Right - aBorderWidth,
                     aBounds.Bottom - aBorderWidth);

    Self.DrawRectangle(NewRect, aColor);

    // top border
    NewRect := RectF(aBounds.Left, aBounds.Top, aBounds.Right, aBounds.Top + aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);

    // bottom border
    NewRect := RectF(aBounds.Left, aBounds.Bottom - aBorderWidth, aBounds.Right, aBounds.Bottom);
    Self.DrawRectangle(NewRect, aBorderColor);

    // left border
    NewRect := RectF(aBounds.Left, aBounds.Top + aBorderWidth, aBounds.Left + aBorderWidth, aBounds.Bottom - aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);

    // right border
    NewRect := RectF(aBounds.Right - aBorderWidth, aBounds.Top + aBorderWidth, aBounds.Right, aBounds.Bottom - aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);
  end;

procedure TGEMDrawRenderTarget.DrawRoundedRectangle(constref aBounds: TGEMRectF; constref aBorderWidth: Single; constref aColor, aBorderColor: TGEMColorF);
var
NewRect: TGEMRectF;
  begin
    // fill
    NewRect := RectF(aBounds.Left + aBorderWidth,
                     aBounds.Top + aBorderWidth,
                     aBounds.Right - aBorderWidth,
                     aBounds.Bottom - aBorderWidth);
    NewRect.SetZ(aBounds.Z);

    Self.DrawRectangle(NewRect, aColor);

    // topleft corner
    Self.DrawWedge(NewRect.TopLeft, aBorderWidth, -Pi, -Pi / 2, aBorderColor);

    // topright corner
    Self.DrawWedge(NewRect.TopRight, aBorderWidth, -Pi / 2, 0, aBorderColor);

    // bottomright corner
    Self.DrawWedge(NewRect.BottomRight, aBorderWidth, 0, Pi / 2, aBorderColor);

    // bottomleft corner
    Self.DrawWedge(NewRect.BottomLeft, aBorderWidth, Pi / 2, Pi, aBorderColor);

    // top border
    NewRect := RectF(aBounds.Left + aBorderWidth, aBounds.Top, aBounds.Right - aBorderWidth, aBounds.Top + aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);

    // bottom border
    NewRect := RectF(aBounds.Left + aBorderWidth, aBounds.Bottom - aBorderWidth, aBounds.Right - aBorderWidth, aBounds.Bottom);
    Self.DrawRectangle(NewRect, aBorderColor);

    // left border
    NewRect := RectF(aBounds.Left, aBounds.Top + aBorderWidth, aBounds.Left + aBorderWidth, aBounds.Bottom - aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);

    // right border
    NewRect := RectF(aBounds.Right - aBorderWidth, aBounds.Top + aBorderWidth, aBounds.Right, aBounds.Bottom - aBorderWidth);
    Self.DrawRectangle(NewRect, aBorderColor);
  end;

procedure TGEMDrawRenderTarget.DrawLine(constref aP1, aP2: TGEMVec3; constref aWidth: Single; constref aColor: TGEMColorF);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
Angle: GLFloat;
  begin
    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(4, 6, 32);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    DrawState.Vertex[VCount + 0].Vector := Vec4(-0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 1].Vector := Vec4(0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 2].Vector := Vec4(0.5, 0.5, 0, 1);
    DrawState.Vertex[VCount + 3].Vector := Vec4(-0.5, 0.5, 0, 1);

    DrawState.Vertex[VCount + 0].Color := aColor;
    DrawState.Vertex[VCount + 1].Color := aColor;
    DrawState.Vertex[VCount + 2].Color := aColor;
    DrawState.Vertex[VCount + 3].Color := aColor;

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;
    DrawState.ID[VCount + 3] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 3;
    DrawState.ElementBuffer[ECount + 2] := VCount + 1;
    DrawState.ElementBuffer[ECount + 3] := VCount + 1;
    DrawState.ElementBuffer[ECount + 4] := VCount + 3;
    DrawState.ElementBuffer[ECount + 5] := VCount + 2;

    Angle := GetAngle(aP1, aP2);

    DrawState.Params[CCount].ColorValues := Vec4(1,1,1,1);
    DrawState.Params[CCount].ColorOverlay := Vec4(0,0,0,1);
    DrawState.Params[CCount].Rotation := Vec4(0,0,Angle,0);
    DrawState.Params[CCount].Scale := Vec4(gemtypes.Distance(aP1, aP2), aWidth, 1, 1);
    DrawState.Params[CCount].Translation := Vec3((aP1.X + aP2.X) / 2, (aP1.Y + aP2.Y) / 2, (aP1.Z + aP2.Z) / 2);

    DrawState.TextureUsing[CCount] := 32;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 6;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := 6;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := Min(aP1.Z, aP2.Z);
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := 4;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 4);
    Inc(DrawState.ElementCount, 6);
  end;

procedure TGEMDrawRenderTarget.DrawRoundedLine(constref aP1, aP2: TGEMVec3; constref aWidth: Single; constref aColor: TGEMColorF);
var
Angle: Single;
Center: TGEMVec3;
Dist: Single;
P1, P2: TGEMVec3;
  begin
    Self.DrawLine(aP1, aP2, aWidth, aColor);
    Angle := GetAngle(aP1, aP2);
    Dist := gemtypes.Distance(aP1, aP2) / 2;
    Center := Vec3( (aP1.X + aP2.X) / 2,
                    (aP1.Y + aP2.Y) / 2,
                    (aP1.Z + aP2.Z) / 2);

    P1.X := Center.X + (Dist * Cos(Angle));
    P1.Y := Center.Y + (Dist * Sin(Angle));
    P1.Z := aP1.Z;
    Self.DrawWedge(P1, aWidth / 2, Angle - (Pi / 2), Angle + (Pi / 2), aColor);

    P1.X := Center.X - (Dist * Cos(Angle));
    P1.Y := Center.Y - (Dist * Sin(Angle));
    P1.Z := aP2.Z;
    Self.DrawWedge(P1, aWidth / 2, (Angle + Pi) - (Pi / 2), (Angle + Pi) + (Pi / 2), aColor);
  end;

procedure TGEMDrawRenderTarget.DrawCircle(constref aCenter: TGEMVec3; constref aRadius: Single; constref aColor: TGEMColorF);
  begin
    Self.DrawWedge(aCenter, aRadius, 0, Pi * 2, aColor);
  end;

procedure TGEMDrawRenderTarget.DrawWedge(constref aCenter: TGEMVec3; constref aRadius, aStartAngle, aEndAngle: Single; constref aColor: TGEMColorF);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
V: PGEMVertex;
E: PCardinal;
I: GLUint;
Angle, AngleInc, Circ: Extended;
P1, P2: TGEMVec3;
PointCount: Integer;
CurV: Integer;
AngleDiff: Extended;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);

    AngleDiff := aEndAngle - aStartAngle;
    Circ := 2 * Pi * aRadius;
    Circ := Circ * (AngleDiff / Pi2);
    PointCount := trunc(Circ * 2);
    AngleInc := AngleDiff / (PointCount);
    Angle := aStartAngle;

    if PointCount <= 1 then Exit();

    DrawState.CheckBatch(PointCount + 1, PointCount * 3, 32);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;
    V := @DrawState.Vertex[VCount];
    E := @DrawState.ElementBuffer[ECount];

    V[0].Vector := Vec3(0, 0, 0);
    V[0].Color := aColor;
    FillDWord(DrawState.ID[VCount], 4 * (PointCount + 1), CCount);

    for I := 1 to PointCount do begin
      V[I].Vector.X := (aRadius * Cos(Angle));
      V[I].Vector.Y := (aRadius * Sin(Angle));
      V[I].Color := aColor;
      Angle := Angle + AngleInc;
    end;

    CurV := VCount;
    ECount := PointCount * 3;
    for I := 0 to PointCount - 2 do begin
      E[0] := VCount;
      E[1] := CurV + 2;
      E[2] := CurV + 1;
      E := E + 3;
      CurV := CurV + 1;
    end;

    E[0] := VCount;
    E[1] := VCount + 1;
    E[2] := CurV + 1;

    DrawState.Params[CCount].ColorValues := ColorF(1,1,1,1);
    DrawState.Params[CCount].ColorOverlay := Vec4(0,0,0,1);
    DrawState.Params[CCount].Rotation := Vec4(0,0,0,0);
    DrawState.Params[CCount].Scale := Vec4(1, 1, 1, 1);
    DrawState.Params[CCount].Translation := aCenter;

    DrawState.TextureUsing[CCount] := 32;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + ECount;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := ECount;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := aCenter.Z;
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := PointCount + 1;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, PointCount + 1);
    Inc(DrawState.ElementCount, ECount);

  end;

procedure TGEMDrawRenderTarget.DrawTexture(var aTexture: TGEMDrawTexture; constref aBounds: TGEMRectF);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
I: Integer;
  begin

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(4, 6, aTexture.Handle);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    DrawState.Vertex[VCount + 0].Vector := Vec4(-0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 1].Vector := Vec4(0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 2].Vector := Vec4(0.5, 0.5, 0, 1);
    DrawState.Vertex[VCount + 3].Vector := Vec4(-0.5, 0.5, 0, 1);

    DrawState.Vertex[VCount + 0].Color := gem_empty;
    DrawState.Vertex[VCount + 1].Color := gem_empty;
    DrawState.Vertex[VCount + 2].Color := gem_empty;
    DrawState.Vertex[VCount + 3].Color := gem_empty;

    DrawState.Vertex[VCount + 0].TexCoord := Vec2(0, 0);
    DrawState.Vertex[VCount + 1].TexCoord := Vec2(1, 0);
    DrawState.Vertex[VCount + 2].TexCoord := Vec2(1, 1);
    DrawState.Vertex[VCount + 3].TexCoord := Vec2(0, 1);

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;
    DrawState.ID[VCount + 3] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 3;
    DrawState.ElementBuffer[ECount + 2] := VCount + 1;
    DrawState.ElementBuffer[ECount + 3] := VCount + 1;
    DrawState.ElementBuffer[ECount + 4] := VCount + 3;
    DrawState.ElementBuffer[ECount + 5] := VCount + 2;

    DrawState.Params[CCount].ColorValues := gem_white;
    DrawState.Params[CCount].ColorOverlay := Vec4(0,0,0,1);
    DrawState.Params[CCount].Rotation := Vec4(0,0,0,0);
    DrawState.Params[CCount].Scale := Vec4(aBounds.Width, aBounds.Height, 1, 1);
    DrawState.Params[CCount].Translation := aBounds.Center;

    for I := 1 to High(DrawState.TextureSlot) do begin
      if DrawState.TextureSlot[I] = 0 then begin
        DrawState.TextureUsing[CCount] := I;
        DrawState.TextureSlot[I] := aTexture.Handle;
        Inc(DrawState.TexturesUsed);
        Break;
      end else if DrawState.TextureSlot[I] = aTexture.Handle then begin
        DrawState.TextureUsing[CCount] := I;
        Break;
      end;
    end;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 6;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := 6;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := aBounds.Z;
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := 4;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 4);
    Inc(DrawState.ElementCount, 6);

  end;

procedure TGEMDrawRenderTarget.DrawSprite(var aSprite: TGEMDrawSprite);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
I: Integer;
  begin
    if aSprite = nil then Exit();

    if DrawState.DrawType <> 'default' then begin
      DrawState.DrawBatch(0,0);
      DrawState.DrawType := 'default';
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(4, 6, aSprite.fTexture.fHandle);

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    DrawState.Vertex[VCount + 0].Vector := Vec4(-0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 1].Vector := Vec4(0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 2].Vector := Vec4(0.5, 0.5, 0, 1);
    DrawState.Vertex[VCount + 3].Vector := Vec4(-0.5, 0.5, 0, 1);

    DrawState.Vertex[VCount + 0].Color := gem_empty;
    DrawState.Vertex[VCount + 1].Color := gem_empty;
    DrawState.Vertex[VCount + 2].Color := gem_empty;
    DrawState.Vertex[VCount + 3].Color := gem_empty;

    DrawState.Vertex[VCount + 0].TexCoord := Vec2(aSprite.TexureRect.Left / aSprite.Texture.Bounds.Right, aSprite.TexureRect.Top / aSprite.Texture.Bounds.Bottom);
    DrawState.Vertex[VCount + 1].TexCoord := Vec2(aSprite.TexureRect.Right / aSprite.Texture.Bounds.Right, aSprite.TexureRect.Top / aSprite.Texture.Bounds.Bottom);
    DrawState.Vertex[VCount + 2].TexCoord := Vec2(aSprite.TexureRect.Right / aSprite.Texture.Bounds.Right, aSprite.TexureRect.Bottom / aSprite.Texture.Bounds.Bottom);
    DrawState.Vertex[VCount + 3].TexCoord := Vec2(aSprite.TexureRect.Left / aSprite.Texture.Bounds.Right, aSprite.TexureRect.Bottom / aSprite.Texture.Bounds.Bottom);

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;
    DrawState.ID[VCount + 3] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 3;
    DrawState.ElementBuffer[ECount + 2] := VCount + 1;
    DrawState.ElementBuffer[ECount + 3] := VCount + 1;
    DrawState.ElementBuffer[ECount + 4] := VCount + 3;
    DrawState.ElementBuffer[ECount + 5] := VCount + 2;

    DrawState.Params[CCount].ColorValues := aSprite.ColorValues;
    DrawState.Params[CCount].ColorOverlay := aSprite.ColorOverlay;
    DrawState.Params[CCount].Rotation := aSprite.fRotations;
    DrawState.Params[CCount].Scale := Vec4(aSprite.Bounds.Width, aSprite.Bounds.Height, 1, 1);
    DrawState.Params[CCount].Translation := aSprite.Bounds.Center;

    for I := 1 to High(DrawState.TextureSlot) do begin
      if DrawState.TextureSlot[I] = 0 then begin
        DrawState.TextureUsing[CCount] := I;
        DrawState.TextureSlot[I] := aSprite.fTexture.Handle;
        Inc(DrawState.TexturesUsed);
        Break;
      end else if DrawState.TextureSlot[I] = aSprite.fTexture.Handle then begin
        DrawState.TextureUsing[CCount] := I;
        Break;
      end;
    end;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 6;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    if DrawState.fDrawSortingEnabled then begin
      DrawState.DrawInfo[CCount].Index := CCount;
      DrawState.DrawInfo[CCount].ElementCount := 6;
      DrawState.DrawInfo[CCount].ElementStart := DrawState.ElementCount;
      DrawState.DrawInfo[CCount].Z := aSprite.Bounds.Z;
      DrawState.DrawInfo[CCount].VertexStart := VCount;
      DrawState.DrawInfo[CCount].VertexCount := 4;
    end;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 4);
    Inc(DrawState.ElementCount, 6);

  end;

procedure TGEMDrawRenderTarget.DrawLight(const aCenter: TGEMVec3; const aRadius: Single; const aColor: TGEMColorI);
var
ECount: GLUint;
VCount: GLUint;
CCount: GLUint;
I: Integer;
  begin
    if DrawState.DrawType <> 'light' then begin
      DrawState.DrawBatch(0,0);
    end;

    DrawState.SetTarget(Self);
    DrawState.CheckBatch(4, 6, 32);
    DrawState.DrawType := 'light';

    CCount := DrawState.CommandCount;
    VCount := DrawState.VertexCount;
    ECount := DrawState.ElementCount;

    DrawState.Vertex[VCount + 0].Vector := Vec4(-0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 1].Vector := Vec4(0.5, -0.5, 0, 1);
    DrawState.Vertex[VCount + 2].Vector := Vec4(0.5, 0.5, 0, 1);
    DrawState.Vertex[VCount + 3].Vector := Vec4(-0.5, 0.5, 0, 1);

    DrawState.Vertex[VCount + 0].Color := aColor;
    DrawState.Vertex[VCount + 1].Color := aColor;
    DrawState.Vertex[VCount + 2].Color := aColor;
    DrawState.Vertex[VCount + 3].Color := aColor;

    DrawState.Vertex[VCount + 0].TexCoord := Vec3(aCenter.x - aRadius, aCenter.y - aRadius, aCenter.z);
    DrawState.Vertex[VCount + 1].TexCoord := Vec3(aCenter.x + aRadius, aCenter.y - aRadius, aCenter.z);
    DrawState.Vertex[VCount + 2].TexCoord := Vec3(aCenter.x + aRadius, aCenter.y + aRadius, aCenter.z);
    DrawState.Vertex[VCount + 3].TexCoord := Vec3(aCenter.x - aRadius, aCenter.y + aRadius, aCenter.z);

    DrawState.ID[VCount + 0] := CCount;
    DrawState.ID[VCount + 1] := CCount;
    DrawState.ID[VCount + 2] := CCount;
    DrawState.ID[VCount + 3] := CCount;

    DrawState.ElementBuffer[ECount + 0] := VCount + 0;
    DrawState.ElementBuffer[ECount + 1] := VCount + 3;
    DrawState.ElementBuffer[ECount + 2] := VCount + 1;
    DrawState.ElementBuffer[ECount + 3] := VCount + 1;
    DrawState.ElementBuffer[ECount + 4] := VCount + 3;
    DrawState.ElementBuffer[ECount + 5] := VCount + 2;

    DrawState.Params[CCount].ColorValues := gem_empty;
    DrawState.Params[CCount].ColorOverlay := gem_empty;
    DrawState.Params[CCount].Rotation := Vec3(0,0,0);
    DrawState.Params[CCount].Scale := Vec3(aRadius * 2, aRadius * 2, 0);
    DrawState.Params[CCount].Translation := aCenter;
    DrawState.Params[CCount].Translation.w := aRadius;

    DrawState.DrawCommand[0].InstanceCount := 1;
    DrawState.DrawCommand[0].FirstIndex := 0;
    DrawState.DrawCommand[0].Count := DrawState.DrawCommand[0].Count + 6;
    DrawState.DrawCommand[0].BaseVertex := 0;
    DrawState.DrawCommand[0].BaseInstance := 0;

    Inc(DrawState.CommandCount);
    Inc(DrawState.VertexCount, 4);
    Inc(DrawState.ElementCount, 6);
  end;

procedure TGEMDrawRenderTarget.DrawText(aFont: TGEMDrawFont; const aCharSize: Cardinal; const aText: String; const aPosition: TGEMVec3; const aColor: TGEMColorF);
var
Origin: Single;
CurPos: TGEMVec3;
Atlas: TGEMDrawFontAtlas;
I: Integer;
CharCode, NextCharCode: Cardinal;
CurChar: ^TGEMDrawFontCharacter;
Sprite: TGEMDrawSprite;
Per: Single;
Kern: Single;
  begin
    if Assigned(aFont) = False then Exit();

    if DrawState.fDrawingText = False then begin
      DrawState.DrawBatch(0, 0);
      DrawState.fDrawingText := True;
    end;

    Atlas := aFont.fAtlas;
    Sprite := DrawState.fSprite;
    Sprite.SetTexture(Atlas.fTexture);
    Sprite.SetColorValues(aColor);
    Sprite.SetOpacity(aColor.Alpha);

    Per := aCharSize / 32;

    Origin := aPosition.Y + (Atlas.Height * Per) - (Atlas.Origin * Per);
    CurPos := aPosition;

    for I := 1 to High(aText) do begin
      if aText[I] = sLineBreak then begin
        Origin := Origin + (Atlas.Height * Per);
        CurPos.X := aPosition.X;
        Continue;
      end;

      CharCode := Ord(aText[I]);
      CurChar := @Atlas.Character[CharCode];

      Sprite.ResetSize();
      Sprite.SetTextureRect(RectIWH(trunc(CurChar.Position.X), trunc(CurChar.Position.Y), CurChar.Width, CurChar.Height));
      Sprite.Bounds.Stretch(Per, Per);

      Sprite.Bounds.SetTop(Origin - (CurChar.BearingY * Per));
      Sprite.Bounds.SetLeft(CurPos.X);
      Self.DrawSprite(Sprite);

      Kern := 0;
      if I <> High(aText) then begin
        NextCharCode := Ord(aText[I + 1]);
        Kern := Atlas.Character[CharCode].Kerning[NextCharCode];
      end;

      CurPos.X := CurPos.X + ((CurChar.Advance) * Per) + (Kern * Per);

    end;

    DrawState.DrawBatch(0, 0);
    DrawState.fDrawingText := False;

  end;

procedure TGEMDrawRenderTarget.SaveToFile(const aFileName: String);
  begin
    DrawState.DrawBatch(0,0);
    Self.fColorBuffer.SaveToFile(aFileName);
  end;

procedure TGEMDrawRenderTarget.SaveDepthToFile(const aFileName: String);
  begin
    DrawState.DrawBatch(0,0);
    Self.fDepthBuffer.SaveToFile(aFileName);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawWindow
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawWindow.Create(const aWidth, aHeight: GLUint; const aTitle: String);
var
x, y, w, h: GLInt;
  begin
    inherited Create(aWidth, aHeight);

    Self.fTitle := aTitle;
    Self.fMaximized := False;
    Self.fMinimized := False;
    Self.fFullScreen := False;
    Self.fHasTitleBar := True;
    Self.fClearColor := ColorF(0, 0, 0, 0);

    glfwWindowHint(GLFW_DOUBLEBUFFER, GL_TRUE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

    Self.fHandle := glfwCreateWindow(aWidth, aHeight, PChar(Self.fTitle), nil, nil);
    glfwMakeContextCurrent(Self.fHandle);

    if not gladLoadGL(TLoadProc(@glfwGetProcAddress)) then begin
      WriteLn('Failed to initialize GLAD!');
    end;

    glfwGetWindowFrameSize(Self.fHandle, @Self.fFrameLeft, @Self.fFrameTop, @Self.fFrameRight, @Self.fFrameBottom);
    glfwGetWindowPos(Self.fHandle, @x, @y);

    Self.fFrameBounds.SetSize(aWidth, aHeight);
    Self.fFrameBounds.SetTopLeft(x, y);
    Self.UpdateFrameSize();

    Self.InitBuffers();

    glViewPort(0, 0, aWidth, aHeight);

    glfwSetErrorCallback(@gemDrawGLFWErrorProc);
    glfwSetWindowCloseCallback(Self.fHandle, @gemDrawWindowCloseProc);
    glfwSetWindowPosCallback(Self.fHandle, @gemDrawWindowPosProc);
    glfwSetWindowSizeCallback(Self.fHandle, @gemDrawWindowSizeProc);
    glfwSetWindowMaximizeCallback(Self.fHandle, @gemDrawWindowMaximizeProc);
    glfwSetWindowIconifyCallback(Self.fHandle, @gemDrawWindowMinimizeProc);
    glfwSetWindowFocusCallback(Self.fHandle, @gemDrawWindowFocusProc);
    glfwSetKeyCallback(Self.fHandle, @gemDrawKeyProc);
    glfwSetCursorPosCallback(Self.fHandle, @gemDrawMousePosProc);
    glfwSetMouseButtonCallback(Self.fHandle, @gemDrawMouseButtonProc);
    glfwSetJoystickCallback(@gemDrawJoystickProc);

    glClearColor(fClearColor.Red, fClearColor.Green, fClearColor.Blue, fClearColor.Alpha);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  end;

procedure TGEMDrawWindow.UpdateFrameSize();
  begin
    Self.fFrameBounds := RectI(Self.fFrameBounds.Left - Self.fFrameLeft - DrawState.fWorkArea.Left,
                               Self.fFrameBounds.Top - Self.fFrameTop - DrawState.fWorkArea.Top,
                               Self.fFrameBounds.Right + Self.fFrameRight - DrawState.fWorkArea.Left - 1,
                               Self.fFrameBounds.Bottom + Self.fFrameBottom - DrawState.fWorkArea.Top - 1);

    if Assigned(Self.fColorBuffer) then begin
      Self.fColorBuffer.SetSize(Self.Bounds.Width, Self.Bounds.Height);
      Self.fBackBuffer.SetSize(Self.Bounds.Width, Self.Bounds.Height);
      Self.fDepthBuffer.SetSize(Self.Bounds.Width, Self.Bounds.Height);
      if DrawState.CurrentTarget = Self then begin
        glViewPort(0, 0, Self.Bounds.Width, Self.Bounds.Height);
      end;
    end;

    if Assigned(Self.fResizeProc) then begin
      Self.fResizeProc();
    end;
  end;

procedure TGEMDrawWindow.Finish();
var
V: Array [0..3] of TGEMVertex;
E: Array [0..5] of GLUint;
Loc: GLInt;
Prog: TGEMDrawProgram;
  begin
    DrawState.SetTarget(Self);
    DrawState.DrawBatch(0,0);

    // no flip
    glBlitNamedFramebuffer(Self.fFBO, 0,
      0, 0, Self.Bounds.Width, Self.Bounds.Height,
      0, Self.Bounds.Height, Self.Bounds.Width, 0,
      GL_COLOR_BUFFER_BIT, GL_NEAREST);

    glFinish();
  end;

procedure TGEMDrawWindow.Update();
  begin
    DrawState.DrawBatch(0,0);
    DrawState.Buffers.UnUseAll();
    glfwSwapBuffers(Self.fHandle);

    glfwPollEvents();
    DrawState.UpdateJoysticks();
  end;

procedure TGEMDrawWindow.Close();
  begin
    glfwSetWindowShouldClose(Self.fHandle, 1);
    DrawState.fInitialized := False;
  end;

procedure TGEMDrawWindow.SetTitle(const aTitle: String);
  begin
    fTitle := aTitle;
    glfwSetWindowTitle(Self.fHandle, PChar(Self.fTitle));
  end;

procedure TGEMDrawWindow.SetPosition(const aPosition: TGEMVec2);
  begin
    glfwSetWindowPos(Self.fHandle, trunc(aPosition.X), trunc(aPosition.Y));
  end;

procedure TGEMDrawWindow.SetLeft(const aLeft: GLFLoat);
  begin
    glfwSetWindowPos(Self.fHandle, trunc(aLeft), trunc(Self.fBounds.Left));
  end;

procedure TGEMDrawWindow.SetTop(const aTop: GLFloat);
  begin
    glfwSetWindowPos(Self.fHandle, trunc(Self.fBounds.Top), trunc(aTop));
  end;

procedure TGEMDrawWindow.SetMaximized(const aMaximized: Boolean = True);
  begin
    if aMaximized then begin
      glfwMaximizeWindow(Self.fHandle);
    end else begin
      glfwRestoreWindow(Self.fHandle);
    end;
  end;

procedure TGEMDrawWindow.SetMinimized(const aMinimized: Boolean = True);
  begin
    if aMinimized then begin
      glfwIconifyWindow(Self.fHandle);
    end else begin
      glfwRestoreWindow(Self.fHandle);
    end;
  end;

procedure TGEMDrawWindow.SetHasTitleBar(const aHasTitleBar: Boolean = True);
var
ow, oh: Integer;
  begin
    if aHasTitleBar then begin
      if Self.fHasTitleBar = False then begin
        Self.fHasTitleBar := True;
        glfwSetWindowAttrib(Self.fHandle, GLFW_DECORATED, 1);

        glfwGetWindowPos(Self.fHandle, @ow, @oh);
        glfwSetWindowPos(Self.fHandle, ow, oh + Self.fFrameTop);

        glfwFocusWindow(Self.fHandle);

      end;
    end else begin
      if Self.fHasTitleBar = True then begin
        Self.fHasTitleBar := False;
        glfwSetWindowAttrib(Self.fHandle, GLFW_DECORATED, 0);

        ow := Self.Bounds.Width;
        oh := Self.Bounds.Height;
        Self.fFrameBounds.SetSize(ow, oh);
        glfwSetWindowSize(Self.fHandle, ow, oh);
        glfwFocusWindow(Self.fHandle);
      end;
    end;
  end;

procedure TGEMDrawWindow.SetResizeProc(const aProc: TGEMDrawProc);
  begin
    Self.fResizeProc := aProc;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawRenderTexture
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawRenderTexture.Create(const aWidth, aHeight: GLUint);
  begin
    inherited Create(aWidth,aHeight);
    DrawState.AddRenderTexture(Self);
    Self.InitBuffers();
  end;

procedure TGEMDrawRenderTexture.SetSize(const aWidth, aHeight: Cardinal);
  begin
    if (aWidth = 0) or (aHeight = 0)then begin
      DrawState.ErrOut(GEM_INVALID_VALUE, GEM_NON_ZERO_EXPECTED, GEM_WARNING);
      Exit();
    end;

    if (aWidth > DrawState.fMaxFramebufferWidth) or (aHeight > DrawState.fMaxFramebufferHeight) then begin
      DrawState.ErrOut(GEM_INVALID_VALUE, GEM_VALUE_TOO_LARGE, GEM_WARNING);
      Exit();
    end;

    Self.fColorBuffer.SetSize(aWidth, aHeight, GEM_DESTROY);
    Self.fBackBuffer.SetSize(aWidth, aHeight, GEM_DESTROY);
    Self.fDepthBuffer.SetSize(aWidth, aHeight, GEM_DESTROY);
    Self.Clear();
    Self.fBounds := RectI(0, 0, aWidth - 1, aHeight - 1);

    if DrawState.CurrentTarget = Self then begin
      DrawState.CurrentTarget := nil;
      DrawState.SetTarget(Self);
    end;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                            TGEMDrawFontAtlas
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawFontAtlas.Create(aOwner: TGEMDrawFont; const aFilePath: String);
var
Lib: PFT_Library;
Glyph: PFT_GlyphSlot;
Metrics: FT_Glyph_Metrics;
OutGlyph: PFT_Glyph;
I: Integer;
GBox, BBox: TGEMRectI;
Image: TGEMDrawImage;
CharImage: TGEMDrawImage;
Index: FT_UInt;
Ret: Integer;
CurChar: ^TGEMDrawFontCharacter;
CurPos: TGEMVec2;
X,Y,G,H: Integer;
Color: TGEMColorI;
MaxAlpha: Integer;
Spread: FT_Int;
ERR: FT_ERROR;
EString: PChar;
Buff: Pointer;
  begin
    Self.fOwner := aOwner;
    Self.fWidth := 0;
    Self.fHeight := 0;
    Self.fGlyphs := 0;
    Self.fOrigin := 0;

    CharImage := TGEMDrawImage.Create();

    Lib := nil;
    Face := nil;
    FT_Init_FreeType(Lib);

    Spread := 2;
    ERR := FT_Property_Set(Lib, 'sdf', 'spread', @Spread);

    FT_New_Face(Lib, PChar(aFilePath), 0, Face);
    FT_Set_Pixel_Sizes(face, 0, 32);

    BBox := RectF(Face.bbox.xMin / 64, Face.bbox.yMin / 64, Face.bbox.xMax / 64, Face.bbox.yMax / 64);

    I := 32;
    while I < 256 do begin
        Self.Character[I].Index := -1;
        Ret := FT_Load_Glyph(Face, FT_Get_Char_Index(Face, I), FT_LOAD_NO_BITMAP);
        if Ret <> 0 then Continue;

        Glyph := Face.glyph;
        FT_RENDER_GLYPH(Glyph, FT_RENDER_MODE_SDF);

        Metrics := Glyph.metrics;
        GBox := RectIWH(0, 0, Glyph.bitmap.width, Glyph.bitmap.rows);

        BBox := RectF(Face.bbox.xMin / 64, Face.bbox.yMin / 64, Face.bbox.xMax / 64, Face.bbox.yMax / 64);

        CurChar := @Self.Character[I];

        CurChar.Symbol := Char(I);
        CurChar.Index := I;
        CurChar.Width := GBox.Width;
        CurChar.Height := GBox.Height;
        CurChar.Advance := trunc(Glyph.metrics.horiAdvance / 64);
        CurChar.BearingX := Metrics.horiBearingX / 64;
        CurChar.BearingY := Metrics.horiBearingY / 64;

        Inc(Self.fWidth, GBox.Width + 1);
        if Self.fHeight < GBox.Height then begin
          Self.fHeight := GBOx.Height;
        end;

        If Self.fOrigin < trunc(CurChar.Height - CurChar.BearingY) then begin
          Self.fOrigin := trunc(CurChar.Height - CurChar.BearingY);
        end;

        Inc(Self.fGlyphs);

        Inc(I);
    end;

    Self.fHeight := Self.fHeight + Self.Origin;
    Image := TGEMDrawImage.Create(Self.Width, Self.Height);
    Image.Fill(gem_empty);
    MaxAlpha := 0;

    CurPos := Vec2(0, 0);
    for I := 32 to 255 do begin
      CurChar := @Self.Character[I];
      if CurChar.Index = -1 then Continue;

      FT_Load_Glyph(Face, FT_Get_Char_Index(Face, I), FT_LOAD_NO_BITMAP);
      FT_Render_Glyph(Face.glyph, FT_RENDER_MODE_SDF);

      Buff := gemUnsignSDF(Face.glyph.bitmap.buffer, Face.glyph.bitmap.width, Face.glyph.bitmap.rows);
      CharImage.LoadFromMemory(Buff, face.glyph.bitmap.width, face.glyph.bitmap.rows, 4);
      FreeMemory(Buff);

      for X := 0 to CurChar.Width - 1 do begin
        for Y := 0 to CurChar.Height - 1 do begin
          G := trunc(CurPos.X) + X;
          H := trunc((Self.Height - Self.Origin) - CurChar.BearingY) + Y;
          Image.Pixel[G,H] := CharImage.Pixel[X,Y];
        end;
      end;

      CurChar.Position := Vec2(CurPos.X, (Self.Height - Self.Origin) - CurChar.BearingY);

      CurPos.X := CurPos.X + CurChar.Width + 1;

    end;

    for X := 0 to Image.Width - 1 do begin
      for Y := 0 to Image.Height - 1 do begin
        Color := Image.Pixel[X,Y];
        Image.Pixel[X,Y] := Color;
      end;
    end;

    Self.fTexture := TGEMDrawTexture.Create(Image);
    Self.fTexture.SaveToFile('Atlas.png', False);

    Image.Free();
    CharImage.Free();

    Self.GetKernings();

    FT_Done_Face(Face);
    FT_Done_FreeType(Lib);

  end;

procedure TGEMDrawFontAtlas.GetKernings();
var
I, Z: FT_ULong;
K: FT_Vector;
LeftIndex, RightIndex: FT_Uint;
ERR: FT_Error;
  begin

    // loop over characters
    for I := 32 to High(Self.Character) do begin
      LeftIndex := FT_Get_Char_Index(Self.Face, I);

      // loop over glyphs indices
      for Z := 32 to 255 do begin
        RightIndex := FT_Get_Char_Index(Self.Face, Z);
        ERR := FT_Get_Kerning(Self.Face, LeftIndex, RightIndex, 0, K);
        Self.Character[I].Kerning[Z] := K.y;
      end;
    end;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                TGEMDrawFont
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMDrawFont.Create(const aFilePath: String);
  begin

    if gemFileExists(aFilePath) then begin
      Self.fFilePath := aFilePath;
      Self.fFontName := ExtractFileName(aFilePath);
      Self.fAtlas := TGEMDrawFontAtlas.Create(Self, aFilePath);
      Self.fValid := True;
    end;

  end;

end.

