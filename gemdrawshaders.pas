unit gemdrawshaders;

{$mode Delphi}{$H+}

{$i gemoptimizations.Inc}

interface

uses
  glad_gl, gemutil,
  Classes, SysUtils, StrUtils;

type
  TGEMDrawShaders = class;
  TGEMDrawProgram = class;
  TGEMDrawUniform = class;
  TGEMDrawAttribute = class;

  TGEMDrawShaders = class(TPersistent)
    private
      fProgram: Array of TGEMDrawProgram;
      fCurrentProgram: TGEMDrawProgram;



    public
      //property ShaderProgram[Name: String]: TGEMDrawProgram read GetProgram;
      property CurrentProgram: TGEMDrawProgram read fCurrentProgram;

      procedure LoadProgram(const aDirectory, aProgramName: String);
      procedure UseProgram(const aProgramName: String);

      function GetProgram(Name: String): TGEMDrawProgram;

  end;

  TGEMDrawProgram = class(TPersistent)
    private
      fID: GLUint;
      fVertexShader: GLUint;
      fFragmentShader: GLUint;
      fUniform: Array of TGEMDrawUniform;
      fAttribute: Array of TGEMDrawAttribute;
      fName: String;

      function LoadShader(var aShader: GLUint; const aFileName: String): Integer;
      procedure GetUniforms();
      procedure GetAttributes();

    public
      property ID: GLUint read fID;
      constructor Create(const aVertexPath, aFragmentPath: String);
      function UniformLocation(const aUniformName: String): GLInt;
      procedure Use();

  end;


  TGEMDrawUniform = class(TPersistent)
    private
      fLocation: GLInt;
      fName: String;
    public
      property Location: GLInt read fLocation;
      property Name: String read fName;
  end;


  TGEMDrawAttribute = class(TPersistent)
  private
    fLocation: GLInt;
    fName: String;
  public
    property Location: GLInt read fLocation;
    property Name: String read fName;
  end;

implementation

function TGEMDrawShaders.GetProgram(Name: String): TGEMDrawProgram;
var
UseName: String;
I: Integer;
  begin
    if Length(Self.fProgram) = 0 then Exit(nil);

    Result := nil;
    UseName := LowerCase(Name);

    for I := 0 to High(Self.fProgram) do begin
      if UseName = Self.fProgram[I].fName then begin
        Exit(Self.fProgram[I]);
      end;
    end;
  end;

procedure TGEMDrawShaders.LoadProgram(const aDirectory, aProgramName: String);
  begin
    SetLength(Self.fProgram, Length(Self.fProgram) + 1);
    Self.fProgram[High(Self.fProgram)] := TGEMDrawProgram.Create(aDirectory + aProgramName + '.vert', aDirectory + aProgramName + '.frag');
    Self.fProgram[High(Self.fProgram)].fName := LowerCase(aProgramName);
  end;

procedure TGEMDrawShaders.UseProgram(const aProgramName: String);
var
UseName: String;
I: Integer;
  begin
    if Length(Self.fProgram) = 0 then begin
      glUseProgram(0);
      Exit();
    end;

    UseName := LowerCase(aProgramName);

    for I := 0 to High(Self.fProgram) do begin
      if UseName = Self.fProgram[I].fName then begin
        if Self.fCurrentProgram = Self.fProgram[I] then begin
          Exit();
        end else begin
          glUseProgram(Self.fProgram[I].fID);
          Self.fCurrentProgram := Self.fProgram[I];
          Exit();
        end;
      end;
    end;

  end;

constructor TGEMDrawProgram.Create(const aVertexPath, aFragmentPath: String);
var
Success: GLInt;
Len: GLInt;
Log: Array of Char;
  begin
    Self.fVertexShader := glCreateShader(GL_VERTEX_SHADER);
    Self.fFragmentShader := glCreateShader(GL_FRAGMENT_SHADER);
    Self.LoadShader(Self.fVertexShader, aVertexPath);
    Self.LoadShader(Self.fFragmentShader, aFragmentPath);

    Self.fID := glCreateProgram();
    glAttachShader(Self.fID, Self.fVertexShader);
    glAttachShader(Self.fID, Self.fFragmentShader);
    glLinkProgram(Self.fID);

    glGetProgramiv(Self.fID, GL_LINK_STATUS, @Success);
    if Success = 0 then begin
      glGetProgramiv(Self.fID, GL_INFO_LOG_LENGTH, @Len);
      SetLength(Log, Len);
      glGetProgramInfoLog(Self.fID, Len, @Len, @Log[0]);
      WriteLn(String(Log));
    end;

    Self.GetUniforms();
    Self.GetAttributes();
  end;

function TGEMDrawProgram.UniformLocation(const aUniformName: String): GLInt;
var
I: Integer;
  begin
    Result := -1;

    if Length(Self.fUniform) = 0 then Exit(-1);

    for I := 0 to High(Self.fUniform) do begin
      if Self.fUniform[I].fName = aUniformName then begin
        Exit(Self.fUniform[I].fLocation);
      end;
    end;

  end;

function TGEMDrawProgram.LoadShader(var aShader: GLUint; const aFileName: String): Integer;
var
source: String;
success: GLInt;
  begin
    gemReadFile(aFileName, source);
    glShaderSource(aShader, 1, PPChar(@source), nil);
    glCompileShader(aShader);

    glGetShaderiv(aShader, GL_COMPILE_STATUS, @success);
    if success <> 1 then begin
      WriteLn('Shader failed to compile');
    end;
  end;

procedure TGEMDrawProgram.GetUniforms();
var
UC: GLInt;
MaxLen: GLInt;
NameBuff: String;
SString: Array of String;
AName: String;
AIndex: Integer;
Len: GLSizei;
Size: GLInt;
UType: GLEnum;
I,Z: Integer;
  begin
    glGetProgramiv(Self.fID, GL_ACTIVE_UNIFORMS, @UC);

    if UC = 0 then Exit();

    SetLength(Self.fUniform, UC);

    glGetProgramiv(Self.fID, GL_ACTIVE_UNIFORM_MAX_LENGTH, @MaxLen);
    SetLength(NameBuff, MaxLen);

    for I := 0 to UC - 1 do begin
      glGetActiveUniform(Self.fID, I, MaxLen, @Len, @Size, @UType, @NameBuff[1]);

      Self.fUniform[I] := TGEMDrawUniform.Create();
      Self.fUniform[I].fName := NameBuff[1..Len];

      Self.fUniform[I].fLocation := glGetUniformLocation(Self.fID, PChar(@Self.fUniform[I].fName[1]));
    end;

  end;

procedure TGEMDrawProgram.GetAttributes();
var
AC: GLInt;
MaxLen: GLInt;
NameBuff: String;
Len: GLSizei;
Size: GLInt;
AType: GLEnum;
I: Integer;
  begin
    glGetProgramiv(Self.fID, GL_ACTIVE_ATTRIBUTES, @AC);

    if AC = 0 then Exit();

    SetLength(Self.fAttribute, AC);

    glGetProgramiv(Self.fID,  GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, @MaxLen);
    SetLength(NameBuff, MaxLen);

    for I := 0 to AC - 1 do begin
      glGetActiveAttrib(Self.fID, I, MaxLen, @Len, @Size, @AType, @NameBuff[1]);

      Self.fAttribute[I] := TGEMDrawAttribute.Create();
      Self.fAttribute[I].fName := NameBuff[1..Len];

      Self.fAttribute[I].fLocation := glGetAttribLocation(Self.fID, PChar(@Self.fAttribute[I].fName[1]));
    end;
  end;

procedure TGEMDrawProgram.Use();
  begin
    glUseProgram(Self.fID);
  end;

end.

