unit gemwav;

{$mode ObjFPC}{$H+}
{$modeswitch advancedrecords}

interface

uses
  gemutil,
  Classes, SysUtils, Math;

type

  TGEMWAVTag = packed Array [0..3] of Char;

  TGEMRiffChunk = packed record
    public
      Tag: TGEMWAVTag;
      FileSize: Integer;
      FormatID: TGEMWAVTag;
  end;

  TGEMFmtChunk = packed record
    public
      Tag: TGEMWAVTag;
      ChunkSize: Integer;
      Format: Int16;
      Channels: Int16;
      Frequency: Integer;
      BytesPerSec: Integer;
      BlockAlignment: Int16;
      BitsPerSample: Int16;
  end;

  TGEMDataChunk = packed record
    public
      Tag: TGEMWAVTag;
      ChunkSize: Integer;
      SampleData: PByte;
  end;

  TGEMWAVFile = packed record
    private
      function GetLength(): Single;
    public
      RIFF: TGEMRIFFChunk;
      FMT: TGEMFMTChunk;
      DATA: TGEMDataChunk;

      property FileSize: Integer read RIFF.FileSize;
      property Format: Int16 read FMT.Format;
      property Channels: Int16 read FMT.Channels;
      property Frequency: Integer read FMT.Frequency;
      property BytesPerSec: Integer read FMT.BytesPerSec;
      property BlockAlignment: Int16 read FMT.BlockAlignment;
      property BitsPerSample: Int16 read FMT.BitsPerSample;
      property DataSize: Integer read DATA.ChunkSize;
      property SampleData: PByte read DATA.SampleData;
      property Length: Single read GetLength;

      function WriteToFile(const aFileName: String): Integer;
      procedure ConvertToInt(const aNewSampleSize: Integer);
      procedure ConvertToFloat(const aNewSampleSize: Integer);
      procedure MixToMono();
      procedure MixToStereo();
  end;


  // loading
  function gemLoadWAVFile(const aFileName: String; var aWAV: TGEMWAVFile): Integer;

  // conversion float-int conversion
  function gemConvertPCMIntToInt(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
  function gemConvertPCMFloatToInt(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
  function gemConvertPCMIntToFloat(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
  function gemConvertPCMFloatToFloat(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;

  // stereo-mono conversion
  function gemMixPCMStereoToMono(var aData: Pointer; var ioDataSize: Integer; const aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;
  function gemMixPCMMonoToStereo(var aData: Pointer; var ioDataSize: Integer; const aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;

  // bit crush
  function gemBitCrush(var aData: Pointer; const aBitRange: Single; const aDataSize, aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;

const
  GEM_MAX_INT8 = 127;
  GEM_MAX_INT16 = 32767;
  GEM_MAX_INT24 = 8388607;
  GEM_MAX_INT32 = 2147483647;

implementation

function gemLoadWAVFile(const aFileName: String; var aWAV: TGEMWAVFile): Integer;
var
Buffer: PByte;
Pos: Uint64;
FileSize: Uint64;
Tag: TGEMWAVTag;
ChunkSize: Integer;

  // cleanup proc to call on error/failed verification of data
  procedure Fail();
    begin
      if Assigned(Buffer) then begin
        FreeMemory(Buffer);
      end;
      if Assigned(aWAV.DATA.SampleData) then begin
        FreeMemory(aWAV.DATA.SampleData);
      end;
      FillChar(aWAV, SizeOf(aWAV), 0);
    end;

  begin
    Result := 0;
    Pos := 0;

    // check if file exists
    if FileExists(aFileName) = False then Exit(0);
    // check that file is at least big enough to hold Riff and Fmt chunks
    if gemFileSize(aFileName) < 36 then Exit(0);

    Buffer := nil;
    FileSize := gemReadFile(aFileName, Buffer);

    // move data into riff record
    Initialize(aWAV.Riff);
    Move(Buffer[0], aWAV.Riff, SizeOf(TGEMRiffChunk));
    Inc(Pos, SizeOf(TGEMRiffChunk));

    // verify Riff chunk
    if aWAV.Riff.Tag <> 'RIFF' then begin
      Fail(); Exit(0);
    end;

    if aWAV.Riff.FormatID <> 'WAVE' then begin
      Fail(); Exit(0);
    end;

    // move data into fmt record
    Initialize(aWAV.Fmt);
    Move(Buffer[Pos], aWAV.Fmt, SizeOf(aWAV.Fmt));
    Inc(Pos, SizeOf(aWAV.Fmt));

    // verify Fmt chunk
    if aWAV.Fmt.Tag <> 'fmt ' then begin
      Fail(); Exit(0);
    end;

    // start looking for the data chunk
    Tag := '0000';
    ChunkSize := 0;
    while Tag <> 'data' do begin
      Move(Buffer[Pos], Tag, 4);
      Move(Buffer[Pos + 4], ChunkSize, 4);

      if Tag <> 'data' then begin
        Inc(Pos, ChunkSize + 8);
      end;

      if Pos >= FileSize then begin
        Fail(); Exit(0);
      end;
    end;

    Move(Buffer[Pos], aWAV.DATA, 8);
    aWAV.DATA.SampleData := GetMemory(ChunkSize);
    Move(Buffer[Pos + 8], aWAV.DATA.SampleData[0], ChunkSize);

    Exit(1);

  end;

function gemConvertPCMIntToInt(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
// convert a buffer of PCM 32 or 64 float data to 8, 16, 24 or 32 bit samples
// aData will be resized
// ioDataSize takes the size of the float buffer, and returns the size of the integer buffer
var
SPtr: PByte;
BPtr: PByte;
SMoveSize: Byte;
BMoveSize: Byte;
TVal: Int64;
RVal: Int64;
I: Integer;
SMulFac: Integer;
BMulFac: Integer;
SampleCount: Integer;
NewDataSize: Integer;
NewData: PByte;
  begin
    Result := 0;

    if (aOldSampleSize = 0) or (aOldSampleSize > 32) then Exit(0);
    if aOldSampleSize mod 8 <> 0 then Exit(0);
    if (aNewSampleSize = 0) or (aNewSampleSize > 32) then Exit(0);
    if aNewSampleSize mod 8 <> 0 then Exit(0);

    SampleCount := trunc(ioDataSize / (aOldSampleSize / 8));
    BMoveSize := trunc(aNewSampleSize / 8);
    SMoveSize := trunc(aOldSampleSize / 8);
    NewDataSize := SampleCount * BMoveSize;
    SMulFac := trunc(IntPower(2, aOldSampleSize) / 2) - 1;
    BMulFac := trunc(IntPower(2, aNewSampleSize) / 2) - 1;

    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    SPtr := aData;
    BPtr := NewData;
    RVal := 0;
    TVal := 0;

    for I := 0 to SampleCount - 1 do begin
      Move(SPtr[0], RVal, SMoveSize);
      TVal := trunc( (RVal / SMulFac) * BMulFac);
      Move(TVal, BPtr[0], BMoveSize);
      BPtr := BPtr + BMoveSize;
      SPtr := SPtr + SMoveSize;
    end;

    FreeMemory(aData);
    aData := NewData;

    Exit(1);
  end;

function gemConvertPCMFloatToInt(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
// convert a buffer of PCM 32 or 64 float data to 8, 16, 24 or 32 bit samples
// aData will be resized
// ioDataSize takes the size of the float buffer, and returns the size of the integer buffer
var
OldPtr, NewPtr: PByte;
OldMoveSize, NewMoveSize: Byte;
I: Integer;
SampleCount: Integer;
NewDataSize: Integer;
NewData: PByte;
Val24: Int32; // used to store value for 24 bit operations
  begin
    Result := 0;

    if (aNewSampleSize = 0) or (aNewSampleSize > 32) then Exit(0);
    if aNewSampleSize mod 8 <> 0 then Exit(0);
    if (aOldSampleSize <> 32) and (aOldSampleSize <> 64) then Exit(0);

    SampleCount := trunc(ioDataSize / (aOldSampleSize / 8));
    NewMoveSize := trunc(aNewSampleSize / 8);
    OldMoveSize := trunc(aOldSampleSize / 8);
    NewDataSize := SampleCount * NewMoveSize;

    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    OldPtr := aData;
    NewPtr := NewData;

    case aOldSampleSize of
      32: // 32 bit float
        begin
          case aNewSampleSize of
            8: // to byte
              begin
                for I := 0 to SampleCount - 1 do begin
                  PByte(NewPtr)[0] := trunc(PSingle(OldPtr)[0] * GEM_MAX_INT8) + 128;
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            16: // to Int16
              begin
                for I := 0 to SampleCount - 1 do begin
                  PInt16(NewPtr)[0] := trunc(PSingle(OldPtr)[0] * GEM_MAX_INT16);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            24: // to 24 bit
              begin
                for I := 0 to SampleCount - 1 do begin
                  Val24 := trunc(PSingle(OldPtr)[0] * GEM_MAX_INT32);
                  Move(PByte(@Val24)[1], NewPtr[0], 3);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            32: // to Int32
              begin
                for I := 0 to SampleCount - 1 do begin
                  PInt32(NewPtr)[0] := trunc(PSingle(OldPtr)[0] * GEM_MAX_INT32);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
          end;
        end;

      64: // 64 bit double
        begin
          case aNewSampleSize of
            8: // to byte
              begin
                for I := 0 to SampleCount - 1 do begin
                  PByte(NewPtr)[0] := trunc(PDouble(OldPtr)[0] * GEM_MAX_INT8) + 128;
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            16: // to Int16
              begin
                for I := 0 to SampleCount - 1 do begin
                  PInt16(NewPtr)[0] := trunc(PDouble(OldPtr)[0] * GEM_MAX_INT16);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            24: // to 24 bit
              begin
                for I := 0 to SampleCount - 1 do begin
                  Val24 := trunc(PDouble(OldPtr)[0] * GEM_MAX_INT32);
                  Move(PByte(@Val24)[1], NewPtr[0], 3);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
            32: // to Int32
              begin
                for I := 0 to SampleCount - 1 do begin
                  PInt32(NewPtr)[0] := trunc(PDouble(OldPtr)[0] * GEM_MAX_INT32);
                  NewPtr := NewPtr + NewMoveSize;
                  OldPtr := OldPtr + OldMoveSize;
                end;
              end;
          end;
        end;
    end;

    FreeMemory(aData);
    aData := NewData;

    Exit(1);
  end;

function gemConvertPCMIntToFloat(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
// convert a buffer of PCM 32 or 64 float data to 8, 16, 24 or 32 bit samples
// aData will be resized
// ioDataSize takes the size of the float buffer, and returns the size of the integer buffer
var
OldPtr, NewPtr: PByte;
OldMoveSize, NewMoveSize: Byte;
SingleVal: Single;
DoubleVal: Double;
Val24: Int32; // used to store 24 bit value
I: Integer;
SampleCount: Integer;
NewDataSize: Integer;
NewData: PByte;
  begin
    Result := 0;

    if (aOldSampleSize = 0) or (aOldSampleSize > 32) then Exit(0);
    if aOldSampleSize mod 8 <> 0 then Exit(0);
    if (aNewSampleSize <> 32) and (aNewSampleSize <> 64) then Exit(0);

    SampleCount := trunc(ioDataSize / (aOldSampleSize / 8));
    NewMoveSize := trunc(aNewSampleSize / 8);
    OldMoveSize := trunc(aOldSampleSize / 8);
    NewDataSize := SampleCount * NewMoveSize;

    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    OldPtr := aData;
    NewPtr := NewData;

    case aOldSampleSize of
      8: // 8 bit
        begin
          if aNewSampleSize = 32 then begin // to float
            for I := 0 to SampleCount - 1 do begin
              SingleVal := (PByte(OldPtr)[0] - 128) / GEM_MAX_INT8;
              Move(SingleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end else begin // to double
            for I := 0 to SampleCount - 1 do begin
              DoubleVal := (PByte(OldPtr)[0] - 128) / GEM_MAX_INT8;
              Move(DoubleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end;
        end;

      16: // 16 bit
        begin
          if aNewSampleSize = 32 then begin // to float
            for I := 0 to SampleCount - 1 do begin
              SingleVal := PInt16(OldPtr)[0] / GEM_MAX_INT16;
              Move(SingleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end else begin // to double
            for I := 0 to SampleCount - 1 do begin
              DoubleVal := PInt16(OldPtr)[0] / GEM_MAX_INT16;
              Move(DoubleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end;
        end;

      24: // 24 bit
        begin
          if aNewSampleSize = 32 then begin // to float
            for I := 0 to SampleCount - 1 do begin
              Move(OldPtr[0], PByte(@Val24)[1], 3);
              SingleVal := Val24 / GEM_MAX_INT32;
              Move(SingleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end else begin // to double
            for I := 0 to SampleCount - 1 do begin
              Move(OldPtr[0], PByte(@Val24)[1], 3);
              DoubleVal := Val24 / GEM_MAX_INT32;
              Move(DoubleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end;
        end;

      32: // 32 bit
        begin
          if aNewSampleSize = 32 then begin // to float
            for I := 0 to SampleCount - 1 do begin
              SingleVal := PInt32(OldPtr)[0] / GEM_MAX_INT32;
              Move(SingleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end else begin // to double
            for I := 0 to SampleCount - 1 do begin
              DoubleVal := PInt32(OldPtr)[0] / GEM_MAX_INT32;
              Move(DoubleVal, NewPtr[0], aNewSampleSize);
              OldPtr := OldPtr + OldMoveSize;
              NewPtr := NewPtr + NewMoveSize;
            end;
          end;
        end;

    end;

    FreeMemory(aData);
    aData := NewData;

    Exit(1);
  end;

function gemConvertPCMFloatToFloat(var aData: Pointer; var ioDataSize: Integer; const aOldSampleSize, aNewSampleSize: Integer): Integer;
// convert a buffer of PCM 32 or 64 float data to 8, 16, 24 or 32 bit samples
// aData will be resized
// ioDataSize takes the size of the float buffer, and returns the size of the integer buffer
var
SPtr: PSingle;
DPtr: PDouble;
I: Integer;
SampleCount: Integer;
NewDataSize: Integer;
NewData: PByte;
  begin
    Result := 0;

    if (aOldSampleSize <> 32) and (aOldSampleSize <> 64) then Exit(0);
    if (aNewSampleSize <> 32) and (aNewSampleSize <> 64) then Exit(0);

    SampleCount := trunc(ioDataSize / (aOldSampleSize / 8));
    NewDataSize := trunc(SampleCount * (aNewSampleSize / 8));

    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    case aNewSampleSize of

      32:
        begin
          SPtr := PSingle(NewData);
          DPtr := aData;
          for I := 0 to SampleCount - 1 do begin
            SPtr[I] := DPtr[I];
          end;
        end;

      64:
        begin
          SPtr := aData;
          DPtr := PDouble(NewData);
          for I := 0 to SampleCount - 1 do begin
            DPtr[I] := SPtr[I];
            SampleCount := SampleCount;
          end;
        end;

    end;

    FreeMemory(aData);
    aData := NewData;

    Exit(1);
  end;

function gemMixPCMStereoToMono(var aData: Pointer; var ioDataSize: Integer; const aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;
var
NewData: PByte;
NewDataSize: Integer;
OldPtr8, NewPtr8: PInt8;
OldPtr16, NewPtr16: PInt16;
OldPtr32, NewPtr32: PInt32;
OldSPtr, NewSPtr: PSingle;
OldDPtr, NewDPtr: PDouble;
Val1, Val2: Integer; // used for 24 bit values
SampleCount: Integer;
I: Integer;
  begin

    Result := 0;

    SampleCount := trunc((ioDataSize / (aSampleSize / 8)) / 2);

    NewDataSize := trunc(ioDataSize / 2);
    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    case aSampleSize of
      8:
        begin
          OldPtr8 := aData;
          NewPtr8 := PInt8(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewPtr8[I] := trunc((OldPtr8[0] + OldPtr8[1]) / 2);
            OldPtr8 := OldPtr8 + 2;
          end;
        end;

      16:
        begin
          OldPtr16 := aData;
          NewPtr16 := PInt16(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewPtr16[I] := trunc((OldPtr16[0] + OldPtr16[1]) / 2);
            OldPtr16 := OldPtr16 + 2;
          end;
        end;

      24:
        begin
          OldPtr8 := aData;
          NewPtr8 := PInt8(NewData);
          for I := 0 to SampleCount - 1 do begin
            Move(OldPtr8[0], PInteger(@Val1)[1], 3);
            Move(OldPtr8[3], PInteger(@Val2)[1], 3);
            Val1 := trunc((Val1 + Val2) / 2);
            Move(PInteger(@Val1)[1], NewPtr8[0], 3);
            NewPtr8 := NewPtr8 + 3;
            OldPtr8 := OldPtr8 + 6;
          end;
        end;

      32: // can be integer or float
        begin
          if aIsFloat = False then begin
            // integer
            OldPtr32 := aData;
            NewPtr32 := PInt32(NewData);
            for I := 0 to SampleCount - 1 do begin
              NewPtr32[I] := trunc((OldPtr32[0] + OldPtr32[1]) / 2);
              OldPtr32 := OldPtr32 + 2;
            end;
          end else begin
            // float
            OldSptr := aData;
            NewSPtr := PSingle(NewData);
            for I := 0 to SampleCount - 1 do begin
              NewSPtr[I] := (OldSptr[0] + OldSptr[1]) / 2;
              OldSptr := OldSptr + 2;
            end;
          end;
        end;

      64: // can only be double
        begin
          OldDptr := aData;
          NewDPtr := PDouble(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewDPtr[I] := (OldDptr[0] + OldDptr[1]) / 2;
            OldDptr := OldDptr + 2;
          end;
        end;
    end;

    FreeMemory(aData);
    aData := NewData;
  end;

function gemMixPCMMonoToStereo(var aData: Pointer; var ioDataSize: Integer; const aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;
var
NewData: PByte;
NewDataSize: Integer;
OldPtr8, NewPtr8: PInt8;
OldPtr16, NewPtr16: PInt16;
OldPtr32, NewPtr32: PInt32;
OldSPtr, NewSPtr: PSingle;
OldDPtr, NewDPtr: PDouble;
Val1, Val2: Integer; // used for 24 bit values
SampleCount: Integer;
I: Integer;
  begin

    Result := 0;

    SampleCount := trunc(ioDataSize / (aSampleSize / 8));

    NewDataSize := ioDataSize * 2;
    NewData := GetMemory(NewDataSize);
    ioDataSize := NewDataSize;

    case aSampleSize of
      8:
        begin
          OldPtr8 := aData;
          NewPtr8 := PInt8(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewPtr8[0] := OldPtr8[I];
            NewPtr8[1] := OldPtr8[I];
            NewPtr8 := NewPtr8 + 2;
          end;
        end;

      16:
        begin
          OldPtr16 := aData;
          NewPtr16 := PInt16(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewPtr16[0] := OldPtr16[I];
            NewPtr16[1] := OldPtr16[I];
            NewPtr16 := NewPtr16 + 2;
          end;
        end;

      24:
        begin
          OldPtr8 := aData;
          NewPtr8 := PInt8(NewData);
          for I := 0 to SampleCount - 1 do begin
            Move(OldPtr8[I], PInteger(@Val1)[1], 3);
            Move(PInteger(@Val1)[1], NewPtr8[0], 3);
            Move(PInteger(@Val1)[1], NewPtr8[3], 3);
            NewPtr8 := NewPtr8 + 2;
          end;
        end;

      32: // can be integer or float
        begin
          if aIsFloat = False then begin
            // integer
            OldPtr32 := aData;
            NewPtr32 := PInt32(NewData);
            for I := 0 to SampleCount - 1 do begin
              NewPtr32[0] := OldPtr32[I];
              NewPtr32[1] := OldPtr32[I];
              NewPtr32 := NewPtr32 + 2;
            end;
          end else begin
            // float
            OldSptr := aData;
            NewSPtr := PSingle(NewData);
            for I := 0 to SampleCount - 1 do begin
              NewSPtr[0] := OldSptr[I];
              NewSPtr[1] := OldSptr[I];
              NewSPtr := NewSPtr + 2;
            end;
          end;
        end;

      64: // can only be double
        begin
          OldDptr := aData;
          NewDPtr := PDouble(NewData);
          for I := 0 to SampleCount - 1 do begin
            NewDPtr[0] := OldDptr[I];
            NewDPtr[1] := OldDptr[I];
            NewDPtr := NewDPtr + 2;
          end;
        end;
    end;

    FreeMemory(aData);
    aData := NewData;
  end;

function gemBitCrush(var aData: Pointer; const aBitRange: Single; const aDataSize, aSampleSize: Integer; const aIsFloat: Boolean = False): Integer;
var
I,Z: Integer;
SampleCount: Integer;
RangeI, HighI: Integer;
RangeD: Double;
Per: Double;
Ptr8: PInt8;
Ptr16: PInt16;
Ptr32: PInt32;
SPtr: PSingle;
DPtr: PDouble;
Val16: Int16;
FRec: Integer;
  begin

    SampleCount := trunc(aDataSize / (aSampleSize / 8));
    FRec := trunc(aBitRange / 8);

    HighI := trunc(IntPower(2, aSampleSize) / 2);
    RangeI := trunc(HighI / aBitRange);

    Ptr16 := aData;
    for I := 0 to trunc(SampleCount / FRec) - 1 do begin
      Val16 := trunc(Ptr16[I * FRec] / RangeI);

      //if Val16 = 0 then begin
      //  Val16 := 1 * sign(Ptr16[I]);
      //end;

      Val16 := trunc(Val16 * RangeI);

      for Z := 0 to FRec - 1 do begin
        Ptr16[(I * FRec) + Z] := Val16;
      end;
    end;

  end;

function TGEMWAVFile.GetLength(): Single;
  begin
    Result := Self.DataSize / (Self.Frequency * (Self.BitsPerSample / 8));
  end;

function TGEMWAVFile.WriteToFile(const aFileName: String): Integer;
  begin
    gemWriteFile(aFileName, @Self.RIFF, 44, True);
    gemAppendFile(aFileName, Self.DATA.SampleData, Self.DataSize);
  end;

procedure TGEMWAVFile.ConvertToInt(const aNewSampleSize: Integer);
  begin
    case Self.Format of
      1: // PCM Integer
        begin
          if aNewSampleSize = Self.BitsPerSample then Exit();

          gemConvertPCMIntToInt(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.FMT.BitsPerSample, aNewSampleSize);
          Self.FMT.Format := 1;
          Self.FMT.BitsPerSample := aNewSampleSize;
          Self.FMT.BytesPerSec := trunc(Self.Frequency * (Self.BitsPerSample / 8));
          Self.FMT.BlockAlignment := trunc(aNewSampleSize / 8);
          Self.RIFF.FileSize := (44 + Self.DataSize);
        end;

      3: // PCM float
        begin
          gemConvertPCMFloatToInt(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.FMT.BitsPerSample, aNewSampleSize);
          Self.FMT.Format := 1;
          Self.FMT.BitsPerSample := aNewSampleSize;
          Self.FMT.BytesPerSec := trunc(Self.Frequency * (Self.BitsPerSample / 8));
          Self.FMT.BlockAlignment := trunc(aNewSampleSize / 8);
          Self.RIFF.FileSize := (44 + Self.DataSize);
        end;
    end;

  end;

procedure TGEMWAVFile.ConvertToFloat(const aNewSampleSize: Integer);
  begin
    case Self.Format of
      1: // PCM Integer
        begin
          gemConvertPCMIntToFloat(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.FMT.BitsPerSample, aNewSampleSize);
          Self.FMT.Format := 3;
          Self.FMT.BitsPerSample := aNewSampleSize;
          Self.FMT.BytesPerSec := trunc(Self.Frequency * (Self.BitsPerSample / 8));
          Self.FMT.BlockAlignment := trunc(aNewSampleSize / 8);
          Self.RIFF.FileSize := (44 + Self.DataSize);
        end;

      3: // PCM float
        begin
          if aNewSampleSize = Self.BitsPerSample then Exit();

          gemConvertPCMFloatToFloat(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.FMT.BitsPerSample, aNewSampleSize);
          Self.FMT.Format := 3;
          Self.FMT.BitsPerSample := aNewSampleSize;
          Self.FMT.BytesPerSec := trunc(Self.Frequency * (Self.BitsPerSample / 8));
          Self.FMT.BlockAlignment := trunc(aNewSampleSize / 8);
          Self.RIFF.FileSize := (44 + Self.DataSize);
        end;
    end;
  end;

procedure TGEMWAVFile.MixToMono();
  begin
    if Self.Channels = 1 then Exit();

    gemMixPCMStereoToMono(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.BitsPerSample, Boolean(Self.Format = 3));
    Self.FMT.Channels := 1;
    Self.FMT.BlockAlignment := trunc(Self.FMT.BlockAlignment / 2);
    Self.FMT.BytesPerSec := trunc(Self.FMT.BytesPerSec / 2);
    Self.RIFF.FileSize := 44 + Self.DataSize;
  end;

procedure TGEMWAVFile.MixToStereo();
  begin
    if Self.Channels = 2 then Exit();

    gemMixPCMMonoToStereo(Self.DATA.SampleData, Self.DATA.ChunkSize, Self.BitsPerSample, Boolean(Self.Format = 3));
    Self.FMT.Channels := 2;
    Self.FMT.BlockAlignment := trunc(Self.FMT.BlockAlignment * 2);
    Self.FMT.BytesPerSec := trunc(Self.FMT.BytesPerSec * 2);
    Self.RIFF.FileSize := 44 + Self.DataSize;
  end;

end.

