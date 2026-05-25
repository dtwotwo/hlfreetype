package freetype;

import freetype.native.Handles.FacePtr;
import freetype.native.Handles.LibraryPtr;
import haxe.io.Bytes;

@:hlNative("freetype")
class Library {
	var handle:LibraryPtr;
	var disposed = false;

	public function new() {
		handle = libraryCreate();
		if (handle == null)
			throw describeLastError();
	}

	public var version(get, never):String;

	@:noCompletion
	inline function get_version():String {
		return stringFromBytes(nativeVersion(handle));
	}

	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		libraryDispose(handle);
	}

	public function loadFace(data:Bytes, index:Int = 0):Face {
		final face = faceFromMemory(handle, @:privateAccess data.b, data.length, index);
		if (face == null)
			throw describeLastError();
		return new Face(this, data, face);
	}

	public static inline function describeLastError():String {
		return stringFromBytes(nativeDescribeLastError());
	}

	public static function stringFromBytes(bytes:hl.Bytes):String {
		if (bytes == null)
			return null;
		return @:privateAccess String.fromUTF8(bytes);
	}

	@:hlNative("freetype", "library_create")
	static function libraryCreate():LibraryPtr {
		return null;
	}

	@:hlNative("freetype", "library_dispose")
	static function libraryDispose(library:LibraryPtr):Void {}

	@:hlNative("freetype", "face_from_memory")
	static function faceFromMemory(library:LibraryPtr, bytes:hl.Bytes, size:Int, index:Int):FacePtr {
		return null;
	}

	@:hlNative("freetype", "version")
	static function nativeVersion(library:LibraryPtr):hl.Bytes {
		return null;
	}

	@:hlNative("freetype", "describe_last_error")
	static function nativeDescribeLastError():hl.Bytes {
		return null;
	}
}
