unit gemgamecontext;

{$mode Delphi}{$H+}
{$modeswitch advancedrecords}

interface

uses
  gemdraw, gemarray,
  Classes, SysUtils;

type

  TGEMContext = class
    public
      Name: String;
      EntryProc: procedure;
      MainProc: procedure;
      ExitProc: procedure;
      KeyDownProc: TGEMDrawKeyProc;
      KeyUpProc: TGEMDrawKeyProc;
      MouseDownProc: TGEMDrawMouseButtonProc;
      MouseUpProc: TGEMDrawMouseButtonProc;
      MouseMoveProc: TGEMDrawMouseMoveProc;
  end;

  TGEMContextController = class
    private
      class var fCurrentContext: TGEMContext;
      class var fContext: TGEMArray<TGEMContext>;

    public
      class property CurrentContext: TGEMContext read fCurrentContext;

      class procedure RegisterContext(aContext: TGEMContext);
      class procedure SetCurrentContext(aContext: TGEMContext; const aDoEntryProc: Boolean = True); overload;
      class procedure SetCurrentContext(const aContextName: String; const aDoEntryProc: Boolean = True); overload;
      class procedure CallContext();

      class procedure OnKeyDown(Key, ScanCode, Mods: Integer); static;
      class procedure OnKeyUp(Key, ScanCode, Mods: Integer); static;
      class procedure OnMouseMove(X, Y: Double); static;
      class procedure OnMouseDown(Button, Mods: Integer); static;
      class procedure OnMouseUp(Button, Mods: Integer); static;
  end;


implementation

class procedure TGEMContextController.RegisterContext(aContext: TGEMContext);
var
I: Integer;
  begin
    for I := 0 to fContext.High do begin
      if fContext[I] = aContext then Exit();
    end;

    fContext.PushBack(aContext);
  end;

class procedure TGEMContextController.SetCurrentContext(aContext: TGEMContext; const aDoEntryProc: Boolean = True);
  begin
    if Assigned(Self.fCurrentContext) then begin
      if Assigned(Self.fCurrentContext.ExitProc) then begin
        Self.fCurrentContext.ExitProc();
      end;
    end;

    Self.fCurrentContext := aContext;
    if aDoEntryProc then begin
      if Assigned(fCurrentContext.EntryProc) then begin
        fCurrentContext.EntryProc();
      end;
    end;
  end;

class procedure TGEMContextController.SetCurrentContext(const aContextName: String; const aDoEntryProc: Boolean = True); overload;
var
I: Integer;
  begin
    for I := 0 to fContext.High do begin
      if fContext[I].Name = aContextName then begin
        SetCurrentContext(fContext[I], aDoEntryProc);
        Exit();
      end;
    end;
  end;

class procedure TGEMContextController.CallContext();
  begin
    if Assigned(fCurrentContext) then begin
      fCurrentContext.MainProc();
    end;
  end;

class procedure TGEMContextController.OnKeyDown(Key, ScanCode, Mods: Integer);
  begin
    if Assigned(fCurrentContext) = False then Exit();

    if Assigned(fCurrentContext.KeyDownProc) then begin
      CurrentContext.KeyDownProc(Key, ScanCode, Mods);
    end;
  end;

class procedure TGEMContextController.OnKeyUp(Key, ScanCode, Mods: Integer);
  begin
    if Assigned(fCurrentContext) = False then Exit();

    if Assigned(fCurrentContext.KeyUpProc) then begin
      CurrentContext.KeyUpProc(Key, ScanCode, Mods);
    end;
  end;

class procedure TGEMContextController.OnMouseMove(X, Y: Double);
  begin
    if Assigned(fCurrentContext) = False then Exit();

    if Assigned(fCurrentContext.MouseMoveProc) then begin
      CurrentContext.MouseMoveProc(X, Y);
    end;
  end;

class procedure TGEMContextController.OnMouseDown(Button, Mods: Integer);
  begin
    if Assigned(fCurrentContext) = False then Exit();

    if Assigned(fCurrentContext.MouseDownProc) then begin
      CurrentContext.MouseDownProc(Button, Mods);
    end;
  end;

class procedure TGEMContextController.OnMouseUp(Button, Mods: Integer);
  begin
    if Assigned(fCurrentContext) = False then Exit();

    if Assigned(fCurrentContext.MouseUpProc) then begin
      CurrentContext.MouseUpProc(Button, Mods);
    end;
  end;

end.

