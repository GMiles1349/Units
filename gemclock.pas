unit GEMClock;

{$ifdef FPC}
	{$mode ObjFPC}{$H+}
	{$modeswitch ADVANCEDRECORDS}
{$endif}

interface

uses
  {$ifndef FPC}
  System.SysUtils, WinAPI.Windows,
  {$else}
  Linux, UnixType, BaseUnix,
  {$endif}
  Classes;


  type
    TGEMTriggerType = (GEM_trigger_on_time = 0, GEM_trigger_on_interval = 1);
    TGEMClockEvent = procedure;

    TGEMClock = Class;
    TGEMEvent = Class;


    TGEMClock = Class
      private
        {$ifndef FPC}
        Freq: Int64;
        InTime: Int64;
        {$else}
        Freq: Int64;
        InTime: TTimeSpec;
        {$endif}
        fRunning: Boolean;
        fStartTime: Double;
        fInterval: Double;
        fCurrentTime: Double;
        fLastTime: Double;
        fCycleTime: Double;
        fTargetTime: Double;
        fElapsedTime: Double;
        fFPS: Double;
        fAverageFPS: Double;
        fFPSCount: Integer;
        fFPSTotal: Double;
        fFrames: Integer;
        fFrameTime: Double;
        fCatchUpEnabled: Boolean;
        fTicks: Int64;
        fExpectedTicks: Int64;

        fEvents: specialize TArray<TGEMEvent>;
        fEventCount: Integer;

        procedure Init(); register;
        procedure Update(); register;
        procedure AddEvent(AEvent: TGEMEvent); register;
        procedure RemoveEvent(AEvent: TGEMEvent); register;
        procedure HandleEvents(); register;

        procedure SetCatchUp(Enable: Boolean = True); register;

      public
        property Running: Boolean read fRunning;
        property Ticks: Int64 read fTicks;
        property ExpectedTicks: Int64 read fExpectedTicks;
        property Interval: Double read fInterval;
        property StartTime: Double read fStartTime;
        property CurrentTime: Double read fCurrentTime;
        property LastTime: Double read fLastTime;
        property CycleTime: Double read fCycleTime;
        property TargetTime: Double read fTargetTime;
        property ElapsedTime: Double read fElapsedTime;
        property FPS: Double read fFPS;
        property AverageFPS: Double read fAverageFPS;
        property CatchUpEnabled: Boolean read fCatchUpEnabled write SetCatchUp;

        constructor Create(AFPS: Integer = 60); overload;
        constructor Create(AInterval: Double = 0.0166666); overload;

        procedure Start(); register;
        procedure Stop(); register;
        procedure Wait(); register;
        procedure WaitForStableFrame(); register;
        procedure SetIntervalInSeconds(AInterval: Double); register;
        procedure SetIntervalInFPS(AInterval: Double); register;
        function GetTime(): Double; register;
    end;


    TGEMEvent = class
      private
        fActive: Boolean;
        fRepeating: Boolean;
        fOwner: TGEMClock;
        fEventProc: TGEMClockEvent;
        fTriggerType: TGEMTriggerType;
        fTriggerTime: Double;
        fNextTriggerTime: Double;

        procedure SetRepeating(const Value: Boolean);
        procedure SetEventProc(const Value: TGEMClockEvent);

        // fTriggerTime is used for TriggerTime and TriggerInterval
        // if trigger type is on time, then setting interval or getting interval will fail or return 0
        // if trigger type is on interval, then setting time or getting time with fail or return 0

        function GetTriggerInterval: Double;
        function GetTriggerTime: Double;
        procedure SetTriggerInterval(const Value: Double);
        procedure SetTriggerTime(const Value: Double);
        procedure SetActive(const Value: Boolean);

      public
        property Owner: TGEMClock read fOwner;
        property Active: Boolean read fActive write SetActive;
        property Repeating: Boolean read fRepeating write SetRepeating;
        property EventProc: TGEMClockEvent read fEventProc write SetEventProc;
        property TriggerType: TGEMTriggerType read fTriggerType;
        property TriggerTime: Double read GetTriggerTime write SetTriggerTime;
        property TriggerInterval: Double read GetTriggerInterval write SetTriggerInterval;

        constructor Create(); overload;
        constructor Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtTime: Double); overload;
        constructor Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtInterval: Double; ARepeating: Boolean = False); overload;

        destructor Destroy(); override;

        procedure AssignToOwner(AOwner: TGEMClock; AActive: Boolean = True); register;
        procedure RemoveFromOwner(); register;

end;

implementation

{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMClock
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMClock.Create(AFPS: Integer = 60);
  begin
    Self.Init();
    Self.SetIntervalInFPS(AFPS);
  end;

procedure TGEMClock.AddEvent(AEvent: TGEMEvent);
var
I: Integer;
  begin

    for I := 0 to High(Self.fEvents) do begin
      if Self.fEvents[i] = AEvent then Exit;
    end;

    Inc(Self.fEventCount);
    SetLength(Self.fEvents, Self.fEventCount);
    Self.fEvents[High(Self.fEvents)] := AEvent;
  end;

procedure TGEMClock.RemoveEvent(AEvent: TGEMEvent);
var
I: Integer;
Index: Integer;
  begin

    Index := -1;
    for I := 0 to High(Self.fEvents) do begin
      if Self.fEvents[i] = AEvent then begin
        Index := I;
        Break;
      end;
    end;

    if Index = -1 then Exit;

    Dec(Self.fEventCount);
    Delete(Self.fEvents,Index,1);

  end;

procedure TGEMClock.HandleEvents();
var
I: Integer;
CheckEvent: TGEMEvent;
  begin

    for I := 0 to High(Self.fEvents) do begin

      if Self.fEvents[i].Active = False then Continue;

      case Ord(Self.fEvents[i].TriggerType) of

        Ord(TGEMTriggerType.GEM_trigger_on_time):
          begin

            if Self.fCurrentTime >= Self.fEvents[i].fTriggerTime then begin
              if Assigned(Self.fEvents[i].fEventProc) then begin
                Self.fEvents[i].fEventProc();
              end;

              Self.fEvents[i].SetActive(False);
            end;

          end;

        Ord(TGEMTriggerType.GEM_trigger_on_interval):
          begin

            if Self.fCurrentTime >= Self.fEvents[i].fNextTriggerTime then begin
              if Assigned(Self.fEvents[i].fEventProc) then begin
                CheckEvent := Self.fEvents[i];
                Self.fEvents[i].fEventProc();
              end;

              // checks that the event still exists and is still the same index in the list in case user actions have removed or destroyed it
              if (Assigned(CheckEvent)) and (i <= High(Self.fEvents)) and (Self.fEvents[i] = CheckEvent) then begin
                if Self.fEvents[i].Repeating then begin
                  Self.fEvents[i].fNextTriggerTime := Self.CurrentTime + Self.fEvents[i].fTriggerTime;
                end else begin
                  Self.fEvents[i].SetActive(False);
                end;
              end;

            end;

          end;

      end;

    end;

  end;

constructor TGEMClock.Create(AInterval: Double = 0.0166666);
  begin
    Self.Init();
    Self.SetIntervalInSeconds(AInterval);
  end;

procedure TGEMClock.Init();
  begin
    Self.fRunning := False;
    Self.fCurrentTime := 0;
    Self.fLastTime := 0;
    Self.fCycleTime := 0;
    Self.fTargetTime := 0;
    Self.fElapsedTime := 0;
    self.fFPS := 0;
    Self.fAverageFPS := 0;
    Self.fFPSCount := 0;
    Self.fFPSTotal := 0;
    Self.fFrames := 0;
    Self.fFrameTime := 0;
    Self.fTicks := 0;

    {$ifndef FPC}
    QueryPerformanceFrequency(Self.Freq);
    {$else}
    clock_getres(CLOCK_MONOTONIC, @InTime);
    Freq := Self.InTime.tv_nsec;
    {$endif}
  end;

function TGEMClock.GetTime(): Double;
  begin
    {$ifndef FPC}
    QueryPerformanceCounter(Self.InTime);
    Result := Self.InTime / Self.Freq;
    {$else}
    clock_gettime(CLOCK_MONOTONIC, @InTime);
    Result := InTime.tv_sec + (InTime.tv_nsec * 1e-9);
    {$endif}
  end;

procedure TGEMClock.Update();
var
CalcTarget: Double;
CalcTicks: Double;
  begin
    Inc(Self.fTicks);
    Self.fLastTime := Self.fCurrentTime;
    Self.fCurrentTime := Self.GetTime();
    Self.fCycleTime := Self.CurrentTime - Self.LastTime;
    Self.fElapsedTime := Self.fElapsedTime + Self.fCycleTime;

    if Self.fCatchUpEnabled = False then begin
      Self.fTargetTime := Self.CurrentTime + Self.Interval;
    end else begin
      CalcTicks := (Self.ElapsedTime / Self.Interval);
      CalcTarget := Self.fStartTime + (CalcTicks * Self.Interval);
      Self.fTargetTime := CalcTarget;
      Self.fExpectedTicks := trunc(CalcTicks);
    end;

    // Update FPS
    Self.fFrameTime := Self.fFrameTime + Self.fCycleTime;
    Inc(Self.fFrames);
    if Self.fFrameTime >= 1 then begin
      Self.fFPS := Self.fFrames / Self.fFrameTime;
      Self.fFrameTime := 0;
      Self.fFrames := 0;

      // Update Average FPS
      Self.fFPSTotal := Self.fFPSTotal + Self.fFPS;
      Inc(self.fFPSCount);
      Self.fAverageFPS := Self.fFPSTotal / Self.fFPSCount;

      // reset the FPS total and count at 10,000
      if Self.fFPSCount > 10000 then begin
        Self.fFPSCount := 0;
        Self.fFPSTotal := 0;
      end;
    end;

    // Events
    Self.HandleEvents();

  end;

procedure TGEMClock.SetCatchUp(Enable: Boolean = True);
  begin
    Self.fCatchUpEnabled := Enable;
  end;

procedure TGEMClock.Start();
  begin
    Self.fCurrentTime := Self.GetTime();
    Self.fTargetTime := Self.fCurrentTime + Self.fInterval;
    Self.fRunning := True;
    Self.fStartTime := Self.fCurrentTime;
  end;

procedure TGEMClock.Stop();
  begin
    Self.fRunning := False;
    Self.fStartTime := 0;
    Self.fCurrentTime := 0;
    Self.fElapsedTime := 0;
    Self.fFPS := 0;
    Self.fFPSCount := 0;
    Self.fFPSTotal := 0;
    Self.fLastTime := 0;
    Self.fCycleTime := 0;
    Self.fTargetTime := 0;
    Self.fAverageFPS := 0;
    Self.fFrames := 0;
    Self.fFrameTime := 0;
  end;

procedure TGEMClock.Wait();
var
req, rem: TTimeSpec;
  begin

    req.tv_sec := 0;
    req.tv_nsec := 10000;
    while (Self.GetTime() < Self.TargetTime) do begin
      fpNanoSleep(@req, @rem);
    end;

    Self.Update();
  end;

procedure TGEMClock.WaitForStableFrame();
  begin
    Repeat
      Self.Wait();
    Until Self.FPS >= Self.Interval * 0.99;
  end;

procedure TGEMClock.SetIntervalInSeconds(AInterval: Double);
  begin
    Self.fInterval := AInterval;
  end;

procedure TGEMClock.SetIntervalInFPS(AInterval: Double);
  begin
    Self.fInterval := 1 / AInterval;
  end;


{(*///////////////////////////////////////////////////////////////////////////*)
--------------------------------------------------------------------------------
                                   TGEMEvent
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMEvent.Create;
  begin

  end;

constructor TGEMEvent.Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtTime: Double);
  begin
    Self.fTriggerType := TGEMTriggerType.GEM_trigger_on_time;
    Self.fTriggerTime := ATriggerAtTime;
    Self.fActive := AActive;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
  end;

constructor TGEMEvent.Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtInterval: Double; ARepeating: Boolean);
  begin
    Self.fTriggerType := TGEMTriggerType.GEM_trigger_on_interval;
    Self.fTriggerTime := ATriggerAtInterval;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.fActive := AActive;
    Self.fRepeating := ARepeating;
  end;

destructor TGEMEvent.Destroy;
  begin
    Self.RemoveFromOwner();
    inherited;
  end;

procedure TGEMEvent.AssignToOwner(AOwner: TGEMClock; AActive: Boolean = True);
  begin
    if AOwner = nil then Exit;

    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.SetActive(AActive);

    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TGEMEvent.RemoveFromOwner();
  begin
    if Self.fOwner <> nil then begin
      Self.fOwner.RemoveEvent(Self);
      Self.SetActive(False);
    end;
  end;

function TGEMEvent.GetTriggerInterval: Double;
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_time then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

function TGEMEvent.GetTriggerTime: Double;
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

procedure TGEMEvent.SetTriggerInterval(const Value: Double);
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_time then Exit;

    Self.fTriggerTime := Value;
    if Self.fOwner <> nil then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TGEMEvent.SetTriggerTime(const Value: Double);
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then Exit;

    Self.fTriggerTime := Value;
  end;

procedure TGEMEvent.SetActive(const Value: Boolean);
  begin
    Self.fActive := Value;
    if Value = True then begin

      if Self.fOwner = nil then begin
        Self.fActive := False;
        Exit;
      end;

      if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then begin
        Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
      end;

    end;
  end;

procedure TGEMEvent.SetEventProc(const Value: TGEMClockEvent);
  begin
    fEventProc := Value;
  end;

procedure TGEMEvent.SetRepeating(const Value: Boolean);
  begin
    fRepeating := Value;
  end;




end.
