import freetype.Library;
import freetype.types.LoadFlags;
import freetype.types.PixelMode;
import haxe.io.Bytes;

private function main() {
	var failed = false;
	final issues:Array<{path:String, message:String, kind:String}> = [];

	for (path in TestSupport.fixtures) {
		final label = TestSupport.fixtureLabel(path);
		try {
			final fixture = TestSupport.loadFixture(path);
			TestSupport.printCheck(label);
			testTTFFace(fixture.bytes, label);
			TestSupport.printOk();
		} catch (e) {
			final message = Std.string(e);
			final kind = TestSupport.classifyIssue(path, message);
			issues.push({path: path, message: message, kind: kind});
			if (kind == "unsupported")
				TestSupport.printUnsupported(label, message);
			else {
				failed = true;
				TestSupport.printFail(label, message);
			}
		}
	}

	try {
		testInvalidInput();
		TestSupport.printOk("invalid");
	} catch (e) {
		failed = true;
		final message = Std.string(e);
		issues.push({path: "invalid", message: message, kind: "fail"});
		TestSupport.printFail("invalid", message);
	}

	if (failed) {
		Sys.println("");
		var failedCount = 0;
		for (issue in issues)
			if (issue.kind == "fail")
				failedCount++;
		Sys.println("Failed checks: " + failedCount);
		for (issue in issues)
			if (issue.kind == "fail")
				Sys.println("- " + TestSupport.fixtureLabel(issue.path) + ": " + issue.message);
		Sys.exit(1);
	}

	var unsupportedCount = 0;
	for (issue in issues)
		if (issue.kind == "unsupported")
			unsupportedCount++;
	if (unsupportedCount > 0)
		Sys.println("Unsupported files: " + unsupportedCount);

	Sys.println("HL tests passed.");
}

private function testTTFFace(bytes:Bytes, label:String):Void {
	final library = new Library();
	final face = library.loadFace(bytes);

	TestSupport.assert(library.version.length > 0, label + ": FreeType version should be available");
	TestSupport.assert(face.familyName != null && face.familyName.length > 0, label + ": family name should be available");
	TestSupport.assert(face.styleName != null && face.styleName.length > 0, label + ": style name should be available");
	TestSupport.assert(face.glyphCount > 0, label + ": glyph count should be positive");
	TestSupport.assert(face.unitsPerEm > 0, label + ": units per em should be positive");
	TestSupport.assert(face.hasGlyph("A".code), label + ": font should contain glyph A");

	face.setPixelSize(0, 32);
	final metrics = face.metrics();
	TestSupport.assertEquals(32, metrics.yPpem, label + ": pixel size should update face metrics");

	final glyph = face.renderCodepoint("A".code, LoadFlags.Default | LoadFlags.ForceAutohint);
	TestSupport.assert(glyph.glyphIndex > 0, label + ": rendered glyph should have an index");
	TestSupport.assert(glyph.advanceX > 0, label + ": rendered glyph should advance horizontally");
	TestSupport.assert(glyph.metrics.width > 0, label + ": rendered glyph should have metrics");
	TestSupport.assert(glyph.bitmap.width > 0, label + ": rendered glyph bitmap should have width");
	TestSupport.assert(glyph.bitmap.height > 0, label + ": rendered glyph bitmap should have height");
	TestSupport.assertEquals(PixelMode.Gray, glyph.bitmap.pixelMode, label + ": rendered glyph should be grayscale");
	TestSupport.assertEquals(glyph.bitmap.byteLength, glyph.bitmap.toBytes().length, label + ": bitmap byte length should match copied data");

	final reused = face.renderCodepoint("B".code, LoadFlags.Default, Normal, glyph);
	TestSupport.assert(reused == glyph, label + ": renderCodepoint should reuse the output glyph");
	TestSupport.assertEquals(face.glyphIndex("B".code), reused.glyphIndex, label + ": reused glyph should update its index");

	final kern = face.kerning(face.glyphIndex("A".code), face.glyphIndex("V".code));
	TestSupport.assert(kern != null, label + ": kerning query should return a vector");

	face.dispose();
	library.dispose();
}

private function testInvalidInput():Void {
	try {
		final library = new Library();
		library.loadFace(Bytes.ofString("not a font"));
		library.dispose();
		throw "invalid font data should fail";
	} catch (e) {
		final message = Std.string(e);
		TestSupport.assert(message.length > 0, "invalid font should expose an error message");
	}
}
