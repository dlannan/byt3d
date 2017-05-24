--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:47 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

//********************************************************************************************************************
//
// fmad llc 2008
//
// jpeg interface
//
//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <Tools/libjpeg/jpeglib.h>

#include <Common/fCommon.h>

#include "fImage.h"
#include "fImageJPEG.h"

//********************************************************************************************************************

typedef struct
    {
        u32	Width;
u32	Height;
u32	BufferSize;
u32	CompressSize;
void*	Buffer;

} fImageJPEG_t;

static void buffer_create(j_compress_ptr cinfo)
    {
        fImageJPEG_t* Img = fMalloc(sizeof(fImageJPEG_t));

Img->Width = cinfo->image_width;
Img->Height = cinfo->image_height;

// its half the size, as compression should at the least get 50% reduction
Img->BufferSize = Img->Width*Img->Height*4/2;
Img->Buffer	= fMalloc(Img->BufferSize);

cinfo->dest->user_data		= Img;
cinfo->dest->next_output_byte	= Img->Buffer;
cinfo->dest->free_in_buffer	= Img->BufferSize;
}

static boolean buffer_flush(j_compress_ptr cinfo)
    {
        fAssert(true);
        printf("empty buffer %i\n", 1024*1024 - cinfo->dest->free_in_buffer);
return TRUE;
}

static void buffer_close(j_compress_ptr cinfo)
{
fImageJPEG_t* I = cinfo->dest->user_data;
fAssert(I);

I->CompressSize = I->BufferSize - cinfo->dest->free_in_buffer;
/*
FILE* F = fopen("out.jpeg", "wb");
fwrite(buffer, len, 1, F);
fclose(F);
*/
}

static fImageJPEG_t* get_image_data(j_compress_ptr cinfo)
{
return cinfo->dest->user_data;
}

fImageJPEG_t* fImgJPEG_Encode(u32 Width, u32 Height, u8* Data)
{
struct jpeg_compress_struct 	cinfo;
struct jpeg_error_mgr		jerr;

cinfo.err = jpeg_std_error(&jerr);
jpeg_create_compress(&cinfo);

struct jpeg_destination_mgr dest_mgr;
dest_mgr.init_destination	= buffer_create;
dest_mgr.empty_output_buffer	= buffer_flush;
dest_mgr.term_destination	= buffer_close;

cinfo.dest = &dest_mgr;

cinfo.image_width	= Width;
cinfo.image_height	= Height;
cinfo.in_color_space	= JCS_RGB;
cinfo.input_components	= 4;
jpeg_set_defaults(&cinfo);

cinfo.dct_method = JDCT_IFAST;

jpeg_set_quality(&cinfo, 75, FALSE);

jpeg_start_compress(&cinfo, TRUE);
char buffer[1024*3];
for (int i=0; i < Height; i++)
{
u8* Row = Data + i*Width*4;

void* scanline[1] = { Row };
jpeg_write_scanlines(&cinfo, (JSAMPARRAY)scanline, 1);
}

fImageJPEG_t* I = get_image_data(&cinfo);

jpeg_finish_compress(&cinfo);
jpeg_destroy_compress(&cinfo);

return I;
}

//********************************************************************************************************************
void fImgJPEG_Free(fImageJPEG_t* I)
{
if (I->Buffer)
{
fFree(I->Buffer);
I->Buffer = NULL;
}
fFree(I);
}

#if 0
//********************************************************************************************************************
char blah[1024*1024*4];
static int lImgJPEG_Compress(lua_State* L)
{
struct fSceneFrame_t * F= toFrame(L, -1);

u8* FrameData32 = fFrame_Readback(F);

//dtrace("%i %i\n", fFrame_Width(F), fFrame_Height(F));
fImageJPEG_t* I = fImgJPEG_Encode(fFrame_Width(F), fFrame_Height(F), FrameData32);

lua_pushlstring(L, I->Buffer, I->CompressSize);

fImgJPEG_Free(I);

return 1;
}
#endif

//********************************************************************************************************************

void fImgJPEG_Register(lua_State* L)
{
//lua_table_register(L, -1, "fImgJPEG_Compress",		lImgJPEG_Compress);
}
