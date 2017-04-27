
------------------------------------------------------------------------------------------------------------
local ffi = require( "ffi" )

local kernel32 	= ffi.load( "kernel32.dll" )
local user32 	= ffi.load( "user32.dll" )
local comdlg32  = ffi.load( "Comdlg32.dll" )
local gdi32     = ffi.load( "gdi32.dll" )

require("ffi/win32")
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

local reg = nil
local count = 0

------------------------------------------------------------------------------------------------------------

function CreateWindow(px, py, wide, high)

	local hInstance = kernel32.GetModuleHandleA(nil)
	local CLASS_NAME = 'TestWindowClass'
	
	if (reg == nil ) then
	
		local classstruct = {}
		classstruct.cbSize 		= ffi.sizeof( "WNDCLASSEXA" )
		classstruct.style 		= bit.bor(user32.CS_HREDRAW, user32.CS_VREDRAW)
	
		classstruct.lpfnWndProc = 
		function(hwnd, msg, wparam, lparam)
			if (msg == user32.WM_DESTROY) then
				user32.PostQuitMessage(0)
				return 0
			end
			return user32.DefWindowProcA(hwnd, msg, wparam, lparam)
		end
		
		classstruct.cbClsExtra 		= 0
		classstruct.cbWndExtra 		= 0
		classstruct.hInstance 		= hInstance	
		classstruct.hIcon 			= user32.LoadIconA(nil, idi.APPLICATION)
		classstruct.hCursor 		= user32.LoadCursorA(nil, idc.ARROW)
		classstruct.hbrBackground 	= nil
		classstruct.lpszMenuName 	= nil
		classstruct.lpszClassName 	= CLASS_NAME
		classstruct.hIconSm = nil
		
		local wndclass = ffi.new( "WNDCLASSEXA", classstruct )	
		local reg = user32.RegisterClassExA( wndclass )
		
		if (reg == 0) then
			error('error #' .. mswin.GetLastError())
		end
	end 
			
	local hwnd = user32.CreateWindowExA( 0, CLASS_NAME, "Test Window", user32.WS_POPUP, px, py, wide, high, nil, nil, hInstance, nil)	
	if (hwnd == nil) then
		error 'unable to create window'
	end
	
	user32.ShowWindow(hwnd, user32.SW_SHOW)	
	return hwnd
end

------------------------------------------------------------------------------------------------------------

local msg = ffi.new 'MSG'

function UpdateWindow(hwnd)

	user32.UpdateWindow(hwnd)
	if (user32.PeekMessageA(msg, nil, 0, 0, user32.PM_REMOVE) ~= 0) then
		user32.TranslateMessage(msg)
		user32.DispatchMessageA(msg)
--		if (msg.message == mswin.WM_QUIT) then
--			quitting = true
--		end
	end
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
