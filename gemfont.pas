unit gemfont;

{$mode Delphi}{$H+}
{$modeswitch ADVANCEDRECORDS}

interface

uses
  freetypeh, gemutil, gemimage,
  Classes, SysUtils;

type
  PFT_Byte = ^FT_Byte;


  function  FT_Render_Glyph(slot : PFT_GlyphSlot; render_mode : FT_Render_Mode ) : FT_Error; cdecl; external freetypedll name 'FT_Render_Glyph';
  function  FT_New_Face(aLibrary: PFT_Library; filepathname: PChar; face_index: FT_Long; var aFace: PFT_FACE): FT_Error; cdecl; external freetypedll name 'FT_New_Face';

implementation


end.

