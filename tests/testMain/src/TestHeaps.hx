import freetype.heaps.FreeTypeFont;
import freetype.heaps.DynamicFreeTypeFont;
import sys.io.File;

private function main() {
	Sys.println("CHECK heaps-font");
	final path = TestSupport.fixtures[0];
	final atlas = FreeTypeFont.buildAtlas(File.getBytes(path), 24, {
		chars: "ABCD AV?",
		uploadTexture: false,
	});
	TestSupport.assert(atlas.font.size == 24, "Heaps font size should match request");
	TestSupport.assert(atlas.font.getChar("A".code) != null, "Heaps font should contain A");
	TestSupport.assert(atlas.font.getChar("A".code).width > 0, "Heaps font glyph advance should be positive");
	TestSupport.assert(atlas.font.getChar("A".code).t.height > 0, "Heaps font glyph tile should have height");
	TestSupport.assert(atlas.font.lineHeight > 0, "Heaps font line height should be positive");
	TestSupport.assert(atlas.font.baseLine > 0, "Heaps font baseline should be positive");
	TestSupport.assert(atlas.pixels.width > 0 && atlas.pixels.height > 0, "Heaps font atlas should have pixels");
	testDynamicGlyphGeneration(path);
	Sys.println("HL Heaps tests passed.");
	Sys.exit(0);
}

private function testDynamicGlyphGeneration(path:String):Void {
	Sys.println("CHECK dynamic-glyphs");
	final font = new DynamicFreeTypeFont([{bytes: File.getBytes(path), name: path}], 24, {
		chars: "?",
		atlasWidth: 16,
		uploadTexture: false,
	});

	final first = font.getChar("A".code);
	TestSupport.assert(first != null, "Dynamic font should generate A");
	TestSupport.assert(first.width > 0, "Dynamically generated A should advance");
	TestSupport.assert(font.hasChar("A".code), "Dynamic font should cache generated A");

	final beforeHeight = font.pixels.height;
	for (code in "BCDEFGHIJKLMNOPQRSTUVWXYZ".split(""))
		font.getChar(code.charCodeAt(0));
	TestSupport.assert(font.pixels.height >= beforeHeight, "Dynamic atlas should keep or grow height after more glyphs");

	font.dispose();
	TestSupport.printOk("dynamic-glyphs");
}
