--
-- Created by David Lannan
-- User: grover
-- Date: 19/04/13
-- Time: 12:04 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi   = require( "ffi" )

user32 = ffi.load( "USER32" )
kernel32 = ffi.load( "KERNEL32" )

ffi.cdef[[

    typedef char* PCIDLIST_ABSOLUTE;
    typedef char* LPCTSTR;
    typedef char* LPTSTR;
    typedef char TCHAR;
    typedef uint32_t LPARAM;
    typedef uint32_t UINT;
    typedef uint32_t HWND;
    typedef uint32_t DWORD;
    typedef uint32_t LPVOID;
    typedef uint32_t LONG;
    typedef uint32_t HINSTANCE;
    typedef uint16_t WORD;

    typedef struct tagBITMAP {
      LONG   bmType;
      LONG   bmWidth;
      LONG   bmHeight;
      LONG   bmWidthBytes;
      WORD   bmPlanes;
      WORD   bmBitsPixel;
      void * bmBits;
    } BITMAP;
    typedef BITMAP *PBITMAP;

    typedef struct _SYSTEMTIME {
      WORD wYear;
      WORD wMonth;
      WORD wDayOfWeek;
      WORD wDay;
      WORD wHour;
      WORD wMinute;
      WORD wSecond;
      WORD wMilliseconds;
    } SYSTEMTIME;
    typedef  SYSTEMTIME *PSYSTEMTIME;

    typedef struct tagBITMAPFILEHEADER {
      WORD  bfType;
      DWORD bfSize;
      WORD  bfReserved1;
      WORD  bfReserved2;
      DWORD bfOffBits;
    } BITMAPFILEHEADER;
    typedef BITMAPFILEHEADER *PBITMAPFILEHEADER;

    typedef struct _SECURITY_ATTRIBUTES {
        DWORD  nLength;
        LPVOID lpSecurityDescriptor;
        uint32_t   bInheritHandle;
    } SECURITY_ATTRIBUTES;
    typedef SECURITY_ATTRIBUTES *PSECURITY_ATTRIBUTES;
    typedef SECURITY_ATTRIBUTES *LPSECURITY_ATTRIBUTES;

    typedef struct _FILETIME {
        DWORD dwLowDateTime;
        DWORD dwHighDateTime;
    } FILETIME;
    typedef FILETIME *PFILETIME;

    typedef struct _WIN32_FIND_DATA {
        DWORD    dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD    nFileSizeHigh;
        DWORD    nFileSizeLow;
        DWORD    dwReserved0;
        DWORD    dwReserved1;
        TCHAR    cFileName[4096];
        TCHAR    cAlternateFileName[14];
    } WIN32_FIND_DATA;
    typedef WIN32_FIND_DATA *PWIN32_FIND_DATA;
    typedef WIN32_FIND_DATA *LPWIN32_FIND_DATA;

    typedef struct tagOFN {
      DWORD         lStructSize;
      HWND          hwndOwner;
      HINSTANCE     hInstance;
      LPCTSTR       lpstrFilter;
      LPTSTR        lpstrCustomFilter;
      DWORD         nMaxCustFilter;
      DWORD         nFilterIndex;
      LPTSTR        lpstrFile;
      DWORD         nMaxFile;
      LPTSTR        lpstrFileTitle;
      DWORD         nMaxFileTitle;
      LPCTSTR       lpstrInitialDir;
      LPCTSTR       lpstrTitle;
      DWORD         Flags;
      WORD          nFileOffset;
      WORD          nFileExtension;
      LPCTSTR       lpstrDefExt;
      LPARAM        lCustData;
      void *        lpfnHook;
      LPCTSTR       lpTemplateName;
      void *        pvReserved;
      DWORD         dwReserved;
      DWORD         FlagsEx;
    } OPENFILENAME;
    typedef OPENFILENAME *LPOPENFILENAME;

	typedef int32_t bool32;
	typedef intptr_t (__stdcall *WNDPROC)(void* hwnd, unsigned int message, uintptr_t wparam, intptr_t lparam);

	enum {
		CS_VREDRAW 		= 0x0001,
		CS_HREDRAW 		= 0x0002,
		CS_OWNDC        = 0x0020,

        ES_LEFT         = 0x00000000,
        ES_CENTER       = 0x00000001,
        ES_RIGHT        = 0x00000002,
        ES_MULTILINE    = 0x00000004,
        ES_UPPERCASE    = 0x00000008,
        ES_LOWERCASE    = 0x00000010,
        ES_PASSWORD     = 0x00000020,
        ES_AUTOVSCROLL  = 0x00000040,
        ES_AUTOHSCROLL  = 0x00000080,
        ES_NOHIDESEL    = 0x00000100,
        ES_COMBO        = 0x00000200,
        ES_OEMCONVERT   = 0x00000400,
        ES_READONLY     = 0x00000800,
        ES_WANTRETURN   = 0x00001000,
        ES_NUMBER       = 0x00002000,

        CTLCOLOR_MSGBOX         = 0,
        CTLCOLOR_EDIT           = 1,
        CTLCOLOR_LISTBOX        = 2,
        CTLCOLOR_BTN            = 3,
        CTLCOLOR_DLG            = 4,
        CTLCOLOR_SCROLLBAR      = 5,
        CTLCOLOR_STATIC         = 6,
        CTLCOLOR_MAX            = 7,
        COLOR_SCROLLBAR         = 0,
        COLOR_BACKGROUND        = 1,
        COLOR_ACTIVECAPTION     = 2,
        COLOR_INACTIVECAPTION   = 3,
        COLOR_MENU              = 4,
        COLOR_WINDOW            = 5,
        COLOR_WINDOWFRAME       = 6,
        COLOR_MENUTEXT          = 7,
        COLOR_WINDOWTEXT        = 8,
        COLOR_CAPTIONTEXT       = 9,
        COLOR_ACTIVEBORDER      = 10,
        COLOR_INACTIVEBORDER    = 11,
        COLOR_APPWORKSPACE      = 12,
        COLOR_HIGHLIGHT         = 13,
        COLOR_HIGHLIGHTTEXT     = 14,
        COLOR_BTNFACE           = 15,
        COLOR_BTNSHADOW         = 16,
        COLOR_GRAYTEXT          = 17,
        COLOR_BTNTEXT           = 18,
        COLOR_INACTIVECAPTIONTEXT = 19,
        COLOR_BTNHIGHLIGHT      = 20,
        COLOR_3DDKSHADOW        = 21,
        COLOR_3DLIGHT           = 22,
        COLOR_INFOTEXT          = 23,
        COLOR_INFOBK            = 24,
        COLOR_DESKTOP           = COLOR_BACKGROUND,
        COLOR_3DFACE            = COLOR_BTNFACE,
        COLOR_3DSHADOW          = COLOR_BTNSHADOW,
        COLOR_3DHIGHLIGHT       = COLOR_BTNHIGHLIGHT,
        COLOR_3DHILIGHT         = COLOR_BTNHIGHLIGHT,
        COLOR_BTNHILIGHT        = COLOR_BTNHIGHLIGHT,

        WM_CREATE                       = 0x0001,
        WM_DESTROY                      = 0x0002,
        WM_MOVE                         = 0x0003,
        WM_SIZE                         = 0x0005,
        WM_ACTIVATE                     = 0x0006,
        WM_KILLFOCUS                    = 0x0008,
        WM_ENABLE                       = 0x000A,
        WM_SETREDRAW                    = 0x000B,
        WM_SETTEXT                      = 0x000C,
        WM_GETTEXT                      = 0x000D,
        WM_GETTEXTLENGTH                = 0x000E,
        WM_PAINT                        = 0x000F,
        WM_CLOSE                        = 0x0010,
        WM_QUERYENDSESSION              = 0x0011,
        WM_QUIT                         = 0x0012,
        WM_QUERYOPEN                    = 0x0013,
        WM_ERASEBKGND                   = 0x0014,
        WM_SYSCOLORCHANGE               = 0x0015,
        WM_ENDSESSION                   = 0x0016,
        WM_SHOWWINDOW                   = 0x0018,
        WM_WININICHANGE                 = 0x001A,

        WS_EX_DLGMODALFRAME     = 0x00000001,
        WS_EX_NOPARENTNOTIFY    = 0x00000004,
        WS_EX_TOPMOST           = 0x00000008,
        WS_EX_ACCEPTFILES       = 0x00000010,
        WS_EX_TRANSPARENT       = 0x00000020,
        WS_EX_MDICHILD          = 0x00000040,
        WS_EX_TOOLWINDOW        = 0x00000080,
        WS_EX_WINDOWEDGE        = 0x00000100,
        WS_EX_CLIENTEDGE        = 0x00000200,
        WS_EX_CONTEXTHELP       = 0x00000400,
        WS_EX_RIGHT             = 0x00001000,
        WS_EX_LEFT              = 0x00000000,
        WS_EX_RTLREADING        = 0x00002000,
        WS_EX_LTRREADING        = 0x00000000,
        WS_EX_LEFTSCROLLBAR     = 0x00004000,
        WS_EX_RIGHTSCROLLBAR    = 0x00000000,
        WS_EX_CONTROLPARENT     = 0x00010000,
        WS_EX_STATICEDGE        = 0x00020000,
        WS_EX_APPWINDOW         = 0x00040000,

		WS_BORDER 		= 0x00800000,
		WS_CAPTION 		= 0x00C00000,
		WS_CHILD 		= 0x40000000,
		WS_CHILDWINDOW 	= 0x40000000,
		WS_CLIPCHILDREN = 0x02000000,
		WS_CLIPSIBLINGS = 0x04000000,
		WS_DISABLED 	= 0x08000000,
		WS_DLGFRAME 	= 0x00400000,
		WS_GROUP 		= 0x00020000,
		WS_HSCROLL 		= 0x00100000,
		WS_ICONIC 		= 0x20000000,
		WS_MAXIMIZE 	= 0x01000000,
		WS_MAXIMIZEBOX 	= 0x00010000,
		WS_MINIMIZE 	= 0x20000000,
		WS_MINIMIZEBOX 	= 0x00020000,
		WS_OVERLAPPED 	= 0x00000000,
		WS_SIZEBOX 		= 0x00040000,
		WS_SYSMENU 		= 0x00080000,
		WS_TABSTOP 		= 0x00010000,
		WS_THICKFRAME 	= 0x00040000,
		WS_TILED 		= 0x00000000,
		WS_VISIBLE 		= 0x10000000,
		WS_VSCROLL 		= 0x00200000,

		WS_POPUP = ((int)0x80000000),
		WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX,
		WS_POPUPWINDOW 	= WS_POPUP | WS_BORDER | WS_SYSMENU,
		WS_TILEDWINDOW 	= WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX,
      		
		WAIT_OBJECT_0 	= 0x00000000,
		PM_REMOVE 		= 0x0001,
		SW_SHOW 		= 5,
		INFINITE 		= 0xFFFFFFFF,
		QS_ALLEVENTS 	= 0x04BF,

        FILE_ATTRIBUTE_READONLY    = 0x00000001,
        FILE_ATTRIBUTE_HIDDEN      = 0x00000002,
        FILE_ATTRIBUTE_SYSTEM      = 0x00000004,
        FILE_ATTRIBUTE_DIRECTORY   = 0x00000010,
        FILE_ATTRIBUTE_ARCHIVE     = 0x00000020,
        FILE_ATTRIBUTE_NORMAL      = 0x00000080,
        FILE_ATTRIBUTE_TEMPORARY   = 0x00000100,
        FILE_ATTRIBUTE_COMPRESSED  = 0x00000800,
        FILE_ATTRIBUTE_OFFLINE     = 0x00001000
	};

	typedef struct RECT { int32_t left, top, right, bottom; } RECT;
	typedef struct POINT { int32_t x, y; } POINT;

	typedef struct WNDCLASSEXA {
		uint32_t cbSize, style;
		WNDPROC lpfnWndProc;
		int32_t cbClsExtra, cbWndExtra;
		void* hInstance;
		void* hIcon;
		void* hCursor;
		int32_t hbrBackground;
		const char* lpszMenuName;
		const char* lpszClassName;
		void* hIconSm;
	} WNDCLASSEXA;

	typedef struct MSG {
		void* hwnd;
		uint32_t message;
		uintptr_t wParam, lParam;
		uint32_t time;
		POINT pt;
	} MSG;

	typedef struct SECURITY_ATTRIBUTES {
		uint32_t nLength;
		void* lpSecurityDescriptor;
		bool32 bInheritHandle;
	} SECURITY_ATTRIBUTES;

    typedef DWORD COLORREF;
    typedef DWORD* LPCOLORREF;

    enum {
        CF_TEXT     = 1,
        CF_BITMAP   = 2,
        CF_DIB      = 8
    };

    int         OpenClipboard(void*);
    void*       GetClipboardData(unsigned);
    int         CloseClipboard();
    void*       GlobalLock(void*);
    int         GlobalUnlock(void*);
    size_t      GlobalSize(void*);
    bool32      EmptyClipboard(void);
    bool32      IsClipboardFormatAvailable(uint32_t format);

    uint32_t    LoadLibraryA( const char *lpFileName );
	void *		GetModuleHandleA(const char* name);
	uint16_t 	RegisterClassExA(const WNDCLASSEXA*);
	intptr_t 	DefWindowProcA(void* hwnd, uint32_t msg, uintptr_t wparam, uintptr_t lparam);
	void 		PostQuitMessage(int exitCode);
	void* 		LoadIconA(void* hInstance, const char* iconName);
	void* 		LoadCursorA(void* hInstance, const char* cursorName);
	uint32_t 	GetLastError();
	void *   	CreateWindowExA(uint32_t exstyle,	const char* classname,	const char* windowname,	int32_t style,	int32_t x, int32_t y, int32_t width, int32_t height, void * parent_hwnd, void * hmenu, void * hinstance, void * param);
	bool32 		ShowWindow(void* hwnd, int32_t command);
	bool32 		UpdateWindow(void* hwnd);
    bool32      SetWindowTextA(void *hWnd, const char *lpString);

    int         GetKeyState( int nVirtKey );

	int 		GetMessageA(MSG* out_msg, void* hwnd, uint32_t filter_min, uint32_t filter_max);
	int 		PeekMessageA(MSG* out_msg, void* hwnd, uint32_t filter_min, uint32_t filter_max, uint32_t removalMode);
	bool32 		TranslateMessage(const MSG* msg);
	intptr_t 	DispatchMessageA(const MSG* msg);
	bool32 		InvalidateRect(void* hwnd, const RECT*, bool32 erase);
	void* 		CreateEventA(SECURITY_ATTRIBUTES*, bool32 manualReset, bool32 initialState, const char* name);
	uint32_t 	MsgWaitForMultipleObjects(uint32_t count, void** handles, bool32 waitAll, uint32_t ms, uint32_t wakeMask);

    bool32      GetOpenFileNameA( LPOPENFILENAME lpofn);
    bool32      CreateDirectoryA( const char*  lpPathName, LPSECURITY_ATTRIBUTES lpsec );
    uint32_t    FindFirstFileA( const char*  lpFileName, LPWIN32_FIND_DATA lpFindFileData );
    bool32      FindNextFileA( uint32_t hFindFile, LPWIN32_FIND_DATA lpFindFileData );
    bool32      FindClose( uint32_t hFindFile );

    void        keybd_event(uint8_t bVk, uint8_t bScan, uint32_t dwFlags, void * dwExtraInfo);
    void        Sleep(DWORD dwMilliseconds);
    bool32      FileTimeToSystemTime( const FILETIME *lpFileTime, PSYSTEMTIME lpSystemTime);

    int         GetObjectA(void * hgdiobj, uint32_t cbBuffer, void * lpvObject);
    uint32_t    GetBitmapBits( void * hbmp, uint32_t cbBuffer,void * lpvBits);
    uint32_t    CreateSolidBrush(uint32_t crColor);
    uint32_t    GetSysColorBrush(int nIndex);

]]
