# hlfreetype

> This library was inspired by [Motion Twin's original HashLink FreeType binding](https://github.com/motion-twin/hlfreetype)

Native FreeType support for HashLink, with optional Heaps font integration.

## What it does

- adds `freetype.Library` for plain HashLink projects
- loads TTF/OTF fonts from memory
- renders glyphs through FreeType into HashLink bytes
- adds `freetype.heaps.FreeTypeFont` for creating `h2d.Font` from one or more TTF files

## Supported formats

- `ttf`
- `ttc`
- `otf`

## Plain HashLink usage

```haxe
final library = new freetype.Library();
final face = library.loadFace(sys.io.File.getBytes("font.ttf"));

face.setPixelSize(0, 32);

final glyph = face.renderCodepoint("A".code);
trace(face.familyName);
trace(glyph.bitmap.width + "x" + glyph.bitmap.height);

face.dispose();
library.dispose();
```

Useful API:

- `Library.loadFace(bytes, ?index)`
- `Library.describeLastError()`
- `Face.setPixelSize(width, height)`
- `Face.setSize(points, ?dpi)`
- `Face.glyphIndex(codepoint)`
- `Face.hasGlyph(codepoint)`
- `Face.kerning(leftGlyph, rightGlyph)`
- `Face.renderCodepoint(codepoint, ?loadFlags, ?renderMode, ?out)`

Public data and enum types live in `freetype.types`, for example:

- `freetype.types.Bitmap`
- `freetype.types.Glyph`
- `freetype.types.FaceMetrics`
- `freetype.types.LoadFlags`
- `freetype.types.RenderMode`
- `freetype.types.PixelMode`

## Heaps usage

Create an `h2d.Font` directly from a TTF file:

```haxe
final font = freetype.heaps.FreeTypeFont.fromFile("font.ttf", 24, {
	chars: "Hello Привет こんにちは",
	kerning: true,
});

final text = new h2d.Text(font, s2d);
text.text = "Hello Привет こんにちは";
```

Use multiple font files when your text spans scripts that one font does not cover:

```haxe
final font = freetype.heaps.FreeTypeFont.fromFiles([
	// windows
	"C:/Windows/Fonts/segoeui.ttf",
	"C:/Windows/Fonts/seguisym.ttf",
	"C:/Windows/Fonts/arial.ttf",
	"C:/Windows/Fonts/Nirmala.ttf",

	// linux
	"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
	"/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf",
	"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
], 24, {
	chars: "Hello Привет हिन्दी 中文 日本語 한국어",
	kerning: true,
});
```

`fromFiles()` bakes one atlas and chooses the first font that contains each requested character.
It does not magically cover all Unicode; the provided font files must contain the glyphs you want to render.
TTC collections load all contained faces by default. With `dynamicFromSources()`, set `faceIndex` on a source to load only one face from a collection.

Use `dynamicFromFiles()` when text can contain characters that were not known up front.
Characters listed in `chars` are preloaded, and later missing glyphs are rendered into the atlas on demand.

Dynamic fonts retain one byte per atlas pixel and release individual glyph bitmap buffers after packing. GPU uploads temporarily expand coverage to full color and alpha, with no change to glyph rendering. Reading `dynamicFont.pixels` materializes the original BGRA buffer and retains it for subsequent pixel access; avoid reading it just to inspect memory usage.

Create from bytes:

```haxe
final bytes = sys.io.File.getBytes("font.ttf");
final font = freetype.heaps.FreeTypeFont.fromBytes(bytes, 24);
```

Register TTF/OTF/TTC files as Heaps resources:

```hxml
--macro freetype.heaps.Macro.main()
```

Then load them through `hxd.Res`:

```haxe
final font = hxd.Res.fonts.my_font.toFont(24);
final dynamicFont = hxd.Res.fonts.my_font.toDynamicFont(24);
```

If you need access to the generated atlas pixels:

```haxe
final atlas = freetype.heaps.FreeTypeFont.buildAtlas(bytes, 24, {
	chars: hxd.Charset.DEFAULT_CHARS,
	uploadTexture: true,
});

final font = atlas.font;
final pixels = atlas.pixels;
```

For multi-font atlases:

```haxe
final atlas = freetype.heaps.FreeTypeFont.buildAtlasFromFiles(paths, 24, {
	chars: textToRender,
});
```

Options:

- `chars`: characters to bake into the atlas
- `antiAliasing`: render grayscale glyphs when enabled
- `kerning`: add FreeType kerning pairs
- `padding`: glyph padding in the atlas
- `atlasWidth`: fixed atlas width, or auto when omitted
- `uploadTexture`: create a real Heaps texture when enabled

## Build

FreeType is fetched and built automatically by CMake.

The same FreeType version is used on Windows and Linux.

FreeType is linked statically into `freetype.hdll`, so users do not need a separate FreeType DLL or shared library.

### Requirements

Common requirements:

* CMake 3.10+
* Ninja
* Git
* `HASHLINK` environment variable pointing to a HashLink installation or source tree

Windows additionally requires:

* Visual Studio / MSVC build tools

Linux additionally requires:

* GCC or Clang
* standard build tools

## Build on Windows

Set `HASHLINK` to your HashLink directory:

```powershell
$env:HASHLINK = "C:\Path\To\HashLink"
```

Configure:

```powershell
cmake --preset windows-release --fresh
```

Build:

```powershell
cmake --build --preset windows-release
```

Output:

```text
out/build/windows-release/extension/freetype.hdll
out/build/windows-release/extension/freetype.lib
```

The native module is:

```text
freetype.hdll
```

Place it next to your `.hl` output, or otherwise make sure HashLink can load it.

## Build on Linux

Install the basic build dependencies.

Ubuntu/Debian:

```sh
sudo apt-get update
sudo apt-get install -y build-essential git cmake ninja-build
```

Set `HASHLINK` to your HashLink installation or source tree:

```sh
export HASHLINK=/path/to/hashlink
```

Configure:

```sh
cmake --preset linux-release --fresh
```

Build:

```sh
cmake --build --preset linux-release
```

Output:

```text
out/build/linux-release/extension/freetype.hdll
```

Place `freetype.hdll` next to your `.hl` output, or otherwise make sure HashLink can load it.

If `libhl.so` is not installed system-wide, make sure it can also be found at runtime, for example:

```sh
export LD_LIBRARY_PATH="$HASHLINK:${LD_LIBRARY_PATH:-}"
```

## Tests

The test suite covers:

* FreeType initialization
* font loading
* face metrics
* kerning
* glyph lookup
* glyph rendering
* TTF/OTF support
* TTC collections when a TTC test font is available
* invalid input handling
* deterministic Heaps atlas creation

### Plain HashLink tests

Compile:

```sh
cd tests/testMain
haxe test-hl.hxml
```

Run:

```sh
hl test.hl
```

### Heaps tests

Compile:

```sh
cd tests/testMain
haxe test-heaps.hxml
```

Run:

```sh
hl test-heaps.hl
```

### Windows test launchers

Convenience launchers are also available on Windows:

* `tests/test-hl.bat`
* `tests/test-heaps.bat`
* `tests/test-heaps-window.bat`

`test-hl` checks plain FreeType loading, metrics, kerning, glyph rendering and invalid input.

`test-heaps` checks deterministic `h2d.Font` atlas creation without opening a window.

`test-heaps-window` opens a Heaps window and renders multilingual Unicode sample text using multiple fallback fonts. Press Escape to close.

## Test fonts

Tests first look for explicitly configured test fonts and then fall back to common system fonts.

To specify a TTF or OTF test font:

### Windows

```powershell
$env:HLFREETYPE_TEST_FONT = "C:\Path\To\font.ttf"
```

or in `cmd.exe`:

```bat
set HLFREETYPE_TEST_FONT=C:\Path\To\font.ttf
```

### Linux

```sh
export HLFREETYPE_TEST_FONT=/path/to/font.ttf
```

For example:

```sh
export HLFREETYPE_TEST_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
```

To explicitly specify a TTC collection:

### Windows

```powershell
$env:HLFREETYPE_TEST_TTC = "C:\Windows\Fonts\msyh.ttc"
```

### Linux

```sh
export HLFREETYPE_TEST_TTC=/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
```

On Ubuntu/Debian, useful test fonts can be installed with:

```sh
sudo apt-get install -y fonts-dejavu-core fonts-noto-cjk
```

## GitHub Actions

GitHub Actions builds and tests the native extension on both Windows and Linux.

The workflow runs against:

* Windows x86_64
* Linux x86_64
* Haxe 4.3.7
* latest Haxe

Nightly builds are published when changes are pushed to `main`.

Release artifacts:

```text
hlfreetype-windows.zip
hlfreetype-linux.tar.gz
```

The Windows archive contains:

```text
freetype.hdll
freetype.lib
```

The Linux archive contains:

```text
freetype.hdll
```

FreeType itself is statically linked into the native module.

HashLink must still be installed or otherwise available on the target system.

## TODO

- macOS support
