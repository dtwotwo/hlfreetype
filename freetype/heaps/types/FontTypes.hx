package freetype.heaps.types;

#if heaps
import freetype.Face;
import freetype.types.Glyph;
import h2d.Font;
import h2d.Tile;
import haxe.io.Bytes;
import hxd.Pixels;

typedef FreeTypeFontOptions = {
	?antiAliasing:Bool,
	?atlasWidth:Int,
	?chars:String,
	?dpi:Int,
	?kerning:Bool,
	?padding:Int,
	?uploadTexture:Bool,
}

typedef FreeTypeFontAtlas = {
	font:Font,
	pixels:Pixels,
	tile:Tile,
}

typedef FreeTypeFontSource = {
	bytes:Bytes,
	?name:String,
	?faceIndex:Int,
}

typedef PackedGlyph = {
	code:Int,
	face:Face,
	glyph:Glyph,
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	advance:Float,
	width:Float,
}
#end
