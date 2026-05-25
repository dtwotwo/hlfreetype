package freetype;

import freetype.native.Handles.FacePtr;
import freetype.types.FaceFlags;
import freetype.types.FaceMetrics;
import freetype.types.Glyph;
import freetype.types.KerningMode;
import freetype.types.LoadFlags;
import freetype.types.RenderMode;
import freetype.types.Vector;
import haxe.io.Bytes;

class Face {
	public var library(default, null):Library;

	final data:Bytes;
	final handle:FacePtr;
	var disposed = false;

	public function new(library:Library, data:Bytes, handle:FacePtr) {
		this.library = library;
		this.data = data;
		this.handle = handle;
	}

	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		faceDispose(handle);
	}

	public var flags(get, never):FaceFlags;

	@:noCompletion
	inline function get_flags():FaceFlags {
		return faceFlags(handle);
	}

	public var glyphCount(get, never):Int;

	@:noCompletion
	inline function get_glyphCount():Int {
		return faceGlyphCount(handle);
	}

	public var unitsPerEm(get, never):Int;

	@:noCompletion
	inline function get_unitsPerEm():Int {
		return faceUnitsPerEm(handle);
	}

	public var ascender(get, never):Int;

	@:noCompletion
	inline function get_ascender():Int {
		return faceAscender(handle);
	}

	public var descender(get, never):Int;

	@:noCompletion
	inline function get_descender():Int {
		return faceDescender(handle);
	}

	public var height(get, never):Int;

	@:noCompletion
	inline function get_height():Int {
		return faceHeight(handle);
	}

	public var familyName(get, never):String;

	@:noCompletion
	inline function get_familyName():String {
		return Library.stringFromBytes(faceFamilyName(handle));
	}

	public var styleName(get, never):String;

	@:noCompletion
	inline function get_styleName():String {
		return Library.stringFromBytes(faceStyleName(handle));
	}

	public function setPixelSize(width:Int, height:Int):Void {
		if (!faceSetPixelSize(handle, width, height))
			throw Library.describeLastError();
	}

	public function setSize(points:Int, dpi:Int = 72):Void {
		setCharSize(0, points * 64, dpi, dpi);
	}

	public function setCharSize(width:Int, height:Int, horizontalDpi:Int = 72, verticalDpi:Int = 72):Void {
		if (!faceSetCharSize(handle, width, height, horizontalDpi, verticalDpi))
			throw Library.describeLastError();
	}

	public function metrics(?out:FaceMetrics):FaceMetrics {
		if (out == null)
			out = new FaceMetrics();
		if (!faceMetrics(handle, out))
			throw Library.describeLastError();
		return out;
	}

	public inline function glyphIndex(codepoint:Int):Int {
		return faceGlyphIndex(handle, codepoint);
	}

	public inline function hasGlyph(codepoint:Int):Bool {
		return glyphIndex(codepoint) != 0;
	}

	public function kerning(leftGlyph:Int, rightGlyph:Int, mode:KerningMode = Default, ?out:Vector):Vector {
		if (out == null)
			out = new Vector();
		if (!faceKerning(handle, leftGlyph, rightGlyph, mode, out))
			throw Library.describeLastError();
		return out;
	}

	public function renderCodepoint(codepoint:Int, loadFlags:LoadFlags = Default, renderMode:RenderMode = Normal, ?out:Glyph):Glyph {
		if (out == null)
			out = new Glyph();
		if (!faceRenderCodepoint(handle, codepoint, loadFlags, renderMode, out, out.metrics, out.bitmap))
			throw Library.describeLastError();
		return out;
	}

	@:hlNative("freetype", "face_dispose")
	static function faceDispose(face:FacePtr):Void {}

	@:hlNative("freetype", "face_flags")
	static function faceFlags(face:FacePtr):FaceFlags {
		return @:privateAccess new FaceFlags(0);
	}

	@:hlNative("freetype", "face_glyph_count")
	static function faceGlyphCount(face:FacePtr):Int {
		return 0;
	}

	@:hlNative("freetype", "face_units_per_em")
	static function faceUnitsPerEm(face:FacePtr):Int {
		return 0;
	}

	@:hlNative("freetype", "face_ascender")
	static function faceAscender(face:FacePtr):Int {
		return 0;
	}

	@:hlNative("freetype", "face_descender")
	static function faceDescender(face:FacePtr):Int {
		return 0;
	}

	@:hlNative("freetype", "face_height")
	static function faceHeight(face:FacePtr):Int {
		return 0;
	}

	@:hlNative("freetype", "face_family_name")
	static function faceFamilyName(face:FacePtr):hl.Bytes {
		return null;
	}

	@:hlNative("freetype", "face_style_name")
	static function faceStyleName(face:FacePtr):hl.Bytes {
		return null;
	}

	@:hlNative("freetype", "face_glyph_index")
	static function faceGlyphIndex(face:FacePtr, codepoint:Int):Int {
		return 0;
	}

	@:hlNative("freetype", "face_set_pixel_size")
	static function faceSetPixelSize(face:FacePtr, width:Int, height:Int):Bool {
		return false;
	}

	@:hlNative("freetype", "face_set_char_size")
	static function faceSetCharSize(face:FacePtr, width:Int, height:Int, horizontalDpi:Int, verticalDpi:Int):Bool {
		return false;
	}

	@:hlNative("freetype", "face_metrics")
	static function faceMetrics(face:FacePtr, out:Dynamic):Bool {
		return false;
	}

	@:hlNative("freetype", "face_kerning")
	static function faceKerning(face:FacePtr, leftGlyph:Int, rightGlyph:Int, mode:KerningMode, out:Dynamic):Bool {
		return false;
	}

	@:hlNative("freetype", "face_render_codepoint")
	static function faceRenderCodepoint(face:FacePtr, codepoint:Int, loadFlags:LoadFlags, renderMode:RenderMode, glyph:Dynamic, metrics:Dynamic, bitmap:Dynamic):Bool {
		return false;
	}
}
