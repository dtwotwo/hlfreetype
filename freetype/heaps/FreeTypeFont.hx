package freetype.heaps;

#if heaps
import freetype.Library;
import freetype.Face;
import freetype.types.Bitmap;
import freetype.types.Glyph;
import freetype.types.LoadFlags;
import freetype.types.PixelMode;
import freetype.types.RenderMode;
import h2d.Font;
import h2d.Font.FontChar;
import h2d.Tile;
import haxe.io.Bytes;
import hxd.Pixels;
import sys.io.File;

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
}

private typedef PackedGlyph = {
	code:Int,
	face:Face,
	glyph:Glyph,
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	advance:Float,
}

@:access(h2d.Font)
@:access(h2d.Tile)
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

	public static function buildAtlas(bytes:Bytes, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		return buildAtlasFromSources([{bytes: bytes, name: name}], size, options, name);
	}

	public static function buildAtlasFromFiles(paths:Array<String>, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		return buildAtlasFromSources([for (path in paths) {bytes: File.getBytes(path), name: path}], size, options, name);
	}

	public static function buildAtlasFromSources(sources:Array<FreeTypeFontSource>, size:Int, ?options:FreeTypeFontOptions, ?name:String):FreeTypeFontAtlas {
		if (sources.length == 0)
			throw "At least one FreeType font source is required";

		final opt = normalizeOptions(options);
		final library = new Library();
		final faces = [];
		for (source in sources) {
			final face = library.loadFace(source.bytes);
			face.setPixelSize(0, size);
			faces.push(face);
		}
		final primaryFace = faces[0];

		final chars = uniqueChars(opt.chars);
		final packed = renderGlyphs(faces, chars, opt);
		packGlyphs(packed, opt);

		final pixels = Pixels.alloc(opt.atlasWidth, atlasHeight(packed, opt), BGRA);
		pixels.clear(0);
		for (glyph in packed)
			writeGlyph(pixels, glyph, opt.padding);

		final tile = opt.uploadTexture ? Tile.fromPixels(pixels) : new Tile(null, 0, 0, pixels.width, pixels.height);
		final font = new Font(name != null ? name : primaryFace.familyName, size);
		final faceMetrics = primaryFace.metrics();
		font.tile = tile;
		font.lineHeight = Math.ceil(faceMetrics.height / 64);
		font.baseLine = Math.ceil(faceMetrics.ascender / 64);
		font.charset = hxd.Charset.getDefault();

		for (entry in packed) {
			final bitmap = entry.glyph.bitmap;
			final charTile = bitmap.width > 0
				&& bitmap.height > 0 ? tile.sub(entry.x
					+ opt.padding, entry.y
					+ opt.padding, bitmap.width, bitmap.height, entry.glyph.bitmapLeft, font.baseLine
					- entry.glyph.bitmapTop) : tile.sub(0, 0, 0, 0, 0, 0);
			font.glyphs.set(entry.code, new FontChar(charTile, entry.advance));
		}

		if (opt.kerning)
			addKerning(packed, font);

		final defaultChar = font.glyphs.get("?".code);
		if (defaultChar != null)
			font.defaultChar = defaultChar;

		for (face in faces)
			face.dispose();
		library.dispose();

		return {
			font: font,
			pixels: pixels,
			tile: tile,
		};
	}

	static function normalizeOptions(?options:FreeTypeFontOptions):FreeTypeFontOptions {
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

	static function uniqueChars(chars:String):Array<Int> {
		final result:Array<Int> = [];
		for (i in 0...chars.length) {
			final code = StringTools.fastCodeAt(chars, i);
			if (result.indexOf(code) == -1)
				result.push(code);
		}
		return result;
	}

	static function renderGlyphs(faces:Array<Face>, chars:Array<Int>, opt:FreeTypeFontOptions):Array<PackedGlyph> {
		final result = [];
		final loadFlags = opt.antiAliasing ? LoadFlags.Default | LoadFlags.ForceAutohint : LoadFlags.Default | LoadFlags.ForceAutohint | LoadFlags.Monochrome;
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
			});
		}

		return result;
	}

	static function findGlyphFace(faces:Array<Face>, code:Int):Face {
		for (face in faces)
			if (face.hasGlyph(code))
				return face;
		return null;
	}

	static function packGlyphs(glyphs:Array<PackedGlyph>, opt:FreeTypeFontOptions):Void {
		glyphs.sort((a, b) -> b.h - a.h);
		if (opt.atlasWidth <= 0)
			opt.atlasWidth = chooseAtlasWidth(glyphs);

		var x = 0;
		var y = 0;
		var rowHeight = 0;
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

	static function chooseAtlasWidth(glyphs:Array<PackedGlyph>):Int {
		var area = 0;
		var maxWidth = 16;
		for (glyph in glyphs) {
			area += glyph.w * glyph.h;
			if (glyph.w > maxWidth)
				maxWidth = glyph.w;
		}
		return nextPowerOfTwo(Std.int(Math.max(maxWidth, Math.ceil(Math.sqrt(area)))));
	}

	static function atlasHeight(glyphs:Array<PackedGlyph>, opt:FreeTypeFontOptions):Int {
		var height = 1;
		for (glyph in glyphs) {
			final bottom = glyph.y + glyph.h;
			if (bottom > height)
				height = bottom;
		}
		return nextPowerOfTwo(height);
	}

	static function nextPowerOfTwo(value:Int):Int {
		var result = 1;
		while (result < value)
			result <<= 1;
		return result;
	}

	static function writeGlyph(pixels:Pixels, entry:PackedGlyph, padding:Int):Void {
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

	static function addKerning(glyphs:Array<PackedGlyph>, font:Font):Void {
		for (right in glyphs) {
			final rightChar = font.glyphs.get(right.code);
			if (rightChar == null)
				continue;

			for (left in glyphs) {
				if (left.face != right.face)
					continue;
				final kerning = right.face.kerning(left.glyph.glyphIndex, right.glyph.glyphIndex);
				if (kerning.x != 0)
					rightChar.addKerning(left.code, kerning.x / 64);
			}
		}
	}
}
#else
class FreeTypeFont {}
#end
