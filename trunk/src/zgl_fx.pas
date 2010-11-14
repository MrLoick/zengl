{
 *  Copyright © Kemka Andrey aka Andru
 *  mail: dr.andru@gmail.com
 *  site: http://andru-kun.inf.ua
 *
 *  This file is part of ZenGL.
 *
 *  ZenGL is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as
 *  published by the Free Software Foundation, either version 3 of
 *  the License, or (at your option) any later version.
 *
 *  ZenGL is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with ZenGL. If not, see http://www.gnu.org/licenses/
}
unit zgl_fx;

{$I zgl_config.cfg}

interface

const
  FX_BLEND_NORMAL = $00;
  FX_BLEND_ADD    = $01;
  FX_BLEND_MULT   = $02;
  FX_BLEND_BLACK  = $03;
  FX_BLEND_WHITE  = $04;
  FX_BLEND_MASK   = $05;

  FX_COLOR_MIX    = $00;
  FX_COLOR_SET    = $01;

  FX2D_FLIPX      = $000001;
  FX2D_FLIPY      = $000002;
  FX2D_VCA        = $000004;
  FX2D_VCHANGE    = $000008;
  FX2D_SCALE      = $000010;

  FX_BLEND        = $100000;
  FX_COLOR        = $200000;

procedure fx_SetBlendMode( const Mode : Byte );
procedure fx_SetColorMode( const Mode : Byte );
procedure fx_SetColorMask( const R, G, B, Alpha : Boolean );

procedure fx2d_SetColor( const Color : LongWord );
procedure fx2d_SetVCA( const c1, c2, c3, c4 : LongWord; const a1, a2, a3, a4 : Byte );
procedure fx2d_SetVertexes( const x1, y1, x2, y2, x3, y3, x4, y4 : Single );
procedure fx2d_SetScale( const scaleX, scaleY : Single );

var
  // FX2D_COLORMIX
  fx2dColor    : array[ 0..3 ] of Byte;
  fx2dAlpha    : PByte;
  fx2dColorDef : array[ 0..3 ] of Byte = ( 255, 255, 255, 255 );
  fx2dAlphaDef : PByte;

  // FX2D_VCA
  fx2dVCA1 : array[ 0..3 ] of Byte = ( 255, 255, 255, 255 );
  fx2dVCA2 : array[ 0..3 ] of Byte = ( 255, 255, 255, 255 );
  fx2dVCA3 : array[ 0..3 ] of Byte = ( 255, 255, 255, 255 );
  fx2dVCA4 : array[ 0..3 ] of Byte = ( 255, 255, 255, 255 );

  // FX2D_VCHANGE
  fx2dVX1, fx2dVX2, fx2dVX3, fx2dVX4 : Single;
  fx2dVY1, fx2dVY2, fx2dVY3, fx2dVY4 : Single;

  // FX2D_SCALE
  FX2D_SX, FX2D_SY : Single;

implementation
uses
  zgl_opengl,
  zgl_opengl_all,
  zgl_render_2d;

procedure fx_SetBlendMode;
  var
    srcBlend : LongWord;
    dstBlend : LongWord;
begin
  if b2d_Started and ( Mode <> b2dcur_Blend ) Then
    batch2d_Flush();

  b2dcur_Blend := Mode;
  case Mode of
    FX_BLEND_NORMAL:
      begin
        srcBlend := GL_SRC_ALPHA;
        dstBlend := GL_ONE_MINUS_SRC_ALPHA;
      end;
    FX_BLEND_ADD:
      begin
        srcBlend := GL_SRC_ALPHA;
        dstBlend := GL_ONE;
      end;
    FX_BLEND_MULT:
      begin
        srcBlend := GL_ZERO;
        dstBlend := GL_SRC_COLOR;
      end;
    FX_BLEND_BLACK:
      begin
        srcBlend := GL_SRC_COLOR;
        dstBlend := GL_ONE_MINUS_SRC_COLOR;
      end;
    FX_BLEND_WHITE:
      begin
        srcBlend := GL_ONE_MINUS_SRC_COLOR;
        dstBlend := GL_SRC_COLOR;
      end;
    FX_BLEND_MASK:
      begin
        srcBlend := GL_ZERO;
        dstBlend := GL_SRC_COLOR;
      end;
  end;
  if ogl_Separate Then
    glBlendFuncSeparateEXT( srcBlend, dstBlend, GL_ONE, GL_ONE_MINUS_SRC_ALPHA )
  else
    glBlendFunc( srcBlend, dstBlend );
end;

procedure fx_SetColorMode;
begin
  if b2d_Started and ( Mode <> b2dcur_Color ) Then
    batch2d_Flush();

  b2dcur_Color := Mode;
  case Mode of
    FX_COLOR_MIX:
      begin
        glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
      end;
    FX_COLOR_SET:
      begin
        glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE_ARB );
        glTexEnvi( GL_TEXTURE_ENV, GL_COMBINE_RGB_ARB,  GL_REPLACE );
        glTexEnvi( GL_TEXTURE_ENV, GL_SOURCE0_RGB_ARB,  GL_PRIMARY_COLOR_ARB );
      end;
  end;
end;

procedure fx_SetColorMask;
  var
    mask : Integer;
begin
  mask := Byte( R ) + Byte( G ) shl 1 + Byte( B ) shl 2 + Byte( Alpha ) shl 3;
  if b2d_Started and ( mask <> b2dcur_ColorMask ) Then
    batch2d_Flush();

  b2dcur_ColorMask := mask;

  glColorMask( Byte( R ), Byte( G ), Byte( B ), Byte( Alpha ) );
end;

procedure fx2d_SetColor;
begin
  fx2dColor[ 0 ] :=   Color             shr 16;
  fx2dColor[ 1 ] := ( Color and $FF00 ) shr 8;
  fx2dColor[ 2 ] :=   Color and $FF;
end;

procedure fx2d_SetVCA;
begin
  fx2dVCA1[ 0 ] :=   C1             shr 16;
  fx2dVCA1[ 1 ] := ( C1 and $FF00 ) shr 8;
  fx2dVCA1[ 2 ] :=   C1 and $FF;
  fx2dVCA1[ 3 ] := A1;

  fx2dVCA2[ 0 ] :=   C2             shr 16;
  fx2dVCA2[ 1 ] := ( C2 and $FF00 ) shr 8;
  fx2dVCA2[ 2 ] :=   C2 and $FF;
  fx2dVCA2[ 3 ] := A2;

  fx2dVCA3[ 0 ] :=   C3             shr 16;
  fx2dVCA3[ 1 ] := ( C3 and $FF00 ) shr 8;
  fx2dVCA3[ 2 ] :=   C3 and $FF;
  fx2dVCA3[ 3 ] := A3;

  fx2dVCA4[ 0 ] :=   C4             shr 16;
  fx2dVCA4[ 1 ] := ( C4 and $FF00 ) shr 8;
  fx2dVCA4[ 2 ] :=   C4 and $FF;
  fx2dVCA4[ 3 ] := A4;
end;

procedure fx2d_SetVertexes;
begin
  fx2dVX1 := x1;
  fx2dVY1 := y1;
  fx2dVX2 := x2;
  fx2dVY2 := y2;
  fx2dVX3 := x3;
  fx2dVY3 := y3;
  fx2dVX4 := x4;
  fx2dVY4 := y4;
end;

procedure fx2d_SetScale;
begin
  FX2D_SX := scaleX;
  FX2D_SY := scaleY;
end;

initialization
  fx2dAlpha    := @fx2dColor[ 3 ];
  fx2dAlphaDef := @fx2dColorDef[ 3 ];

end.
