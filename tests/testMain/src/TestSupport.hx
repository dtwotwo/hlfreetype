import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

typedef FontFixture = {
	path:String,
	bytes:Bytes,
}

typedef FixtureIssue = {
	path:String,
	message:String,
	kind:String,
}

class TestSupport {
	public static final supportedExtensions = ["ttf", "otf"];
	public static final fixtures = loadFixtures();

	static function loadFixtures():Array<String> {
		final explicitPath = Sys.getEnv("HLFREETYPE_TEST_FONT");
		if (explicitPath != null && explicitPath.length > 0 && FileSystem.exists(explicitPath))
			return [explicitPath];

		final localDir = "fonts";
		final localFonts = collectFonts(localDir);
		if (localFonts.length > 0)
			return localFonts;

		final systemFonts = [
			"C:/Windows/Fonts/arial.ttf",
			"C:/Windows/Fonts/segoeui.ttf",
			"C:/Windows/Fonts/calibri.ttf"
		];
		final result = [];
		for (path in systemFonts)
			if (FileSystem.exists(path))
				result.push(path);

		assert(result.length > 0, "No TTF fixtures found. Set HLFREETYPE_TEST_FONT to a readable font file.");
		return result;
	}

	static function collectFonts(dir:String):Array<String> {
		final result = [];
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return result;

		for (name in FileSystem.readDirectory(dir)) {
			final path = dir + "/" + name;
			if (FileSystem.isDirectory(path))
				continue;
			final ext = Path.extension(name);
			if (ext != null && supportedExtensions.indexOf(ext.toLowerCase()) != -1)
				result.push(path);
		}
		result.sort(Reflect.compare);
		return result;
	}

	public static function loadFixture(path:String):FontFixture {
		return {
			path: path,
			bytes: File.getBytes(path),
		};
	}

	public static function assert(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	public static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		if (expected != actual)
			throw message + " (expected=" + Std.string(expected) + ", actual=" + Std.string(actual) + ")";
	}

	public static function fixtureLabel(path:String):String {
		return Path.withoutDirectory(path);
	}

	public static function printCheck(label:String):Void {
		Sys.println("CHECK " + label);
	}

	public static function printOk(?label:String):Void {
		Sys.println("OK" + (label != null ? "   " + label : ""));
	}

	public static function printFail(label:String, message:String):Void {
		Sys.println("FAIL " + label + ": " + message);
	}

	public static function printUnsupported(label:String, message:String):Void {
		final prefix = label + ": ";
		final cleanMessage = StringTools.startsWith(message, prefix) ? message.substr(prefix.length) : message;
		Sys.println("UNSUPPORTED " + label + " (" + cleanMessage + ")");
	}

	public static function classifyIssue(path:String, message:String):String {
		final ext = Path.extension(path);
		if (ext == null || supportedExtensions.indexOf(ext.toLowerCase()) == -1)
			return "unsupported";
		return "fail";
	}
}
