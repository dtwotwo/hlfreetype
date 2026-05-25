package freetype.types;

enum abstract KerningMode(Int) to Int {
	final Default = 0;
	final Unfitted = 1;
	final Unscaled = 2;
}
