
------------------------------------------------------------------------------------------------------------
local fileio    = require("scripts/utils/fileio")
------------------------------------------------------------------------------------------------------------
--package.preload['extern.mswindows.winmm'] = function()
--	local ffi = require 'ffi'
--
--	ffi.cdef [[
--
--	enum {
--	TIME_PERIODIC = 0x1,
--	TIME_CALLBACK_FUNCTION = 0x00,
--	TIME_CALLBACK_EVENT_SET = 0x10,
--	TIME_CALLBACK_EVENT_PULSE = 0x20
--	};
--	uint32_t timeSetEvent(uint32_t delayMs, uint32_t resolutionMs, void* callback_or_event, uintptr_t user, uint32_t eventType);
--
--	]]
--
--	return ffi.load 'winmm'
--end
--
--package.preload['extern.mswindows.idi'] = function()
--
--	local ffi = require 'ffi'
--
--	return {
--		APPLICATION = ffi.cast('const char*', 32512);
--	}
--
--end
--
--package.preload['extern.mswindows.idc'] = function()
--
--	local ffi = require 'ffi'
--
--	return {
--		ARROW = ffi.cast('const char*', 32512);
--	}
--
--end

--local bit = require 'bit'
--local ffi = require 'ffi'
--local mswin = require 'extern.mswindows'
--local winmm = require 'extern.mswindows.winmm'
--local idi = require 'extern.mswindows.idi'
--local idc = require 'extern.mswindows.idc'

------------------------------------------------------------------------------------------------------------

idi = { APPLICATION = ffi.cast('const char*', 32512) }
idc = { ARROW = ffi.cast('const char*', 32512) }

window_debug_class_reg = nil
local count = 0

------------------------------------------------------------------------------------------------------------

function InitializeComponent(hWnd)

    local hInstance = kernel32.GetModuleHandleA(nil)

    -- Adding a Button.
    local hBtn = user32.CreateWindowExA(user32.WS_EX_APPWINDOW, "BUTTON", "temp", bit.bor(user32.WS_CHILD, user32.WS_VISIBLE), 327, 7, 70, 21, hWnd, nil, hInstance, nil)
    user32.SetWindowTextA(hBtn, "&Button")

    -- Adding a Label.
    local hLabel = user32.CreateWindowExA(user32.WS_EX_CLIENTEDGE, "STATIC", "temp", bit.bor(user32.WS_CHILD, user32.WS_VISIBLE), 7, 7, 50, 21, hWnd, nil, hInstance, nil)
    user32.SetWindowTextA(hLabel, "Label:")

    -- Adding a ListBox.
    local hListBox = user32.CreateWindowExA(user32.WS_EX_CLIENTEDGE, "LISTBOX", "temp", bit.bor(user32.WS_CHILD, user32.WS_VISIBLE, user32.WS_VSCROLL, user32.ES_AUTOVSCROLL), 7, 35, 300, 200, hWnd, nil, hInstance, nil)

    -- Adding a TextBox.
    local hTextBox = user32.CreateWindowExA(user32.WS_EX_CLIENTEDGE, "EDIT", "temp", bit.bor(user32.WS_CHILD, user32.WS_VISIBLE, user32.ES_AUTOVSCROLL), 62, 7, 245, 21, hWnd, nil, hInstance, nil)
    user32.SetWindowTextA(hTextBox, "Input text here...")
end

------------------------------------------------------------------------------------------------------------

function CreateWindow(px, py, wide, high)

	local hInstance = kernel32.GetModuleHandleA(nil)
	local CLASS_NAME = 'DebugWindow'

	if (window_debug_class_reg == nil ) then
        -- Rich Edit.. nice...
        kernel32.LoadLibraryA("Riched32.dll")

        local classstruct = {}
		classstruct.cbSize 		= ffi.sizeof( "WNDCLASSEXA" )
        classstruct.style       = 0

		classstruct.lpfnWndProc = 
		function(hwnd, msg, wparam, lparam)
			if (msg == user32.WM_DESTROY) then
                print("Trying to quit from debug window.")
				user32.PostQuitMessage(user32.WM_QUIT)
				return 0
--            elseif (msg == user32.WM_CREATE) then
--                return 0
--            elseif (msg == user32.WM_PAINT) then
--                return 0
			end
			return user32.DefWindowProcA(hwnd, msg, wparam, lparam)
		end
		
		classstruct.cbClsExtra 		= 0
		classstruct.cbWndExtra 		= 0
		classstruct.hInstance 		= hInstance	
		classstruct.hIcon 			= nil --user32.LoadIconA(nil, idi.APPLICATION)
		classstruct.hCursor 		= nil --user32.LoadCursorA(nil, idc.ARROW)
		classstruct.hbrBackground 	= user32.GetSysColorBrush(user32.COLOR_WINDOW)
		classstruct.lpszMenuName 	= nil
		classstruct.lpszClassName 	= CLASS_NAME
		classstruct.hIconSm = nil
		
		local wndclass = ffi.new( "WNDCLASSEXA", classstruct )
		local window_debug_class_reg = user32.RegisterClassExA( wndclass )
		
		if (window_debug_class_reg == nil) then
			error('error #' .. kernel32.GetLastError())
		end
	end 

	local hwnd = user32.CreateWindowExA( user32.WS_EX_CLIENTEDGE, CLASS_NAME, "Debug Window", user32.WS_OVERLAPPEDWINDOW, px, py, wide, high, nil, nil, hInstance, nil)
    -- local hwnd_edit = user32.CreateWindowExA( 0x0, "RICHEDIT","text", bit.bor(user32.WS_BORDER, user32.WS_CHILD, user32.WS_VISIBLE, user32.ES_MULTILINE),10,10,300,300,hwnd,nil,hInstance,nil)
	if (hwnd == nil) then
		error 'unable to create window'
    end

    InitializeComponent(hwnd)
	
	user32.ShowWindow(hwnd, user32.SW_SHOW)
    user32.UpdateWindow(hwnd)

	return hwnd
end

------------------------------------------------------------------------------------------------------------

function UpdateWindow(hwnd)

    local msg = ffi.new("MSG")

	while (user32.PeekMessageA(msg, nil, 0, 0, user32.PM_REMOVE) ~= 0) do
		user32.TranslateMessage(msg)
		user32.DispatchMessageA(msg)
		if (msg.message == user32.WM_QUIT) then
			return 1
		end
    end

    return 0
end

------------------------------------------------------------------------------------------------------------

--local timerEvent = mswin.CreateEventA(nil, false, false, nil)
--if (timerEvent == nil) then
--	error('unable to create event')
--end
--local timer = winmm.timeSetEvent(25, 5, timerEvent, 0, bit.bor(winmm.TIME_PERIODIC, winmm.TIME_CALLBACK_EVENT_SET))
--if (timer == 0) then
--	error('unable to create timer')
--end

------------------------------------------------------------------------------------------------------------

--local handleCount = 1
--local handles = ffi.new('void*[1]', {timerEvent})
--
--local msg = ffi.new 'MSG'
--
--local quitting = false
--while not quitting do
--	local waitResult = mswin.MsgWaitForMultipleObjects(handleCount, handles, false, mswin.INFINITE, mswin.QS_ALLEVENTS)
--	if (waitResult == mswin.WAIT_OBJECT_0 + handleCount) then
--		if (mswin.PeekMessageA(msg, nil, 0, 0, mswin.PM_REMOVE) ~= 0) then
--			mswin.TranslateMessage(msg)
--			mswin.DispatchMessageA(msg)
--			if (msg.message == mswin.WM_QUIT) then
--				quitting = true
--			end
--		end
--	elseif (waitResult == mswin.WAIT_OBJECT_0) then
--		mswin.InvalidateRect(testHwnd, nil, false)
--	else
--		print 'unexpected event'
--	end
--end

------------------------------------------------------------------------------------------------------------

function WindowsFileSelect()

end

------------------------------------------------------------------------------------------------------------

function WindowsFolderSelect()
    local ofn = ffi.new("OPENFILENAME")
    ofn.lStructSize = ffi.sizeof(ofn)
    ofn.lpstrFile = ffi.new( "char[512]" )
    ofn.lpstrFilter = ffi.new( "char[19]", "All\0*.*\0Text\0*.TXT\0")
    ofn.lpstrInitialDir = ffi.new( "char[3]", "C:/")
    comdlg32.GetOpenFileNameA( ofn )

    print("Selected folder: ", ffi.string(ofn.lpstrFile ), ffi.string(ofn.lpstrFilter ))
end


------------------------------------------------------------------------------------------------------------
