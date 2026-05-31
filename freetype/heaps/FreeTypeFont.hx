package freetype.heaps;

#if heaps
import freetype.Library;
import freetype.Face;
import freetype.heaps.types.FontTypes.FreeTypeFontAtlas;
import freetype.heaps.types.FontTypes.FreeTypeFontOptions;
import freetype.heaps.types.FontTypes.FreeTypeFontSource;
import freetype.heaps.types.FontTypes.PackedGlyph;
import freetype.types.Bitmap;
import freetype.types.Glyph;
import freetype.types.LoadFlags;
import freetype.types.RenderMode;
import h2d.Font;
import h2d.Tile;
import haxe.io.Bytes;
import hxd.Pixels;
import sys.io.File;

@:access(h2d.Font)
class FreeTypeFont {
	public static function fromFile(path:String, size:Int, ?options:FreeTypeFontOptions):Font {
		return fromBytes(File.getBytes(path), size, options, path);
	}

	public static function fromFiles(paths:Array<String>, size:Int, ?options:FreeTypeFontOptions):Font {
		return buildAtlasFromFiles(paths, size, options).font;
	}

	public static function fromBytes(bytes:Bytes, size:Int, ?options:FreeTypeFontOptions, ?name:String):Font {
		return buildAtlas(bytes, size, options, name).font;
	}

	public static function dynamicFromFile(path:String, size:Int, ?options:FreeTypeFontOptions):DynamicFreeTypeFont {
		return dynamicFromBytes(File.getBytes(path), size, options, path);
	}

	public static function dynamicFromFiles(paths:Array<String>, size:Int, ?options:FreeTypeFontOptions, ?name:String):DynamicFreeTypeFont {
		return dynamicFromSources([for (path in paths) {bytes: File.getBytes(path), name: path}], size, options, name);
	}

	public static function dynamicFromBytes(bytes:Bytes, size:Int, ?options:FreeTypeFontOptions, ?name:String):DynamicFreeTypeFont {
		return dynamicFromSources([{bytes: bytes, name: name}], size, options, name);
	}

	public static function dynamicFromSources(sources:Array<FreeTypeFontSource>, size:Int, ?options:FreeTypeFontOptions, ?name:String):DynamicFreeTypeFont {
		return new DynamicFreeTypeFont(sources, size, options, name);
	}

	public static function buildAtlas(bytes:Bytes, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		return buildAtlasFromSources([{bytes: bytes, name: name}], size, options, name);
	}

	public static function buildAtlasFromFiles(paths:Array<String>, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		return buildAtlasFromSources([for (path in paths) {bytes: File.getBytes(path), name: path}], size, options, name);
	}

	public static function buildAtlasFromSources(sources:Array<FreeTypeFontSource>, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		final dynamicFont = new DynamicFreeTypeFont(sources, size, options, name);
		final font = new Font(dynamicFont.name, dynamicFont.size);
		font.tile = dynamicFont.tile;
		font.lineHeight = dynamicFont.lineHeight;
		font.baseLine = dynamicFont.baseLine;
		font.charset = hxd.Charset.getDefault();
		font.defaultChar = dynamicFont.defaultChar;

		for (code in dynamicFont.glyphs.keys())
			font.glyphs.set(code, dynamicFont.glyphs.get(code));
		dynamicFont.disposeSources();

		return {
			font: font,
			pixels: dynamicFont.pixels,
			tile: dynamicFont.tile,
		};
	}

	public static function normalizeOptions(?options:FreeTypeFontOptions):FreeTypeFontOptions {
		final opt:FreeTypeFontOptions = options == null ? {} : options;
		if (opt.antiAliasing == null)
			opt.antiAliasing = true;
		if (opt.chars == null)
			opt.chars = hxd.Charset.DEFAULT_CHARS;
		if (opt.dpi == null)
			opt.dpi = 72;
		if (opt.kerning == null)
			opt.kerning = true;
		if (opt.padding == null)
			opt.padding = 1;
		if (opt.uploadTexture == null)
			opt.uploadTexture = true;
		if (opt.atlasWidth == null)
			opt.atlasWidth = 0;

		return opt;
	}

	public static function uniqueChars(chars:String):Array<Int> {
		final result:Array<Int> = [];
		for (i in 0...chars.length) {
			final code = StringTools.fastCodeAt(chars, i);
			if (result.indexOf(code) == -1)
				result.push(code);
		}
		return result;
	}

	public static function renderGlyphs(faces:Array<Face>, chars:Array<Int>, opt:FreeTypeFontOptions):Array<PackedGlyph> {
		final result = [];
		final loadFlags = opt.antiAliasing ? LoadFlags.Default | LoadFlags.NoHinting : LoadFlags.Default | LoadFlags.NoHinting | LoadFlags.Monochrome;
		final renderMode = opt.antiAliasing ? RenderMode.Normal : RenderMode.Mono;

		for (code in chars) {
			final face = findGlyphFace(faces, code);
			if (face == null)
				continue;
			final glyph = face.renderCodepoint(code, loadFlags, renderMode);
			result.push({
				code: code,
				face: face,
				glyph: glyph,
				x: 0,
				y: 0,
				w: glyph.bitmap.width + opt.padding * 2,
				h: glyph.bitmap.height + opt.padding * 2,
				advance: glyph.advanceX / 64,
				width: glyphWidth(glyph),
			});
		}

		return result;
	}

	public static function findGlyphFace(faces:Array<Face>, code:Int):Face {
		for (face in faces)
			if (face.hasGlyph(code))
				return face;
		return null;
	}

	public static function packGlyphs(glyphs:Array<PackedGlyph>, opt:FreeTypeFontOptions):Void {
		glyphs.sort((a, b) -> b.h - a.h);
		if (opt.atlasWidth <= 0)
			opt.atlasWidth = chooseAtlasWidth(glyphs);

		var x = 0, y = 0, rowHeight = 0;
		for (glyph in glyphs) {
			if (glyph.w > opt.atlasWidth)
				opt.atlasWidth = nextPowerOfTwo(glyph.w);
			if (x + glyph.w > opt.atlasWidth) {
				x = 0;
				y += rowHeight;
				rowHeight = 0;
			}
			glyph.x = x;
			glyph.y = y;
			x += glyph.w;
			if (glyph.h > rowHeight)
				rowHeight = glyph.h;
		}
	}

	public static function chooseAtlasWidth(glyphs:Array<PackedGlyph>):Int {
		var area = 0;
		var maxWidth = 16;
		for (glyph in glyphs) {
			area += glyph.w * glyph.h;
			if (glyph.w > maxWidth)
				maxWidth = glyph.w;
		}
		return nextPowerOfTwo(Std.int(Math.max(maxWidth, Math.ceil(Math.sqrt(area)))));
	}

	public static function atlasHeight(glyphs:Array<PackedGlyph>, opt:FreeTypeFontOptions):Int {
		var height = 1;
		for (glyph in glyphs) {
			final bottom = glyph.y + glyph.h;
			if (bottom > height)
				height = bottom;
		}
		return nextPowerOfTwo(height);
	}

	public static function nextPowerOfTwo(value:Int):Int {
		var result = 1;
		while (result < value)
			result <<= 1;
		return result;
	}

	public static function writeGlyph(pixels:Pixels, entry:PackedGlyph, padding:Int):Void {
		final bitmap = entry.glyph.bitmap;
		if (bitmap.width <= 0 || bitmap.height <= 0 || bitmap.buffer == null)
			return;

		switch (bitmap.pixelMode) {
			case Gray:
				writeGrayGlyph(pixels, bitmap, entry.x + padding, entry.y + padding);
			case Mono:
				writeMonoGlyph(pixels, bitmap, entry.x + padding, entry.y + padding);
			default:
				throw "Unsupported FreeType bitmap mode: " + bitmap.pixelMode;
		}
	}

	public static function glyphWidth(glyph:Glyph):Float {
		return Math.max(glyph.advanceX / 64, glyph.bitmapLeft + glyph.bitmap.width);
	}

	public static function addKerning(glyphs:Array<PackedGlyph>, font:Font):Void {
		for (right in glyphs) {
			final rightChar = font.glyphs.get(right.code);
			if (rightChar == null)
				continue;

			for (left in glyphs) {
				if (left.face != right.face)
					continue;
				final kerning = right.face.kerning(left.glyph.glyphIndex, right.glyph.glyphIndex);
				if (kerning.x != 0)
					rightChar.addKerning(left.code, Std.int(kerning.x / 64));
			}
		}
	}

	static function writeGrayGlyph(pixels:Pixels, bitmap:Bitmap, tx:Int, ty:Int):Void {
		for (y in 0...bitmap.height) {
			final row = y * bitmap.pitch;
			for (x in 0...bitmap.width) {
				final alpha = bitmap.buffer.getUI8(row + x);
				pixels.setPixel(tx + x, ty + y, alpha << 24 | 0xFFFFFF);
			}
		}
	}

	static function writeMonoGlyph(pixels:Pixels, bitmap:Bitmap, tx:Int, ty:Int):Void {
		for (y in 0...bitmap.height) {
			final row = y * bitmap.pitch;
			for (x in 0...bitmap.width) {
				final byte = bitmap.buffer.getUI8(row + (x >> 3));
				final alpha = (byte & (0x80 >> (x & 7))) != 0 ? 0xFF : 0;
				pixels.setPixel(tx + x, ty + y, alpha << 24 | 0xFFFFFF);
			}
		}
	}
}
#else
class FreeTypeFont {}
#end
