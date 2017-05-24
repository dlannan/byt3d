--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:48 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

#ifndef __fmad_world_image_h__
#define __fmad_world_image_h__

typedef struct fImage_t
    {
        u32		Width;
u32		Height;

u8		ChannelBits;
u8		Channels;
u8		pad0;
u8		pad1;

u32*		Data;

} fImage_t;

// IF: world -> image format
typedef struct fImage_t* fImageLoad_f(lua_State* L);
typedef struct fImageDef_t
    {
        char			Extension[128];
fImageLoad_f*		Load;
void*			Save;

} fImageDef_t;

// IF: image format -> world
typedef void fImage_Define_f(fImageDef_t* Def);
typedef struct fImageExternal_t
    {
        fImage_Define_f*	Define;

    } fImageExternal_t;

int 		fImage_Register(lua_State* L);
fImage_t*	fImage_Load(const char* Format, lua_State* L);
void 		fImage_Save(fImage_t* Image, lua_State* L) ;
void 		fImage_Free(fImage_t* Image);

#endif
