unit GEMAudio;


{$ifdef FPC}
{$mode ObjFPC}{$H+}
{$modeswitch ADVANCEDRECORDS}
{$modeswitch AUTODEREF}
{$endif}

{$HINTS OFF}
{$POINTERMATH ON}


interface

uses
  OpenAl, GEMTypes,
  classes, SysUtils, Math, StrUtils;

  Const ALBUFFER = (0);
  Const ALSOURCE = (1);
  Const ALLISTERN = (2);

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Enums
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type TGEMSoundState = (pgl_initial = AL_INITIAL, pgl_stopped = AL_STOPPED, pgl_playing = AL_PLAYING, pgl_paused = AL_PAUSED);

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMNotes
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    TGEMNotes = class
    private
      Note: Array [0..8] of Array [0..11] of Single;
      constructor Create();
      function GetNoteOrdinal(ANote: String): Integer;
    public
      function GetNoteFrequency(ANoteName: String): Single; overload;
      function GetNoteFrequency(AOrdinal: Integer; AOctive: Cardinal): Single; overload;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMWaveHeader
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PGEMWaveHeader = ^TGEMWaveHeader;
    TGEMWaveHeader = packed record
    public
      RIFF: DWORD; // always 'RIFF'
      FILE_SIZE: DWORD;
      WAVE: DWORD; // always 'WAVE'
      FMT: DWORD; // always 'fmt '
      RIFF_SIZE: DWORD; // always 16
      AUDIO_FORMAT: WORD; // 1, 2 or 4
      CHANNELS: Int16;
      SAMPLE_RATE: DWORD; // per second, ex. 44100
      BYTES_PER_SECOND: DWORD; // Sample Rate * channels * block align
      BLOCK_ALIGN: Int16; // in bytes
      BITS_PER_SAMPLE: Int16;
      DATA_HEADER: DWORD; // always 'data'
      DATA_SIZE: DWORD;

      class operator Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TGEMWaveHeader);
      procedure Fill(AAudioFormat, AChannels: WORD; ASampleRate, ADataSize: DWord); overload;
      procedure Fill(ASource: Pointer); overload;
      function CheckValid(): Boolean;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMAudioData
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PGEMAudioData = ^TGEMAudioData;
    TGEMAudioData = record
    private
      fBuffer: specialize TArray<Int16>;
      fDuration: Single;
      fHeaderInfo: TGEMWaveHeader;

      function GetSize(): Int64;
      function GetSamples(): Cardinal;
      function GetBitDepth(): Int16;
      procedure UpdateDuration();

    public
      property Buffer: specialize TArray<Int16> read fBuffer;
      property BufferSize: Int64 read GetSize;
      property SampleCount: Cardinal read GetSamples;
      property SampleRate: Cardinal read fHeaderInfo.SAMPLE_RATE;
      property BlockSize: Int16 read fHeaderinfo.BLOCK_ALIGN;
      property BitDepth: Int16 read GetBitDepth;
      property Channels: Int16 read fHeaderInfo.Channels;
      property BytesPerSecond: Cardinal read fHeaderInfo.BYTES_PER_SECOND;
      property BitsPerSample: Int16 read fHeaderInfo.BITS_PER_SAMPLE;
      property Duration: Single read fDuration;
      property HeaderInfo: TGEMWaveHeader read fHeaderInfo;

      procedure Configure(ASampleRate, ABitDepth, AChannels: Cardinal);
      procedure SetSampleRate(ASampleRate: Cardinal);
      procedure SetBitDepth(ABitDepth: Int16);
      procedure SetChannels(AChannels: Cardinal);

      procedure NormalizeGain();
      procedure AdjustGain(APercent: Single);
      procedure MaxAmplifyNoClip(ASampleStart, ASampleEnd: Cardinal); overload;
      procedure MaxAmplifyNoClip(ATimeStart, ATimeEnd: Single); overload;
      procedure AdjustBass(APercentage: Single);

      procedure AddReverb(AReverbLength: Single);
      procedure GainFade(ASampleStart, ASampleEnd: Cardinal; AGainStart, AGainEnd: Single); overload;
      procedure GainFade(ATimeStart, ATimeEnd: Single; AGainStart, AGainEnd: Single); overload;

      procedure ClearBuffer();
      procedure FillBuffer(ASource: Pointer; ASourceSize, ASourceSampleRate, ASourceBitDepth: Cardinal);
      procedure AppendBuffer(ASource: specialize TArray<Int16>);
      procedure InsertBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal); overload;
      procedure InsertBuffer(ASource: specialize TArray<Int16>; APosition: Single); overload;
      procedure PasteBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal); overload;
      procedure PasteBuffer(ASource: specialize TArray<Int16>; ATimePosition: Single); overload;
      procedure DeleteBuffer(ASampleStart, ASampleEnd: Cardinal); overload;
      procedure DeleteBuffer(ATimeStart, ATimeEnd: Single); overload;
      procedure CombineBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal); overload;
      procedure CombineBuffer(ASource: specialize TArray<Int16>; ATimePosition: Single); overload;
      procedure ReverseBuffer(ASampleStart, ASampleEnd: Cardinal); overload;
      procedure ReverseBuffer(ATimeStart, ATimeEnd: Single); overload;

      procedure TrimSilence(AAmplitudeLimit: Single; ATrimLeft: Boolean = True; ATrimRight: Boolean = True);

      procedure SpeedUp();

      procedure CopyFrom(var ASource: TGEMAudioData; AStartSample, AEndSample: Cardinal); overload;
      procedure CopyFrom(var ASource: TGEMAudioData; AStartTime, AEndTime: Single); overload;
      function GetSlice(AStartTime, AEndTime: Single): specialize TArray<Int16>; overload;
      function GetSlice(ASampleStart, ASampleEnd: Cardinal): specialize TArray<Int16>; overload;

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLAudioGenerator
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLAudioGenerator = ^TPGLAudioGenerator;
    TPGLAudioGenerator = record
      private
        fSampleRate: Cardinal;
        fBitDepth: Cardinal;
        fAmplitude: Single;
        fAttack: Single;
        fDecay: Single;
        fOutBuffer: specialize TArray<Int16>;

        procedure ApplyAttackDecay();

      public
        property SampleRate: Cardinal read fSampleRate;
        property BitDepth: Cardinal read fBitDepth;
        property Amplitude: Single read fAmplitude;
        property Attack: Single read fAttack;
        property Decay: Single read fDecay;

        class operator Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TPGLAudioGenerator);

        procedure SetAttack(AAttack: Single);
        procedure SetDecay(ADecay: Single);
        procedure SetAmplitdute(AAmplitude: Single);

        function GenSilence(AFrequency: Single; ALength: Single): specialize TArray<Int16>;
        function GenNoise(AFrequencyLow, AFrequencyHigh, AAmplitudeLow, AAmplitudeHigh: Single; ALength: Single): specialize TArray<Int16>;
        function GenSquareTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): specialize TArray<Int16>;
        function GenTriangleTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): specialize TArray<Int16>;
        function GenSawToothTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): specialize TArray<Int16>;
        function GenSineTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): specialize TArray<Int16>;
        function CombineData(AData1, AData2: specialize TArray<Int16>; ATrim: Boolean = False): specialize TArray<Int16>;

    end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundBuffer
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLSoundBuffer = ^TGEMSoundBuffer;
    TGEMSoundBuffer = class(TObject)
    private
      fIsValid: Boolean;
      fBuffer: TALUint;
      fLength: TALFloat;
      fName: String;

      constructor Create();


    public
      property IsValid: Boolean read fIsValid;
      property Buffer: TALUint read fBuffer;
      property Length: TALFloat read fLength;
      property Name: String read fName;

      procedure LoadDataFromFile(FileName: String; NameBuffer: String);  inline;
      procedure LoadDataFromMemory(ASource: Pointer; ASourceSize: Integer; AFrequency: Integer);  inline;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLMusicBuffer
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLMusicBuffer = ^TPGLMusicBuffer;
    TPGLMusicBuffer = class(TObject)
      private
        fState: TGEMSoundState;
        fIsValid: Boolean;
        fBuffers: Array [0..4] of TALUint;
        fQueued: Array [0..4] of Boolean;
        fSource: TALUint;
        fData: Pointer;
        fDataPos: Cardinal;
        fDataSize: Cardinal;
        fFormat: Integer;
        fFrequency: Cardinal;
        fBitsPerSample: TALInt;
        fChannels: TALInt;
        fPeriod: TALInt;
        fLength: TALFloat;
        fName: String;
        fSpeed: TALFloat;

        procedure Stream();

      public
        property IsValid: Boolean read fIsValid;
        property Data: Pointer read fData;
        property DataPos: Cardinal read fDataPos;
        property Length: TALFloat read fLength;
        property Name: String read fName;
        property Speed: TALFloat read fSpeed;

        constructor Create();

        procedure LoadDataFromFile(FileName: String; NameBuffer: String);  inline;

        procedure Play();
        procedure Pause();
        procedure Stop();
        procedure Resume();
        procedure GetData(out ADest: Pointer); overload;
        procedure GetData(out ADest: specialize TArray<Byte>); overload;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundSource
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    PPGLSoundSource = ^TGEMSoundSource;
    TGEMSoundSource = record
    private
      Source: TALUInt;
      fState: TGEMSoundState;

      fHasBuffer: Boolean; // is the buffer assigned?
      fBuffer: TGEMSoundBuffer;

      fisDynamic: Boolean;
      fGain: Single;
      fPosition: TGEMVec2;

      fHasPositionPointers: Boolean; // Are position pointer values set?
      fXPointer,fYPointer: PSingle; // Pointers to values to update from dynamically

      fHasVariablePitch: Boolean;
      fPitchRange: Array [0..1] of Single;
      fBaseFrequency: TALFloat;
      fCurrentFrequency: TALFLoat;

      fDirection: Single;
      fRadius: Single;
      fConeAngle: Single;
      fConeOuterGain: Single;
      fLooping: Boolean;
      fisPlaying: Boolean;

      procedure UpdateBufferPosition();
      procedure CheckHasBuffer();  inline;

    public
      Name: String;

      class operator Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TGEMSoundSource);

      // Properties
      property HasBuffer: Boolean read fHasBuffer;
      property Buffer: TGEMSoundBuffer read fBuffer;
      property isDynamic: Boolean read fisDynamic;
      property Gain: Single read fGain;
      property Position: TGEMVec2 read fPosition;
      property HasVariablePitch: Boolean read fHasVariablePitch;
      property Looping: Boolean read fLooping;
      property Direction: Single read fDirection;
      property Radius: Single read fRadius;
      property ConeAngle: Single read fConeAngle;
      property ConeOuterGain: Single read fConeOuterGain;
      property State: TGEMSoundState read fState;
      property isPlaying: Boolean read fisPlaying;

      // Setters
      procedure AssignBuffer(aBuffer: TGEMSoundBuffer); overload;  inline;
      procedure AssignBuffer(aBufferName: String); overload;  inline;
      procedure SetGain(Value: Single);  inline;
      procedure SetPosition(APosition: TGEMVec2);  inline;
      procedure SetPositionPointers(pX,pY: Pointer);  inline;
      procedure SetVariablePitch(LowRange,HighRange: Single);  inline;
      procedure SetFixedPitch(Value: Single);  inline;
      procedure SetLooping(Value: Boolean = True);  inline;
      procedure SetDirection(Angle: Single);  inline;
      procedure SetRadius(Distance: Single);  inline;
      procedure SetCone(Angle,aConeOuterGain: Single);  inline;
      procedure SetConeAngle(Angle: Single);  inline;
      procedure SetConeOuterGain(aGain: Single);  inline;
      procedure SetDynamic(Enable: Boolean = True);  inline;

      // Actions
      procedure ReleasePositionPointers();  inline;
      procedure UpdatePosition();  inline;
      procedure Play();  inline;
      procedure Stop();  inline;
      procedure Pause();
      procedure Resume();
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLSoundSlot
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


  type
    PPGLSoundSlot = ^TPGLSoundSlot;
    TPGLSoundSlot = record
    private
      SoundSource: ^TGEMSoundSource;
      Source: TALUint;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLListener
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    TPGLListener = class
    private
      fDirection: Single;
      fPosition: TGEMVec2;
      fVolume: TALFloat;

      listenerpos: array [0..2] of TALfloat;
      listenervel: array [0..2] of TALfloat;
      listenerdir: array [0..2] of TALfloat;

      constructor Create();

    public
      property Direction: TALFloat read fDirection;
      property Position: TGEMVec2 read fPosition;
      property Volume: TALFloat read fVolume;

      procedure SetPosition(APosition: TGEMVec2);
      procedure SetDirection(Angle: Single);
      procedure SetVolume(Value: Single);
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLSourceTemp
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    TSourceTemp = class
    public
      Name: String;
      source : TALuint;
      sourcepos: array [0..2] of TALfloat;
      sourcevel: array [0..2] of TALfloat;
      State: Paluint;
      Buffer: TALUint;
      SFreq: TALSizeI;

      constructor Create();
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundInstance
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  type
    TGEMSoundInstance = class
    private
      fVorbisSupport: Boolean;
      fEAXSupport: Boolean;
      fGlobalVolume: Single;
      fListener: TPGLListener;
      fDynamicSound: Boolean;
      fNotes: TGEMNotes;

      BufferCount: Integer;
      Buffers: Array of TGEMSoundBuffer;
      SourceCount: Integer;
      Sources: Array of ^TGEMSoundSource;
      Sounds: Array [0..100] of TPGLSoundSlot;
      CurrentSound: TALUint;
      CurrentMusic: TPGLMusicBuffer;
      TempSource: TGEMSoundSource;

      PauseCount: TALUInt;
      PauseList: Array of PPGLSoundSource;

      procedure PlaySound(var From: TGEMSoundSource);  inline;
      procedure StopSound(var From: TGEMSoundSource);  inline;

    public
      // Properties
      property VorbisSupport: Boolean read fVorbisSupport;
      property EAXSupport: Boolean read fEAXSupport;
      property GlobalVolume: Single read fGlobalVolume;
      property Listener: TPGLListener read fListener;
      property DyanmicSound: Boolean read fDynamicSound;
      property Notes: TGEMNotes read fNotes;

      constructor Create();
      Destructor Destroy(); override;
      procedure Update();

      // factories
      function GenSoundBuffer(var ABuffer: TGEMSoundBuffer; AName: String; AFileName: String): Boolean;

      // Setters
      procedure SetGlobalVolume(Value: Single);  inline;
      procedure SetDynamicSound(Enable: Boolean = True);  inline;
      procedure PlayFromBuffer(Buffer: TGEMSoundBuffer); Overload;
      procedure PlayFromBuffer(Buffer: TGEMSoundBuffer; APosition: TGEMVec2; Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single); Overload;
      procedure PauseAllPlaying();
      procedure ResumeAllPaused();

      // Getters
      function GetSoundBufferByName(ABufferName: String): TGEMSoundBuffer;
  end;



{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   Procedures
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  procedure AlGetErrorState();
  procedure ALClearErrors();
  function AlReturnError(): String;

  function pglLoadWaveFile(AFileName: String; var AData: TGEMAudioData): Boolean;

  procedure pglTrimAudioSilence(var ASource: specialize TArray<Int16>; AAmplitudeLimit: Single; ATrimLeft: Boolean = True; ATrimRight: Boolean = True);

  function pglConvertAudio(ASource: Pointer; ASourceSize, AOldSampleRate, AOldBitDepth, ANewSampleRate, ANewBitDepth: Cardinal): specialize TArray<Byte>;
  procedure pglConvertBitDepth8to16(var ASource: specialize TArray<Byte>);
  procedure pglConvertBitDepth16to8(var ASource: specialize TArray<Byte>);
  procedure pglConvertSampleRate(var ASource: specialize TArray<Byte>; AOldSampleRate, ANewSampleRate, ABitDepth: Cardinal);
  procedure pglConvertSampleRate8Bit(var ASource: specialize TArray<Byte>; AOldSampleRate, ANewSampleRate: Cardinal);
  procedure pglConvertSampleRate16Bit(var ASource: specialize TArray<Byte>; AOldSampleRate, ANewSampleRate: Cardinal);

  procedure pglGainTremolo(ASource: Pointer; ABitDepth, ASourceSize: Cardinal; AMinChange, AMaxChange: Single; AChangeFrequency: Cardinal);
  procedure pglBitCrush(ASource: Pointer; ASampleRate, ABitDepth, ASourceSize: Cardinal);

  function pglAudioFindPeriod(ASource: specialize TArray<Int16>): Cardinal;
  function pglTimeStretch(const InData: specialize TArray<Int16>; const InSampleRate, OutSampleRate: Integer; const StretchFactor: Double): specialize TArray<Int16>;


  procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint);  inline;
  procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);  inline;
  procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint);  inline;
  procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat);  inline;
  procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);  inline;
  procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat);  inline;

  procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint);  inline;
  procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);  inline;
  procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint);  inline;
  procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat);  inline;
  procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);  inline;
  procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat);  inline;

var
OpenALRunning: Boolean;
argv: array of PalByte;

ErrorState: TALuint;

format: TALEnum;
size: TALSizei;
freq: TALSizei;
loop: TALInt;
data: TALVoid;

SoundCount: NativeInt;
UtilitySource: TSourceTemp;

pglSound: TGEMSoundInstance;

implementation


constructor TGEMNotes.Create();
var
I: Integer;
NotePos, OctavePos: Integer;
LineVals: specialize TArray<String>;
SplitVals: specialize TArray<String>;
InFile: TextFile;
EXEPath: String;
  begin
    Inherited;

    EXEPath := ExtractFilePath(ParamStr(0));
    AssignFile(InFile, EXEPath + 'NoteFrequencies.dat');
    Reset(InFile);

    SetLength(LineVals,9 * 12);
    I := 0;

    while EOF(InFile) = False do begin
      ReadLn(InFile, LineVals[i]);
      Inc(I);
    end;

    CloseFile(InFile);

    NotePos := 0;
    OctavePos := 0;

    for I := 0 to High(LineVals) do begin
      SplitVals := SplitString(LineVals[i],',');
      Self.Note[OctavePos, NotePos] := SplitVals[1].ToSingle;

      Inc(NotePos);
      if NotePos > 11 then begin
        NotePos := 0;
        Inc(OctavePos);
      end;
    end;

  end;


function TGEMNotes.GetNoteOrdinal(ANote: String): Integer;
var
NoteOrd: Integer;
  begin
    Result := -1;

    NoteOrd := Ord(ANote.ToCharArray[0]) - 65;

    if InRange(NoteOrd,0,11) = False then begin
      Exit(-1);
    end;

    case NoteOrd of
      2: Result := 0;
      3: Result := 2;
      4: Result := 4;
      5: Result := 5;
      6: Result := 7;
      0: Result := 9;
      1: Result := 11;
    end;

  end;


function TGEMNotes.GetNoteFrequency(ANoteName: String): Single;
var
Octave: Integer;
NoteNum: Integer;
Chars: specialize TArray<Char>;
AdjVal: Integer;
  begin
    Result := 0;
    AdjVal := 0;

    Chars := ANoteName.ToCharArray;

    if Length(Chars) = 2 then begin
      Octave := String(Chars[1]).ToInteger;
      if InRange(Octave,0,8) = False then begin
        Exit(0);
      end;

      NoteNum := Self.GetNoteOrdinal(Chars[0]);
      if NoteNum = -1 then begin
        Exit(0);
      end;

    end else if Length(Chars) = 3 then begin

      Octave := String(Chars[1]).ToInteger;
      if InRange(Octave,0,8) = False then begin
        Exit(0);
      end;

      NoteNum := Self.GetNoteOrdinal(Chars[0]);
      if NoteNum = -1 then begin
        Exit(0);
      end;

      if Chars[1] = '#' then begin
        AdjVal := 1;
      end else if Chars[1] = 'b' then begin
        AdjVal := -1;
      end;

    end else begin
      Exit(0);

    end;

    NoteNum := NoteNum + AdjVal;
    if NoteNum > 11 then begin
      NoteNum := NoteNum - 12;
      Inc(Octave);
    end else if NoteNum < 0 then begin
      NoteNum := NoteNum - 12;
      Dec(Octave);
    end;

    if InRange(Octave,0,8) = False then begin
      Exit(0);
    end;

    Result := Self.Note[Octave, NoteNum];

  end;


function TGEMNotes.GetNoteFrequency(AOrdinal: Integer; AOctive: Cardinal): Single;
  begin
    Result := 1;

    while AOrdinal > 11 do begin
      Inc(AOctive,1);
      Dec(AOrdinal,12);
    end;

    while AOrdinal < 0 do begin
      Dec(AOctive,1);
      Inc(AOrdinal,12);
    end;

    if AOctive > 8 then Exit;

    Result := Self.Note[AOctive, AOrdinal];
  end;


constructor TPGLListener.Create();
Var
I: NativeInt;
  begin

    for I := 0 to 2 do begin
    self.listenerpos[i] := 0.0;
    self.listenervel[i] := 0.0;
    end;

    Self.fPosition := Vec2(0,0);
    Self.fDirection := 0;
    self.fVolume := 0;
  end;

constructor TSourceTemp.Create();
Var
I: NativeInt;

  begin

    Inherited Create();

    for i := 0 to 2 do
    begin

    self.sourcepos[i] := 0.0;
    self.sourcevel[i] := 0.0;

    end;

    AlGenSources(1,@Self.Source);
    AlSourcef ( self.source, AL_PITCH, 1.0 );
    AlSourcef ( self.source, AL_GAIN, 1.0 );
    AlSourcefv ( self.source, AL_POSITION, @self.sourcepos);
    AlSourcei ( self.source, AL_LOOPING, 0);
    AlSourcef(Self.Source, AL_MAX_GAIN,1);
    AlSourceF(Self.Source, AL_MIN_GAIN,0);

  end; // Create Source


constructor TGEMSoundInstance.Create();
Var
I: Integer;

  begin

    Inherited;

    pglSound := Self;

    InitOpenAL;
    AlutInit(nil,argv);
    OpenALRunning := True;

    SoundCount := 0;

    alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);

    Self.fListener := TPGLListener.Create();

    UtilitySource := TSourceTemp.Create();

    for I := 0 to 100 do begin
      AlGenSources(1, @Self.Sounds[i].Source);
      AlSourcei(Self.Sounds[i].Source, AL_LOOPING, AL_FALSE);
    end;

    Self.CurrentSound := 0;
    Self.BufferCount := 0;
    Self.SourceCount := 0;
    Self.fNotes := TGEMNotes.Create();

    //Self.fVorbisSupport := alIsExtensionPresent('AL_EXT_vorbis');
    //Self.fEAXSupport := alIsExtensionPresent('EAX2.0');
    //EAXSet := alGetProcAddress('EAXSet');
    //EAXGet := alGetProcAddress('EAXGet');
  end;


destructor TGEMSoundInstance.Destroy();
  begin
    Inherited;
  end;

function TGEMSoundInstance.GenSoundBuffer(var ABuffer: TGEMSoundBuffer; AName: string; AFileName: string): Boolean;
var
I: Integer;
  begin

    Result := False;

    if Assigned(ABuffer) = True then Exit;

    // check to see if other buffers have the same name
    for I := 0 to High(Self.Buffers) do begin
      if Self.Buffers[i].Name = AName then begin
        Exit;
      end;
    end;

    ABuffer := TGEMSoundBuffer.Create();
    ABuffer.LoadDataFromFile(AFileName, AName);

    // add to buffer list
    SetLength(Self.Buffers, Length(Self.Buffers) + 1);
    I := High(Self.Buffers);
    Self.Buffers[i] := ABuffer;
  end;


procedure TGEMSoundInstance.SetGlobalVolume(Value: Single);
  begin

    if Value > 1 then begin
      Value := 1;
    end Else if Value < 0 then begin
      Value := 0;
    end;

    Self.Listener.SetVolume(Value);
  end;


procedure TGEMSoundInstance.SetDynamicSound(Enable: Boolean = True);
  begin
    Self.fDynamicSound := Enable;
    if Enable = True then begin
      alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);
    end Else begin
      alDistanceModel(AL_NONE);
    end;
  end;


procedure TGEMSoundInstance.PlayFromBuffer(Buffer: TGEMSoundBuffer);
  begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(1);
    Self.TempSource.SetPosition(Self.Listener.Position);
    Self.TempSource.SetFixedPitch(1);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(0);
    self.TempSource.SetRadius(0);
    Self.TempSource.SetCone(Pi*2,1);
    Self.TempSource.Play();
  end;


procedure TGEMSoundInstance.PlayFromBuffer(Buffer: TGEMSoundBuffer; APosition: TGEMVec2; Radius,Direction,Gain,Pitch,ConeAngle,ConeOuterGain: Single);
  begin
    Self.TempSource.AssignBuffer(Buffer);
    Self.TempSource.SetGain(Gain);
    Self.TempSource.SetPosition(APosition);
    Self.TempSource.SetFixedPitch(Pitch);
    Self.TempSource.SetLooping(False);
    Self.TempSource.SetDirection(Direction);
    Self.TempSource.SetRadius(Radius);
    Self.TempSource.SetCone(ConeAngle,ConeOuterGain);
    Self.Playsound(Self.TempSource);
  end;


procedure TGEMSoundInstance.PauseAllPlaying();
// pause all sounds that are currently playing and add to resume list
var
I,R: TALUint;
  begin
    for I := 0 to High(Self.Sources) do begin
      if Self.Sources[i].fState = pgl_playing then begin

        R := Self.PauseCount;
        if R + 1 > Length(Self.PauseList) then begin
          SetLength(Self.PauseList, R + 1);
        end;

        Self.PauseList[R] := @Self.Sources[i].Source;
        Self.Sources[r].Pause();

        Inc(Self.PauseCount);

      end;
    end;
  end;


procedure TGEMSoundInstance.ResumeAllPaused();
// resume all sounds from pause list, clear pause list
var
I,R: TALUint;
  begin
    for I := 0 to Self.PauseCount - 1 do begin
      Self.PauseList[i].Play;
      Self.PauseList[i] := nil;
    end;

    Self.PauseCount := 0;
  end;


function TGEMSoundInstance.GetSoundBufferByName(ABufferName: String): TGEMSoundBuffer;
var
I: Integer;
  begin
    Result := nil;
    for I := 0 to High(Self.Buffers) do begin
      if Self.Buffers[i].Name = ABufferName then begin
        Result := Self.Buffers[i];
      end;
    end;
  end;

procedure TGEMSoundInstance.PlaySound(Var From: TGEMSoundSource);
Var
CurSound: ^TPGLSoundSlot;
Dist: Single;
Angle: Single;
GainChange: Single;
DX,DY: Single;

  begin

    CurSound := @Self.Sounds[Self.CurrentSound];
    CurSound.SoundSource := @From;
    alSourceStop(CurSound.Source);

    pglSourcei(CurSound.Source, AL_BUFFER, From.Buffer.Buffer);

    // use source properties if dynamic sound is enabled
    if (From.isDynamic = True) and (Self.DyanmicSound = True) then begin

      pglSource3f(CurSound.Source,AL_POSITION, From.Position.X, From.Position.Y, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, From.Radius);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, From.Radius / 4);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 5);

      DX := 1 * Cos(From.Direction);
      DY := 1 * Sin(From.Direction);

      alSource3f(CurSound.Source, AL_DIRECTION, DX,DY,0);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE,From.ConeAngle);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE,0);
      alSourcef(Cursound.Source, AL_CONE_OUTER_GAIN,From.ConeOuterGain);

    end Else begin

      pglSource3f(CurSound.Source, AL_POSITION, Self.Listener.Position.X, Self.Listener.Position.Y, 0);
      pglSourceF(CurSound.Source, AL_MAX_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_REFERENCE_DISTANCE, 0);
      pglSourceF(CurSound.Source, AL_ROLLOFF_FACTOR, 1);

      alSourcef(CurSound.Source, AL_CONE_OUTER_ANGLE, 360);
      alSourcef(CurSound.Source, AL_CONE_INNER_ANGLE, 260);
      alSourcef(CurSound.Source, AL_CONE_OUTER_GAIN, 1);

    end;

    if From.HasVariablePitch = False then begin
      AlSourcef(CurSound.Source, AL_PITCH,From.fPitchRange[0]);
    end Else begin
      AlSourcef(CurSound.Source, AL_PITCH, From.fPitchRange[1] * Random());
    end;

    if From.Looping = True then begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_TRUE);
    end Else begin
      AlSourceI(CurSound.Source,AL_LOOPING, AL_FALSE);
    end;

    AlSourcePlay(CurSound.Source);

    Self.CurrentSound := Self.CurrentSound + 1;
      if Self.CurrentSound > 100 then begin
        Self.CurrentSound := 0;
      end;

    Exit
  end;


procedure TGEMSoundInstance.StopSound(var From: TGEMSoundSource);

Var
CurSound: ^TPGLSoundSlot;
I: Integer;
ReturnVal: TALint;

  begin

    for I := 0 to 100 do begin

      CurSound := @Self.Sounds[i];
      AlGetSourcei(Cursound.Source,AL_SOURCE_STATE,@ReturnVal);

      if ReturnVal = AL_PLAYING then begin
        if CurSound.SoundSource = @From then begin
          AlSourceStop(CurSound.Source);
        end;
      end;

    end;

  end;


procedure TGEMSoundInstance.Update();
var
I: Integer;
P: TALInt;
  begin

    for I := 0 to High(pglSound.Sources) do begin

      alGetSourceI(pglSound.Sources[i]^.Source, AL_SOURCE_STATE, @pglSound.Sources[i].fState);

      if pglSound.Sources[i].fState = TGEMSoundState.pgl_playing then begin
        pglSound.Sources[i].fisPlaying := True;
      end else begin
        pglSound.Sources[i].fisPlaying := False;
      end;

      // update position for pointers
      if pglSound.Sources[i].fHasPositionPointers then begin
        pglSound.Sources[i].UpdatePosition();
      end;

    end;

    if Self.CurrentMusic <> nil then begin
      alGetSourceI(Self.CurrentMusic.fSource, AL_SOURCE_STATE, @pglSound.CurrentMusic.fState);
      alSource3f(Self.CurrentMusic.fSource, AL_POSITION, Self.Listener.Position.X, Self.Listener.Position.Y, 0);
      Self.CurrentMusic.Stream();
    end;

  end;

procedure ALClearErrors();
  begin
    AlGetError();
    ErrorState := 0;
  end;

procedure AlGetErrorState();
  begin
    ErrorState := AlGetError();
      if ErrorState <> AL_NO_ERROR then begin
        AlReturnError();
      end;
  end;


function AlReturnError(): String;
  begin

    Case ErrorState of

      AL_NO_ERROR : Result := 'No Error!';

      AL_INVALID_NAME : Result := 'Invalid Name';

      AL_INVALID_ENUM : Result := 'Invalid Enum Value';

      AL_INVALID_VALUE : Result := 'Invalid Value Passed';

      AL_INVALID_OPERATION : Result := 'Invalid Operation';

      AL_OUT_OF_MEMORY : Result := 'Out Of Memory';

    end;

  end;


procedure TPGLListener.SetPosition(APosition: TGEMVec2);
Var
Orr: Array [0..5] of Single;
I: Integer;
  begin
    Self.fPosition := APosition;
    Self.listenerpos[0] := APosition.X;
    Self.listenerpos[1] := APosition.Y;
    Self.listenerpos[2] := 0;
    AlListenerfv(AL_POSITION,@Self.listenerpos);

    Orr[0] := 0;
    Orr[1] := 1;
    Orr[2] := 1;
    Orr[3] := 0;
    Orr[4] := 0;
    Orr[5] := 1;

    alListenerfv(AL_ORIENTATION,@Orr);

    // move music source with listener
    if pglSound.CurrentMusic <> nil then begin
      alSource3f(pglSound.CurrentMusic.fSource, AL_POSITION, APosition.X, APosition.Y, 0);
    end;

    // move non-dynamic sounds with listener
    for I := 0 to High(pglSound.Sources) do begin
      if pglSound.Sources[i].State = TGEMSoundState.pgl_playing then begin
        if pglSound.Sources[i].isDynamic = False then begin
          alSource3f(pglSound.Sources[i].Source, AL_POSITION, APosition.X, APosition.Y, 0);
        end;
      end;
    end;

  end;

procedure TPGLListener.SetDirection(Angle: Single);
Var
X,Y: Single;
  begin
    X := 1 * Cos(Angle);
    Y := 1 * Sin(Angle);
    Self.listenerdir[0] := X;
    Self.listenerdir[1] := Y;
  end;


procedure TPGLListener.SetVolume(Value: Single);
  begin
    Self.fVolume := Value;
    if Self.Volume < 0 then Self.fVolume := 0;
    if Self.Volume > 1 then Self.fVolume := 1;
    alListenerf(AL_GAIN,Self.Volume);
  end;


class operator TGEMWaveHeader.Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TGEMWaveHeader);
var
WriteChars: Array [0..3] of AnsiChar;
  begin

    // write 'RIFF' to RIFF field
    WriteChars[0] := 'R';
    WriteChars[1] := 'I';
    WriteChars[2] := 'F';
    WriteChars[3] := 'F';
    Move(WriteChars[0], Dest.RIFF, 4);

    // Initialize FILE_SIZE to 0, fill in later
    Dest.FILE_SIZE := 0;

    // write 'WAVE' AnsiString WAVE field
    WriteChars[0] := 'W';
    WriteChars[1] := 'A';
    WriteChars[2] := 'V';
    WriteChars[3] := 'E';
    Move(WriteChars[0], Dest.WAVE, 4);

    // write 'fmt ' to FMT field
    Dest.FMT := 544501094;

    // format section length always 16
    Dest.RIFF_SIZE := (16);

    // format type always 1 for PCM data
    Dest.AUDIO_FORMAT := (1);;

    // channel count always 1 for now
    Dest.CHANNELS := (1);

    // Initialize sample rate, Bits for second and Bits per sample to 0, fill in later
    Dest.SAMPLE_RATE := 0;

    Dest.BYTES_PER_SECOND := 0;

    Dest.BITS_PER_SAMPLE := 0;

    // write 'data' to DATA_SECTION field
    WriteChars[0] := 'd';
    WriteChars[1] := 'a';
    WriteChars[2] := 't';
    WriteChars[3] := 'a';
    Move(WriteChars[0], Dest.DATA_HEADER, 4);

    // Initialize data size to 0, fill in later
    Dest.DATA_SIZE := 0;

  end;


procedure TGEMWaveHeader.Fill(AAudioFormat, AChannels: WORD; ASampleRate, ADataSize: DWord);
  begin
    Self.AUDIO_FORMAT := (AAudioFormat);
    Self.CHANNELS := (AChannels);
    Self.SAMPLE_RATE := (ASampleRate);
    Self.DATA_SIZE := (ADataSize);
    Self.BYTES_PER_SECOND := (ASampleRate * Cardinal(Self.BLOCK_ALIGN));
    Self.BITS_PER_SAMPLE := (8 * Self.BLOCK_ALIGN);
    Self.FILE_SIZE := (ADataSize + 36);
  end;


procedure TGEMWaveHeader.Fill(ASource: Pointer);
var
WPtr: PWORD;
DPtr: PDWORD;
  begin
    Move(ASource^, Self.Riff, 44);
  end;


function TGEMWaveHeader.CheckValid(): Boolean;
var
CheckChars: Array [0..3] of AnsiChar;
  begin

    Result := False;

    // check that all text label values are correct

    Move(Self.RIFF, CheckChars, 4);
    if CheckChars <> 'RIFF' then begin
      Exit;
    end;

    Move(Self.WAVE, CheckChars, 4);
    if CheckChars <> 'WAVE' then begin
      Exit;
    end;

    Move(Self.FMT, CheckChars, 4);
    if CheckChars <> 'fmt ' then begin
      Exit;
    end;

    Move(Self.DATA_HEADER, CheckChars, 4);
    if CheckChars <> 'data' then begin
      Exit;
    end;

    Result := True;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMAudioData
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

procedure TGEMAudioData.Configure(ASampleRate, ABitDepth, AChannels: Cardinal);
  begin
    Self.fHeaderinfo.SAMPLE_RATE := ASampleRate;
    Self.fHeaderinfo.BLOCK_ALIGN := trunc(ABitDepth / 8);
    Self.fHeaderinfo.CHANNELS := AChannels;
    Self.fHeaderInfo.BYTES_PER_SECOND := ASampleRate * trunc(ABitDepth / 8);
    Self.fHeaderInfo.BITS_PER_SAMPLE := ABitDepth;
  end;

function TGEMAudioData.GetSize(): Int64;
  begin
    Result := Length(Self.fBuffer) * 2;
  end;

function TGEMAudioData.GetSamples(): Cardinal;
  begin
    Result := trunc(Length(Self.Buffer) / Self.BitDepth);
  end;

function TGEMAudioData.GetBitDepth: SmallInt;
  begin
    Result := Self.fHeaderInfo.BLOCK_ALIGN * 8;
  end;

procedure TGEMAudioData.UpdateDuration();
  begin
    Self.fDuration := (Self.GetSize / 2) / Self.SampleRate;
    Self.fHeaderInfo.DATA_SIZE := Length(Self.fBuffer) * Self.fHeaderInfo.BLOCK_ALIGN;
    Self.fHeaderInfo.FILE_SIZE := Self.fHeaderInfo.DATA_SIZE + 36;
  end;

procedure TGEMAudioData.SetSampleRate(ASampleRate: Cardinal);
  begin
    Self.fHeaderInfo.SAMPLE_RATE := ASampleRate;
  end;

procedure TGEMAudioData.SetBitDepth(ABitDepth: Int16);
  begin
    if (ABitDepth <> 8) and (ABitDepth <> 16) then Exit;
    if ABitDepth = Self.BitDepth then Exit;

    Self.fHeaderInfo.BLOCK_ALIGN := trunc(ABitDepth / 8);
  end;

procedure TGEMAudioData.SetChannels(AChannels: Cardinal);
  begin
    Self.fHeaderInfo.CHANNELS := AChannels;
  end;

procedure TGEMAudioData.ClearBuffer();
  begin
    SetLength(Self.fBuffer, 0);
    Self.fDuration := 0;
  end;

procedure TGEMAudioData.FillBuffer(ASource: Pointer; ASourceSize, ASourceSampleRate, ASourceBitDepth: Cardinal);
  begin
    if (Self.SampleRate = ASourceSampleRate) and (Cardinal(Self.BitDepth) = ASourceBitDepth) then begin
      if Length(Self.fBuffer) > 0 then begin
        Self.ClearBuffer();
      end;

      SetLength(Self.fBuffer, trunc(ASourceSize / 2));
      Move(ASource^, Self.fBuffer[0], ASourceSize);
      Self.UpdateDuration();
    end;
  end;

procedure TGEMAudioData.AppendBuffer(ASource: specialize TArray<Int16>);
  begin
    Insert(ASource, Self.fBuffer, Length(Self.fBuffer));
    Self.UpdateDuration();
  end;

procedure TGEMAudioData.InsertBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal);
var
Tail: specialize TArray<Int16>;
TailLength: Cardinal;
  begin
    TailLength := Length(Self.fBuffer) - ASamplePosition;
    SetLength(Tail, TailLength);
    Move(Self.fBuffer[ASamplePosition], Tail[0], TailLength * 2);

    SetLength(Self.fBuffer, ASamplePosition);
    Insert(ASource, Self.fBuffer, Length(Self.fBuffer));
    Insert(Tail, Self.fBuffer, Length(Self.fBuffer));

    Self.UpdateDuration();
  end;

procedure TGEMAudioData.InsertBuffer(ASource: specialize TArray<Int16>; APosition: Single);
var
SamplePos: Cardinal;
Per: Single;
  begin
    Per := APosition / Self.Duration;
    SamplePos := trunc(Length(Self.fBuffer) * Per);
    Self.InsertBuffer(ASource, SamplePos);
  end;


procedure TGEMAudioData.PasteBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal);
var
SampleEnd: Cardinal;
PasteLength: Cardinal;
NewLength: Cardinal;
  begin

    if ASamplePosition > High(Self.fBuffer) then Exit;

    PasteLength := Length(ASource);

    NewLength := ASamplePosition + PasteLength;
    if NewLength > Length(Self.fBuffer) then begin
      SetLength(Self.fBuffer, NewLength);
    end;

    Move(ASource[0], Self.fBuffer[ASamplePosition], PasteLength * 2);

    Self.UpdateDuration();

  end;


procedure TGEMAudioData.PasteBuffer(ASource: specialize TArray<Int16>; ATimePosition: Single);
var
SamplePos: Cardinal;
Per: Single;
  begin
    Per := ATimePosition / Self.Duration;
    SamplePos := trunc(Length(Self.fBuffer) * Per);
    Self.PasteBuffer(ASource, SamplePos);
  end;


procedure TGEMAudioData.DeleteBuffer(ASampleStart, ASampleEnd: Cardinal);
var
DelEnd, DelLength: Cardinal;
  begin

    if ASampleStart > High(Self.fBuffer) then Exit;

    DelEnd := ASampleEnd;
    if DelEnd > High(Self.fBuffer) then DelEnd := High(Self.fBuffer);

    DelLength := (DelEnd - ASampleStart) + 1;

    Delete(Self.fBuffer, ASampleStart, DelLength);

    Self.UpdateDuration();

  end;

procedure TGEMAudioData.DeleteBuffer(ATimeStart, ATimeEnd: Single);
var
StartPos, EndPos: Cardinal;
Per: Single;
  begin
    Per := ATimeStart / Self.Duration;
    Startpos := trunc(Length(Self.fBuffer) * Per);

    Per := ATimeEnd / Self.Duration;
    EndPos := trunc(Length(Self.fBuffer) * Per);

    Self.DeleteBuffer(StartPos, Endpos);
  end;

procedure TGEMAudioData.CombineBuffer(ASource: specialize TArray<Int16>; ASamplePosition: Cardinal);
var
I: Integer;
NewLength: Integer;
SPos, DPos: Integer;
WriteVal: Integer;
  begin

    // exit if sample position passed end of buffer
    if ASamplePosition > High(Self.fBuffer) then Exit;

    // resize buffer if needed
    NewLength := 0;
    if ASamplePosition + Length(ASource) > Length(Self.fBuffer) then begin
      NewLength := ASamplePosition + Length(ASource);
      SetLength(Self.fBuffer, NewLength);
    end;

    SPos := 0;

    for I := ASamplePosition to High(Self.fBuffer) do begin

      WriteVal := Self.fBuffer[i] + ASource[SPos];
      if WriteVal > High(Int16) then WriteVal := High(Int16);
      if WriteVal < Low(Int16) then WriteVal := Low(Int16);

      Self.fBuffer[I] := WriteVal;

      Inc(SPos);

    end;


    if NewLength <> 0 then begin
      Self.UpdateDuration();
    end;

  end;

procedure TGEMAudioData.CombineBuffer(ASource: specialize TArray<Int16>; ATimePosition: Single);
var
Per: Single;
SamplePos: Cardinal;
  begin

    // get the perctange value of the position into the length of the buffer in time
    Per := ATimePosition / Self.fDuration;
    if Per >= 1 then begin
      Exit;
    end;

    // convert percentage into position in buffer array
    SamplePos := trunc(Length(Self.fBuffer) * Per);

    Self.CombineBuffer(ASource, Cardinal(SamplePos));

  end;


procedure TGEMAudioData.ReverseBuffer(ASampleStart, ASampleEnd: Cardinal);
var
I: Integer;
SPtr, EPtr: PSmallInt;
SPos, EPos: Cardinal;
TempVal: Int16;
  begin
    SPos := ASampleStart;
    EPos := ASampleEnd;

    while EPos - SPos > 1 do begin
      SPtr := @Self.fBuffer[SPos];
      EPtr := @Self.fBuffer[Epos];
      TempVal := Sptr[0];
      Sptr[0] := EPtr[0];
      EPtr[0] := TempVal;
      Inc(Spos);
      Dec(EPos);
    end;

  end;


procedure TGEMAudioData.ReverseBuffer(ATimeStart, ATimeEnd: Single);
var
SampleStart, SampleEnd: Cardinal;
Per: Single;
  begin

    Per := ATimeStart / Self.Duration;
    SampleStart := trunc(Length(Self.fBuffer) * Per);

    Per := ATimeEnd / Self.Duration;
    SampleEnd := trunc(Length(Self.fBuffer) * Per);

    Self.ReverseBuffer(SampleStart, SampleEnd);

  end;

procedure TGEMAudioData.TrimSilence(AAmplitudeLimit: Single; ATrimLeft: Boolean = True; ATrimRight: Boolean = True);
  begin
    pglTrimAudioSilence(Self.fBuffer, AAmplitudeLimit, ATrimLeft, ATrimRight);
    Self.UpdateDuration();
  end;


procedure TGEMAudioData.SpeedUp();
var
I: Integer;
NewData: specialize TArray<Int16>;
NewDataSize: Int64;
NewPos: Integer;
Per: Single;
PerCount: Integer;
  begin

    Per := 0.9;
    NewDataSize := trunc(Length(Self.fBuffer) * Per);
    SetLength(NewData, NewDataSize);

    NewPos := 0;
    PerCount := 0;
    I := 0;

    while I < high(Self.fBuffer) - 1 do begin

      NewData[NewPos] := Self.fBuffer[i];
      Inc(I);
      Inc(Percount);

      if PerCount >= ((1-Per) * 100) - 1 then begin
        PerCount := 0;
      end else begin
        Inc(NewPos);
      end;

      if NewPos > High(NewData) then Break;

    end;

    Self.fBuffer := NewData;
    Self.UpdateDuration();

  end;


procedure TGEMAudioData.CopyFrom(var ASource: TGEMAudioData; AStartSample, AEndSample: Cardinal);
var
CopyLength: Cardinal;
CopyEnd: Cardinal;
I: Integer;
WritePos: Integer;
  begin

    if AStartSample > High(ASource.fBuffer) then begin
      Exit;
    end;

    CopyEnd := AEndSample;
    if CopyEnd > High(ASource.fBuffer) then begin
      CopyEnd := High(ASource.fBuffer);
    end;

    CopyLength := CopyEnd - AStartSample;
    SetLength(Self.fBuffer, CopyLength);
    WritePos := 0;

    for I := AStartSample to CopyEnd do begin
      Self.fBuffer[WritePos] := ASource.fBuffer[I];
      Inc(WritePos);
    end;

    Self.fHeaderInfo := ASource.fHeaderInfo;

  end;


procedure TGEMAudioData.CopyFrom(var ASource: TGEMAudioData; AStartTime, AEndTime: Single);
var
SampleStart, SampleEnd: Cardinal;
Per: Single;
  begin

    Per := AStartTime / Self.Duration;

    SampleStart := trunc(Length(Self.fBuffer) * Per);

    Per := AEndTime / Self.Duration;
    SampleEnd := trunc(Length(Self.fBuffer) * Per);

    Self.CopyFrom(ASource, SampleStart, SampleEnd);

  end;


procedure TGEMAudioData.NormalizeGain();
var
HighGain, LowGain, MidGain: Int16;
ChangeDiff: Single;
I: Integer;
  begin

    HighGain := 0;
    LowGain := 0;

    for I := 0 to High(Self.fBuffer) do begin
      if Abs(Self.fBuffer[i]) > HighGain then HighGain := Abs(Self.fBuffer[i]);
      if Abs(Self.fBuffer[i]) < LowGain then LowGain := Abs(Self.fBuffer[i]);
    end;

    MidGain := LowGain + trunc((HighGain - LowGain) / 2);
    ChangeDiff := MidGain / High(Int16);

    for I := 0 to High(Self.fBuffer) do begin
      Self.fBuffer[i] := trunc(Self.fBuffer[i] * ChangeDiff);
    end;

  end;


function TGEMAudioData.GetSlice(AStartTime, AEndTime: Single): specialize TArray<Int16>;
var
SampleStart, SampleEnd: Cardinal;
Per: Single;
  begin

    Per := AStartTime / Self.Duration;
    SampleStart := trunc(Length(Self.fBuffer) * Per);

    Per := AEndTime / Self.Duration;
    SampleEnd := trunc(Length(Self.fBuffer) * Per);

    Result := Self.GetSlice(SampleStart, SampleEnd);

  end;


function TGEMAudioData.GetSlice(ASampleStart, ASampleEnd: Cardinal): specialize TArray<Int16>;
var
I: Integer;
WritePos: Integer;
CopyLength, CopyEnd: Cardinal;
  begin

    if ASampleStart > High(Self.fBuffer) then Exit;

    CopyEnd := ASampleEnd;
    if CopyEnd > High(Self.fBuffer) then CopyEnd := High(Self.fBuffer);

    CopyLength := CopyEnd - ASampleStart;
    SetLength(Result, CopyLength + 1);

    WritePos := 0;

    for I := ASampleStart to CopyEnd do begin
      Result[WritePos] := Self.fBuffer[I];
      Inc(WritePos);
    end;

  end;


procedure TGEMAudioData.AdjustGain(APercent: Single);
var
I: Integer;
WriteVal: Integer;
  begin
    for I := 0 to High(Self.fBuffer) do begin
      WriteVal := trunc(Self.fBuffer[i] * APercent);
      if WriteVal > High(Int16) then WriteVal := High(Int16);
      If WriteVal < Low(Int16) then WriteVal := Low(Int16);
      Self.fBuffer[i] := WriteVal;
    end;
  end;

procedure TGEMAudioData.MaxAmplifyNoClip(ASampleStart, ASampleEnd: Cardinal);
var
I: Integer;
MaxGain: Integer;
Per: Single;
SamPer: Single;
  begin

    MaxGain := 0;
    for I := 0 to High(Self.fBuffer) do begin
      if Abs(Self.fBuffer[i]) > MaxGain then MaxGain := Abs(Self.fBuffer[i]);
    end;

    Per := MaxGain / High(Int16);

    for I := 0 to High(Self.fBuffer) do begin
      SamPer := Self.fBuffer[i] / MaxGain;
      Self.fBuffer[i] := trunc(Self.fBuffer[i] * ((1 / Per) * (1 / SamPer)));
    end;

  end;

procedure TGEMAudioData.MaxAmplifyNoClip(ATimeStart, ATimeEnd: Single);
var
SampleStart, SampleEnd: Cardinal;
Per: Single;
  begin

    Per := ATimeStart / Self.Duration;
    SampleStart := trunc(Length(Self.fBuffer) * Per);

    Per := ATimeEnd / Self.Duration;
    SampleEnd := trunc(Length(Self.fBuffer) * Per);

    Self.MaxAmplifyNoClip(SampleStart, SampleEnd);

  end;

procedure TGEMAudioData.AdjustBass(APercentage: Single);
var
I: Integer;
WriteVal: Integer;
  begin

    if Length(Self.fBuffer) = 0 then Exit;

    for I := 0 to High(Self.fBuffer) do begin
      if Self.fBuffer[i] < 0 then begin
        WriteVal := trunc(Self.fBuffer[i] * APercentage);
        if WriteVal < Low(Int16) then WriteVal := Low(Int16);
      end else begin
        WriteVal := Self.fBuffer[i];
      end;

      Self.fBuffer[i] := WriteVal;
    end;


  end;

procedure TGEMAudioData.AddReverb(AReverbLength: Single);
  begin

    Self.UpdateDuration();

  end;


procedure TGEMAudioData.GainFade(ASampleStart, ASampleEnd: Cardinal; AGainStart, AGainEnd: Single);
var
I: Integer;
WriteVal: Integer;
CurGain: Single;
GainStep: Single;
  begin

    if ASampleEnd > High(Self.fBuffer) then Exit;
    if ASampleEnd > High(Self.fBuffer) then ASampleEnd := High(Self.fBuffer);

    CurGain := AGainStart;
    GainStep := (AGainEnd - AGainStart) / (ASampleEnd - ASampleStart);

    for I := ASampleStart to ASampleEnd do begin
      WriteVal := trunc(Self.fBuffer[I] * CurGain);
      if WriteVal > High(Int16) then WriteVal := High(Int16);
      if WriteVal < Low(Int16) then WriteVal := Low(Int16);
      Self.fBuffer[I] := WriteVal;
      CurGain := CurGain + GainStep;
    end;

  end;


procedure TGEMAudioData.GainFade(ATimeStart, ATimeEnd: Single; AGainStart, AGainEnd: Single);
var
SampleStart, SampleEnd: Cardinal;
Per: Single;
  begin

    Per := ATimeStart / Self.Duration;
    SampleStart := trunc(Length(Self.fBuffer) * Per);

    Per := ATimeEnd / Self.Duration;
    SampleEnd := trunc(Length(Self.fBuffer) * Per);

    Self.GainFade(SampleStart, SampleEnd, AGainStart, AGainEnd);

  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TPGLAudioGenerator
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

class operator TPGLAudioGenerator.Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TPGLAudioGenerator);
  begin
    Dest.fAmplitude := 0.8;
    Dest.fAttack := 0;
    Dest.fDecay := 1;
    Dest.fSampleRate := 44100;
    Dest.fBitDepth := 16;
  end;

procedure TPGLAudioGenerator.ApplyAttackDecay();
var
I: Integer;
SPos,EPos: Integer;
CurGain: Single;
GainStep: Single;
  begin

    // attack
    SPos := 0;
    EPos := trunc(High(Self.fOutBuffer) * Self.fAttack);

    CurGain := 0;
    GainStep := Self.fAmplitude / (EPos - SPos);

    for I := SPos to EPos do begin
      Self.fOutBuffer[i] := trunc(Self.fOutBuffer[i] * CurGain);
      CurGain := CurGain + GainStep;
    end;

    // decay
    SPos := trunc(High(Self.fOutBuffer) * Self.Decay);
    EPos := High(Self.fOutBuffer);

    CurGain := Self.fAmplitude;
    GainStep := Self.fAmplitude / (EPos - SPos);

    for I := SPos to EPos do begin
      Self.fOutBuffer[i] := trunc(Self.fOutBuffer[i] * CurGain);
      CurGain := CurGain - GainStep;
    end;

  end;


procedure TPGLAudioGenerator.SetAttack(AAttack: Single);
  begin
    Self.fAttack := AAttack;
    if Self.fAttack < 0 then Self.fAttack := 0;
    if Self.fAttack > 1 then Self.fAttack := 1;
    if Self.fAttack > Self.fDecay then Self.fDecay := Self.fAttack;
  end;

procedure TPGLAudioGenerator.SetDecay(ADecay: Single);
  begin
    Self.fDecay := ADecay;
    if Self.fDecay < 0 then Self.fDecay := 0;
    if Self.fDecay > 1 then Self.fDecay := 1;
    if Self.fDecay < Self.fAttack then Self.fAttack := Self.fDecay;
  end;

procedure TPGLAudioGenerator.SetAmplitdute(AAmplitude: Single);
  begin
    Self.fAmplitude := AAmplitude;
    if Self.fAmplitude < 0 then Self.fAmplitude := 0;
    if Self.fAmplitude > 1 then Self.fAmplitude := 1;
  end;

function TPGLAudioGenerator.GenSilence(AFrequency: Single; ALength: Single): specialize TArray<Int16>;
var
DataLength: Integer;
  begin
    DataLength := trunc((AFrequency * 2) * ALength);
    SetLength(Result, DataLength);
    FillByte(Result[0], DataLength, 0);
  end;

function TPGLAudioGenerator.GenNoise(AFrequencyLow, AFrequencyHigh, AAmplitudeLow, AAmplitudeHigh: Single; ALength: Single): specialize TArray<Int16>;
var
WriteVal: Int16;
I,A: Integer;
NoiseBuffer: specialize TArray<Int16>;
FRange: Single;
FTarget: Integer;
ARange: Single;
SampleCount: Integer;
S: Integer;
  begin
    SetLength(Self.fOutBuffer, trunc(Self.fSampleRate * ALength));

    FRange := AFrequencyHigh - AFrequencyLow;
    FTarget := trunc(Self.SampleRate /  (AFrequencyLow + (FRange * Random())));

    ARange := AAmplitudeHigh - AAmplitudeLow;

    WriteVal := trunc(High(Int16) * (AAmplitudeLow + (ARange * Random())));
    S := 1;

    SampleCount := 0;

    for I := 0 to High(Self.fOutBuffer) do begin

      Self.fOutBuffer[i] := WriteVal;

      Inc(SampleCount);
      if SampleCount >= FTarget then begin
        SampleCount := 0;
        WriteVal := -WriteVal;
        FTarget := trunc(Self.SampleRate /  (AFrequencyLow + (FRange * Random())));
        S := -S;
        WriteVal := trunc(High(Int16) * (AAmplitudeLow + (ARange * Random()))) * S;
      end;

    end;


    Self.ApplyAttackDecay();
    Result := Self.fOutBuffer;

  end;

function TPGLAudioGenerator.GenSquareTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): specialize TArray<Int16>;
var
I: Integer;
WriteVal: Integer;
SampleCount: Integer;
WaveLength: Integer;
HighVal, LowVal: Int16;
  begin

    SetLength(Self.fOutBuffer, trunc(44100 * ALength));

    HighVal := trunc(High(Int16) * Self.Amplitude);
    LowVal := trunc(Low(Int16) * Self.Amplitude);

    WriteVal := HighVal;
    SampleCount := 0;
    WaveLength := trunc(44100 / AFrequency);

    for I := 0 to High(Self.fOutBuffer) do begin
      Self.fOutBuffer[i] := WriteVal;

      Inc(SampleCount);
      if SampleCount >= WaveLength then begin
        SampleCount := 0;
        WriteVal := -WriteVal;
      end;

    end;

    Self.ApplyAttackDecay();
    Result := Self.fOutBuffer;
  end;


function TPGLAudioGenerator.GenTriangleTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): TArray<Int16>;
var
I: Integer;
WriteVal: Integer;
SampleCount: Integer;
WaveLength: Integer;
WriteHigh,WriteLow: Integer;
StepVal: Single;
StepDir: Integer;
  begin
    SetLength(Self.fOutBuffer, trunc(44100 * ALength));

    WriteVal := APhaseStart;
    WriteHigh := trunc(High(Int16) * Self.fAmplitude);
    WriteLow := trunc(-High(Int16) * Self.fAmplitude);;

    SampleCount := 0;
    WaveLength := trunc((44100 / AFrequency) / 2);

    StepVal := (Abs(WriteHigh) + Abs(WriteLow)) / WaveLength;
    StepDir := -1;

    for I := 0 to High(Self.fOutBuffer) do begin

      Self.fOutBuffer[i] := WriteVal;

      WriteVal := trunc(WriteVal + (StepVal * StepDir));

      if (WriteVal <= WriteLow) and (StepDir = -1) then begin
        StepDir := StepDir * -1;
        WriteVal := WriteLow;

      end else if (WriteVal >= WriteHigh) and (StepDir = 1) then begin
        StepDir := StepDir * -1;
        WriteVal := WriteHigh;
      end;

    end;

    Self.ApplyAttackDecay();
    Result := Self.fOutBuffer;

  end;


function TPGLAudioGenerator.GenSawToothTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): TArray<Int16>;
var
I: Integer;
WriteVal: Integer;
SampleCount: Integer;
WaveLength: Integer;
WriteHigh,WriteLow: Integer;
StepVal: Single;
StepDir: Integer;
  begin
    SetLength(Self.fOutBuffer, trunc(44100 * ALength));

    WriteVal := APhaseStart;
    WriteHigh := trunc(High(Int16) * Self.fAmplitude);
    WriteLow := trunc(-High(Int16) * Self.fAmplitude);;

    SampleCount := 0;
    WaveLength := trunc(44100 / AFrequency) * 2;
    StepVal := (Abs(WriteHigh) + Abs(WriteLow)) / WaveLength;
    StepDir := -1;

    for I := 0 to High(Self.fOutBuffer) do begin

      Self.fOutBuffer[i] := WriteVal;

      WriteVal := trunc(WriteVal + (StepVal * StepDir));
      if WriteVal < WriteLow then begin
        WriteVal := WriteHigh;
      end;

    end;

    Self.ApplyAttackDecay();
    Result := Self.fOutBuffer;

  end;


function TPGLAudioGenerator.GenSineTone(AFrequency: Single; ALength: Single; APhaseStart: Integer = 0): TArray<Int16>;
var
Phase: Integer;
T: Double;
DeltaT: Double;
WriteDbl: Double;
SampleCount: Integer;
  begin

    SetLength(Self.fOutBuffer, trunc(44100 * ALength));
    SampleCount := 0;

    T := 0;
    DeltaT := 1 / 44100;
    Phase := APhaseStart;

    while SampleCount < Length(Self.fOutBuffer) do begin
      WriteDbl := Self.fAmplitude * sin((Pi * 2) * AFrequency * T + Phase);
      Self.fOutBuffer[SampleCount] := trunc(WriteDbl * High(Int16));
      Inc(SampleCount,1);
      T := T + DeltaT;
    end;

    Self.ApplyAttackDecay();
    Result := Self.fOutBuffer;

  end;

function TPGLAudioGenerator.CombineData(AData1, AData2: TArray<Int16>; ATrim: Boolean = False): TArray<Int16>;
var
WriteLength: Integer;
WriteVal: Integer;
I: Integer;
  begin

    {$POINTERMATH ON};

    WriteLength := Min(Length(AData1), Length(AData2));
    SetLength(Result, WriteLength);

    for I := 0 to writelength - 1 do begin

      WriteVal := AData1[i] + AData2[i];

      if WriteVal > High(Int16) then begin
        WriteVal := High(Int16);
      end;
      if WriteVAl < Low(int16) then begin
        WriteVal := Low(Int16);
      end;

      Result[i] := WriteVal;
    end;

    if ATrim = False then begin
      if Length(AData1) > Length(AData2) then begin
        SetLength(Result, Length(AData1));
        Move(AData1[WriteLength], Result[WriteLength], (Length(AData1) - WriteLength) * 2);
      end else if Length(AData2) > Length(AData1) then begin
        SetLength(Result, Length(AData2));
        Move(AData2[WriteLength], Result[WriteLength], (Length(AData2) - WriteLength) * 2);
      end;
    end;

  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundBuffer
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}


constructor TGEMSoundBuffer.Create();
  begin
    Self.fIsValid := False;
    Self.fBuffer := 0;
    Self.fLength := 0;
    Self.fName := '';
  end;

procedure TGEMSoundBuffer.LoadDataFromFile(FileName: string; NameBuffer: String);
  begin

    if FileExists(FileName) = False then Exit;

    Self.fIsValid := True;

    Self.fName := NameBuffer;

    AlGenBuffers(1, @Self.fBuffer);
    AlutLoadWavFile(FileName, format, data, size, freq, loop);
    AlBufferData(Self.fBuffer, format, data, size, freq);
    AlutUnloadWav(format, data, size, freq);

      if (format = AL_FORMAT_MONO8) or (format = AL_FORMAT_STEREO8) then begin
        Self.fLength := (Size / 2) / Freq;
      end Else begin
        Self.fLength := (Size / 4) / Freq;
      end;
  end;


procedure TGEMSoundBuffer.LoadDataFromMemory(ASource: Pointer; ASourceSize: Integer; AFrequency: Integer);
  begin
    Self.fIsValid := True;

    Self.fName := '';

    AlDeleteBuffers(1,@Self.fBuffer);
    AlGenBuffers(1,@Self.fBuffer);
    AlBufferData(Self.fBuffer, AL_FORMAT_MONO16, ASource, ASourceSize, AFrequency);
    Self.fLength := (ASourceSize / 4) / AFrequency;
  end;


constructor TPGLMusicBuffer.Create();
var
I: Integer;
Env: TALUInt;
  begin
    inherited;
    alGenSources(1,@Self.fSource);
    alSourcef(Self.fSource, AL_GAIN, 1);
    alSource3f(Self.fSource, AL_DIRECTION, 0, 0, 0);
    alSourcef(Self.fSource, AL_MAX_DISTANCE, 0);
    alSourcef(Self.fSource, AL_REFERENCE_DISTANCE, 0);
    alSourcef(Self.fSource, AL_ROLLOFF_FACTOR,0);
    alSourcef(Self.fSource, AL_CONE_OUTER_ANGLE, 0);
    alSourcef(Self.fSource, AL_CONE_INNER_ANGLE, 0);
    alSourcef(Self.fSource, AL_CONE_OUTER_GAIN, 1);

    Self.fState := TGEMSoundState.pgl_initial;
    Self.fSpeed := 1;
  end;

procedure TPGLMusicBuffer.LoadDataFromFile(FileName: string; NameBuffer: string);
var
TempBuffer: TALUInt;
  begin
    if FileExists(FileName) = False then Exit;

    Self.fIsValid := True;

    Self.fName := NameBuffer;
    Self.fSpeed := 2;

    AlGenBuffers(5, @Self.fBuffers);
    AlutLoadWavFile(FileName, Self.fFormat, Self.fData, Self.fDataSize, Self.fFrequency, loop);

    alGenBuffers(1,@Tempbuffer);
    alBufferData(Tempbuffer, Self.fFormat, Self.fData, Self.fDataSize, trunc(Self.fFrequency / Self.Speed));
    alGetBufferI(Tempbuffer, AL_BITS, @Self.fBitsPerSample);
    alGetBufferI(TempBuffer, AL_CHANNELS, @Self.fChannels);
    alDeleteBuffers(1,@TempBuffer);


      if (format = AL_forMAT_MONO8) or (format = AL_forMAT_STEREO8) then begin
        Self.fLength := (Self.fDataSize / 2) / Self.fFrequency;
      end Else begin
        Self.fLength := (Self.fDataSize / 4) / Self.fFrequency;
      end;

  end;


procedure TPGLMusicBuffer.Play();
var
I,R: TALUint;
BufferSize: TALUint;
DataPointer: PByte;
DoBreak: Boolean;
QueueCount: Integer;
BuffersQueued: TALInt;
Bytes: TArray<Byte>;
BytePos: TALFloat;
  begin

    if Self.fState = pgl_playing then Exit;

    Self.fDataPos := 0;
    QueueCount := 0;

    for I := 0 to 4 do begin

      DataPointer := Self.fData;
      DataPointer := DataPointer + Self.fDataPos;

      DoBreak := False;

      if Self.fDataSize - Self.fDataPos < (Self.fFrequency * 2) then begin
        BufferSize := Self.fDataSize - Self.fDataPos;
        DoBreak := True;
      end else begin
        BufferSize := Self.fFrequency;
      end;


      alBufferData(Self.fBuffers[i], Self.fFormat, PByte(Self.fData) + Self.fDataPos, BufferSize, Self.fFrequency);
      alSourceQueueBuffers(Self.fSource, 1, @Self.fBuffers[i]);
      Self.fQueued[i] := True;
      Inc(Self.fDataPos, BufferSize);

      if Self.fDataPos >= Self.fDataSize then begin
        Self.fDataPos := 0;
      end;

      if DoBreak then Break;

    end;

    alGetSourceI(Self.fSource, AL_BUFFERS_QUEUED, @BuffersQueued);
    alSource3f(Self.fSource, AL_POSITION, pglSound.Listener.Position.X + 10, pglSound.Listener.Position.Y, -100);
    alSourcePlay(self.fSource);

    Self.fState := TGEMSoundState.pgl_playing;

    pglSound.CurrentMusic := Self;
  end;


procedure TPGLMusicbuffer.Pause();
  begin

  end;

procedure TPGLMusicBuffer.Stop();
  begin

  end;

procedure TPGLMusicBuffer.Resume();
  begin

  end;

procedure TPGLMusicBuffer.GetData(out ADest: Pointer);
  begin
    Move(Self.fData^, ADest^, Self.fDataSize);
  end;

procedure TPGLMusicBuffer.GetData(out ADest: TArray<Byte>);
  begin
    SetLength(ADest, Self.fDataSize);
    Move(Self.fData^, ADest[0], Self.fDataSize);
  end;


procedure TPGLMusicBuffer.Stream();
var
I,R: Integer;
BuffersProcessed: TALInt;
BuffersQueued: TALInt;
CurBuffer: TALUInt;
BufferSize: Integer;
DataPointer: PByte;
BytePos: TALFloat;
Bytes: TArray<Byte>;
IterCount: TALInt;
ChunkSize: TALInt;
MoveSize: TALInt;
ByteCount: TALInt;
  begin

    if Self.fState <> pgl_playing then begin
      Exit;
    end;

    BuffersProcessed := 0;

    alGetSourceI(Self.fSource, AL_BUFFERS_QUEUED, @BuffersQueued);
    alGetSourceI(Self.fSource, AL_BUFFERS_PROCESSED, @BuffersProcessed);
    DataPointer := Self.fData;
    DataPointer := DataPointer + Self.fDataPos;


    while BuffersProcessed > 0 do begin
      CurBuffer := 0;
      alSourceUnqueueBuffers(Self.fSource, 1, @CurBuffer);

      if Self.fDataSize - Self.fDataPos < (Self.fFrequency) then begin
        BufferSize := Self.fDataSize - Self.fDataPos;
      end else begin
        BufferSize := Self.fFrequency;
      end;

      DataPointer := Self.fData;
      DataPointer := DataPointer + Self.fDataPos;
      alBufferData(CurBuffer, Self.fFormat, DataPointer, BufferSize, Self.fFrequency);

      Inc(Self.fDataPos, BufferSize);

      for I := 0 to 4 do begin
        if CurBuffer = Self.fBuffers[i] then begin
          Self.fQueued[i] := True;
          Break;
        end;
      end;

      if Self.fDataPos >= Self.fDataSize then begin
        Self.fDataPos := 0;
      end;

      alSourceQueueBuffers(Self.fSource, 1, @CurBuffer);

      Dec(BuffersProcessed);

    end;

  end;


class operator TGEMSoundSource.Initialize({$ifdef FPC} var {$else} out {$endif} Dest: TGEMSoundSource);
  begin
    Dest.fRadius := 100;
    Dest.fHasBuffer := False;
    Dest.fGain := 1;
    Dest.fPosition := Vec2(0,0);
    Dest.fHasPositionPointers := False;
    Dest.fXPointer := Nil;
    Dest.fYPointer := Nil;
    Dest.fHasVariablePitch := False;
    Dest.fPitchRange[0] := 1;
    Dest.fPitchRange[1] := 1;
    Dest.fDirection := 0;
    Dest.fConeAngle := 360;
    Dest.fConeOuterGain := 1;
    Dest.fLooping := False;
    Dest.fisDynamic := False;
    Dest.Source := 0;
  end;


procedure TGEMSoundSource.CheckHasBuffer();
  begin

    // if doesn't have buffer, then create source, add to pglSound source array
    if Self.fHasBuffer = False then begin
      Inc(pglSound.SourceCount);
      SetLength(pglSound.Sources, pglSound.SourceCount);
      pglSound.Sources[pglSound.SourceCount - 1] := @Self;
      Self.fHasBuffer := true;
    end;

  end;

procedure TGEMSoundSource.AssignBuffer(Buffer: TGEMSoundBuffer);
  begin

    // Gen source if has none
    if Self.Source = 0 then begin
      alGenSources(1,@Self.Source);
    end;

    if Buffer.IsValid = False then Exit;

    // Make sure the source is created first
    Self.CheckHasBuffer();
    Self.fBuffer := Buffer;
    Self.fHasBuffer := True;
    alSourcei(Self.Source, AL_BUFFER, Self.fBuffer.Buffer);
  end;


procedure TGEMSoundSource.AssignBuffer(ABufferName: String);
var
I: Integer;
  begin
    for I := 0 to High(pglSound.Buffers) do begin
      if pglSound.Buffers[i].Name = ABufferName then begin
        Self.AssignBuffer(pglSound.Buffers[i]);
      end;
    end;
  end;


procedure TGEMSoundSource.SetGain(Value: Single);
  begin
    if Value < 0 then Value := 0;
    if Value > 1 then Value := 1;

    Self.fGain := Value;
  end;


procedure TGEMSoundSource.UpdateBufferPosition();
  begin
    alSource3F(Self.Source, AL_POSITION, Self.Position.X, Self.Position.Y, 0);
  end;


procedure TGEMSoundSource.SetPosition(APosition: TGEMVec2);
  begin
    Self.fHasPositionPointers := False;
    Self.fPosition := APosition;
    Self.UpdateBufferPosition();
  end;


procedure TGEMSoundSource.SetPositionPointers(pX: Pointer; pY: Pointer);
  begin
    Self.fHasPositionPointers := True;
    Self.fXPointer := pX;
    Self.fYPointer := pY;
  end;


procedure TGEMSoundSource.SetVariablePitch(LowRange: Single; HighRange: Single);
  begin
    Self.fHasVariablePitch := True;
    Self.fPitchRange[0] := LowRange;
    Self.fPitchRange[1] := HighRange;
  end;


procedure TGEMSoundSource.SetFixedPitch(Value: Single);
  begin
    Self.fHasVariablePitch := False;
    Self.fPitchRange[0] := Value;
    Self.fPitchRange[1] := Value;
    alSourceF(Self.Source, AL_PITCH, Value);
  end;

procedure TGEMSoundSource.SetLooping(Value: Boolean = True);
  begin
    Self.fLooping := Value;
    alSourceI(Self.Source, AL_LOOPING, Value.ToInteger);
  end;

procedure TGEMSoundSource.SetDirection(Angle: Single);
Var
I,R: Integer;
DX,DY: Single;
  begin
    Self.fDirection := Angle;

    R := -1;

    for I := 0 to High(pglSound.Sounds) do begin
      if (pglSound.Sounds[i].SoundSource = @Self) then begin
        R := I;
        Break;
      end;
    end;

    if R = -1 then Exit;

    DX := 1 * Cos(Self.Direction);
    DY := 1 * Sin(Self.Direction);

    alSource3f(pglSound.Sounds[r].Source, AL_DIRECTION, DX, DY, 0);

  end;

procedure TGEMSoundSource.SetRadius(Distance: Single);
  begin
    Self.fRadius := Distance;
  end;

procedure TGEMSoundSource.SetCone(Angle: Single; ConeOuterGain: Single);
  begin
    Self.fConeAngle := Angle * (180 / Pi);
    Self.fConeOuterGain := ConeOuterGain;
  end;

procedure TGEMSoundSource.SetConeAngle(Angle: Single);
  begin
    Self.fConeAngle := Angle * (180 / Pi);
  end;

procedure TGEMSoundSource.SetConeOuterGain(Gain: Single);
  begin
    Self.fConeOuterGain := Gain;
  end;

procedure TGEMSoundSource.ReleasePositionPointers();
  begin
    Self.fHasPositionPointers := False;
    Self.fXPointer := nil;
    Self.fYPointer := nil;
  end;

procedure TGEMSoundSource.SetDynamic(Enable: Boolean = True);
  begin
    Self.fisDynamic := Enable;
  end;

procedure TGEMSoundSource.UpdatePosition();
  begin
    if Self.fHasPositionPointers = False then Exit;

//    Self.fPosition.X := Self.fXPointer^;
//    Self.fPosition.Y := Self.fYPointer^;
    Self.UpdateBufferPosition();
  end;


procedure TGEMSoundSource.Play();
var
Dist: Double;
  begin

    if Self.fBuffer = nil then Exit;
    if Self.fBuffer.fIsValid = False then Exit;
    if Self.fisPlaying then Exit;

    if Self.fHasPositionPointers then begin
      Self.UpdatePosition();
    end;


    Dist := Sqrt( IntPower(pglSound.Listener.Position.X - Self.Position.X, 2) + IntPower(pglSound.Listener.Position.Y - Self.Position.Y, 2));

    If Dist > Self.Radius then Exit;

    alSourcef(Self.Source, AL_GAIN, Self.Gain * ( Self.Radius / Dist) );
    alSource3f(Self.Source, AL_POSITION, Self.Position.X, Self.Position.Y,0 );
    alSource3f(Self.Source, AL_DIRECTION, Cos(Self.Direction), Sin(Self.Direction), 0);
    alSourcef(Self.Source, AL_MAX_DISTANCE, Self.Radius);
    alSourcef(Self.Source, AL_REFERENCE_DISTANCE, 10);
    alSourcef(Self.Source, AL_ROLLOFF_FACTOR,2);
    alSourcef(Self.Source, AL_CONE_OUTER_ANGLE, Self.ConeAngle);
    alSourcef(Self.Source, AL_CONE_INNER_ANGLE, 0);
    alSourcef(Self.Source, AL_CONE_OUTER_GAIN, Self.ConeOuterGain);

    alSourcePlay(Self.Source);

    Self.fState := pgl_playing;
    Self.fisPlaying := True;
  end;


procedure TGEMSoundSource.Stop();
  begin
    if Self.fState <> pgl_playing then Exit;
    alSourceStop(Self.Source);
    Self.fState := pgl_stopped;
  end;


procedure TGEMSoundSource.Pause();
  begin
    if Self.fState <> pgl_playing then Exit;
    alSourcePause(Self.Source);
    Self.fState := pgl_paused;
  end;

procedure TGEMSoundSource.Resume();
  begin
    if Self.fState <> pgl_paused then Exit;
    alSourcePlay(Self.Source);
    Self.fState := pgl_playing;
  end;


function Rnd(Val1,Val2: Single): Single;
Var
Diff: Single;
Return: Single;
  begin
    Val1 := Val1 * 100000;
    Val2 := Val2 * 100000;
    Diff := Val2 - Val1;
    Return := Random(trunc(Diff)) + Val1;
    Return := Return / 100000;
    Result := Return;
  end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure pglBufferi(Target: TALUint; Enum: TALEnum; Value: TALUint);
  begin
    ALGetError();
    ALBufferi(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBuffer3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  begin
    ALGetError();
    ALBuffer3i(Target,Enum,Value2, Value2, Value3);
    AlGetErrorState();
  end;

procedure pglBufferiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  begin
    ALGetError();
    ALBufferiv(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBufferf(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  begin
    ALGetError();
    ALBufferf(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglBuffer3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  begin
    ALGetError();
    ALBuffer3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglBufferfv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  begin
    ALGetError();
    ALBufferfv(Target,Enum,Value);
    AlGetErrorState();
  end;

{------------------------------------------------------------------------------}

procedure pglSourcei(Target: TALUint; Enum: TALEnum; Value: TALUint);
  begin
    ALGetError();
    AlSourcei(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSource3i(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALuint);
  begin
    ALGetError();
    AlSource3i(Target,Enum,Value2,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglSourceiv(Target: TALUint; Enum: TALEnum; Value: PALint);
  begin
    ALGetError();
    AlSourceiv(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSourcef(Target: TALUint; Enum: TALEnum; Value: TALfloat);
  begin
    ALGetError();
    AlSourcef(Target,Enum,Value);
    AlGetErrorState();
  end;

procedure pglSource3f(Target: TALUint; Enum: TALEnum; Value1, Value2, Value3: TALfloat);
  begin
    ALGetError();
    AlSource3f(Target,Enum,Value1,Value2,Value3);
    AlGetErrorState();
  end;

procedure pglSourcefv(Target: TALUint; Enum: TALEnum; Value: PALFloat);
  begin
    ALGetError();
    AlSourcefv(Target,Enum,Value);
    AlGetErrorState();
  end;


function pglLoadWaveFile(AFileName: String; var AData: TGEMAudioData): Boolean;
var
Header: TGEMWaveHeader;
ReadBuffer: TArray<Byte>;
DataBuffer: TArray<Byte>;
BufferSize: Int64;
BytesRead: Cardinal;
InFile: HFILE;
OFS: OFSTRUCT;
  begin
    Result := False;

    // fail and zero memory of header if file not found
    if FileExists(AFileName) = False then begin
      Exit;
    end;

    // open file and read file size
    InFile := OpenFile(PAnsiChar(AnsiString(AFileName)), OFS, OF_READ);

    BufferSize := 0;
    GetFileSizeEX(InFile, BufferSize);

    // if file size is not at least size of TGEMWaveHeader, fail
    if BufferSize < SizeOf(TGEMWaveHeader) then begin
      Exit;
    end;

    // read in file, check top 44 bytes for wav file header
    SetLength(ReadBuffer, BufferSize);
    ReadFile(InFile, ReadBuffer[0], BufferSize, BytesRead, nil);
    Move(ReadBuffer[0], Header, SizeOf(TGEMWaveHeader));

    if Header.CheckValid = False then begin
      Exit;
    end;

    // move the rest of the data into another buffer for only audio data
    // convert to 16 bit pcm if needed
    SetLength(DataBuffer, Length(ReadBuffer) - 44);
    Move(ReadBuffer[44], DataBuffer[0], Length(ReadBuffer) - 44);

    if Header.BLOCK_ALIGN = 1 then begin
      pglConvertBitDepth8to16(DataBuffer);
      Header.BLOCK_ALIGN := 2;
      Header.BYTES_PER_SECOND := Header.BYTES_PER_SECOND * 2;
      Header.BITS_PER_SAMPLE := Header.BITS_PER_SAMPLE * 2;
    end;

    AData.fHeaderInfo := Header;

    // copy all over data into abuffer
    SetLength(AData.fBuffer, trunc(Length(DataBuffer) / 2));
    Move(DataBuffer[0], AData.fBuffer[0], Length(DataBuffer));

    AData.UpdateDuration();

    Result := True;

  end;


procedure pglTrimAudioSilence(var ASource: TArray<Int16>; AAmplitudeLimit: Single; ATrimLeft: Boolean = True; ATrimRight: Boolean = True);
var
I: Integer;
  begin

    if ATrimLeft then begin
      for I := 0 to High(ASource) do begin
        if abs(ASource[i]) >= High(Int16) * AAmplitudeLimit then begin
          Delete(ASource,0, I);
          break;
        end;
      end;
    end;

    if ATrimRight then begin

      I := High(ASource);
      while I > 0 do begin
        if abs(ASource[i]) >= High(Int16) * AAmplitudeLimit then begin
          Delete(ASource, I, Length(ASource) - I);
          break;
        end;
      end;

    end;

  end;

function pglConvertAudio(ASource: Pointer; ASourceSize, AOldSampleRate, AOldBitDepth, ANewSampleRate, ANewBitDepth: Cardinal): TArray<Byte>;
  begin

    SetLength(Result, ASourceSize);
    Move(ASource^, Result[0], ASourceSize);

    if AOldBitDepth <> ANewBitDepth then begin
      if (ANewBitDepth = 8) or (ANewBitDepth = 16) then begin
        if ANewBitDepth = 8 then begin
          pglConvertBitDepth16to8(Result);
        end else begin
          pglConvertBitDepth8to16(Result);
        end;
      end;
    end;

  end;


procedure pglConvertBitDepth8to16(var ASource: TArray<Byte>);
var
NewVals: TArray<Byte>;
NPtr: PSmallInt;
OPos,NPos: Cardinal;
I: Integer;
Diff: Double;
WriteVal: Integer;
FinalVal: Int16;
  begin

    SetLength(NewVals, Length(ASource) * 2);
    OPos := 0;
    NPos := 0;

    Diff := High(Int16) / High(Byte);

    for I := 0 to High(ASource) do begin

      NPtr := @NewVals[NPos];
      WriteVal := trunc(ASource[I] - 128);
      WriteVal := trunc(WriteVal * (Diff * 2));

      if WriteVal > High(Int16) then begin
        WriteVal := High(Int16);
      end else if WriteVal < Low(Int16) then begin
        WriteVal := Low(Int16);
      end;

      FinalVal := WriteVal;

      NPtr[0] := FinalVal;

      Inc(NPos,2);

    end;

    ASource := NewVals;

  end;


procedure pglConvertBitDepth16to8(var ASource: TArray<Byte>);
var
NewVals: TArray<Byte>;
OPtr: PSmallInt;
OPos,NPos: Cardinal;
I: Integer;
Diff: Double;
WriteVal: Int16;
FinalVal: Int8;
  begin

    SetLength(NewVals, trunc(Length(ASource) / 2));
    OPos := 0;
    NPos := 0;

    OPtr := @ASource[0];

    Diff := High(Int8) / High(int16);

    for I := 0 to High(NewVals) do begin

      WriteVal := trunc(OPtr[OPos] * Diff);

      if WriteVal > High(Int8) then begin
        WriteVal := High(Int8);
      end else if WriteVal < Low(Int8) then begin
        WriteVal := Low(Int8);
      end;

      FinalVal := WriteVal;
      Move(FinalVal, NewVals[i], 1);

      Inc(OPos,1);

    end;

    ASource := NewVals;

  end;


procedure pglConvertSampleRate(var ASource: TArray<Byte>; AOldSampleRate, ANewSampleRate, ABitDepth: Cardinal);
  begin
    if (AOldSampleRate mod 2 <> 0) or (ANewSampleRate mod 2 <> 0) then Exit;

    if ABitDepth = 8 then begin
      pglConvertSampleRate8Bit(ASource, AOldSampleRate, ANewSampleRate);
    end else if ABitDepth = 16 then begin
      pglConvertSampleRate16Bit(ASource, AOldSampleRate, ANewSampleRate);
    end else begin
      Exit;
    end;
  end;

procedure pglConvertSampleRate8Bit(var ASource: TArray<Byte>; AOldSampleRate, ANewSampleRate: Cardinal);
var
NewVals: TArray<Byte>;
NewSize: Integer;
I: Integer;
SPos, NPos: Integer;
SMove, NMove: Integer;
ConvPer: Single;
Limit: Integer;
  begin

    ConvPer := ANewSampleRate / AOldSampleRate;
    NewSize := Length(ASource);
    NewSize := trunc(NewSize * ConvPer);
    SetLength(NewVals, NewSize);

    SPos := 0;
    NPos := 0;

    if ConvPer < 1 then begin
      NMove := 1;
      SMove := trunc(1 * 1/ConvPer);
    end else begin
      SMove := 1;
      NMove := trunc(1 * 1/ConvPer);
    end;

    Limit := Min(Length(ASource), Length(NewVals));

    for I := 0 to Limit - 1 do begin
      Move(ASource[SPos], NewVals[NPos], 1);
      Inc(NPos, NMove);
      Inc(SPos, SMove);
    end;

    ASource := NewVals;

  end;

procedure pglConvertSampleRate16Bit(var ASource: TArray<Byte>; AOldSampleRate, ANewSampleRate: Cardinal);
var
NewVals: TArray<Byte>;
NewSize: Integer;
I: Integer;
SPos, NPos: Integer;
SMove, NMove: Integer;
ConvPer: Single;
Limit: Integer;
  begin

    ConvPer := ANewSampleRate / AOldSampleRate;
    NewSize := Length(ASource);
    NewSize := trunc(NewSize * ConvPer);
    SetLength(NewVals, NewSize);

    SPos := 0;
    NPos := 0;

    if ConvPer < 1 then begin
      NMove := 2;
      SMove := trunc(2 * 1/ConvPer);
    end else begin
      SMove := 2;
      NMove := trunc(2 * 1/ConvPer);
    end;

    Limit := Min(Length(ASource), Length(NewVals));
    Limit := trunc(Limit / 2);

    for I := 0 to Limit - 1 do begin
      Move(ASource[SPos], NewVals[NPos], 2);
      Inc(NPos, NMove);
      Inc(SPos, SMove);
    end;

    ASource := NewVals;

  end;


procedure pglGainTremolo(ASource: Pointer; ABitDepth, ASourceSize: Cardinal; AMinChange, AMaxChange: Single; AChangeFrequency: Cardinal);
var
ChangeArray: TArray<Single>;
ChangeRange: Double;
T: Double;
DeltaT: Double;
Phase: Single;
SampleCount: Integer;
I: Integer;
Ptr: PSmallInt;
  begin

    SetLength(ChangeArray, trunc(ASourceSize / 2));

    T := 0;
    DeltaT := 1 / AChangeFrequency;
    Phase := 0;
    ChangeRange := AMaxChange - AMinChange;
    SampleCount := 0;

    while SampleCount < Length(ChangeArray) do begin
      ChangeArray[SampleCount] := (ChangeRange / 2) * sin((Pi * 2) * 1 * T + Phase);
      Inc(SampleCount,1);
      T := T + DeltaT;
    end;

    Ptr := ASource;

    for I := 0 to trunc(ASourceSize / 2) - 1 do begin
      Ptr[i] := trunc(Ptr[i] * (1 - ChangeArray[i]));
    end;

  end;


procedure pglBitCrush(ASource: Pointer; ASampleRate, ABitDepth, ASourceSize: Cardinal);
  procedure Crush16Bit();
  var
  Data: PSmallInt;
  Dpos: Integer;
  WriteVal: Integer;
  I,R: Integer;
  RStart, REnd: Int16;
  RStep, RVal: Single;
  const
  CrushVal: Integer = 4;
  AmpVal: Integer = 16;
    begin
      Data := ASource;
      DPos := 0;

      // reduce bandwidth
      for I := 0 to trunc(ASourceSize / 2) - 1 do begin
        WriteVal := Data[I];

        WriteVal := trunc(AmpVal  * (WriteVal / High(Int16)));
        WriteVal := trunc(High(Int16) * (WriteVal / AmpVal));

        if WriteVal = 0 then begin
          WriteVal := trunc(High(Int16) * (1/AmpVal)) * Sign(Data[i]);
        end;

        Data[I] := SmallInt(WriteVal);
      end;

      // reduce fidelity
      for I := 0 to trunc(ASourceSize / (CrushVal * 2)) - 1 do begin
        for R := 1 to CrushVal - 1 do begin
          Data[DPos + R] := Data[DPos];
        end;

        if I <> 0 then begin
          Data[DPos] := Data[DPos - 1];
        end;

        Inc(DPos, CrushVal);
      end;

      // turn square waves to 'ramps'
//      DPos := 0;
//      for I := 0 to trunc(ASourceSize / (CrushVal * 2)) - 1 do begin
//        if I = 0 then begin
//          RStart := Data[0];
//        end else begin
//          RStart := Data[DPos];
//        end;
//
//        REnd := Data[DPos + CrushVal];
//
//        RStep := (REnd - RStart) / CrushVal;
//        RVal := RStart;
//
//        for R := 1 to CrushVal - 1 do begin
//          Data[DPos + R] := round(Rval);
//          RVal := Rval + RStep;
//        end;
//
//        Inc(DPos, CrushVal);
//
//      end;

    end;

  procedure Crush8Bit();
    begin

    end;

  begin;

    if ABitDepth = 8 then begin
      Crush8Bit();
    end else if ABitDepth = 16 then begin
      Crush16Bit();
    end;

  end;


function pglAudioFindPeriod(ASource: TArray<Int16>): Cardinal;
var
I: Integer;
SPtr: PSmallInt;
SPos: Integer;
WaveCount: Cardinal;
Waves: TArray<Cardinal>;
Avg: Int64;
ZeroPos: Integer;
HasZero: Boolean;
  begin

    Result := 0;

    SPtr := @ASource[0];
    WaveCount := 0;
    HasZero := False;
    ZeroPos := 0;

    for I := 0 to High(ASource) do begin
      if SPtr[0] = 0 then begin

        if HasZero = True then begin
          if I - ZeroPos > 1 then begin
            SetLength(Waves, WaveCount + 1);
            Waves[WaveCount] := I - ZeroPos;
            Inc(WaveCount);
            ZeroPos := I;
          end;
        end else begin
          HasZero := True;
        end;

      end;

      Inc(SPtr);
    end;

    Avg := 0;

    for I := 0 to High(Waves) do begin
      Inc(Avg, Waves[i]);
    end;

    Avg := trunc(Avg / Length(Waves));

    Result := Avg;

  end;


function pglTimeStretch(const InData: TArray<Int16>; const InSampleRate, OutSampleRate: Integer; const StretchFactor: Double): TArray<Int16>;
var
n, m, i, j: Int64;
inbuf, outbuf: Pfftw_real;
fftplan: fftw_plan;
window: array of Double;
fftdata: array of tfftw_complex;
WriteVal: Int64;
  begin
    // Compute the number of input and output samples
    n := Length(InData);
    m := Round(n / StretchFactor);

    // Allocate memory for input and output buffers
    GetMem(inbuf, n * SizeOf(Double));
    GetMem(outbuf, m * SizeOf(Double));

    ZeroMemory(inbuf, n * SizeOf(Double));
    ZeroMemory(outbuf, m * SizeOf(Double));

    // Copy input data to input buffer and zero-pad to next power of 2
    for i := 0 to n-1 do begin
      inbuf[i] := InData[i] / 32767.0;
    end;

    while (n and (n-1)) <> 0 do begin
      if n >= Length(InData) then Break;
        inbuf[n] := 0.0;
        Inc(n);
    end;

    // Allocate memory for window and FFT data
    SetLength(window, n);
    SetLength(fftdata, n div 2 + 1);

    // Initialize FFT plan for real-to-complex transform
    fftplan := fftw_plan_dft_r2c_1d(n, inbuf, @fftdata[0], FFTW_ESTIMATE);

    // Compute Hann window function
    for i := 0 to n-1 do
      window[i] := 0.5 - 0.5 * Cos(2 * Pi * i / (n-1));

    // Apply window function and compute FFT
    for i := 0 to n-1 do
      inbuf[i] := inbuf[i] * window[i];
    fftw_execute(fftplan);

    // Apply phase vocoder time-stretching algorithm
    for i := 0 to m-1 do begin
      // Compute frequency shift for current output sample
      j := Round(i * StretchFactor);
      if j >= n div 2 then
        break;
      // Scale complex FFT data by frequency shift
      fftdata[j].re := fftdata[j].re * (i / StretchFactor);
      fftdata[j].im := fftdata[j].im * (i / StretchFactor);
      // Copy complex FFT data to output buffer
      outbuf[i] := fftdata[j].re;
      if j < n div 2 then
        outbuf[i] := outbuf[i] + fftdata[j+1].im;
    end;

    // Initialize FFT plan for complex-to-real transform
    fftplan := fftw_plan_dft_c2r_1d(m, @fftdata[0], pfftw_real(outbuf), FFTW_ESTIMATE);

    // Compute IFFT and copy output data to output buffer
    fftw_execute(fftplan);
    SetLength(Result, m);
    for i := 0 to m-1 do begin
      WriteVal := Round(outbuf[i] * 32767.0);
      if WriteVal > High(Int16) then WriteVal := High(Int16);
      if WriteVal < Low(Int16) then WriteVal := Low(Int16);
      Result[i] := WriteVal;
    end;

    // Free memory and return output buffer
    fftw_destroy_plan(fftplan);
    FreeMem(outbuf);
    FreeMem(inbuf);
  end;



initialization
  begin
    LoadLibrary(PWideChar(ExtractFilePath(ParamStr(0)) + '\FFTW\libfftw3-3.dll'))
  end;

end.
