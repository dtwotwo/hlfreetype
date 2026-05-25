#define HL_NAME(n) freetype_##n

#include <hl.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

typedef struct {
	void (*finalize)(void *);
	FT_Library value;
} hl_ft_library;

typedef struct {
	void (*finalize)(void *);
	FT_Face value;
} hl_ft_face;

typedef struct {
	hl_type *t;
	int x;
	int y;
} hl_ft_vector;

typedef struct {
	hl_type *t;
	int width;
	int height;
	int horiBearingX;
	int horiBearingY;
	int horiAdvance;
	int vertBearingX;
	int vertBearingY;
	int vertAdvance;
} hl_ft_glyph_metrics;

typedef struct {
	hl_type *t;
	int rows;
	int width;
	int pitch;
	vbyte *buffer;
	unsigned short numGrays;
	unsigned char pixelMode;
} hl_ft_bitmap;

typedef struct {
	hl_type *t;
	unsigned short xPpem;
	unsigned short yPpem;
	int xScale;
	int yScale;
	int ascender;
	int descender;
	int height;
	int maxAdvance;
} hl_ft_face_metrics;

typedef struct {
	hl_type *t;
	int glyphIndex;
	int bitmapLeft;
	int bitmapTop;
	int advanceX;
	int advanceY;
} hl_ft_glyph;

static char last_error[256] = "";

static void clear_error(void) {
	last_error[0] = '\0';
}

static void set_error(const char *context, FT_Error error) {
	snprintf(last_error, sizeof(last_error), "%s failed with FreeType error 0x%02x", context, error);
}

static void set_message(const char *message) {
	snprintf(last_error, sizeof(last_error), "%s", message);
}

static int valid_library(hl_ft_library *library) {
	return library != NULL && library->value != NULL;
}

static int valid_face(hl_ft_face *face) {
	return face != NULL && face->value != NULL;
}

static int run_ft(const char *context, FT_Error error) {
	if(error != 0) {
		set_error(context, error);
		return 0;
	}

	clear_error();
	return 1;
}

static void library_finalize(void *handle) {
	hl_ft_library *library = (hl_ft_library *)handle;
	if(library->value != NULL) {
		FT_Done_FreeType(library->value);
		library->value = NULL;
	}
}

static void face_finalize(void *handle) {
	hl_ft_face *face = (hl_ft_face *)handle;
	if(face->value != NULL) {
		FT_Done_Face(face->value);
		face->value = NULL;
	}
}

static vbyte *copy_string(const char *value) {
	if(value == NULL)
		return NULL;

	return hl_copy_bytes((const vbyte *)value, (int)strlen(value) + 1);
}

HL_PRIM hl_ft_library *HL_NAME(library_create)(void) {
	hl_ft_library *library = (hl_ft_library *)hl_gc_alloc_finalizer(sizeof(hl_ft_library));
	library->finalize = library_finalize;
	library->value = NULL;

	if(!run_ft("FT_Init_FreeType", FT_Init_FreeType(&library->value)))
		return NULL;

	return library;
}

HL_PRIM void HL_NAME(library_dispose)(hl_ft_library *library) {
	if(library != NULL)
		library_finalize(library);
}

HL_PRIM hl_ft_face *HL_NAME(face_from_memory)(hl_ft_library *library, vbyte *bytes, int size, int index) {
	hl_ft_face *face;

	if(!valid_library(library)) {
		set_message("Invalid FreeType library");
		return NULL;
	}
	if(bytes == NULL || size <= 0) {
		set_message("Invalid font data");
		return NULL;
	}

	face = (hl_ft_face *)hl_gc_alloc_finalizer(sizeof(hl_ft_face));
	face->finalize = face_finalize;
	face->value = NULL;

	if(!run_ft("FT_New_Memory_Face", FT_New_Memory_Face(library->value, bytes, size, index, &face->value)))
		return NULL;

	run_ft("FT_Select_Charmap", FT_Select_Charmap(face->value, FT_ENCODING_UNICODE));
	return face;
}

HL_PRIM void HL_NAME(face_dispose)(hl_ft_face *face) {
	if(face != NULL)
		face_finalize(face);
}

HL_PRIM vbyte *HL_NAME(version)(hl_ft_library *library) {
	FT_Int major = 0;
	FT_Int minor = 0;
	FT_Int patch = 0;
	char version[32];

	if(!valid_library(library)) {
		set_message("Invalid FreeType library");
		return NULL;
	}

	FT_Library_Version(library->value, &major, &minor, &patch);
	snprintf(version, sizeof(version), "%d.%d.%d", major, minor, patch);
	return hl_copy_bytes((const vbyte *)version, (int)strlen(version) + 1);
}

HL_PRIM vbyte *HL_NAME(describe_last_error)(void) {
	return hl_copy_bytes((const vbyte *)last_error, (int)strlen(last_error) + 1);
}

HL_PRIM int HL_NAME(face_flags)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->face_flags : 0;
}

HL_PRIM int HL_NAME(face_glyph_count)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->num_glyphs : 0;
}

HL_PRIM int HL_NAME(face_units_per_em)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->units_per_EM : 0;
}

HL_PRIM int HL_NAME(face_ascender)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->ascender : 0;
}

HL_PRIM int HL_NAME(face_descender)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->descender : 0;
}

HL_PRIM int HL_NAME(face_height)(hl_ft_face *face) {
	return valid_face(face) ? (int)face->value->height : 0;
}

HL_PRIM vbyte *HL_NAME(face_family_name)(hl_ft_face *face) {
	return valid_face(face) ? copy_string(face->value->family_name) : NULL;
}

HL_PRIM vbyte *HL_NAME(face_style_name)(hl_ft_face *face) {
	return valid_face(face) ? copy_string(face->value->style_name) : NULL;
}

HL_PRIM int HL_NAME(face_glyph_index)(hl_ft_face *face, int codepoint) {
	return valid_face(face) ? (int)FT_Get_Char_Index(face->value, (FT_ULong)codepoint) : 0;
}

HL_PRIM bool HL_NAME(face_set_pixel_size)(hl_ft_face *face, int width, int height) {
	if(!valid_face(face)) {
		set_message("Invalid FreeType face");
		return false;
	}

	return run_ft("FT_Set_Pixel_Sizes", FT_Set_Pixel_Sizes(face->value, (FT_UInt)width, (FT_UInt)height)) != 0;
}

HL_PRIM bool HL_NAME(face_set_char_size)(hl_ft_face *face, int width, int height, int horizontal_dpi, int vertical_dpi) {
	if(!valid_face(face)) {
		set_message("Invalid FreeType face");
		return false;
	}

	return run_ft("FT_Set_Char_Size", FT_Set_Char_Size(face->value, width, height, (FT_UInt)horizontal_dpi, (FT_UInt)vertical_dpi)) != 0;
}

HL_PRIM bool HL_NAME(face_metrics)(hl_ft_face *face, hl_ft_face_metrics *metrics) {
	FT_Size_Metrics *source;

	if(!valid_face(face) || metrics == NULL || face->value->size == NULL) {
		set_message("Invalid FreeType face metrics request");
		return false;
	}

	source = &face->value->size->metrics;
	metrics->xPpem = source->x_ppem;
	metrics->yPpem = source->y_ppem;
	metrics->xScale = (int)source->x_scale;
	metrics->yScale = (int)source->y_scale;
	metrics->ascender = (int)source->ascender;
	metrics->descender = (int)source->descender;
	metrics->height = (int)source->height;
	metrics->maxAdvance = (int)source->max_advance;
	clear_error();
	return true;
}

HL_PRIM bool HL_NAME(face_kerning)(hl_ft_face *face, int left, int right, int mode, hl_ft_vector *out) {
	FT_Vector kerning;

	if(!valid_face(face) || out == NULL) {
		set_message("Invalid FreeType kerning request");
		return false;
	}
	if(!run_ft("FT_Get_Kerning", FT_Get_Kerning(face->value, (FT_UInt)left, (FT_UInt)right, (FT_UInt)mode, &kerning)))
		return false;

	out->x = (int)kerning.x;
	out->y = (int)kerning.y;
	return true;
}

HL_PRIM bool HL_NAME(face_render_codepoint)(hl_ft_face *face, int codepoint, int load_flags, int render_mode, hl_ft_glyph *glyph, hl_ft_glyph_metrics *metrics, hl_ft_bitmap *bitmap) {
	FT_UInt glyph_index;
	FT_GlyphSlot slot;
	FT_Bitmap *source;
	int pitch_size;
	int buffer_size;

	if(!valid_face(face) || glyph == NULL || metrics == NULL || bitmap == NULL) {
		set_message("Invalid FreeType render request");
		return false;
	}

	glyph_index = FT_Get_Char_Index(face->value, (FT_ULong)codepoint);
	if(glyph_index == 0) {
		set_message("Missing glyph");
		return false;
	}
	if(!run_ft("FT_Load_Glyph", FT_Load_Glyph(face->value, glyph_index, load_flags)))
		return false;
	if(!run_ft("FT_Render_Glyph", FT_Render_Glyph(face->value->glyph, (FT_Render_Mode)render_mode)))
		return false;

	slot = face->value->glyph;
	source = &slot->bitmap;

	glyph->glyphIndex = (int)glyph_index;
	glyph->bitmapLeft = slot->bitmap_left;
	glyph->bitmapTop = slot->bitmap_top;
	glyph->advanceX = (int)slot->advance.x;
	glyph->advanceY = (int)slot->advance.y;

	metrics->width = (int)slot->metrics.width;
	metrics->height = (int)slot->metrics.height;
	metrics->horiBearingX = (int)slot->metrics.horiBearingX;
	metrics->horiBearingY = (int)slot->metrics.horiBearingY;
	metrics->horiAdvance = (int)slot->metrics.horiAdvance;
	metrics->vertBearingX = (int)slot->metrics.vertBearingX;
	metrics->vertBearingY = (int)slot->metrics.vertBearingY;
	metrics->vertAdvance = (int)slot->metrics.vertAdvance;

	bitmap->rows = (int)source->rows;
	bitmap->width = (int)source->width;
	bitmap->pitch = source->pitch;
	bitmap->numGrays = source->num_grays;
	bitmap->pixelMode = source->pixel_mode;

	pitch_size = source->pitch < 0 ? -source->pitch : source->pitch;
	buffer_size = (int)source->rows * pitch_size;
	if(source->buffer != NULL && buffer_size > 0) {
		bitmap->buffer = hl_copy_bytes((const vbyte *)source->buffer, buffer_size);
	} else {
		bitmap->buffer = NULL;
	}

	clear_error();
	return true;
}

#define _LIBRARY _ABSTRACT(hl_ft_library)
#define _FACE _ABSTRACT(hl_ft_face)

DEFINE_PRIM(_LIBRARY, library_create, _NO_ARG);
DEFINE_PRIM(_VOID, library_dispose, _LIBRARY);
DEFINE_PRIM(_FACE, face_from_memory, _LIBRARY _BYTES _I32 _I32);
DEFINE_PRIM(_VOID, face_dispose, _FACE);
DEFINE_PRIM(_BYTES, version, _LIBRARY);
DEFINE_PRIM(_BYTES, describe_last_error, _NO_ARG);
DEFINE_PRIM(_I32, face_flags, _FACE);
DEFINE_PRIM(_I32, face_glyph_count, _FACE);
DEFINE_PRIM(_I32, face_units_per_em, _FACE);
DEFINE_PRIM(_I32, face_ascender, _FACE);
DEFINE_PRIM(_I32, face_descender, _FACE);
DEFINE_PRIM(_I32, face_height, _FACE);
DEFINE_PRIM(_BYTES, face_family_name, _FACE);
DEFINE_PRIM(_BYTES, face_style_name, _FACE);
DEFINE_PRIM(_I32, face_glyph_index, _FACE _I32);
DEFINE_PRIM(_BOOL, face_set_pixel_size, _FACE _I32 _I32);
DEFINE_PRIM(_BOOL, face_set_char_size, _FACE _I32 _I32 _I32 _I32);
DEFINE_PRIM(_BOOL, face_metrics, _FACE _DYN);
DEFINE_PRIM(_BOOL, face_kerning, _FACE _I32 _I32 _I32 _DYN);
DEFINE_PRIM(_BOOL, face_render_codepoint, _FACE _I32 _I32 _I32 _DYN _DYN _DYN);
