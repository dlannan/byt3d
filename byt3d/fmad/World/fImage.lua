--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:48 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

//********************************************************************************************************************
//
// fmad llc 2008
//
// generic interface for image loaders
//
//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <Common/fCommon.h>
#include <Network/fNetwork.h>
#include <Module/Render/fRealize.h>
#include <Module/World/fSceneObject.h>

#include "fImage.h"

//********************************************************************************************************************

static int 		s_ImageCount	= 0;
static int 		s_ImageMax	= 16;
static fImageDef_t	s_Image[16];

//********************************************************************************************************************

static void iImage_Define(fImageDef_t* Def)
    {
for (int i=0; i < s_ImageCount; i++)
    {
if (strcmp(s_Image[i].Extension, Def->Extension) == 0)
    {
        ftrace("duplicate image file extension [%s]\n", Def->Extension);
        fAssert(false);
    }
}
    memcpy(&s_Image[s_ImageCount++], Def, sizeof(fImageDef_t));
    ftrace("ImageFormat [%10s] Defined\n", Def->Extension);
    }

    //********************************************************************************************************************

    static int lImage_Define(lua_State* L)
        {
            const char* Desc = lua_tostring(L, -2);
    printf("scene image register: [%s]\n", Desc);

    u32 BCLen	= 0;
    const char* _Buf= lua_tolstring(L, -1, &BCLen);

    // need to null terminiate it...
    char* BC = (char *)fMalloc(BCLen+1);
    memcpy(BC, _Buf, BCLen);
    BC[BCLen] = 0;


    fImageExternal_t EIF;
    EIF.Define = iImage_Define;

    // register the image
    fExecuteJIT(BC, BCLen, "fImage_Open", &EIF);
    fAssert(s_ImageCount < s_ImageMax);

    fFree(BC);

    return 0;
}

//********************************************************************************************************************

static int lImage_Dump(lua_State* L)
    {
for (int i=0; i < s_ImageCount; i++)
    {
        printf("[%02i] Image format %s\n", i, s_Image[i].Extension);
    }
}

//********************************************************************************************************************

fImage_t* fImage_Load(const char* Format, lua_State* L)
    {
        // find the format
fImageDef_t* Def = NULL;
for (int i=0; i < s_ImageCount; i++)
    {
if (strcmp(s_Image[i].Extension, Format) == 0)
    {
        Def = &s_Image[i];
break;
}
}
fAssert(Def);

fImage_t* Img = Def->Load(L);
return Img;
}


//********************************************************************************************************************

void fImage_Save(fImage_t* Image, lua_State* L)
{
fAssert(false);
}
//********************************************************************************************************************

void fImage_Free(fImage_t* Image)
{
if (Image->Data != NULL)
{
fFree(Image->Data);
Image->Data = NULL;
}
}

//********************************************************************************************************************

int fImage_Register(lua_State* L)
{
lua_table_register(L, -1, "Image_Define",	lImage_Define);
lua_table_register(L, -1, "Image_Dump",		lImage_Dump);

return 0;
}
