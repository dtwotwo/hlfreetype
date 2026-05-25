import freetype.heaps.FreeTypeFont;
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
	Sys.println("HL Heaps tests passed.");
	Sys.exit(0);
}
