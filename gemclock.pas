unit GEMClock;

{$mode Delphi}{$H+}
{$modeswitch ADVANCEDRECORDS}

{ auto inline in release build }
{$ifopt D+}
  {$optimization AUTOINLINE}
{$endif}

interface

uses
  {$ifndef FPC}
  System.SysUtils, WinAPI.Windows,
  {$else}
  Linux, UnixType, BaseUnix, SysUtils,
  {$endif}
  Classes;

type
  TTimeSpec = UnixType.timespec;
  TGEMTriggerType = (GEM_trigger_on_time = 0, GEM_trigger_on_interval = 1);
  TGEMClockEventProc = procedure;

  TGEMClock = Class;
  TGEMClockEvent = Class;

  TGEMDateStruct = record
    private
      fYear: Cardinal;
      fMonth: Cardinal;
      fDay: Cardinal;

      procedure SetYear(const aYear: Cardinal);
      procedure SetMonth(const aMonth: Cardinal);
      procedure SetDay(const aDay: Cardinal);

    public
      property Year: Cardinal read fYear write SetYear;
      property Month: Cardinal read fMonth write SetMonth;
      property Day: Cardinal read fDay write SetDay;

      constructor Create(const aYear, aMonth, aDay: Cardinal);

      procedure SetDate(const aYear, aMonth, aDay: Cardinal);
      procedure SetCurrentDate();
      function Difference(const aDate: TGEMDateStruct): Integer;
  end;


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

      fEvents: TArray<TGEMClockEvent>;
      fEventCount: Integer;

      procedure Init(); register;
      procedure Update(); register;
      procedure AddEvent(AEvent: TGEMClockEvent); register;
      procedure RemoveEvent(AEvent: TGEMClockEvent); register;
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


  TGEMClockEvent = class
    private
      fActive: Boolean;
      fRepeating: Boolean;
      fOwner: TGEMClock;
      fEventProc: TGEMClockEventProc;
      fTriggerType: TGEMTriggerType;
      fTriggerTime: Double;
      fNextTriggerTime: Double;

      procedure SetRepeating(const Value: Boolean);
      procedure SetEventProc(const Value: TGEMClockEventProc);

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
      property EventProc: TGEMClockEventProc read fEventProc write SetEventProc;
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


  (* Date Functions *)
  function gemMonthLength(const aMonth: Cardinal; aYear: Cardinal = 0): Cardinal; overload;
  function gemMonthLength(const aMonth: String; aYear: Cardinal = 0): Cardinal; overload;
  function gemYearLength(const aYear: Cardinal): Cardinal;
  function gemOrdinalDate(const aYear, aMonth, aDay: Cardinal): Cardinal;

  // sleeping
  procedure gemSleep(const amilliseconds: UInt64);
  procedure gemUSleep(const amicroseconds: UInt64);
  procedure gemNSleep(const ananoseconds: UInt64);
  procedure gemSleepUntil(const atime: TTimeSpec); overload;
  procedure gemSleepUntil(const atime: Double); overload;

  // time-keeping
  function gemGetCPUTime(): TTimeSpec; overload;
  function gemGetProcessTime(): TTimeSpec; overload;
  procedure gemResetProcessTime();

  // time conversion
  function gemTStoSecs(const atimespec: TTimeSpec): Double;

implementation

var
  RequiredTime: TTimeSpec;
  RemainingTime: TTimeSpec;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMDateStruct
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMDateStruct.Create(const aYear, aMonth, aDay: Cardinal);
	begin
  	Self.SetYear(aYear);
    Self.SetMonth(aMonth);
    Self.SetDay(aDay);
  end;

procedure TGEMDateStruct.SetYear(const aYear: Cardinal);
	begin
  	fYear := aYear;
  end;

procedure TGEMDateStruct.SetMonth(const aMonth: Cardinal);
	begin
  	if aMonth = 0 then begin
      fMonth := 1;
    end else if aMonth > 12 then begin
      fMonth := 12;
    end else begin
      fMonth := aMonth;
    end;

    Self.SetDay(fDay);
  end;

procedure TGEMDateStruct.SetDay(const aDay: Cardinal);
var
MaxDay: Cardinal;
	begin
  	MaxDay := gemMonthLength(fMonth);
    if aDay = 0 then begin
      fDay := 0;
    end else if aDay > MaxDay then begin
      fDay := MaxDay;
    end else begin
      fDay := aDay;
    end;
  end;

procedure TGEMDateStruct.SetDate(const aYear, aMonth, aDay: Cardinal);
	begin
  	Self.Year := aYear;
    Self.Month := aMonth;
    Self.Day := aDay;
  end;

procedure TGEMDateStruct.SetCurrentDate();
var
y,m,d: Word;
  begin
  	DecodeDate(Date, y, m ,d);
    Self.SetDate(y, m, d);
  end;

function TGEMDateStruct.Difference(const aDate: TGEMDateStruct): Integer;
var
LowDate, HighDate: ^TGEMDateStruct;
SDays, DDays: Cardinal;
YearDiff: Cardinal;
I: Integer;
	begin
    LowDate := nil;
    HighDate := nil;

  	if Self.Year < aDate.Year then begin
      LowDate := @Self;
      HighDate := @aDate;
    end else if aDate.Year < Self.Year then begin
      LowDate := @aDate;
      HighDate := @Self;
    end;

    SDays := gemOrdinalDate(Self.Year, Self.Month, Self.Day);
    DDays := gemOrdinalDate(aDate.Year, aDate.Month, aDate.Day);

    if Assigned(LowDate) then begin
    	YearDiff := 0;
      for I := LowDate^.Year to HighDate^.Year - 1 do begin
        Inc(YearDiff, gemYearLength(I));
      end;

      if LowDate = @Self then begin
        DDays := DDays + YearDiff + 1;
      end else begin
        SDays := SDays + YearDiff + 1;
      end;

      LowDate := nil;
      HighDate := nil;
    end;

    Result := SDays - DDays;
  end;

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

procedure TGEMClock.AddEvent(AEvent: TGEMClockEvent);
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

procedure TGEMClock.RemoveEvent(AEvent: TGEMClockEvent);
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
CheckEvent: TGEMClockEvent;
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
      Self.fTargetTime := Self.fTargetTime + Self.Interval;
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
  begin
    while Self.GetTime() < Self.TargetTime do begin
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
                                   TGEMClockEvent
--------------------------------------------------------------------------------
(*///////////////////////////////////////////////////////////////////////////*)}

constructor TGEMClockEvent.Create;
  begin

  end;

constructor TGEMClockEvent.Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtTime: Double);
  begin
    Self.fTriggerType := TGEMTriggerType.GEM_trigger_on_time;
    Self.fTriggerTime := ATriggerAtTime;
    Self.fActive := AActive;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
  end;

constructor TGEMClockEvent.Create(AOwner: TGEMClock; AActive: Boolean; ATriggerAtInterval: Double; ARepeating: Boolean);
  begin
    Self.fTriggerType := TGEMTriggerType.GEM_trigger_on_interval;
    Self.fTriggerTime := ATriggerAtInterval;
    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.fActive := AActive;
    Self.fRepeating := ARepeating;
  end;

destructor TGEMClockEvent.Destroy;
  begin
    Self.RemoveFromOwner();
    inherited;
  end;

procedure TGEMClockEvent.AssignToOwner(AOwner: TGEMClock; AActive: Boolean = True);
  begin
    if AOwner = nil then Exit;

    Self.fOwner := AOwner;
    Self.fOwner.AddEvent(Self);
    Self.SetActive(AActive);

    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TGEMClockEvent.RemoveFromOwner();
  begin
    if Self.fOwner <> nil then begin
      Self.fOwner.RemoveEvent(Self);
      Self.SetActive(False);
    end;
  end;

function TGEMClockEvent.GetTriggerInterval: Double;
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_time then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

function TGEMClockEvent.GetTriggerTime: Double;
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then begin
      Result := 0;
    end else begin
      Result := Self.fTriggerTime;
    end;
  end;

procedure TGEMClockEvent.SetTriggerInterval(const Value: Double);
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_time then Exit;

    Self.fTriggerTime := Value;
    if Self.fOwner <> nil then begin
      Self.fNextTriggerTime := Self.fOwner.CurrentTime + Self.fTriggerTime;
    end;
  end;

procedure TGEMClockEvent.SetTriggerTime(const Value: Double);
  begin
    if Self.fTriggerType = TGEMTriggerType.GEM_trigger_on_interval then Exit;

    Self.fTriggerTime := Value;
  end;

procedure TGEMClockEvent.SetActive(const Value: Boolean);
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

procedure TGEMClockEvent.SetEventProc(const Value: TGEMClockEventProc);
  begin
    fEventProc := Value;
  end;

procedure TGEMClockEvent.SetRepeating(const Value: Boolean);
  begin
    fRepeating := Value;
  end;

function gemMonthLength(const aMonth: Cardinal; aYear: Cardinal = 0): Cardinal;
	begin

    if aYear = 0 then aYear := CurrentYear();

    case aMonth of
      1: Exit(31);
      2:
      	begin
        	if aYear mod 4 = 0 then begin
            Exit(29);
          end else begin
            Exit(28);
          end;
        end;

      3: Exit(31);
      4: Exit(30);
      5: Exit(31);
      6: Exit(30);
      7: Exit(31);
      8: Exit(31);
      9: Exit(30);
      10:Exit(31);
      11:Exit(30);
      12:Exit(31);
      else Exit(0);

    end;
  end;

function gemMonthLength(const aMonth: String; aYear: Cardinal = 0): Cardinal;
	begin
    if aYear = 0 then aYear := CurrentYear();

  	if CompareText(aMonth, 'JAN') <> 0 then begin
    	Exit(31);
    end else if CompareText(aMonth, 'FEB') <> 0 then begin
      if aYear mod 4 = 0 then begin
        Exit(29);
      end else begin
        Exit(28);
      end;
    end else if CompareText(aMonth, 'MAR') <> 0 then begin
      Exit(31);
    end else if CompareText(aMonth, 'APR') <> 0 then begin
      Exit(30);
    end else if CompareText(aMonth, 'MAY') <> 0 then begin
      Exit(31);
    end else if CompareText(aMonth, 'JUN') <> 0 then begin
      Exit(30);
    end else if CompareText(aMonth, 'JUL') <> 0 then begin
      Exit(31);
    end else if CompareText(aMonth, 'AUG') <> 0 then begin
      Exit(31);
    end else if CompareText(aMonth, 'SEP') <> 0 then begin
      Exit(30);
    end else if CompareText(aMonth, 'OCT') <> 0 then begin
      Exit(31);
    end else if CompareText(aMonth, 'NOV') <> 0 then begin
      Exit(30);
    end else if CompareText(aMonth, 'DEC') <> 0 then begin
      Exit(31);
    end else begin
      Exit(0);
    end;
  end;

function gemYearLength(const aYear: Cardinal): Cardinal;
	begin
    if aYear mod 4 = 0 then Exit(366) else Exit(365);
  end;

function gemOrdinalDate(const aYear, aMonth, aDay: Cardinal): Cardinal;
var
I: Integer;
	begin
    Result := 0;

    if (aMonth = 0) or (aMonth > 12) then Exit(0);
    if (aDay = 0) or (aDay > gemMonthLength(aMonth, aYear)) then Exit(0);

    for I := 1 to aMonth - 1 do begin
    	Result := Result + gemMonthLength(I);
    end;

    Result := Result + aDay;

  end;

procedure gemSleep(const amilliseconds: UInt64);
var
m,s: UInt64;
	begin
  	m := amilliseconds;
    s := 0;
    while m >= 1000 do begin
      s := s + 1;
      m := m - 1000;
    end;

    RequiredTime.tv_sec := s;
    RequiredTime.tv_nsec := m * 1000000;
    FillByte(RemainingTime, sizeof(TTimespec), 0);
    repeat
      fpNanoSleep(@RequiredTime, @RemainingTime);
    until (RemainingTime.tv_nsec = 0) and (RemainingTime.tv_sec = 0);

  end;

procedure gemUSleep(const amicroseconds: UInt64);
var
u,s: UInt64;
	begin
    u := amicroseconds;
		s := 0;
    while u >= 1000000 do begin
      s := s + 1;
      u := u - 1000000;
    end;

    RequiredTime.tv_sec := s;
    RequiredTime.tv_nsec := u * 100;
    FillByte(RemainingTime, sizeof(TTimespec), 0);
    repeat
      fpNanoSleep(@RequiredTime, @RemainingTime);
    until (RemainingTime.tv_nsec = 0) and (RemainingTime.tv_sec = 0);
  end;

procedure gemNSleep(const ananoseconds: UInt64);
var
n,s: UInt64;
	begin
    n := ananoseconds;
		s := 0;
    while n >= 1000000000 do begin
      s := s + 1;
      n := n - 1000000000;
    end;

    RequiredTime.tv_sec := s;
    RequiredTime.tv_nsec := n;
    FillByte(RemainingTime, sizeof(TTimespec), 0);
    repeat
      fpNanoSleep(@RequiredTime, @RemainingTime);
    until (RemainingTime.tv_nsec = 0) and (RemainingTime.tv_sec = 0);
  end;

function gemGetCPUTime(): TTimeSpec;
	begin
  	clock_gettime(CLOCK_MONOTONIC_RAW, @Result);
  end;


function gemGetProcessTime(): TTimeSpec;
	begin
  	clock_gettime(CLOCK_THREAD_CPUTIME_ID, @Result);
  end;

procedure gemResetProcessTime();
	begin
    FillByte(RequiredTime, sizeof(TTimeSpec), 0);
    clock_settime(CLOCK_THREAD_CPUTIME_ID, @RequiredTime);
  end;

function gemTStoSecs(const atimespec: TTimeSpec): Double;
	begin
    Exit(atimespec.tv_sec + (atimespec.tv_nsec * 1e-9));
  end;

procedure gemSleepUntil(const atime: TTimeSpec);
var
UseTime: TTimeSpec;
  begin
  	RequiredTime := gemGetCPUTime();
    UseTime.tv_sec := atime.tv_sec - RequiredTime.tv_sec;
    UseTime.tv_nsec := atime.tv_nsec - RequiredTime.tv_nsec;

    while UseTime.tv_nsec < 0 do begin
      UseTime.tv_nsec := UseTime.tv_nsec + 1000000000;
      UseTime.tv_sec := UseTime.tv_sec - 1;
    end;

    if (UseTime.tv_sec < 0) or (UseTime.tv_nsec < 0) then Exit();

    repeat
    	fpNanoSleep(@UseTime, @RemainingTime);
    until (RemainingTime.tv_sec = 0) and (RemainingTime.tv_nsec = 0);

  end;

procedure gemSleepUntil(const atime: Double);
var
UseTime: TTimeSpec;
Rem: Double;
n,s: Int64;
  begin
    s := trunc(atime);
    Rem := atime - s;
    n := trunc(Rem * 1000000000);
  	RequiredTime := gemGetCPUTime();
    UseTime.tv_sec := s - RequiredTime.tv_sec;
    UseTime.tv_nsec := n - RequiredTime.tv_nsec;

    while UseTime.tv_nsec < 0 do begin
      UseTime.tv_nsec := UseTime.tv_nsec + 1000000000;
      UseTime.tv_sec := UseTime.tv_sec - 1;
    end;

    if (UseTime.tv_sec < 0) or (UseTime.tv_nsec < 0) then Exit();

    repeat
    	fpNanoSleep(@UseTime, @RemainingTime);
    until (RemainingTime.tv_sec = 0) and (RemainingTime.tv_nsec = 0);
  end;




end.
