package freetype.heaps;

#if heaps
import freetype.Library;
import freetype.Face;
import freetype.heaps.types.FontTypes.FreeTypeFontOptions;
import freetype.heaps.types.FontTypes.FreeTypeFontSource;
import freetype.heaps.types.FontTypes.PackedGlyph;
import freetype.types.FaceFlags;
import h2d.Font;
import h2d.Font.FontChar;
import h2d.Tile;
import hxd.Pixels;

@:access(h2d.Font)
@:access(h2d.Tile)
class DynamicFreeTypeFont extends Font {
	public var pixels(default, null):Pixels;

	final library:Library;
	final faces:Array<Face>;
	final opt:FreeTypeFontOptions;
	final packed:Array<PackedGlyph> = [];
	final packedByFace:Array<Array<PackedGlyph>> = [];
	final glyphFaces:Map<Int, Face> = [];
	final missing:Map<Int, Bool> = [];
	final retiredTiles:Array<Tile> = [];

	var cursorX = 0;
	var cursorY = 0;
	var rowHeight = 0;
	var sourcesDisposed = false;
	var disposed = false;

	public function new(sources:Array<FreeTypeFontSource>, size:Int, ?options:FreeTypeFontOptions, ?name:String) {
		if (sources.length == 0)
			throw "At least one FreeType font source is required";

		opt = FreeTypeFont.normalizeOptions(options);
		library = new Library();
		faces = [];

		for (source in sources)
			loadSourceFaces(source, size);

		final primaryFace = faces[0];
		super(name != null ? name : primaryFace.familyName, size);

		final faceMetrics = primaryFace.metrics();

		charset = new DynamicFreeTypeCharset(this, hxd.Charset.getDefault());

		final chars = FreeTypeFont.uniqueChars(opt.chars);
		for (entry in FreeTypeFont.renderGlyphs(faces, chars, opt))
			addPacked(entry);
		updateVerticalMetrics(faceMetrics);
		FreeTypeFont.packGlyphs(packed, opt);
		updatePackingCursor();

		final pixels = Pixels.alloc(opt.atlasWidth, FreeTypeFont.atlasHeight(packed, opt), BGRA);
		this.pixels = pixels;
		pixels.clear(FreeTypeFont.glyphClearColor);
		for (glyph in packed)
			FreeTypeFont.writeGlyph(pixels, glyph, opt.padding);

		tile = createTile();
		for (entry in packed)
			glyphs.set(entry.code, new FontChar(glyphTile(entry), entry.width));

		if (opt.kerning)
			FreeTypeFont.addKerning(packed, this);

		final fallback = glyphs.get("?".code);
		if (fallback != null)
			defaultChar = fallback;
	}

	public override function hasChar(code:Int):Bool {
		return glyphs.get(code) != null || findGlyphFace(code) != null;
	}

	public override function dispose():Void {
		if (disposed)
			return;
		disposed = true;

		super.dispose();
		for (tile in retiredTiles)
			tile.dispose();
		disposeSources();
		pixels.dispose();
	}

	public function disposeSources():Void {
		if (sourcesDisposed)
			return;
		sourcesDisposed = true;

		for (face in faces)
			face.dispose();
		library.dispose();
	}

	private function loadSourceFaces(source:FreeTypeFontSource, size:Int):Void {
		final firstIndex = source.faceIndex != null ? source.faceIndex : 0;
		final firstFace = loadSourceFace(source, firstIndex, size);
		faces.push(firstFace);

		if (source.faceIndex != null)
			return;

		for (index in 1...firstFace.faceCount)
			faces.push(loadSourceFace(source, index, size));
	}

	private function loadSourceFace(source:FreeTypeFontSource, index:Int, size:Int):Face {
		final face = library.loadFace(source.bytes, index);
		face.setPixelSize(0, size);
		return face;
	}

	public function generateChar(code:Int):FontChar {
		if (sourcesDisposed)
			return null;
		if (missing.exists(code))
			return null;

		final face = findGlyphFace(code);
		if (face == null) {
			missing.set(code, true);
			return null;
		}

		final glyph = face.renderCodepoint(code, FreeTypeFont.loadFlagsFor(opt), FreeTypeFont.renderModeFor(opt));
		final entry:PackedGlyph = {
			code: code,
			face: face,
			glyph: glyph,
			x: 0,
			y: 0,
			w: glyph.bitmap.width + opt.padding * 2,
			h: glyph.bitmap.height + opt.padding * 2,
			advance: glyph.advanceX / 64,
			width: FreeTypeFont.glyphWidth(glyph, opt.padding),
		};

		placeGlyph(entry);
		addPacked(entry);
		FreeTypeFont.writeGlyph(pixels, entry, opt.padding);
		uploadPixels();

		final char = new FontChar(glyphTile(entry), entry.width);
		glyphs.set(code, char);
		addKerningFor(entry, char);
		addKerningToExisting(entry);
		return char;
	}

	private function findGlyphFace(code:Int):Face {
		if (glyphFaces.exists(code))
			return glyphFaces.get(code);

		final face = FreeTypeFont.findGlyphFace(faces, code);
		if (face != null)
			glyphFaces.set(code, face);
		return face;
	}

	private function addPacked(entry:PackedGlyph):Void {
		packed.push(entry);

		var group:Array<PackedGlyph> = null;
		for (candidate in packedByFace)
			if (candidate[0].face == entry.face) {
				group = candidate;
				break;
			}

		if (group == null) {
			group = [];
			packedByFace.push(group);
		}
		group.push(entry);
	}

	private function packedFaceGroup(face:Face):Array<PackedGlyph> {
		for (group in packedByFace)
			if (group[0].face == face)
				return group;
		return [];
	}

	private function placeGlyph(glyph:PackedGlyph):Void {
		if (glyph.w > opt.atlasWidth)
			resizeAtlas(FreeTypeFont.nextPowerOfTwo(glyph.w), pixels.height);

		if (cursorX + glyph.w > opt.atlasWidth) {
			cursorX = 0;
			cursorY += rowHeight;
			rowHeight = 0;
		}

		if (cursorY + glyph.h > pixels.height)
			resizeAtlas(opt.atlasWidth, FreeTypeFont.nextPowerOfTwo(cursorY + glyph.h));

		glyph.x = cursorX;
		glyph.y = cursorY;
		cursorX += glyph.w;
		if (glyph.h > rowHeight)
			rowHeight = glyph.h;
	}

	private function resizeAtlas(width:Int, height:Int):Void {
		final newWidth = FreeTypeFont.nextPowerOfTwo(Std.int(Math.max(width, opt.atlasWidth)));
		final newHeight = FreeTypeFont.nextPowerOfTwo(Std.int(Math.max(height, pixels.height)));
		if (newWidth == opt.atlasWidth && newHeight == pixels.height)
			return;

		final next = Pixels.alloc(newWidth, newHeight, BGRA);
		next.clear(FreeTypeFont.glyphClearColor);
		next.blit(0, 0, pixels, 0, 0, pixels.width, pixels.height);
		pixels.dispose();
		pixels = next;
		opt.atlasWidth = newWidth;
		if (tile != null)
			retiredTiles.push(tile);
		tile = createTile();
		for (entry in packed) {
			final char = glyphs.get(entry.code);
			if (char != null)
				char.t = glyphTile(entry);
		}
	}

	private function createTile():Tile {
		return FreeTypeFont.atlasTile(pixels, opt);
	}

	private function uploadPixels():Void {
		if (!opt.uploadTexture)
			return;
		tile.getTexture().uploadPixels(pixels);
	}

	private function glyphTile(entry:PackedGlyph):Tile {
		final bitmap = entry.glyph.bitmap;
		return bitmap.width > 0
			&& bitmap.height > 0 ? tile.sub(entry.x, entry.y, entry.w, entry.h, entry.glyph.bitmapLeft
				- opt.padding, baseLine
				- entry.glyph.bitmapTop
				- opt.padding) : tile.sub(0, 0, 0, 0, 0, 0);
	}

	private function updateVerticalMetrics(faceMetrics:freetype.types.FaceMetrics):Void {
		var baseline = Math.ceil(faceMetrics.ascender / 64);
		var descent = Math.ceil(-faceMetrics.descender / 64);

		for (entry in packed) {
			final bitmap = entry.glyph.bitmap;
			if (bitmap.width <= 0 || bitmap.height <= 0)
				continue;

			baseline = Math.ceil(Math.max(baseline, entry.glyph.bitmapTop + opt.padding));
			descent = Math.ceil(Math.max(descent, bitmap.height - entry.glyph.bitmapTop + opt.padding));
		}

		baseLine = baseline;
		lineHeight = Math.ceil(Math.max(faceMetrics.height / 64, baseline + descent));
	}

	private function updatePackingCursor():Void {
		cursorX = cursorY = rowHeight = 0;
		for (glyph in packed) {
			if (glyph.y > cursorY) {
				cursorY = glyph.y;
				cursorX = rowHeight = 0;
			}

			final right = glyph.x + glyph.w;
			if (right > cursorX)
				cursorX = right;
			if (glyph.y == cursorY && glyph.h > rowHeight)
				rowHeight = glyph.h;
		}
	}

	private function addKerningFor(right:PackedGlyph, rightChar:FontChar):Void {
		if (!opt.kerning || !right.face.flags.has(FaceFlags.Kerning))
			return;
		for (left in packedFaceGroup(right.face)) {
			if (left.code == right.code)
				continue;
			final kerning = right.face.kerning(left.glyph.glyphIndex, right.glyph.glyphIndex);
			if (kerning.x != 0)
				rightChar.addKerning(left.code, Std.int(kerning.x / 64));
		}
	}

	private function addKerningToExisting(left:PackedGlyph):Void {
		if (!opt.kerning || !left.face.flags.has(FaceFlags.Kerning))
			return;
		for (right in packedFaceGroup(left.face)) {
			if (left == right)
				continue;
			final rightChar = glyphs.get(right.code);
			if (rightChar == null)
				continue;
			final kerning = right.face.kerning(left.glyph.glyphIndex, right.glyph.glyphIndex);
			if (kerning.x != 0)
				rightChar.addKerning(left.code, Std.int(kerning.x / 64));
		}
	}
}

@:access(hxd.Charset)
private class DynamicFreeTypeCharset extends hxd.Charset {
	final font:DynamicFreeTypeFont;
	final fallback:hxd.Charset;

	public function new(font:DynamicFreeTypeFont, fallback:hxd.Charset) {
		super();
		this.font = font;
		this.fallback = fallback;
	}

	public override function resolveChar<T>(code:Int, glyphs:Map<Int, T>):Null<T> {
		final generated = font.generateChar(code);
		if (generated != null)
			return cast generated;
		return fallback.resolveChar(code, glyphs);
	}

	public override function isCJK(code):Bool {
		return fallback.isCJK(code);
	}

	public override function isSpace(code):Bool {
		return fallback.isSpace(code);
	}

	public override function isBreakChar(code):Bool {
		return fallback.isBreakChar(code);
	}

	public override function isComplementChar(code):Bool {
		return fallback.isComplementChar(code);
	}
}
#else
class DynamicFreeTypeFont {}
#end
