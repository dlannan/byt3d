local ffi   = require( "ffi" )
 
ffi.cdef[[

    typedef char* PCIDLIST_ABSOLUTE;
    typedef char* LPCTSTR;
    typedef char* LPTSTR;
    typedef uint32_t LPARAM;
    typedef uint32_t UINT;
    typedef uint32_t HWND;
    typedef uint32_t DWORD;
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

    typedef struct tagBITMAPFILEHEADER {
      WORD  bfType;
      DWORD bfSize;
      WORD  bfReserved1;
      WORD  bfReserved2;
      DWORD bfOffBits;
    } BITMAPFILEHEADER;
    typedef BITMAPFILEHEADER *PBITMAPFILEHEADER;

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
		WM_DESTROY 		= 0x0002,
		WM_QUIT 		= 0x0012,

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
		QS_ALLEVENTS 	= 0x04BF
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
		void* hbrBackground;
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

	void *		GetModuleHandleA(const char* name);
	uint16_t 	RegisterClassExA(const WNDCLASSEXA*);
	intptr_t 	DefWindowProcA(void* hwnd, uint32_t msg, uintptr_t wparam, uintptr_t lparam);
	void 		PostQuitMessage(int exitCode);
	void* 		LoadIconA(void* hInstance, const char* iconName);
	void* 		LoadCursorA(void* hInstance, const char* cursorName);
	uint32_t 	GetLastError();
	void* 		CreateWindowExA(uint32_t exstyle,	const char* classname,	const char* windowname,	int32_t style,	int32_t x, int32_t y, int32_t width, int32_t height, void* parent_hwnd, void* hmenu, void* hinstance, void* param);
	bool32 		ShowWindow(void* hwnd, int32_t command);
	bool32 		UpdateWindow(void* hwnd);
	bool32 		PeekMessageA(MSG* out_msg, void* hwnd, uint32_t filter_min, uint32_t filter_max, uint32_t removalMode);
	bool32 		TranslateMessage(const MSG* msg);
	intptr_t 	DispatchMessageA(const MSG* msg);
	bool32 		InvalidateRect(void* hwnd, const RECT*, bool32 erase);
	void* 		CreateEventA(SECURITY_ATTRIBUTES*, bool32 manualReset, bool32 initialState, const char* name);
	uint32_t 	MsgWaitForMultipleObjects(uint32_t count, void** handles, bool32 waitAll, uint32_t ms, uint32_t wakeMask);

    bool32      GetOpenFileNameA( LPOPENFILENAME lpofn);
    void        keybd_event(uint8_t bVk, uint8_t bScan, uint32_t dwFlags, void * dwExtraInfo);
    void        Sleep(DWORD dwMilliseconds);

    int         GetObjectA(void * hgdiobj, uint32_t cbBuffer, void * lpvObject);
    uint32_t    GetBitmapBits( void * hbmp, uint32_t cbBuffer,void * lpvBits);

]]
