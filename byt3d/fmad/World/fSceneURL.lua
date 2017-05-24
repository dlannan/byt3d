--
-- Created by David Lannan
-- User: grover
-- Date: 19/05/13
-- Time: 2:34 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--

//********************************************************************************************************************
//
// fmad llc 2008
//
// url parser healper
//
//********************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <Common/fCommon.h>
#include "fSceneURL.h"

//********************************************************************************************************************
bool fSceneURL_Parse(	const char* url,
char* Protocol,
char* Scene,
char* Host,
char* Type,
char* Path,
char* Parent,
char* Name)
    {
        static char _Protocol[1024];
static char _Scene[1024];
static char _Host[1024];
static char _Type[1024];
static char _Path[1024];
static char _Parent[1024];
static char _Name[1024];

if (url == NULL) return false;

Protocol= (Protocol == NULL) ? _Protocol : Protocol;
Scene	= (Scene == NULL) ? _Scene : Scene;
Host	= (Host == NULL) ? _Host : Host;
Type	= (Type == NULL) ? _Type : Type;
Path	= (Path == NULL) ? _Path : Path;
Parent	= (Parent == NULL) ? _Parent : Parent;
Name	= (Name == NULL) ? _Name : Name;

// defaults
strcpy(Protocol, "");
strcpy(Scene, "");
strcpy(Host, "");
strcpy(Type, "");
strcpy(Path, "/");
strcpy(Parent, "");
strcpy(Name, "");

enum
    {
        PROTOCOL	= 1,	// protocol
SCENE,			// scene name
HOST,			// host name
TYPE,			// type
PATH,			// path
ARGS,			// arguments
};

u32 PCount = 0;

u32 p = 0;
u32 s = 0;
u32 h = 0;
u32 t = 0;
u32 a = 1;
u32 parent = 0;

bool PathSet = false;

u32 State = PROTOCOL;
u32 len = strlen(url);
bool Valid = true;
for (int i=0; i < len && Valid; i++)
    {
        int c = url[i];
switch (State)
    {
        case PROTOCOL:
{
switch (c)
    {
        case URI_SET_DIGIT:
case URI_SET_ALPHA:
Protocol[p++] = c;
break;
case ':':
if (PCount != 0) Valid = false;
PCount |= (1<<0);
break;
case '/': 	PCount += (1<<1);	break;
default:	Valid = false;		break;
}

// : and two /
if (PCount == 5)
{
// is next part scene or host ?
State = HOST;
for (int j=i; j < len; j++)
{
if (url[j] == '@')
{
State = SCENE;
break;
}
}
}
break;
}
break;

case SCENE:
switch (c)
{
case URI_SET_DIGIT:
case URI_SET_ALPHA:
Scene[s++] = c;
break;
case '@':	State = HOST;		break;
case ':':	State = TYPE;		break;
case '/':	State = PATH;		break;
default:	Valid = false;		break;
}
break;

case HOST:
switch (c)
{
case URI_SET_DIGIT:
case URI_SET_ALPHA:
case _UT('.'):
case _UT(' '):
case _UT('_'):
Host[h++] = c;
break;
case ':':	State = TYPE;		break;
case '/':	State = PATH;		break;
default:	Valid = false;		break;
}
break;

case TYPE:
switch (c)
{
case URI_SET_DIGIT:
case URI_SET_ALPHA:
Type[t++] = c;
break;
case '/':	State = PATH;		break;
default:	Valid = false;		break;
}
break;

case PATH:
switch (c)
{
case _UT('/'):
if ((a > 0) && (Path[a-1] == '/'))
{
//printf("path skip %c\n", c);
break;
}
parent		= a;
Path[a++]	= c;
break;
case URI_PATH:
// ? is valid path char, but break it out here
if (c != '?')
{
PathSet		= true;
Path[a++]	= c;
}
else
{
State = ARGS;
}
break;

default:	Valid = false;		break;
}
break;

default:
break;
}

if (!Valid)
{
ftrace("invalid URL pos %i %s\n", i, url);
return false;
}
}

// asciiz
Protocol[p]	= 0;
Scene[s]	= 0;
if (h > 0)	Host[h]	= 0;
Type[t]		= 0;
Path[a]		= 0;

// root node
u32 r = 0;
Parent[r++] = '/';
for (int i=0; i < parent; i++)
{
Parent[r] = Path[i];

switch (Path[i])
{
case URI_PATH:
r++;
break;
// remove redundant ///////aasdfasdf//asdf
case _UT('/'):
if (Parent[r-1] != Path[i]) r++;
break;
}
}
Parent[r] = 0;

int n = 0;
for (int i=parent; i < a; i++)
{
if ((n == 0) && (Path[i] == '/')) continue;		// skip leading /
Name[n++] = Path[i];
}
Name[n] = 0;

/*
ftrace("url    [%s]\n", url);
ftrace("prot   [%s]\n", Protocol);
ftrace("scen   [%s]\n", Scene);
ftrace("host   [%s]\n", Host);
ftrace("port   [%s]\n", Type);
ftrace("path   [%s]\n", Path);
ftrace("parent [%s]\n", Parent);
ftrace("name   [%s]\n", Name);
*/
return true;
}

//********************************************************************************************************************
bool fSceneURL_Generate(char* url,
char* Protocol,
char* Host,
char* Path,
char* Parent,
char* Name)
{
u32 p = 0;

// protocol
for (int i=0; i < strlen(Protocol); i++)
{
url[p++] = Protocol[i];
}
url[p++] = ':';
url[p++] = '/';
url[p++] = '/';

Host = (Host == NULL) ? "localhost" : Host;
for (int i=0; i < strlen(Host); i++)
{
url[p++] = Host[i];
}
url[p++] = '/';

if (Path != NULL)
{
for (int i=0; i < strlen(Path); i++)
{
u32 c = Path[i];
switch (c)
{
case '/':
if (url[p-1] == '/') break;

case URI_PATH:
url[p++] = c;
break;
}
}
}
else if ((Parent != NULL) && (Name != NULL))
{
for (int i=0; i < strlen(Parent); i++)
{
u32 c = Parent[i];
switch (c)
{
case '/':
if (url[p-1] == '/') break;
case URI_PATH:
url[p++] = c;
break;
}
}
if (url[p-1] != '/') url[p++] = '/';
for (int i=0; i < strlen(Name); i++)
{
u32 c = Name[i];
switch (c)
{
case '/':
if (url[p-1] == '/') break;
case URI_SET_DIGIT:
case URI_SET_ALPHA:
url[p++] = c;
break;
}
}
}
url[p++] = 0;
}

//********************************************************************************************************************
// flattens out a url
void fSceneURL_Flatten(char* URL)
{
u32 len = strlen(URL);
u32 p = 0;
for (int i=0; i < len; i++)
{
int c = URL[i];
switch (c)
{
case '/':
if ((p > 0) && (URL[p-1] == '/')) break;
case '_':
case '-':
case ' ':
case '.':
case URI_SET_DIGIT:
case URI_SET_ALPHA:
URL[p++] = c;
break;
}
}
URL[p++] = 0;
}
//********************************************************************************************************************
// returns parent url
void fSceneURL_Parent(char* parent, const char* url)
{
u32 len = strlen(url);
u32 last = 0;
u32 count = 0;
for (int i=0; i < len; i++)
{
int c = url[i];
switch (c)
{
case '/':
count++;
last = i;
break;
}
}
// only 3 / 's so dont overwrite /
if (count == 3) last++;

memcpy(parent, url, last);
parent[last] = 0;	// asciiz
}
