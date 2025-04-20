unit GEMUtil;

{$ifdef FPC}
  {$mode ObjFPC}{$H+}
  {$modeswitch ADVANCEDRECORDS}
  {$modeswitch TYPEHELPERS}
{$endif}

{$i gemoptimizations.Inc}

interface

uses
  {$ifdef LINUX}
  BaseUnix, Unix, UnixType, Process, ncurses,
  {$else}
  Windows,
  {$endif}

  Classes, SysUtils, StrUtils;


type

  PGEMDirectory = ^TGEMDirectory;
  TGEMDirectory = record
    private
      fPath: String;
      fDirectories: {$ifdef FPC} specialize {$endif} TArray<String>;
      fFiles: {$ifdef FPC} specialize {$endif} TArray<String>;

      procedure SetPath(aPath: String);

      function GetFileCount(): UInt32;
      function GetDirectoryCount(): UInt32;
      function GetFile(Index: UInt32): String;
      function GetDirectory(Index: UInt32): String;

    public
      property Path: String read fPath write SetPath;
      property FileCount: UInt32 read GetFileCount;
      property DirectoryCount: UInt32 read GetDirectoryCount;
      property Files[Index: UInt32]: String read GetFile;
      property Directories[Index: UInt32]: String read GetDirectory;

      function HasFile(const aFileName: String): Boolean;

  end;


  PGEMFileStream = ^TGEMFileStream;
  TGEMFileStream = class(TPersistent)
  	private
      fOpen: Boolean;
      fRootPath: String;
      fFilePath: String;
      fFileName: String;
    	fHandle: cint;
      fStat: Stat;
      fFileSize: Int64;
      fPosition: Integer;
      fBuffer: Array of Byte;

      procedure Initialize();
      function GetFullPath(): String;
      function GetBufferSize(): Cardinal;

    public
      property isOpen: Boolean read fOpen;
      property RootPath: String read fRootPath;
    	property FilePath: String read fFilePath;
      property FileName: String read fFileName;
      property FullPath: String read GetFullPath;
      property FileSize: Int64 read fFileSize;
      property Position: Integer read fPosition;
      property BufferSize: Cardinal read GetBufferSize;

      constructor Create(const aFileName: String = '');
      function Open(const aFileName: String): Integer;
      function Close(): Integer;
      function SetPosition(const aPosition: UInt64): Integer;
      function MovePosition(const aCount: Int64): Integer;
      procedure SeekStart();
      procedure SeekEnd();
      function Read(const aBytesToRead: UInt64 = 0): UInt64;
      function InsertData(aData: String; const aUpdatePosition: Boolean = True): UInt64;
      procedure GetBuffer(var aBuffer: String);

  end;

  (* Posix Error Handling *)
  function gemWriteError(const message: String = ''): Int32;

  (* Function Console Output *)
  procedure gemUtilEnableOutput(const aEnable: Boolean = True);
  procedure gemUtilSendOutput(const aOutput: PChar);

	(* Bit Manipulation *)
  procedure PutBit(var Value: UInt8; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: UInt16; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: UInt32; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: UInt64; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: Int8; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: Int16; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: Int32; Index: Byte; State: Boolean); overload;
  procedure PutBit(var Value: Int64; Index: Byte; State: Boolean); overload;

  function GetBit(Value: UInt8; Index: Byte): Boolean; overload;
  function GetBit(Value: UInt16; Index: Byte): Boolean; overload;
  function GetBit(Value: UInt32; Index: Byte): Boolean; overload;
  function GetBit(Value: UInt64; Index: Byte): Boolean; overload;
  function GetBit(Value: Int8; Index: Byte): Boolean; overload;
  function GetBit(Value: Int16; Index: Byte): Boolean; overload;
  function GetBit(Value: Int32; Index: Byte): Boolean; overload;
  function GetBit(Value: Int64; Index: Byte): Boolean; overload;

  procedure PutAllBits(var Value: UInt8; State: Boolean); overload;
  procedure PutAllBits(var Value: UInt16; State: Boolean); overload;
  procedure PutAllBits(var Value: UInt32; State: Boolean); overload;
  procedure PutAllBits(var Value: UInt64; State: Boolean); overload;
  procedure PutAllBits(var Value: Int8; State: Boolean); overload;
  procedure PutAllBits(var Value: Int16; State: Boolean); overload;
  procedure PutAllBits(var Value: Int32; State: Boolean); overload;
  procedure PutAllBits(var Value: Int64; State: Boolean); overload;

  (* File Functions *)
  procedure gemCheckTrailingSlash(var aDirPath: String); inline;
  function gemFileExists(const aFileName: String): Boolean;
  function gemIsDirectory(aFileName: String): Boolean;
  function gemFindFile(aFileName: String; aRootPath: String): String;
  function gemReadFile(aFileName: String; out aBuffer: UnicodeString): Int32; overload;
  function gemReadFile(aFileName: String; out aBuffer: AnsiString): Int32; overload;
  function gemReadFile(aFileName: String; var aBuffer: {$ifdef FPC} specialize {$endif} TArray<Byte>): Int32; overload;
  function gemReadFile(aFileName: String; var aBuffer: {$ifdef FPC} specialize {$endif} TArray<Char>): Int32; overload;
  function gemReadFile(aFileName: String; var aBuffer: Pointer): Int32; overload;
  function gemWriteFile(const aFileName: String; const aData: Pointer; const aSize: UInt32; const aOverWriteExisting: Boolean = False): Int32; overload;
  function gemWriteFile(const aFileName: String; const aData: PChar; const aOverWriteExisting: Boolean = False): Int32; overload;
  function gemWriteFile(const aFileName: String; const aData: String; const aOverWriteExisting: Boolean = False): Int32; overload;
  function gemAppendFile(const aFileName: String; const aData: Pointer; const aSize: UInt32): Int32; overload;
  function gemDeleteFile(const aFileName: String): Int32;
	function gemDeleteFileOverWrite(const aFileName: String): Int32;
  function gemDeleteDirectory(const aFileName: String): Int32;
  function gemEraseFile(const aFileName: String): Int32;
  function gemListFiles(const aPath: String; var aStringList: {$ifdef FPC} specialize {$endif} TArray<String>): UInt32;
  function gemListDirectories(const aPath: String; var aStringList: {$ifdef FPC} specialize {$endif} TArray<String>): UInt32; overload;
  function gemListDirectories(const aPath: String): {$ifdef FPC} specialize {$endif} TArray<String>; overload;
  function gemRemoveFileExtension(const aFileName: String): String;
  function gemReplaceFileExtension(const aFileName, aNewExtension: String): String;
  function gemFileSize(const aFileName: String): Int64;
  function gemExtractFileName(const aFilePath: String; const aTrimExtension: Boolean): String;

  (* String Functions *)
  function gemCharsToString(const aChars: Array of Char): String;
  function gemPos(aSourceString, aSubString: String; const aStartPosition: Cardinal = 1; const aMatchCase: Boolean = False): Cardinal;
  function gemMultiPos(const aSourceString, aSubString: String; const aStartPosition: Cardinal = 1; const aMatchCase: Boolean = False): {$ifdef FPC} specialize {$endif} TArray<Cardinal>;
  function gemStringSlice(const aSourceString: String; const aStartPos, aLength: Cardinal; const aTruncate: Boolean = False): String;
  function gemSplitString(const aSourceString, aDelimiter: String): {$ifdef FPC} specialize {$endif} TArray<String>;
  function gemParseBetween(const aSourceString, aStartString, aEndString: String): {$ifdef FPC} specialize {$endif} TArray<String>;
  procedure gemReplace(var aText: String; const aOldValue, aNewValue: String; const aCount: Cardinal = 0);
  function gemStrisInt(const aSourceString: String): Boolean;
  function gemGrep(const aSourceString: String; const aPattern: String; const aLimit: Cardinal = 0): {$ifdef FPC} specialize {$endif} TArray<String>;
  procedure strAdd(var S: String; const A: String);
  procedure strCut(var aSource: String; const aSubString: String);
  procedure strTrimPadding(var aSource: String);
  function strTrimLeft(const aSource: String; const aPattern: String): String;
  function strTrimRight(const aSource: String; const aPattern: String): String;
  function StrPad(const aCount: Integer; const aChar: AnsiChar = ' '): String;
  function StrPadLeft(const aText: String; const aPadChar: AnsiChar; const aMaxChars: Cardinal): String;

  (* Memory Functions *)
  function gemInitMemory(const aSize: UInt64; const aValues: Array of Byte): Pointer; overload;
  function gemInitMemory(const aSize: UInt64; const aValues: Pointer; const aValuesSize: Cardinal): Pointer; overload;
  function gemCopyMemory(var aData: Pointer; const aDataSize: Integer): Pointer;

  (* Console / Terminal *)
  function gemPromptYesNo(const aPrompt: String; const aDefault: Integer = -1): Boolean;
  function gemPromptRange(const aPrompt: String; const aLow, aHigh: Integer; const aUseDefault: Boolean = False; const aDefault: Integer = 0): Integer;

  (* Misc / Math *)
  function gemPaethPredictorByte(const A, B, C: Byte): Byte;
  function gemWrapByte(const aValue: Integer): Byte;

  (* Operators *)
  operator := (const A: specialize TArray<String>): String;

var
	GEMOutputEnabled: Boolean = False;

implementation

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                           Posix Error Handling
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

function gemWriteError(const message: String = ''): Int32;
	begin
    if GEMOutputEnabled = False then Exit();

  	Result := ERRNO;
    if Result = 0 then Exit();

    Write(#27'[31m');
    Write('    ERROR: ');
    Write(#27'[0m');

    case Result of
      ESysENOENT: WriteLn(message + 'NO SUCH FILE OR DIRECTORY');
    	ESysENOTDIR: WriteLn(message + 'NOT A DIRECTORY');
      ESysEACCES: WriteLn(message + 'Permission Denied');
    end;



    WriteLn();
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                          Function Console Output
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

procedure gemUtilEnableOutput(const aEnable: Boolean = True);
	begin
  	GEMOutputEnabled := aEnable;
  end;

procedure gemUtilSendOutput(const aOutput: PChar);
	begin
   if GEMOutputEnabled = False then Exit();
   WriteLn(aOutPut);
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              Bit Manipulation
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

procedure PutBit(var Value: UInt8; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((UInt8(1) shl Index) xor High(UInt8))) or (UInt8(State) shl Index);
  end;

procedure PutBit(var Value: UInt16; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((UInt16(1) shl Index) xor High(UInt16))) or (UInt16(State) shl Index);
  end;

procedure PutBit(var Value: UInt32; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((UInt32(1) shl Index) xor High(UInt32))) or (UInt32(State) shl Index);
  end;

procedure PutBit(var Value: UInt64; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((UInt64(1) shl Index) xor High(UInt64))) or (UInt64(State) shl Index);
  end;

procedure PutBit(var Value: Int8; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((Int8(1) shl Index) xor High(Int8))) or (Int8(State) shl Index);
  end;

procedure PutBit(var Value: Int16; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((Int16(1) shl Index) xor High(Int16))) or (Int16(State) shl Index);
  end;

procedure PutBit(var Value: Int32; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((Int32(1) shl Index) xor High(Int32))) or (Int32(State) shl Index);
  end;

procedure PutBit(var Value: Int64; Index: Byte; State: Boolean);
  begin
    Value := (Value and ((Int64(1) shl Index) xor High(Int64))) or (Int64(State) shl Index);
  end;


function GetBit(Value: UInt8; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: UInt16; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: UInt32; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: UInt64; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: Int8; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: Int16; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: Int32; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;

function GetBit(Value: Int64; Index: Byte): Boolean;
  begin
    Result := ((Value shr Index) and 1) = 1;
  end;


procedure PutAllBits(var Value: UInt8; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 7 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: UInt16; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 15 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: UInt32; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 31 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: UInt64; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 63 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: Int8; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 7 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: Int16; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 15 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: Int32; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 31 do begin
    	PutBit(Value, I, State);
  	end;
	end;

procedure PutAllBits(var Value: Int64; State: Boolean);
var
I: UInt8;
  begin
  	for I := 0 to 63 do begin
    	PutBit(Value, I, State);
  	end;
	end;


(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                               TGEMDirectory
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

procedure TGEMDirectory.SetPath(aPath: String);
var
PathLength: Integer;
  begin

    Self.fPath := aPath;
    PathLength := Length(Self.fPath);
    {$ifndef LINUX}
    if (Self.fPath[PathLength] = '/') or (Self.fPath[PathLength] = '\') then begin
      SetLength(Self.fPath, PathLength - 1);
    end;
    {$endif}

    if gemIsDirectory(Self.fPath) = False then begin
      Self.fPath := '';
      SetLength(Self.fDirectories, 0);
      SetLength(Self.fFiles, 0);
      Exit();
    end;

    gemListDirectories(aPath, Self.fDirectories);
    gemListFiles(aPath, Self.fFiles);

  end;

function TGEMDirectory.GetFileCount(): UInt32;
  begin
    Exit(Length(Self.fFiles));
  end;

function TGEMDirectory.GetDirectoryCount(): UInt32;
  begin
    Exit(Length(Self.fDirectories));
  end;

function TGEMDirectory.GetFile(Index: UInt32): String;
  begin
    if Index > High(Self.fFiles) then Exit('');
    Exit(Self.fFiles[Index]);
  end;

function TGEMDirectory.GetDirectory(Index: UInt32): String;
  begin
    if Index > High(Self.fDirectories) then Exit('');
    Exit(Self.fDirectories[Index]);
  end;

function TGEMDirectory.HasFile(const aFileName: String): Boolean;
var
I: Integer;
	begin
    Result := False;

    for I := 0 to High(Self.fFiles) do begin
    	if Self.fFiles[I] = aFileName then begin
        Exit(True);
      end;
    end;

  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              TGEMFileStream
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

constructor TGEMFileStream.Create(const aFileName: String = '');
	begin
  	Self.Initialize();

    if aFileName <> '' then begin
    	Self.Open(aFileName);
    end;
  end;

procedure TGEMFileStream.Initialize();
	begin
    Self.fOpen := False;
    Self.fRootPath := ExtractFilePath(ParamStr(0));
    Self.fFilePath := '';
    Self.fFileName := '';
    Self.fFileSize := 0;
    Self.fPosition := 0;
    Self.fHandle := 0;
    FillByte(Self.fStat, SizeOf(Self.fStat), 0);
    SetLength(Self.fBuffer, 0);
  end;

function TGEMFileStream.GetFullPath(): String;
	begin
  	Exit(Self.fFilePath + Self.fFileName);
  end;

function TGEMFileStream.GetBufferSize(): Cardinal;
	begin
  	Exit(Length(Self.fBuffer));
  end;

function TGEMFileStream.Open(const aFileName: String): Integer;
var
PathString: String;
UseName: String;
	begin
    Self.Close();
    Result := 0;
    UseName := '';
  	PathString := ExtractFilepath(aFileName);
    if PathString <> '' then begin
      if gemFileExists(aFileName) then begin
        UseName := aFileName;
      end;
    end else begin
      UseName := gemFindFile(aFileName, Self.fRootPath);
    end;

    if UseName = '' then begin
    	Self.Initialize();
      Exit(0);
    end;

    Self.fOpen := True;
    Self.fPosition := 0;
    Self.fFilePath := ExtractFilePath(aFileName);
    Self.fFileName := ExtractFileName(aFileName);
    Self.fHandle := fpOpen(aFileName, O_RDWR);
    fpStat(aFileName, Self.fStat);
    Self.fFileSize := Self.fStat.st_size;
  end;

function TGEMFileStream.Close(): Integer;
	begin
  	if Self.fOpen = False then Exit(0);

    fpClose(Self.fHandle);
    Self.Initialize();
  end;

function TGEMFileStream.SetPosition(const aPosition: UInt64): Integer;
	begin

    if Self.fOpen = False then begin
    	Exit(-1);
    end;

  	if aPosition <= Self.fFileSize - 1 then begin
    	fplSeek(Self.fHandle, aPosition, SEEK_SET);
      Self.fPosition := aPosition;
      Exit(Self.fPosition);
    end else begin
      Exit(-1);
    end;
  end;

function TGEMFileStream.MovePosition(const aCount: Int64): Integer;
var
NewPos: Int64;
	begin
    if Self.fOpen = False then begin
    	Exit(-1);
    end;

    NewPos := Self.fPosition + aCount;
    if NewPos < 0 then NewPos := 0;
    if NewPos >= Self.fFileSize then NewPos := Self.fFileSize - 1;
    fplSeek(Self.fHandle, NewPos, SEEK_SET);
    Self.fPosition := NewPos;
    Exit(NewPos);
  end;

procedure TGEMFileStream.SeekStart();
  begin
  	if Self.fOpen = False then Exit();

    fplSeek(Self.fHandle, 0, SEEK_SET);
    Self.fPosition := 0;
  end;

procedure TGEMFileStream.SeekEnd();
	begin
    if Self.fOpen = False then Exit();

    fplSeek(Self.fHandle, Self.fFileSize - 1, SEEK_SET);
    Self.fPosition := Self.fFileSize - 1;
  end;

function TGEMFileStream.Read(const aBytesToRead: UInt64 = 0): UInt64;
var
ReadLen: UInt64;
BuffLeft: UInt64;
	begin
    if Self.fOpen = False then Exit(0);

    ReadLen := aBytesToRead;
    if ReadLen = 0 then ReadLen := Self.fFileSize;

    Result := 0;

    BuffLeft := Self.fFileSize - Self.fPosition;
    if ReadLen > BuffLeft then begin
      Result := BuffLeft;
      ReadLen := BuffLeft;
    end;

    SetLength(Self.fBuffer, ReadLen);
    fpRead(Self.fHandle, Self.fBuffer[0], ReadLen);
    Inc(Self.fPosition, ReadLen);

  end;

function TGEMFileStream.InsertData(aData: String; const aUpdatePosition: Boolean = True): UInt64;
var
DataSize: QWord;
NewPos: UInt64;
Buffer: Array of Byte;
BuffSize: UInt64;
	begin

    DataSize := Length(aData) * SizeOf(aData[1]);
    if DataSize = 0 then Exit(0);

    NewPos := Self.fPosition + DataSize;
    BuffSize := Self.fFileSize - Self.fPosition;
    SetLength(Buffer, BuffSize);

    fpRead(Self.fHandle, Buffer[0], BuffSize);
    fplSeek(Self.fHandle, Self.fPosition, SEEK_SET);

    fpWrite(Self.fHandle, aData[1], DataSize);
    fpWrite(Self.fHandle, Buffer[0], BuffSize);

    if aUpdatePosition = False then begin
      fplSeek(Self.fHandle, Self.fPosition, SEEK_SET);
    end else begin
      fplSeek(Self.fHandle, NewPos, SEEK_SET);
      Self.fPosition := NewPos;
    end;

    fpStat(Self.FullPath, Self.fStat);
    Self.fFileSize := Self.fStat.st_size;

  end;

procedure TGEMFileStream.GetBuffer(var aBuffer: String);
var
CharSize: Integer;
CharLen: Integer;
RemSize: Integer;
	begin
    aBuffer := '0';
    CharSize := SizeOf(aBuffer[1]);
    CharLen := trunc(Self.BufferSize / CharSize);
    RemSize := Self.BufferSize mod CharSize;

    if RemSize = 0 then begin
      SetLength(aBuffer, CharLen);
    end else begin
      SetLength(aBuffer, CharSize + 1);
    end;

    System.Move(Self.fBuffer[0], aBuffer[1], Self.BufferSize);
  end;

(*/////////////////////////////////////////////////////////////////////////////)
(------------------------------------------------------------------------------)
                              File Functions
(------------------------------------------------------------------------------)
(/////////////////////////////////////////////////////////////////////////////*)

procedure gemCheckTrailingSlash(var aDirPath: String); inline;
	begin
  	if aDirPath[High(aDirPath)] <> '/' then aDirPath := aDirPath + '/';
  end;

function gemFileExists(const aFileName: String): Boolean;
var
{$ifdef LINUX}
FHandle: cint;
{$else}
FHandle: HFILE;
OFS: _OFSTRUCT;
{$endif}
  begin

    {$ifdef LINUX}

    	FHandle := 0;
    	FHandle := fpOpen(aFileName, O_RDONLY);
      gemWriteError();
    	Result := FHandle > 0;
      fpClose(FHandle);

    {$else}
      FHandle := OpenFile(PAnsiChar(AnsiString(aFileName)), OFS, OF_EXIST);
      Result := FHandle <> HFILE_ERROR;
      CloseHandle(FHandle);
    {$endif}

  end;


function gemIsDirectory(aFileName: String): Boolean;
var
{$ifdef LINUX}
RetVal: cint;
FStat: Stat;
{$else}
FileInfo: DWORD;
{$endif}
  begin

    {$ifdef LINUX}

    	Result := False;
    	RetVal := fpStat(aFileName, FStat);
    	if (RetVal <> 0) or (FStat.st_mode and S_IFDIR <> 0) then Result := True;
      gemWriteError();

    {$else}

        FileInfo := GetFileAttributes(PWideChar(aFileName));
        Result := (FileInfo and FILE_ATTRIBUTE_DIRECTORY <> 0);

    {$endif}
  end;


function gemFindFile(aFileName: String; aRootPath: String): String;
var
RetName: String;
CheckName: String;
I: Integer;
Dirs: Array of String;
Files: Array of String;
FileCount: Integer;
DirCount: Integer;
FStat: Stat;
  begin

    gemCheckTrailingSlash(aRootPath);

    Initialize(Files);
    Initialize(Dirs);
    Initialize(FStat);
    RetName := '';
    Result := '';

    FileCount := gemListFiles(aRootPath, Files);
    DirCount := gemListDirectories(aRootPath, Dirs);

    if (FileCount = 0) and (DirCount = 0) then Exit;

    for I := 0 to DirCount - 1 do begin
    	fplStat(aRootPath + Dirs[I], FStat);
      if(FStat.st_mode and S_IFLNK = 0) then begin
      	CheckName := gemFindFile(aFileName, aRootPath + Dirs[I] + '/');
        if CheckName <> '' then begin
          if RetName <> '' then RetName := RetName + ',';
          RetName := RetName + CheckName;
        end;
      end else begin
        Dirs[I] := Dirs[I];
      end;
    end;

    for I := 0 to FileCount - 1 do begin
    	fplStat(aRootPath + Files[I], FStat);
      if (FStat.st_mode and S_IFMT <> S_IFLNK) then begin
      	if Files[I] = aFileName then begin
        	if RetName <> '' then RetName := RetName + ',';
          RetName := RetName + aRootPath + Files[I];
        end;
      end;
    end;

    Result := RetName;

  end;


function gemReadFile(aFileName: String; out aBuffer: UnicodeString): Int32;
var
BuffSize: Int32;
Data: Pointer;
I: UInt32;
  begin
  	BuffSize := gemReadFile(aFileName, Data);
    SetLength(aBuffer, BuffSize);

    if BuffSize = 0 then begin
    	Exit(BuffSize);
    end;

    for I := 0 to BuffSize - 1 do begin
    	aBuffer[I + 1] := PChar(Data)[I];
    end;

  end;


function gemReadFile(aFileName: String; out aBuffer: AnsiString): Int32;
var
BuffSize: Int32;
Data: Pointer;
I: UInt32;
  begin
  	BuffSize := gemReadFile(aFileName, Data);
    SetLength(aBuffer, BuffSize);

    if BuffSize <= 0 then begin
    	Exit(BuffSize);
    end;

    for I := 0 to BuffSize - 1 do begin
    	aBuffer[I + 1] := PAnsiChar(Data)[I];
    end;

    Exit(BuffSize);

  end;

function gemReadFile(aFileName: String; var aBuffer: {$ifdef FPC} specialize {$endif} TArray<Byte>): Int32;
var
BuffSize: Int32;
Data: Pointer;
I: UInt32;
  begin
  	BuffSize := gemReadFile(aFileName, Data);
    SetLength(aBuffer, BuffSize);

    if BuffSize = 0 then begin
    	Exit(BuffSize);
    end;

    for I := 0 to BuffSize - 1 do begin
    	aBuffer[I] := PByte(Data)[I];
    end;

  end;


function gemReadFile(aFileName: String; var aBuffer: {$ifdef FPC} specialize {$endif} TArray<Char>): Int32;
var
BuffSize: Int32;
Data: Pointer;
I: UInt32;
  begin
  	BuffSize := gemReadFile(aFileName, Data);
    SetLength(aBuffer, BuffSize);

    if BuffSize = 0 then begin
    	Exit(BuffSize);
    end;

    for I := 0 to BuffSize - 1 do begin
    	aBuffer[I] := PChar(Data)[I];
    end;

  end;


function gemReadFile(aFileName: String; var aBuffer: Pointer): Int32;
var
ReadSize: Integer;
RetVal: Integer;
{$ifdef LINUX}
FHandle: cint;
HStat: Stat;
{$else}
FHandle: HFILE;
OFS: _OFSTRUCT;
BytesRead: Cardinal;
FileSize: Int64;
{$endif}
  begin

    {$ifdef LINUX}

      FHandle := fpOpen(aFileName, O_RDONLY, O_RDONLY);
      if FHandle = -1 then Exit(-1);

      Initialize(HStat);
      fpfStat(FHandle, HStat);

      if HStat.st_size = 0 then begin
        ReadSize := 512000;
      end else begin
        ReadSize := HStat.st_size;
      end;

      aBuffer := GetMemory(ReadSize);

      RetVal := fpRead(FHandle, aBuffer^, ReadSize);

      if RetVal < ReadSize then begin
        aBuffer := ReallocMem(aBuffer, RetVal);
        ReadSize := RetVal;
      end;

      fpClose(FHandle);
      Exit(ReadSize);

    {$else}

      FHandle := OpenFile(PAnsiChar(AnsiString(aFileName)), OFS, OF_EXIST);
      if FHandle = HFILE_ERROR then begin
        Exit(-1);
      end;

      GetFileSizeEX(FHandle, FileSize);

      aBuffer := GetMemory(FileSize);
      Windows.ReadFile(FHandle, aBuffer, FileSize, BytesRead, nil);

      CloseHandle(FHandle);

      Exit(FileSize);

    {$endif}
  end;


function gemWriteFile(const aFileName: String; const aData: Pointer; const aSize: UInt32; const aOverWriteExisting: Boolean = False): Int32;
var
{$ifdef LINUX}
FHandle: cint;
{$else}
FHandle: HFILE;
OFS: _OFSTRUCT;
Flags: Integer;
BytesWritten: Cardinal;
{$endif}
  begin

    {$ifdef LINUX}

      Result := 0;

      if aSize = 0 then Exit(0);

      FHandle := fpOpen(aFileName, O_RDWR or O_CREAT or O_TRUNC);

      if FHandle = -1 then begin
        gemWriteError('Cannot open file ' + aFileName + ': ');
      end;

      if FHandle <> -1 then begin
        if aOverWriteExisting = False then Exit(-1);
      end;

      Result := fpWrite(FHandle, aData, aSize);

      fpClose(FHandle);

    {$else}

      Flags := OPEN_ALWAYS;
      FHandle := OpenFile(PAnsiChar(AnsiString(aFileName)), OFS, OF_EXIST);

      if FHandle <> HFILE_ERROR then begin
        Flags := Flags or TRUNCATE_EXISTING;
        if aOverWriteExisting = False then Exit(-1);
      end;


      FHandle := CreateFile(PWideChar(aFileName), GENERIC_WRITE, 0, nil, Flags, 0, 0);
      Windows.WriteFile(FHandle, aData, aSize, BytesWritten, nil);

      CloseHandle(FHandle);
    {$endif}
  end;


function gemWriteFile(const aFileName: String; const aData: PChar; const aOverWriteExisting: Boolean = False): Int32;
  begin
    Result := gemWriteFile(aFileName, aData, StrLen(aData), aOverWriteExisting);
  end;

function gemWriteFile(const aFileName: String; const aData: String; const aOverWriteExisting: Boolean = False): Int32;
var
DataSize: UInt32;
  begin
    DataSize := Length(aData);
    Result := gemWriteFile(aFileName, PByte(@aData[1]), DataSize, aOverWriteExisting);
  end;

function gemAppendFile(const aFileName: String; const aData: Pointer; const aSize: UInt32): Int32;
var
FHandle: cint;
  begin

    Result := 0;

    FHandle := fpOpen(aFileName, O_RDWR or O_APPEND);
    if FHandle = -1 then begin
      Exit(-1);
    end;

    Result := fpWrite(FHandle, aData, aSize);
    fpClose(FHandle);

  end;

function gemDeleteFileOverWrite(const aFileName: String): Int32;
var
Buff: Array [0..99] of Byte;
FileSize: Int64;
CurPos: Int64;
FHandle: cint;
FStat: Stat;
	begin

    // open the file and get the file size, seek to position 0
    FHandle := fpOpen(aFileName, O_WRONLY, S_IRWXU);
    if FHandle = -1 then begin
      if gemFileExists(aFileName) then begin
        gemUtilSendOutput(PChar('Could not delete file ' + aFileName + '. Access Denied'));
        Exit(-1);
      end else begin
      	gemUtilSendOutput(PChar('File ' + aFileName + ' does not exist.'));
        Exit(-1);
      end;
    end;

    fpfStat(FHandle, FStat);
    FileSize := FStat.st_size;
    fpLSeek(FHandle, 0, SEEK_SET);
    CurPos := 0;

    // initialize the write buffer with 0's
    Initialize(Buff);
    FillByte(Buff[0], 100, 0);

    // write 100 bytes at a time, seek forward
    while CurPos < (FileSize - 100) - 1 do begin
    	fpWrite(FHandle, Buff[0], 100);
      Inc(CurPos, 100);
      fpLSeek(FHandle, CurPos, SEEK_SET);
    end;

    // overwrite remaining amount
    if CurPos <> FileSize - 1 then begin
    	fpWrite(FHandle, Buff[0], (FileSize) - CurPos);
    end;

    // unlink / delete file, close the handle
    fpUnLink(aFileName);
		fpClose(FHandle);

    // send output
    gemUtilSendOutput(PChar(aFileName + ': Overwrote ' + FileSize.ToString + ' bytes and deleted.'));

    Exit(0);

  end;

function gemDeleteFile(const aFileName: String): Int32;
var
I,R,T: Integer;
Dir: TGEMDirectory;
FDir: TGEMDirectory;
	begin
    Write('Attempting to delete file ' + aFileName + '... ');
  	if gemFileExists(aFileName) = False then Exit(-1);

    Result := fpUnlink(aFileName);
    case Result of
    	-1: // Failed
        begin
        	WriteLn('Failed!');
          gemWriteError();
        end;

      else // Succeeded
        WriteLn('Success!');
    end;
  end;

function gemDeleteDirectory(const aFileName: String): Int32;
var
I: Integer;
Files, Directories: Array of String;
FileCount, DirectoryCount: UInt32;
	begin

    // Just delete if regular file
    if not gemIsDirectory(aFileName) then begin
      Exit(gemDeleteFile(aFileName));
    end;

    Write('Attempting to delete directory ' + aFileName + '... ');

    Initialize(Files);
    Initialize(Directories);

    FileCount := gemListFiles(aFileName, Files);
    DirectoryCount := gemListDirectories(aFileName, Directories);

    // Delete all files
    for I := 0 to FileCount - 1 do begin
      gemDeleteFile(aFileName + '/' + Files[I]);
    end;

    // Recursively delete all sub-directories
    for I := 0 to DirectoryCount - 1 do begin
      WriteLn();
    	gemDeleteDirectory(aFileName + '/' + Directories[I]);
    end;

    // Delete this directory
    Result := fpRmdir(aFileName);
    if Result = -1 then begin
    	WriteLn('Failed!');
      gemWriteError();
    end else begin
      WriteLn('Success!');
    end;

  end;

function gemEraseFile(const aFileName: String): Int32;
var
H: cint;
	begin
  	if gemFileExists(aFileName) = False then Exit(-1);
    gemWriteFile(aFileName, nil, 0, True);
  end;

function gemListFiles(const aPath: String; var aStringList: {$ifdef FPC} specialize {$endif} TArray<String>): UInt32;
var
{$ifdef LINUX}
DirStream: PDirent;
CurDir: PDir;
{$else}
FileInfo: WIN32_FIND_DATAW;
FHandle: HFILE;
IsDir: Boolean;
RetVal: Boolean;
{$endif}
  begin

    Result := 0;
    SetLength(aStringList, 0);

    {$ifdef LINUX}

			CurDir := fpOpenDir(aPath);
    	if CurDir = nil then begin
      	Exit(0);
    	end;

    	DirStream := fpReadDir(CurDir^);

      if DirStream = nil then Exit(0);

      while DirStream <> nil do begin
        if (DirStream^.d_name <> '.') and (DirStream^.d_name <> '..') then begin
      	  if gemIsDirectory(aPath + DirStream^.d_name) = False then begin
        	  Inc(Result);
            SetLength(aStringList, Result);
            aStringList[High(aStringlist)] := DirStream^.d_name;
          end;
        end;
        DirStream := fpReadDir(CurDir^);
      end;

      fpCloseDir(CurDir^);

    {$else}

      // get the first file in the directory
      FHandle := FindFirstFile(PWideChar(aPath + '*'), FileInfo);

      if FHandle = INVALID_HANDLE_VALUE then begin
        Exit(0);
      end else begin
        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = False) then begin
          Inc(Result);
          SetLength(aStringList, Result);
          aStringList[Result - 1] := FileInfo.cFileName;
        end;
      end;

      // loop through the rest of them
      while FHandle <> INVALID_HANDLE_VALUE do begin
        RetVal := FindNextFile(FHandle, FileInfo);
        if RetVal = False then Break;

        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = True) then Continue;

        Inc(Result);
        SetLength(aStringList, Result);
        aStringList[Result - 1] := FileInfo.cFileName;

      end;


    {$endif}

  end;


function gemListDirectories(const aPath: String; var aStringList: {$ifdef FPC} specialize {$endif} TArray<String>): UInt32;
var
{$ifdef LINUX}
DirStream: PDirent;
CurDir: PDir;
{$else}
FileInfo: WIN32_FIND_DATAW;
FHandle: HFILE;
IsDir: Boolean;
RetVal: Boolean;
{$endif}
  begin

    Result := 0;
    SetLength(aStringList, 0);

    {$ifdef LINUX}

    	CurDir := fpOpenDir(aPath);
    	if CurDir = nil then begin
      	Exit(0);
    	end;

    	DirStream := fpReadDir(CurDir^);

      if DirStream = nil then Exit(0);

      while DirStream <> nil do begin
        if (DirStream^.d_name <> '.') and (DirStream^.d_name <> '..') then begin
      	  if gemIsDirectory(aPath + DirStream^.d_name) = True then begin
        	  Inc(Result);
            SetLength(aStringList, Result);
            aStringList[High(aStringlist)] := DirStream^.d_name;
          end;
        end;
        DirStream := fpReadDir(CurDir^);
      end;

      fpCloseDir(CurDir^);

    {$else}

      // get the first file in the directory
      FHandle := FindFirstFile(PWideChar(aPath + '*'), FileInfo);

      if FHandle = INVALID_HANDLE_VALUE then begin
        Exit(0);
      end else begin
        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = True) then begin
          Inc(Result);
          SetLength(aStringList, Result);
          aStringList[Result - 1] := FileInfo.cFileName;
        end;
      end;

      // loop through the rest of them
      while FHandle <> INVALID_HANDLE_VALUE do begin
        RetVal := FindNextFile(FHandle, FileInfo);
        if RetVal = False then Break;

        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = False) then Continue;

        Inc(Result);
        SetLength(aStringList, Result);
        aStringList[Result - 1] := FileInfo.cFileName;

      end;


    {$endif}

  end;

function gemListDirectories(const aPath: String): {$ifdef FPC} specialize {$endif} TArray<String>;
var
{$ifdef LINUX}
DirStream: PDirent;
CurDir: PDir;
Count: UInt32;
{$else}
FileInfo: WIN32_FIND_DATAW;
FHandle: HFILE;
IsDir: Boolean;
RetVal: Boolean;
{$endif}
  begin

    Initialize(Result);
    Count := 0;

    {$ifdef LINUX}

    	CurDir := fpOpenDir(aPath);
    	if CurDir = nil then begin
      	Exit();
    	end;

    	DirStream := fpReadDir(CurDir^);

      if DirStream = nil then Exit();

      while DirStream <> nil do begin
        if (DirStream^.d_name <> '.') and (DirStream^.d_name <> '..') then begin
      	  if gemIsDirectory(aPath + DirStream^.d_name) = True then begin
        	  Inc(Count);
            SetLength(Result, Count);
            Result[High(Result)] := DirStream^.d_name;
          end;
        end;
        DirStream := fpReadDir(CurDir^);
      end;

      fpCloseDir(CurDir^);

    {$else}

      // get the first file in the directory
      FHandle := FindFirstFile(PWideChar(aPath + '*'), FileInfo);

      if FHandle = INVALID_HANDLE_VALUE then begin
        Exit(0);
      end else begin
        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = True) then begin
          Inc(Result);
          SetLength(aStringList, Result);
          aStringList[Result - 1] := FileInfo.cFileName;
        end;
      end;

      // loop through the rest of them
      while FHandle <> INVALID_HANDLE_VALUE do begin
        RetVal := FindNextFile(FHandle, FileInfo);
        if RetVal = False then Break;

        IsDir := (FileInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0);
        if (IsDir = False) then Continue;

        Inc(Result);
        SetLength(aStringList, Result);
        aStringList[Result - 1] := FileInfo.cFileName;

      end;


    {$endif}

  end;

function gemRemoveFileExtension(const aFileName: String): String;
var
DPos: Integer;
	begin
    DPos := Pos('.', aFileName);
    if DPos = 0 then Exit(aFileName);
    Exit( MidStr(aFileName, 0, DPos - 1 ));
  end;

function gemReplaceFileExtension(const aFileName, aNewExtension: String): String;
var
UseExt: String;
	begin
    UseExt := aNewExtension;
    if Pos('.', UseExt) = 0 then begin
    	UseExt := '.' + UseExt;
    end;

  	Exit( gemRemoveFileExtension(aFileName) + UseExt);
  end;

function gemFileSize(const aFileName: String): Int64;
var
fstat: stat;
	begin
    if gemFileExists(aFileName) = False then Exit(0);
    if gemIsDirectory(aFileName) then Exit(0);

    Initialize(fstat);
    fpStat(aFileName, fstat);
    Exit(fstat.st_size);
  end;

function gemExtractFileName(const aFilePath: String; const aTrimExtension: Boolean): String;
var
SlashPos, DotPos: Integer;
  begin
    // find last occurance of / or \
    SlashPos := High(aFilePath);
    DotPos := SlashPos;
    while SlashPos >= 1 do begin
      if (aFilePath[SlashPos] = '/') or (aFilePath[SlashPos] = '\') then break;
      Dec(SlashPos);
    end;

    if aTrimExtension then begin
      while DotPos > 1 do begin
        if aFilePath[DotPos] = '.' then break;
        Dec(DotPos);
      end;
    end;

    Result := aFilePath[SlashPos + 1 .. DotPos - 1];
  end;

function gemCharsToString(const aChars: Array of Char): String;
// turn array of char into string
// check for null terminator, do not include
var
I: Integer;
	begin
    Result := '';
		for I := 0 to High(aChars) do begin
    	if achars[I] = #$00 then begin
      	Exit();
      end;
      Result := Result + aChars[I];
    end;
  end;

function gemPos(aSourceString, aSubString: String; const aStartPosition: Cardinal = 1; const aMatchCase: Boolean = False): Cardinal;
// return 0 on no instance of substring found
var
I: Integer;
CurPos: Integer;
CheckPos: Integer;
SourceLen, SubLen: Integer;
Found: Boolean;
	begin
    Result := 0;
    CurPos := aStartPosition;

    SourceLen := Length(aSourceString);
    	if SourceLen = 0 then Exit(0);
      if CurPos > SourceLen then Exit(0);
    SubLen := Length(aSubString);
    	if Sublen = 0 then Exit(0);
      if CurPos + (SubLen - 1) > SourceLen then Exit(0);

    // adjust case of strings if no match case
    if aMatchCase = False then begin
      aSourceString := UpperCase(aSourceString);
      aSubString := UpperCase(aSubString);
    end;

    while CurPos <= SourceLen do begin
      if aSourceString[CurPos] = aSubString[1] then begin

        Found := True;

        for I := 2 to SubLen do begin
        	CheckPos := CurPos + (I - 1);
          // exit on checking beyond lenght of source
          if CheckPos > SourceLen then begin
            Exit(0);
          end;

          // exit on characters dont match
          if aSourceString[CheckPos] <> aSubString[I] then begin
            CurPos := CheckPos - 1;
            Found := False;
            break;
          end;

        end;

        // if we got here, we found the whole string, exit with CurPos
        if Found = True then begin
        	Exit(CurPos);
        end;

      end;

      Inc(CurPos,1);
    end;

	end;


function gemMultiPos(const aSourceString, aSubString: String; const aStartPosition: Cardinal = 1; const aMatchCase: Boolean = False): {$ifdef FPC} specialize {$endif} TArray<Cardinal>;
var
CurPos: Integer;
FoundCount: Integer;
RetVal: Cardinal;
	begin
    SetLength(Result, 0);
    FoundCount := 0;

    CurPos := aStartPosition;
    while CurPos <= Length(aSourceString) do begin
    	RetVal := gemPos(aSourceString, aSubString, CurPos, aMatchCase);
      if RetVal <> 0 then begin
        Inc(FoundCount);
        SetLength(Result, FoundCount);
        Result[FoundCount - 1] := RetVal;
        CurPos := Retval + (Length(aSubString));
      end else begin
      	Exit();
      end;
    end;

	end;


function gemStringSlice(const aSourceString: String; const aStartPos, aLength: Cardinal; const aTruncate: Boolean = False): String;
var
I: Integer;
CurPos: Integer;
EndPos: Integer;
SubLen: Integer;
	begin
    if aStartPos > Length(aSourceString) then Exit('');

    EndPos := aStartPos + (aLength - 1);
    SubLen := aLength;
    if EndPos > Length(aSourceString) then begin
    	if aTruncate = False then begin
        Exit();
      end else begin
      	SubLen := (Length(aSourceString) - aStartPos) + 1;
        EndPos := aStartPos + (SubLen - 1);
      end;
    end;

    CurPos := 1;
    SetLength(Result, SubLen);
    for I := aStartPos to EndPos do begin
    	Result[CurPos] := aSourceString[I];
      Inc(CurPos, 1);
    end;
  end;


function gemSplitString(const aSourceString, aDelimiter: String): {$ifdef FPC} specialize {$endif} TArray<String>;
var
DelPos, DelLength: Integer;
CurPos, CheckStart: Integer;
FoundCount: Integer;
ParseStart, ParseEnd, ParseLength: Integer;
	begin

    Initialize(Result);
    SetLength(Result, 0);
    // can't split if source isn't bigger than the delimiter + 1
    if Length(aSourceString) < Length(aDelimiter) + 1 then Exit();

    // can't delimit on an empty delimiter
    if Length(aDelimiter) = 0 then Exit();

    FoundCount := 0;
    CurPos := 1;
    CheckStart := 1;
    DelLength := Length(aDelimiter);

		while True do begin
      if CurPos >= Length(aSourceString) - DelLength then Break;

    	DelPos := gemPos(aSourceString, aDelimiter, CurPos, True);
      if DelPos = 0 then begin
      	ParseStart := CurPos;
        ParseEnd := High(aSourceString);
        ParseLength := (ParseEnd - ParseStart) + 1;
        Inc(FoundCount, 1);
        SetLength(Result, FoundCount);
        Result[FoundCount - 1] := gemStringSlice(aSourceString, ParseStart, ParseLength, False);
        Exit();
      end;

      if DelPos = CheckStart then begin
        CurPos := DelPos + (DelLength - 1);
        CheckStart := CurPos;
        Continue;
      end;

      ParseStart := CurPos;
      ParseEnd := ParseStart + ((DelPos - CurPos) - 1);
      ParseLength := (ParseEnd - ParseStart) + 1;
      Inc(FoundCount, 1);
      SetLength(Result, FoundCount);
      Result[FoundCount - 1] := gemStringSlice(aSourceString, ParseStart, ParseLength, False);
      CurPos := DelPos + (DelLength);
      CheckStart := CurPos;

    end;

  end;


function gemParseBetween(const aSourceString, aStartString, aEndString: String): {$ifdef FPC} specialize {$endif} TArray<String>;
// find instances of text between aStartString and aEndString in aSourceString
// checks for nested start/end
var
FoundCount: Integer;
CurPos: Integer;
CheckPos: Integer;
SPos, EPos: Cardinal;
ParseStart, ParseEnd, ParseLength: Integer;
RetVals, EndVals: Array of Cardinal;
	begin

    Initialize(Result);
    FoundCount := 0;
		CurPos := 1;

    while CurPos < High(aSourceString) do begin

      SPos := gemPos(aSourceString, aStartString, CurPos, True);
      if SPos = 0 then Exit();

      SPos := SPos + Length(aStartString);
      EPos := gemPos(aSourceString, aEndString, SPos + 1, True);
      if EPos = 0 then Exit();

      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := aSourceString[SPos..EPos-1];

      CurPos := CurPos + Length(aEndString);

    end;

  end;

procedure gemReplace(var aText: String; const aOldValue, aNewValue: String; const aCount: Cardinal = 0);
var
P: Integer;
R: Integer;
CurPos: Integer;
NewString: String;
  begin
    R := 0;
    CurPos := 1;
    Initialize(NewString);

    while True do begin
    	P := Pos(aOldValue, aText, CurPos);

      if P <> 0 then begin
      	NewString := NewString + aText[CurPos..P-1];
        if Length(aNewValue) <> 0 then NewString := NewString + aNewValue;
        CurPos := P + Length(aOldValue);
        Inc(R);
      end else begin
        Break;
      end;

      if R <> 0 then begin
        if R >= aCount then begin
          Break;
        end;
      end;

    end;

		if CurPos < High(aText) then begin
      NewString := NewString + aText[CurPos..High(aText)];
    end;

    aText := NewString;

  end;

function gemStrisInt(const aSourceString: String): Boolean;
var
I: Integer;
	begin
  	Result := False;

    try
      I := aSourceString.ToInteger();
      Exit(True);
    except
      Exit(False);
    end;
  end;

function gemGrep(const aSourceString: String; const aPattern: String; const aLimit: Cardinal = 0): {$ifdef FPC} specialize {$endif} TArray<String>;
var
I: Integer;
C: Integer;
SString: Array of String;
	begin
    Initialize(Result);
    C := 0;

    SString := SplitString(aSourceString, sLineBreak);
    for I := 0 to High(SString) do begin
    	if Pos(aPattern, SString[I]) <> 0 then begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := SString[I];
        Inc(C);
        if C = aLimit then begin
          Exit();
        end;
      end;
    end;

  end;

procedure strAdd(var S: String; const A: String);
	begin
  	S := S + A;
  end;

procedure strCut(var aSource: String; const aSubString: String);
	begin
		if gemPos(aSource, aSubString) <> 0 then begin
    	aSource := AnsiMidStr(aSource, Length(aSubString) + 1, (Length(aSource)) - Length(aSubString));
    end;
  end;

procedure strTrimPadding(var aSource: String);
var
I: Integer;
Sel: Integer;
	begin
    if Length(aSource) = 0 then Exit;

    Sel := 0;

    // trim left
    for I := 1 to High(aSource) do begin
    	if (aSource[I] <> ' ') then begin
        if Sel <> 0 then begin
        	Delete(aSource, 1, Sel);
        end;
        break;
      end;
      Inc(Sel);
    end;

    Sel := 0;
    I := High(aSource);
    while true do begin
      if aSource[I] <> ' ' then begin
        if Sel <> 0 then begin
        	Delete(aSource, I + 1, Sel);
        end;
        break;
      end;
      Inc(Sel);
      Dec(I);
    end;

  end;

function strTrimLeft(const aSource: String; const aPattern: String): String;
var
I,R: Integer;
PLen: Integer;
Start: Integer;
	begin
    Initialize(Result);
    Start := 1;
    PLen := Length(aPattern);

    while Pos(aPattern, aSource, Start) = Start do begin
      Start := Start + PLen;
    end;

    if Start > High(aSource) then Exit('');

    Result := aSource[Start..High(aSource)];
  end;

function strTrimRight(const aSource: String; const aPattern: String): String;
var
I,R: Integer;
PLen: Integer;
Start: Integer;
	begin
    if Length(aSource) = 0 then Exit(aSource);

    Initialize(Result);
    PLen := Length(aPattern);
    Start := High(aSource) - (PLen - 1);

    while Pos(aPattern, aSource, Start) = Start do begin
      Start := Start - PLen;
    end;

    if Start <= 0 then Exit(aSource);

    Result := aSource[1..Start];
  end;

function StrPad(const aCount: Integer; const aChar: AnsiChar = ' '): String;
	begin
    if aCount = 0 then Exit('');
    Initialize(Result);
    SetLength(Result, aCount);
    FillChar(Result[1], aCount, aChar);
  end;

function StrPadLeft(const aText: String; const aPadChar: AnsiChar; const aMaxChars: Cardinal): String;
var
padlen: Cardinal;
	begin
  	if Length(aText) >= aMaxChars then Exit(aTexT);

    padlen := aMaxChars - Length(aText);
    Exit(StrPad(padlen, aPadChar) + aText);
  end;

function gemInitMemory(const aSize: UInt64; const aValues: Array of Byte): Pointer; overload;
var
I: Integer;
Step: Integer;
Remain: Integer;
Ptr: PByte;
Pos: Integer;
	begin

    Result := GetMemory(aSize);

    Step := trunc(aSize / Length(aValues));
    Remain := aSize - (Step * Length(aValues));
    Ptr := Result;
    Pos := 0;

    for I := 0 to Step - 1 do begin
    	System.Move(aValues[0], Ptr[Pos], Length(aValues));
      Inc(Pos, Length(aValues));
    end;

    if Remain <> 0 then begin
    	for I := 0 to Remain - 1 do begin
      	Ptr[Pos + I] := aValues[I];
      end;
    end;

  end;

function gemInitMemory(const aSize: UInt64; const aValues: Pointer; const aValuesSize: Cardinal): Pointer; overload;
var
I: Integer;
Step: Integer;
Remain: Integer;
Ptr: PByte;
SPtr: PByte;
Pos: Integer;
	begin

    Result := GetMemory(aSize);

    Step := trunc(aSize / aValuesSize);
    Remain := aSize - (Step * aValuesSize);
    Ptr := Result;
    Pos := 0;

    for I := 0 to Step - 1 do begin
    	System.Move(aValues, Ptr[0], aValuesSize);
      Inc(Pos, aValuesSize);
    end;

    if Remain <> 0 then begin
      SPtr := aValues;
      for I := 0 to Remain - 1 do begin
      	Ptr[Pos + I] := SPtr[I];
      end;
    end;

  end;

function gemCopyMemory(var aData: Pointer; const aDataSize: Integer): Pointer;
var
Max: PtrUint;
RealSize: Integer;
	begin

    Max := MemSize(aData);
    if aDataSize > Max then begin
      RealSize := Max;
    end else begin
      RealSize := aDataSize;
    end;

  	Result := GetMemory(RealSize);
    System.Move(aData^, Result^, RealSize);
  end;

function gemPromptYesNo(const aPrompt: String; const aDefault: Integer = -1): Boolean;
// aDefault specifies if y or n should be the default answer
// 0 = n
// 1 = y
// -1 or anything else = no default
var
ReadStr: String;
OpStr: String;
  begin
    Result := False;

    case aDefault of
       0: OpStr := '(y/N):';
       1: OpStr := '(Y/n):';
       else OpStr := '(y/n):';
    end;

    while True do begin
      Write(OpStr);
      ReadLn(ReadStr);
      ReadStr := LowerCase(ReadStr);

      // return default on no input
      if ReadStr = '' then begin
        case aDefault of
          0: Exit(False);
          1: Exit(True);
        end;
      end;

      // check input
      if (ReadStr = 'y') or (ReadStr = 'yes') then begin
        Exit(True);
      end else if (ReadStr = 'n') or (ReadStr = 'no') then begin
        Exit(False);
      end;

    end;
  end;

function gemPromptRange(const aPrompt: String; const aLow, aHigh: Integer; const aUseDefault: Boolean = False; const aDefault: Integer = 0): Integer;
// match input to a range of numbers from aLow to aHigh
var
ReadStr: String;
CheckVal: Integer;
OpStr: String;
UsingDefault: Boolean;
  begin
    Result := aLow;

    UsingDefault := False;
    if aUseDefault = True then begin
      if (aDefault >= aLow) and (aDefault <= aHigh) then begin
        UsingDefault := True;
      end;
    end;

    OpStr := '(' + aLow.ToString() + '-' + aHigh.ToString();
    if UsingDefault = True then begin
      OpStr := OpStr + ', default=' + aDefault.ToString();
    end;

    OpStr := OpStr + '):';

    while True do begin
      Write(OpStr);
      ReadLn(ReadStr);

      if ReadStr = '' then begin
        if UsingDefault = True then begin
          Write(aDefault);
          Exit(aDefault);
        end;
      end;

      if gemStrIsInt(ReadStr) = False then begin
        WriteLn('Please enter a valid number from ' + aLow.ToString() + ' to ' + aHigh.ToString());
        Continue;
      end else begin
        CheckVal := ReadStr.ToInteger();
      end;

      if (CheckVal >= aLow) and (CheckVal <= aHigh) then begin
        Exit(CheckVal);
      end else begin
        WriteLn('Please enter a valid number from ' + aLow.ToString() + ' to ' + aHigh.ToString());
      end;

    end;
  end;

function gemPaethPredictorByte(const A, B, C: Byte): Byte;
var
p, pa, pb, pc: Integer;
   begin
        // a = left, b = above, c = upper left
        p := A + B;
        p := p - C; // initial estimate
        pa := abs(p - a);      // distances to a, b, c
        pb := abs(p - b);
        pc := abs(p - c);
        // return nearest of a,b,c,
        // breaking ties in order a,b,c.
        if (pa <= pb) and (pa <= pc) then begin
        	exit(a);
        end else if pb <= pc then begin
          exit(b);
        end else begin
          exit(c);
        end;
   end;

function gemWrapByte(const aValue: Integer): Byte;
var
Ret: Integer;
	begin
    Ret := aValue;
  	while Ret < 0 do Inc(Ret, 256);
    while Ret > 255 do Dec(Ret, 256);
    Exit(Byte(Ret));
  end;

operator := (const A: specialize TArray<String>): String;
	begin
  	Result := '';
    if Length(A) <> 0 then begin
      Result := A[0];
    end;
  end;

end.

