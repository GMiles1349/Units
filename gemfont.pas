unit gemfont;

{$mode ObjFPC}{$H+}
{$modeswitch ADVANCEDRECORDS}

interface

uses
  freetypeh, gemutil, gemimage,
  Classes, SysUtils;

type
  PFT_Byte = ^FT_Byte;

  TGEMFontCharacter = record
    private
      fSymbol: Char;
      fTop: Integer;
      fHeight: Integer;
      fBottom: Integer;
      fBitmap: TGEMImage;

    public

  end;

  TGEMFontAtlas = class(TObject)
    private
      fSize: Integer;
      fHeight: Integer;
      fAtlas: TGEMImage;

    public

  end;

  TGEMFont = class(TObject)
    private
      fName: String;
      fPath: String;
      fSearchPaths: TStringList;
      fAtlas: Array of TGEMFontAtlas;

      function GetSearchPath(const aIndex: Cardinal): String;
      function FindFont(const aFontName: String): Integer;

    public
      property Name: String read fName;
      property Path: String read fPath;
      property SearchPaths[Index: Cardinal]: String read GetSearchPath;

      constructor Create(const aFontName: String = '');
      function AddSearchPath(const aPath: String): Integer;

  end;

  function  FT_Render_Glyph(slot : PFT_GlyphSlot; render_mode : FT_Render_Mode ) : FT_Error; cdecl; external freetypedll name 'FT_Render_Glyph';
  function  FT_New_Face(aLibrary: PFT_Library; filepathname: PChar; face_index: FT_Long; var aFace: PFT_FACE): FT_Error; cdecl; external freetypedll name 'FT_New_Face';

implementation

constructor TGEMFont.Create(const aFontName: String = '');
  begin
    inherited Create();

    // get initial search paths
    Self.fSearchPaths := TStringList.Create();
    Self.fSearchPaths.Add(ExtractFilePath(ParamStr(0)));

    {$ifdef linux}
      if gemFileExists('/usr/share/fonts/') then begin
        Self.fSearchPaths.Add('/usr/share/fonts/');
      end;
    {$endif}

    if aFontName <> '' then begin
      Self.FindFont(aFontName);
    end;

  end;

function TGEMFont.GetSearchPath(const aIndex: Cardinal): String;
  begin
    if aIndex > Self.fSearchPaths.Count - 1 then Exit('');
    Exit(Self.fSearchPaths[aIndex]);
  end;

function TGEMFont.FindFont(const aFontName: String): Integer;
var
I, P: Integer;
RetPath: String;
  begin
    Result := 0;

    if Self.fSearchPaths.Count = 0 then Exit(0);

    for I := 0 to Self.fSearchPaths.Count - 1 do begin
      RetPath := gemFindFile(aFontName, Self.fSearchPaths[I]);
    end;

    if RetPath = '' then Exit(0);

    P := Pos(',', RetPath);

    if P <> 0 then begin
      RetPath := RetPath[1..P -1];
    end;

    Result := 1;

    Self.fName := aFontName;
    Self.fPath := ExtractFilePath(RetPath);
  end;

function TGEMFont.AddSearchPath(const aPath: String): Integer;
  begin
    Result := 0;
    if gemFileExists(aPath) then begin
      Self.fSearchPaths.Add(aPath);
      Exit(1);
    end;
  end;

end.

