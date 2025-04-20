unit gemaudio;

{$mode ObjFPC}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$MACRO ON}

{ enables checking and output of OpenAL errors }
{$define gemaudio_enable_errors}

{ macro used to call OpenAL error checker when error checking is enabled, included as the last call of every function }
{$define call_err_macro :=
  {$ifdef gemaudio_enable_errors}
    gemAudioCheckError(FuncName); {$endif}
}

interface

uses
  openal, gemtypes, gemarray, gemmath, gemwav,
  Classes, SysUtils;

type

  { forward declarations }

  TGEMAudio = class;
  TGEMSoundListener = class;
  TGEMSoundBuffer = class;
  TGEMSoundSource = class;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMTimeFloat
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMTimeFloat = record
    private
      fValue: Single;
      function GetMinutes(): Integer;
      function GetSeconds(): Single;
    public
      property Value: Single read fValue write fValue;
      property Minutes: Integer read GetMinutes;
      property Seconds: Single read GetSeconds;
      function ToString(): String;
      class operator := (A: Single): TGEMTimeFloat;
      class operator := (A: TGEMTimeFloat): Single;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMAudio
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMAudio = class(TObject)
    private
      fBufferList: specialize TGEMArray<TGEMSoundBuffer>;
      fSourceList: specialize TGEMArray<TGEMSoundSource>;
      fListener: TGEMSoundListener;

      procedure AddBuffer(aBuffer: TGEMSoundBuffer);
      procedure AddSource(aSource: TGEMSoundSource);
      procedure RemoveBuffer(aBuffer: TGEMSoundBuffer);
      procedure RemoveSource(aSource: TGEMSoundSource);

    public
      property Listener: TGEMSoundListener read fListener;

      constructor Create();

      procedure Update();

      procedure StopAllPlaying();
      procedure PauseAllPlaying();
      procedure ResumeAllPaused();
      function GetAllPlaying(): specialize TArray<TGEMSoundSource>;
      function GetAllPaused(): specialize TArray<TGEMSoundSource>;
      function GetAllStopped(): specialize TArray<TGEMSoundSource>;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundListener
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMSoundListener = class(TObject)
    private
      fPosition: TGEMVec3;
      fDirection, fUpVector: TGEMVec3;
      fGain: TALFloat;
      fMaxDistance: TALFloat;
      fAttenuationEnabled: TALBoolean;

      procedure UpdateOrientation();

    public
      property Position: TGEMVec3 read fPosition;
      property Direction: TGEMVec3 read fDirection;
      property UpVector: TGEMVec3 read fUpVector;
      property Gain: TALFloat read fGain;
      property MaxDistance: TALFloat read fMaxDistance;
      property AttenuationEnabled: TALBoolean read fAttenuationEnabled;

      constructor Create();

      procedure SetPosition(const aPos: TGEMVec3);
      procedure MovePosition(const aPos: TGEMVec3);
      procedure SetDirection(const aDirection: TGEMVec3);
      procedure DirectAt(const aAt: TGEMVec3);
      procedure SetUpVector(const aUp: TGEMVec3);
      procedure SetGain(const aGain: TALFloat);
      procedure SetMaxDistance(const aDistance: TALFloat);
      procedure EnableAttenuation(const aEnabled: Boolean = True);
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                 TGEMSoundBuffer
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMSoundBuffer = class(TObject)
    private
      fValid: Boolean;
      fBuffer: TALUint;
      fSize: TALSizei;
      fFrequency: TALSizei;
      fFormat: TALEnum;
      fBitDepth: TALSizei;
      fLength: TGEMTimeFloat;
      fStereo: TALBoolean;
      fData: PALVoid;

    public
      property Valid: Boolean read fValid;
      property Buffer: TALUint read fBuffer;
      property Size: TALSizei read fSize;
      property Frequency: TALSizei read fFrequency;
      property Format: TALEnum read fFormat;
      property Length: TGEMTimeFloat read fLength;
      property Data: PALVoid read fData;

      constructor Create(const aFileName: String);
      destructor Destroy(); override;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                 TGEMSoundSource
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

  TGEMSoundSource = class(TObject)
    private
      fSource: TALUint;
      fBuffer: TGEMSoundBuffer;
      fPosition: TGEMVec3;
      fLastPosition: TGEMVec3;
      fUsePosition: TGEMVec3;
      fGain: TALFloat;
      fRelativeGainLow, fRelativeGainHigh, fRelativeGain: TALFloat;
      fGainRange: TALFloat;
      fPitch: Single;
      fRadius: TALFloat;
      fDirection: TGEMVec3;
      fConeAngle: TALFloat;
      fOffset: TGEMTimeFloat;
      fPlaying: TALBoolean;
      fPaused: TALBoolean;
      fStopped: TALBoolean;
      fAttenuationEnabled: TALBoolean;
      fLoop: TALBoolean;

      procedure UpdateState();

    public
      property Buffer: TGEMSoundBuffer read fBuffer;
      property Position: TGEMVec3 read fPosition;
      property LastPosition: TGEMVec3 read fLastPosition;
      property Gain: TALFloat read fGain;
      property RelativeGainLow: TALFloat read fRelativeGainLow;
      property RelativeGainHigh: TALFloat read fRelativeGainHigh;
      property RelativeGain: TALFloat read fRelativeGain;
      property Pitch: Single read fPitch;
      property Radius: TALFloat read fRadius;
      property Direction: TGEMVec3 read fDirection;
      property ConeAngle: TALFloat read fConeAngle;
      property Offset: TGEMTimeFloat read fOffset;
      property Playing: TALBoolean read fPlaying;
      property Paused: TALBoolean read fPaused;
      property Stopped: TALBoolean read fStopped;
      property AttenuationEnabled: TALBoolean read fAttenuationEnabled;
      property Loop: TALBoolean read fLoop;

      constructor Create();
      destructor Destroy(); override;

      procedure AssignBuffer(aBuffer: TGEMSoundBuffer);
      procedure UnassignBuffer();

      procedure Play();
      procedure Pause();
      procedure Stop();
      procedure SetPosition(const aPos: TGEMVec3);
      procedure MovePosition(const aPos: TGEMVec3);
      procedure SetGain(const aGain: TALFloat);
      procedure SetRelativeGain(const aLow, aHigh: TALFloat);
      procedure SetPitch(const aPitch: Single);
      procedure SetRadius(const aRadius: TALFloat);
      procedure SetDirection(const aDirection: TGEMVec3);
      procedure DirectAt(const aAt: TGEMVec3);
      procedure SetConeAngle(const aAngle: TALFloat);
      procedure SetOffset(const aOffset: TALFloat);
      procedure EnableAttenuation(const aEnabled: Boolean = True);
      procedure SetLooping(const aLoop: Boolean = True);
  end;


  procedure gemAudioCheckError(const aFuncName: String);
  procedure gemPrepWaveFile(const aFileName: String; out oSize, oFreq: TALSizei; out oFormat: TALEnum; var aData: TALVoid);

implementation

var
  AudioInstance: TGEMAudio;
  Err: TALEnum;


procedure gemAudioCheckError(const aFuncName: String);
  begin
    Err := ALGetError();

    case Err of
      AL_NO_ERROR: { do nothing };
      AL_INVALID_NAME: WriteLn('AL ERROR: ' + aFuncName + ' - AL_INVALID_NAME');
      AL_INVALID_ENUM: WriteLn('AL ERROR: ' + aFuncName + ' - AL_INVALID_ENUM');
      AL_INVALID_VALUE: WriteLn('AL ERROR: ' + aFuncName + ' - AL_INVALID_VALUE');
      AL_INVALID_OPERATION: WriteLn('AL ERROR: ' + aFuncName + ' - AL_INVALID_OPERATION');
      AL_OUT_OF_MEMORY: WriteLn('AL ERROR: ' + aFuncName + ' - AL_OUT_OF_MEMORY');
      else
        WriteLn('AL_ERROR: ' + aFuncName + ' - UNSPECIFIED ERROR');
    end;
  end;

procedure gemPrepWaveFile(const aFileName: String; out oSize, oFreq: TALSizei; out oFormat: TALEnum; var aData: TALVoid);
const FuncName: String = 'gemPrepWaveFile';
var
size, freq: TALSizei;
format: TALEnum;
WAV: TGEMWAVFile;
  begin

    format := 0;
    size := 0;
    freq := 0;
    oSize := size;
    oFreq := freq;
    oFormat := format;

    Initialize(WAV);
    gemLoadWAVFile(aFileName, WAV); // handles more WAV formats that ALutLoadWavFile
    WAV.ConvertToInt(16); // just make everything 16 bit pcm for uniformity

    case WAV.BlockAlignment of
      1:
        begin
          if WAV.Channels = 1 then format := AL_FORMAT_MONO8;
          if WAV.Channels = 2 then format := AL_FORMAT_STEREO8;
        end;

      2:
        begin
          if WAV.Channels = 1 then format := AL_FORMAT_MONO16;
          if WAV.Channels = 2 then format := AL_FORMAT_STEREO16;
        end;
    end;

    aData := WAV.SampleData;

    size := WAV.DataSize;
    freq := WAV.Frequency;

    oSize := size;
    oFormat := format;
    oFreq := freq;

    call_err_macro;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMTimeFloat
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

function TGEMTimeFloat.GetMinutes(): Integer;
  begin
    Exit(trunc(Self.fValue / 60));
  end;

function TGEMTimeFloat.GetSeconds(): Single;
  begin
    Exit(Self.fValue - Self.GetMinutes());
  end;

function TGEMTimeFloat.ToString(): String;
  begin
    Exit(Self.GetMinutes.ToString + ':' + Self.GetSeconds.ToString);
  end;

class operator TGEMTimeFloat.:=(A: Single): TGEMTimeFloat;
  begin
    Result.fValue := A;
  end;

class operator TGEMTimeFloat.:= (A: TGEMTimeFloat): Single;
  begin
    Result := A.Value;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMAudio
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMAudio.Create();
const FuncName: String = 'TGEMAudio.Create';
  begin
    inherited Create();

    InitOpenAL();
    AlutInit(nil, PALByte(argv));
    ALDistanceModel(AL_LINEAR_DISTANCE_CLAMPED);

    AudioInstance := Self;

    Initialize(Self.fBufferList);
    Initialize(Self.fSourceList);

    Self.fListener := TGEMSoundListener.Create();

    call_err_macro;
  end;

procedure TGEMAudio.AddBuffer(aBuffer: TGEMSoundBuffer);
const FuncName: String = 'TGEMAudio.AddBuffer';
var
CanAdd: Boolean;
  begin
    CanAdd := False;

    if Self.fBufferList.High = 0 then begin
      CanAdd := True;
    end else begin
      if Self.fBUfferList.FindFirst(aBuffer) = -1 then begin
        CanAdd := True;
      end;
    end;

    if CanAdd then begin
      Self.fBufferList.PushBack(aBuffer);
    end;

    call_err_macro;
  end;

procedure TGEMAudio.AddSource(aSource: TGEMSoundSource);
const FuncName: String = 'TGEMAudio.AddSource';
var
CanAdd: Boolean;
  begin
    CanAdd := False;

    if Self.fSourceList.High = 0 then begin
      CanAdd := True;
    end else begin
      if Self.fSourceList.FindFirst(aSource) = -1 then begin
        CanAdd := True;
      end;
    end;

    if CanAdd then begin
      Self.fSourceList.PushBack(aSource);
    end;

    call_err_macro;
  end;

procedure TGEMAudio.RemoveBuffer(aBuffer: TGEMSoundBuffer);
const FuncName: String = 'TGEMAudio.RemoveBuffer';
var
I: Integer;
  begin
    Self.fBufferList.DeleteFirst(aBuffer);

    for I := 0 to Self.fSourceList.High do begin
      if Self.fSourceList[I].fBuffer = aBuffer then begin
        Self.fSourceList[I].UnassignBuffer();
      end;
    end;

    call_err_macro;
  end;

procedure TGEMAudio.RemoveSource(aSource: TGEMSoundSource);
const FuncName: String = 'TGEMAudio.RemoveSource';
  begin
    Self.fSourceList.DeleteFirst(aSource);

    call_err_macro;
  end;

procedure TGEMAudio.Update();
const FuncName: String = 'TGEMAudio.Update';
var
I: Integer;
  begin

    for I := 0 to Self.fSourceList.High do begin
      Self.fSourceList[I].UpdateState();
    end;

    call_err_macro;
  end;

procedure TGEMAudio.StopAllPlaying();
const FuncName: String = 'TGEMAudio.StopAllPlaying';
var
State: TALInt;
I: Integer;
  begin

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_PLAYING then begin
        Self.fSourceList[I].Stop();
      end;
    end;

    call_err_macro;
  end;

procedure TGEMAudio.PauseAllPlaying();
const FuncName: String = 'TGEMAudio.PauseAllPlaying';
var
State: TALInt;
I: Integer;
  begin

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_PLAYING then begin
        Self.fSourceList[I].Pause();
      end;
    end;

    call_err_macro;
  end;

procedure TGEMAudio.ResumeAllPaused();
const FuncName: String = 'TGEMAudio.ResumeAllPaused';
var
State: TALInt;
I: Integer;
  begin

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_PAUSED then begin
        Self.fSourceList[I].Play();
      end;
    end;

    call_err_macro;
  end;

function TGEMAudio.GetAllPlaying(): specialize TArray<TGEMSoundSource>;
const FuncName: String = 'TGEMAudio.GetAllPlaying';
var
I: Integer;
C: Integer;
State: TALInt;
  begin

    Initialize(Result);

    if Self.fSourceList.Size = 0 then Exit();

    SetLength(Result, Self.fSourceList.Size);
    C := 0;

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_PLAYING then begin
        Result[C] := Self.fSourceList[I];
        Inc(C);
      end;
    end;

    SetLength(Result, C);

    call_err_macro;
  end;

function TGEMAudio.GetAllPaused(): specialize TArray<TGEMSoundSource>;
const FuncName: String = 'TGEMAudio.GetAllPaused';
var
I: Integer;
C: Integer;
State: TALInt;
  begin

    Initialize(Result);

    if Self.fSourceList.Size = 0 then Exit();

    SetLength(Result, Self.fSourceList.Size);
    C := 0;

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_PAUSED then begin
        Result[C] := Self.fSourceList[I];
        Inc(C);
      end;
    end;

    SetLength(Result, C);
    call_err_macro;
  end;

function TGEMAudio.GetAllStopped(): specialize TArray<TGEMSoundSource>;
const FuncName: String = 'TGEMAudio.GetAllStopped';
var
I: Integer;
C: Integer;
State: TALInt;
  begin

    Initialize(Result);

    if Self.fSourceList.Size = 0 then Exit();

    SetLength(Result, Self.fSourceList.Size);
    C := 0;

    for I := 0 to Self.fSourceList.High do begin
      ALGetSourcei(Self.fSourceList[I].fSource, AL_SOURCE_STATE, @State);
      if State = AL_STOPPED then begin
        Result[C] := Self.fSourceList[I];
        Inc(C);
      end;
    end;

    SetLength(Result, C);

    call_err_macro;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundListener
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMSoundListener.Create();
const FuncName: String = 'TGEMSoundListener.Create';
  begin
    Self.fPosition := Vec3(0, 0, 0);
    Self.fDirection := Vec3(0, 0, 0);
    Self.fUpVector := Vec3(0, 1, 0);
    Self.fGain := 1;
    Self.fAttenuationEnabled := True;

    ALListenerf(AL_GAIN, 1);
    ALListenerfv(AL_POSITION, @Self.fPosition.X);
    ALListenerfv(AL_ORIENTATION, @Self.fDirection.X);

    call_err_macro;
  end;

procedure TGEMSoundListener.UpdateOrientation();
const FuncName: String = 'TGEMSoundListener.UpdateOrientation';
  begin
    ALListenerfv(AL_ORIENTATION, @Self.fDirection.X);
    call_err_macro;
  end;

procedure TGEMSoundListener.SetPosition(const aPos: TGEMVec3);
const FuncName: String = 'TGEMSoundListener.SetPosition';
var
I: Integer;
  begin
    Self.fPosition := aPos;
    ALListenerfv(AL_POSITION, @Self.fPosition.X);

    for I := 0 to AudioInstance.fSourceList.high do begin
      if AudioInstance.fSourceList[I].fAttenuationEnabled = False then begin
        AudioInstance.fSourceList[I].fUsePosition := Self.fPosition;
      end;
    end;

    call_err_macro;
  end;

procedure TGEMSoundListener.MovePosition(const aPos: TGEMVec3);
const FuncName: String = 'TGEMSoundListener.MovePosition';
  begin
    Self.SetPosition(Self.fPosition + aPos);

    call_err_macro;
  end;

procedure TGEMSoundListener.SetDirection(const aDirection: TGEMVec3);
const FuncName: String = 'TGEMSoundListener.SetDirection';
  begin
    Self.fDirection := aDirection;
    Self.UpdateOrientation();
    call_err_macro;
  end;

procedure TGEMSoundListener.DirectAt(const aAt: TGEMVec3);
const FuncName: String = 'TGEMSoundListener.DirectAt';
  begin
    Self.fDirection := Normal(Self.fPosition - aAt);
    Self.UpdateOrientation();
    call_err_macro;
  end;

procedure TGEMSoundListener.SetUpVector(const aUp: TGEMVec3);
const FuncName: String = 'TGEMSoundListener.SetUpVector';
  begin
    Self.fUpVector := aUp;
    Self.UpdateOrientation();
    call_err_macro;
  end;

procedure TGEMSoundListener.SetGain(const aGain: TALFloat);
const FuncName: String = 'TGEMSoundListener.SetGain';
  begin
    Self.fGain := aGain;
    if Self.fGain > 1 then begin
      Self.fGain := 1;
    end else if Self.fGain < 0 then begin
      Self.fGain := 0;
    end;

    ALListenerf(AL_GAIN, Self.fGain);

    call_err_macro;
  end;

procedure TGEMSoundListener.SetMaxDistance(const aDistance: TALFloat);
const FuncName: String = 'TGEMSoundListener.SetMaxDistance';
var
I: Integer;
  begin
    Self.fMaxDistance := abs(aDistance);

    call_err_macro;
  end;

procedure TGEMSoundListener.EnableAttenuation(const aEnabled: Boolean = True);
const FuncName: String = 'TGEMSoundListener.SetMaxDistance';
  begin
    Self.fAttenuationEnabled := aEnabled;
    if aEnabled then begin
      ALDistanceModel(AL_LINEAR_DISTANCE_CLAMPED);
    end else begin
      ALDistanceModel(AL_NONE);
    end;
    call_err_macro;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMSoundBuffer
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMSoundBuffer.Create(const aFileName: String);
const FuncName: String = 'TGEMSoundBuffer.Create';
var
loop: TALInt;
  begin
    Self.fValid := False;

    if FileExists(aFileName) = False then Exit();

    AudioInstance.AddBuffer(Self);

    Self.fValid := True;
    ALGenBuffers(1, @Self.fBuffer);

    gemPrepWaveFile(aFileName, Self.fSize, Self.fFrequency, Self.fFormat, Self.fData);

    ALBufferData(Self.fBuffer, Self.fFormat, Self.fData, Self.fSize, Self.fFrequency);

    case Self.fFormat of
      AL_FORMAT_MONO8:
        begin
          Self.fBitDepth := 8;
          Self.fStereo := False;
        end;

      AL_FORMAT_MONO16:
        begin
          Self.fBitDepth := 16;
          Self.fStereo := False;
        end;

      AL_FORMAT_STEREO8:
        begin
          Self.fBitDepth := 8;
          Self.fStereo := True;
        end;

      AL_FORMAT_STEREO16:
        begin
         Self.fBitDepth := 16;
         Self.fStereo := True;
        end;
    end;

    Self.fLength := (Self.fSize / Self.fFrequency) / (Self.fBitDepth / 8);

    call_err_macro;
  end;

destructor TGEMSoundBuffer.Destroy();
const FuncName: String = 'TGEMSoundBuffer.Destroy';
  begin
    ALutUnloadWav(Self.fFormat, Self.fData, Self.fSize, Self.fFrequency);
    AudioInstance.RemoveBuffer(Self);

    ALDeleteBuffers(1, @Self.fBuffer);

    inherited Destroy();
    call_err_macro;
  end;

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                               TGEMSoundSource
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMSoundSource.Create();
const FuncName: String = 'TGEMSoundSource.Create';
  begin
    inherited Create();

    AudioInstance.AddSource(Self);

    ALGenSources(1, @Self.fSource);
    ALSourcef(Self.fSource, AL_MAX_DISTANCE, 100);
    ALSourcef(Self.fSource, AL_REFERENCE_DISTANCE, 75);
    ALSourcef(Self.fSource, AL_ROLLOFF_FACTOR, 1);
    ALSourcef(Self.fSource, AL_GAIN, 1);
    AlSourcef(Self.fSource, AL_MAX_GAIN, 1);
    ALSourcef(Self.fSource, AL_MIN_GAIN, 0);
    ALSourcef(Self.fSource, AL_CONE_OUTER_GAIN, 1);
    ALSourcef(Self.fSource, AL_CONE_INNER_ANGLE, 1);
    ALSourcef(Self.fSource, AL_CONE_OUTER_ANGLE, 360);

    Self.fPosition := Vec3(0,0,0);
    Self.fLastPosition := Vec3(0,0,0);
    Self.fUsePosition := Vec3(0,0,0);
    Self.fDirection := Vec3(1, 0, 0);
    Self.fConeAngle := Pi * 2;

    Self.fGain := 1;
    Self.fRelativeGain := 1;
    Self.fRelativeGainLow := 0;
    Self.fRelativeGainHigh := 1;
    Self.fGainRange := 1;
    Self.fPitch := 1;

    Self.fAttenuationEnabled := True;

    Self.fPlaying := False;
    Self.fPaused := False;
    Self.fStopped := True;

    call_err_macro;
  end;

destructor TGEMSoundSource.Destroy();
const FuncName: String = 'TGEMSoundSource.Destory';
  begin
    Self.Stop();
    ALSourcei(Self.fSource, AL_BUFFER, 0);
    Self.fBuffer := nil;
    ALDeleteSources(1, @Self.fSource);

    AudioInstance.RemoveSource(Self);

    call_err_macro;
  end;

procedure TGEMSoundSource.UpdateState();
const FuncName: String = 'TGEMSoundSource.UpdateState';
var
State: TALInt;
Diff: TGEMVec3;
  begin

    ALGetSourcei(Self.fSource, AL_SOURCE_STATE, @State);
    case State of
      AL_PLAYING:
        begin
          Self.fPlaying := True;
          Self.fPaused := False;
          Self.fStopped := False;
        end;

      AL_PAUSED:
        begin
          Self.fPlaying := False;
          Self.fPaused := True;
          Self.fStopped := False;
        end;

      AL_STOPPED:
        begin
          Self.fPlaying := False;
          Self.fPaused := False;
          Self.fStopped := True;
        end;
    end;

    ALGetSourcef(Self.fSource, AL_SEC_OFFSET, @Self.fOffset);

    Diff := Self.fPosition - Self.fLastPosition;
    ALSourcefv(Self.fSource, AL_VELOCITY, @Diff.X);
    Self.fLastPosition := Self.fPosition;

    call_err_macro;
  end;

procedure TGEMSoundSource.AssignBuffer(aBuffer: TGEMSoundBuffer);
const FuncName: String = 'TGEMSoundSource.AssignBuffer';
  begin
    if Assigned(aBuffer) = False then Exit();
    if aBuffer.fValid = False then Exit();

    Self.fBuffer := aBuffer;
    ALSourcei(Self.fSource, AL_BUFFER, aBuffer.fBuffer);

    call_err_macro;
  end;

procedure TGEMSoundSource.UnassignBuffer();
const FuncName: String = 'TGEMSoundSource.UnassignBuffer';
  begin
    Self.Stop();
    ALSourcei(Self.fSource, AL_BUFFER, 0);
    Self.fBuffer := nil;
  end;

procedure TGEMSoundSource.Play();
const FuncName: String = 'TGEMSoundSource.Play';
  begin
    if Self.fBuffer = nil then Exit();

    ALSourcePlay(Self.fSource);
    Self.fPlaying := True;
    Self.fPaused := False;
    Self.fStopped := False;

    call_err_macro;
  end;

procedure TGEMSoundSource.Pause();
const FuncName: String = 'TGEMSoundSource.Pause';
  begin
    if Self.fBuffer = nil then Exit();

    ALSourcePause(Self.fSource);
    Self.fPlaying := False;
    Self.fPaused := True;
    Self.fStopped := False;

    call_err_macro;
  end;

procedure TGEMSoundSource.Stop();
const FuncName: String = 'TGEMSoundSource.Stop';
  begin
    if Self.fBuffer = nil then Exit();

    ALSourceStop(Self.fSource);
    Self.fPlaying := False;
    Self.fPaused := False;
    Self.fStopped := True;

    call_err_macro;
  end;

procedure TGEMSoundSource.SetPosition(const aPos: TGEMVec3);
const FuncName: String = 'TGEMSoundSource.SetPosition';
  begin
    Self.fLastPosition := Self.fPosition;
    Self.fPosition := aPos;

    if Self.fAttenuationEnabled then begin
      Self.fUsePosition := Self.fPosition;
    end else begin
      Self.fUsePosition := AudioInstance.Listener.Position;
    end;

    ALSourcefv(Self.fSource, AL_POSITION, @Self.fUsePosition.X);

    call_err_macro;
  end;

procedure TGEMSoundSource.MovePosition(const aPos: TGEMVec3);
const FuncName: String = 'TGEMSoundSource.MovePosition';
  begin
    Self.fLastPosition := Self.fPosition;
    Self.fPosition := Self.fPosition + aPos;

    if Self.fAttenuationEnabled then begin
      Self.fUsePosition := Self.fPosition;
    end else begin
      Self.fUsePosition := AudioInstance.Listener.Position;
    end;

    ALSourcefv(Self.fSource, AL_POSITION, @Self.fUsePosition.X);

    call_err_macro;
  end;

procedure TGEMSoundSource.SetGain(const aGain: TALFloat);
const FuncName: String = 'TGEMSoundSource.SetGain';
  begin
    Self.fGain := aGain;

    if Self.fGain > 1 then begin
      Self.fGain := 1;
    end else if Self.fGain < 0 then begin
      Self.fGain := 0;
    end;

    Self.fRelativeGain := Self.fRelativeGainLow + (Self.fGainRange * Self.fGain);

    ALSourcef(Self.fSource, AL_GAIN, Self.fRelativeGain);

    call_err_macro;
  end;

procedure TGEMSoundSource.SetRelativeGain(const aLow, aHigh: TALFloat);
const FuncName: String = 'TGEMSoundSource.SetRelativeGain';
var
temp: TALFloat;
  begin
    Self.fRelativeGainLow := ClampF(aLow);
    Self.fRelativeGainHigh := ClampF(aHigh);

    if aLow > aHigh then begin
      temp := Self.fRelativeGainLow;
      Self.fRelativeGainLow := Self.fRelativeGainHigh;
      Self.fRelativeGainHigh := temp;
    end;

    Self.fGainRange := Self.fRelativeGainHigh - Self.fRelativeGainLow;

    Self.SetGain(Self.fGain);

    call_err_macro;
  end;

procedure TGEMSoundSource.SetPitch(const aPitch: Single);
  begin
    Self.fPitch := aPitch;
    alSourcef(Self.fSource, AL_PITCH, aPitch);
  end;

procedure TGEMSoundSource.SetRadius(const aRadius: TALFloat);
const FuncName: String = 'TGEMSoundSource.SetRadius';
  begin
    Self.fRadius := abs(aRadius);
    ALSourcef(Self.fSource, AL_MAX_DISTANCE, Self.fRadius);
    ALSourcef(Self.fSource, AL_REFERENCE_DISTANCE, Self.fRadius * 0.25);
    call_err_macro;
  end;

procedure TGEMSoundSource.SetDirection(const aDirection: TGEMVec3);
const FuncName: String = 'TGEMSoundSource.SetDirection';
  begin
    Self.fDirection := Normal(aDirection);
    ALSourcefv(Self.fSource, AL_DIRECTION, @Self.fDirection.X);

    call_err_macro;
  end;

procedure TGEMSoundSource.DirectAt(const aAt: TGEMVec3);
const FuncName: String = 'TGEMSoundSource.DirectAt';
  begin
    Self.SetDirection(Normal(aAt - Self.fDirection));
    call_err_macro;
  end;

procedure TGEMSoundSource.SetConeAngle(const aAngle: TALFloat);
const FuncName: String = 'TGEMSoundSource.SetConeAngle';
var
D: Single;
  begin

    Self.fConeAngle := aAngle;
    D := Degrees(Self.fConeAngle);
    ClampRadians(Self.fConeAngle);
    ClampDegrees(D);
    ALSourcef(Self.fSource, AL_CONE_OUTER_ANGLE, D);

    if D = 360 then begin
      ALSourcef(Self.fSource, AL_CONE_OUTER_GAIN, 1);
    end else begin
      ALSourcef(Self.fSource, AL_CONE_OUTER_GAIN, 0);
    end;

    call_err_macro;
  end;

procedure TGEMSoundSource.SetOffset(const aOffset: TALFloat);
const FuncName: String = 'TGEMSoundSource.SetOffset';
  begin
    Self.fOffset := aOffset;
    if Self.fOffset.Value > Self.fBuffer.fLength.Value then begin
      Self.fOffset.Value := Self.fBuffer.Length.Value;
    end;
    ALSourcef(Self.fSource, AL_SEC_OFFSET, Self.fOffset.Value);
  end;

procedure TGEMSoundSource.EnableAttenuation(const aEnabled: Boolean = True);
const FuncName: String = 'TGEMSoundSource.SetConeAngle';
  begin
    Self.fAttenuationEnabled := aEnabled;
    if aEnabled then begin
      ALSourcei(Self.fSource, AL_SOURCE_RELATIVE, AL_FALSE);
    end else begin
      ALSourcei(Self.fSource, AL_SOURCE_RELATIVE, AL_TRUE);
    end;
    Self.SetPosition(Self.Position);
    call_err_macro;
  end;

procedure TGEMSoundSource.SetLooping(const aLoop: Boolean = True);
const FuncName: String = 'TGEMSoundSource.SetLooping';
  begin
    Self.fLoop := aLoop;
    ALSourcei(Self.fSource, AL_LOOPING, aLoop.ToInteger);
    call_err_macro;
  end;

initialization
  begin
  {$ifdef gemaudio_enable_errors}
    WriteLn('gemaudio error reporting enabled');
  {$endif}
  end;

finalization
  begin
    if Assigned(AudioInstance) then begin
      while AudioInstance.fBufferList.Size > 0 do begin
        AudioInstance.fBufferList[0].Free();
      end;

      while AudioInstance.fSourceList.Size > 0 do begin
        AudioInstance.fSourceList[0].Free();
      end;

      ALutExit();
    end;

    gemAudioCheckError('Finalization');
  end;

end.

