-------------------------------------------------------------------------------------------------------------
--
-- fmad llc 2008 
--
-- lua scene object vm 
--
-------------------------------------------------------------------------------------------------------------

-- persistance arse
permtable		= { 1234 } 
perms			= { [coroutine.yield] = 1, [permtable] = 2 }
unperms			= { [1] = coroutine.yield, [2] = permtable }

-------------------------------------------------------------------------------------------------------------

ObjectName 		= "uninitialized"

-------------------------------------------------------------------------------------------------------------
-- list of resereved global vars to ignore
__reserved =
{
-- lua core
["xpcall"]				= true, 
["require"]				= true, 
["getfenv"]				= true, 
["next"]				= true, 
["assert"]				= true, 
["load"]				= true, 
["module"]				= true, 
["rawset"]				= true, 
["rawequal"]			= true,  
["collectgarbage"]		= true, 
["setmetatable"]		= true,
["getmetatable"]		= true, 
["tostring"]			= true, 
["print"]				= true, 
["unpack"]				= true, 
["tonumber"]			= true, 
["pcall"]				= true, 
["newproxy"]			= true, 
["type"]				= true, 
["select"]				= true,
["gcinfo"]				= true, 
["pairs"]				= true, 
["ipairs"]				= true, 
["npairs"]				= true, 
["dirlist"]				= true, 
["rawget"]				= true, 
["loadstring"]			= true, 
["dofile"]				= true, 
["setfenv"]				= true, 
["error"]				= true, 
["loadfile"]			= true,
["debug"]				= true,
["io"]					= true,
["math"]				= true,
["pluto"]				= true,
["coroutine"]			= true,
["perms"]				= true,
["unperms"]				= true,
["_G"]					= true,
["inspector"]			= true,
["os"]					= true,
["string"]				= true,
["package"]				= true,
["table"]				= true,
["permtable"]			= true,
["_VERSION"]			= true,

-- runtime
["ftrace"]				= true, 
["dtrace"]				= true, 
["etrace"]				= true, 
["sel"]					= true, 
["newtry"]				= true, 	-- error handlers Lua/lbaselib.c
["protect"]				= true, 	-- error handlers Lua/lbaselib.c

-- locals
["toSource"]			= true,
["getFunctionSource"]	= true,
["setFunctionSource"]	= true,
["getSource"]			= true,
["setSource"]			= true,
["Setup"]				= true,
["Serialize"]			= true,
["ObjectInfo"]			= true,		-- used by editor
["DispatchPacket"]		= true,		-- used by editor
["DispatchAdd"]			= true,		-- used by editor
--["DispatchTable"]		= true,		-- used by editor
["fTableDupNoUser"]		= true,
["fWorld2Local"]		= true,
["fLocal2World"]		= true,
["ObjectExport"]		= true,		-- exports an individual object to a file
["thisGID"]				= true,
["thisSceneName"]		= true,
["thisHostName"]		= true,
["thisObjectURL"]		= true,
["SendQueue"]			= true,
["Packet"]				= true,
["Send"]				= true,
["HTTPGet"]				= true,
["HTTPPost"]			= true,
["HTTData"]				= true,
["fPackedArray_Create"]	= true,
["fPackedArray_Destroy"]= true,
["fPackedArray_Set"]	= true,
["fPackedArray_Get"]	= true,
["fPackedArray_Length"]	= true,
["NodeL2W"]				= true,
["HostFrameNo"]			= true,

-- vars 
["fBase"]				= true,
["fGlobal"]				= true,
["fObject"]				= true,
["fGlobal_Get"]			= true,
["RealizeFlush"]		= true,		-- realizer signal
["__reserved"]			= true,		-- this list 
}

--------------------------------------------------------------------------------------------------------------
function string:split( inSplitPattern, outResults )
	if not outResults then
		outResults = { }
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( self, theStart ) )
	return outResults
end
--------------------------------------------------------------------------------------------------------------
function sel(cond, a, b)
	if (cond == true) then return a else return b end
end

-----------------------------------------------------------------------------------------------------------
function npairs(t)
	if (t == nil) then
		return function(state, v) end, nil, nil 
	else
		return next,t,nil 
	end
end

-------------------------------------------------------------------------------------------------------------
-- setup/process parameters
function Setup(buf)

	-- unpersist
	local arg = pluto.unpersist(unperms, buf).arg

	-- rservered values
	local __reserved = 
	{
	["DispatchTable"] = true
	}

	-- add everything to the global scope 

	for k,v in pairs(arg) do	

		-- might already exists?
		if (_G[k] != nil) then
		--ftrace("WARNING: setup overrwiting value ["..k.."]\n")
		end

		if (__reserved[k] == true) then continue end
		_G[k] = v	
	end

	-- merge dispatch table

	for D,Fn in npairs(arg.DispatchTable) do

		if (DispatchTable[D] != nil) then continue end
		ftrace("adding disatpch ["..D.."]\n")
		DispatchTable[D] = Fn 
	end

	-- top level vars (do this last so it will override anything in arg[]

	ObjectName = assert(arg.Name, "object setup has no name!")
	ObjectHost = assert(arg.Host, "object setup has no host!")
	ObjectPath = assert(arg.Path, "object setup has no path!")

	-- flag for update

	Dirty = true
end

-------------------------------------------------------------------------------------------------------------
-- dispatch & routing 
DispatchTable = {} 
function DispatchAdd(cmd, fn)
	DispatchTable[cmd] = fn
end

function DispatchPacket(cmd, serial)

	local Fn = DispatchTable[cmd]
	if (Fn == nil) then
		ftrace("WARNING: no dispatch for ["..cmd.."]\n")
		return
	end

	-- deserialize and call

	local pkt = pluto.unpersist(unperms, serial).packet
	Fn(pkt)
end

-------------------------------------------------------------------------------------------------------------
-- update the current state
function Update()
	--dtrace("object update!\n")
	--toSource()
end

-------------------------------------------------------------------------------------------------------------
-- returns the source code for all public functions 
function getSource()

	local Source = "-------------------------------------------------------------------------------------------------------------------------- ["..os.date().."]\n"
	Source = Source.."-- Object ["..ObjectPath.."] Host["..ObjectHost.."] Name["..ObjectName.."]\n"
	for fnName,fn in pairs(_G) do
		if (type(fn) != "function") then continue end

		-- ignore reserved functions	
		if (__reserved[fnName] != nil) then continue end

		-- header
		Source = Source.."----------------------------------------------------------------------------------------------------------------------\ ["..os.date().."]\n"
		Source = Source.."-- function ["..fnName.."] begin ["..os.date().."] \n"
		Source = Source..getFunctionSource(fnName)
		Source = Source.."-- function ["..fnName.."] end ["..os.date().."]\n"
	end
	return Source 
end
-------------------------------------------------------------------------------------------------------------
-- sets the new source 
function setSource(Source)

	ftrace("object set new source code ["..Source.."]\n")
	local code,err = loadstring(Source)
	if (err != nil) then

		local ret = ""

		local errorline = tonumber(err:split(":")[2])
		local errormsg = err:split(":")[3]
		ftrace("compile fail: line:"..errorline.." ["..errormsg.."]\n")

		local sourceLines = source:split("\n")
		local lineno = 1
		for k1,s in ipairs(sourceLines) do
			local hit = sel(lineno == errorline, "X", " ")
			ftrace("	[%10s] %04i %s"..s.."\n", k, lineno, hit)
			lineno = lineno + 1
		end

		return err
	else

		-- replace function
		-- NOTE: not all that happy here as it means functions MUST
		-- be in the global namespace. e.g. running code() will update the _G[funcname]
		-- variable instead of returning a function. The down side is, if you
		-- modify the loadstring() source to just return function()...end
		-- then the the bytecode.source looses the function name. its a bit
		-- woobly so.. still thinking about alternate solutions 
		
		-- ass.. for now theres no checking of overwriting variables which matter!	
		code()

		for fnName,fn in pairs(_G) do
			if (type(fn) != "function") then continue end

			-- ignore reserved functions	
			if (__reserved[fnName] != nil) then continue end

			ftrace("function source begin ["..fnName.."]\n")	
			ftrace(getFunctionSource(fnName).."\n")
			ftrace("function source end   ["..fnName.."]\n")	
		end

	end
	return "Success"
end
-------------------------------------------------------------------------------------------------------------
-- return sourcv for the specified function name
--function getFunctionSource(fnName, serial)
--
--	local fn = _G[fnName]
--	if (fn == nil) then
--		dtrace("getFunctionSource: fn["..fnName.."] does not exist\n");
--		return ""
--	end
--
--	if (type(fn) != "function") then
--		dtrace("getFunctionSource: fn["..fnName.."] is not a function\n");
--		return ""
--	end
--
--	local F = inspector.getheader(fn)
--	return F.source
--end
-------------------------------------------------------------------------------------------------------------
-- update function code 
function setFunction(fnName, serial)

	ftrace("set the function ["..fnName.."]\n")

	local fn = _G[fnName]
	if (fn != nil) then
		ftrace("WARNING: setFunctionSource: fn["..fnName.."] about to be replaced\n");
	end
	ftrace("len ["..(#serial).."]\n")

	local Info = pluto.unpersist(unperms, serial)
	if (type(Info.fn) != "function") then
		ftrace("setFunctionSource: fn["..fnName.."] value is not a function!\n");
		return ""
	end

	-- set it

	_G[fnName] = Info.fn
end

-------------------------------------------------------------------------------------------------------------
-- convert object to source 
function toSource()

	dtrace("function list\n");
	for k,v in pairs(_G) do
		if (type(v) == "function") and (__reserved[k] == nil) then

			local F = inspector.getheader(v)
			dtrace("	[%10s] functions: "..F.functions.."\n", k)
			dtrace("	[%10s] constants: "..F.constants.."\n", k)
			dtrace("	[%10s] locals   : "..F.locals.."\n", k)

			-- recompile and replace

			--local newCode = "Update = functioln(t) ftrace(\"new update function\\n\") toSource() end"
			--local source = newCode
			local source = F.source 

			--local code,err = loadstring(F.source)
			local code,err = loadstring(source)
			if (err != nil) then

				local errorline = tonumber(err:split(":")[2])
				local errormsg = err:split(":")[3]
				dtrace("compile fail: line:"..errorline.." ["..errormsg.."]\n")

				local sourceLines = source:split("\n")
				local lineno = 1
				for k1,s in ipairs(sourceLines) do
					local hit = sel(lineno == errorline, "X", " ")
					dtrace("	[%10s] %04i %s"..s.."\n", k, lineno, hit)
					lineno = lineno + 1
				end
			else
				-- replace function
				-- NOTE: not all that happy here as it means functions MUST
				-- be in the global namespace. e.g. running code() will update the _G[funcname]
				-- variable instead of returning a function. The down side is, if you
				-- modify the loadstring() source to just return function()...end
				-- then the the bytecode.source looses the function name. its a bit
				-- woobly so.. still thinking about alternate solutions 
				code()
			end
		end
	end
end
-------------------------------------------------------------------------------------------------------------
function Serialize()

	ftrace("serialize object ["..Name.."]\n");
	local global = {}
	for k,v in pairs(_G) do
		if (__reserved[k] == nil) then
			ftrace("%-20s type["..type(v).."]\n", k)
			--pluto.persist(perms, v )
			global[k] = v
		end
	end

	local serial = pluto.persist(perms, global )
	ftrace("serial len "..(#serial).."\n")

	return serial
end
--------------------------------------------------------------------------------------------------------------
-- duplicate a table without user data
function fTableDupNoUser(key, t, level)

	if (level == nil) then level = 0 end
	--dtrace("dup no user ["..level.."]\n")

	if (__reserved[key] != nil) then return "reserved" end

	local n = {}
	for k,v in pairs(t) do

		--print("table dup ["..k.."]\n")

		if ((type(v) != "user") and (type(v) != "function") and (type(v) != "table")) then
			n[k] = v
		elseif (type(v) == "table") then
			n[k] = fTableDupNoUser(k, v, level + 1) 
		else
			n[k] = type(v) 
		end
	end
	return n 
end
-------------------------------------------------------------------------------------------------------------
-- object info
function ObjectInfo()

	local fnList	= {}
	local varList	= {}
	for k,v in pairs(_G) do

		if (__reserved[k] == true) then continue end

		if (type(v) == "function") then 

			--dtrace("func ["..k.."] "..type(k).."\n")
			fnList[k] = "function"

		elseif (type(v) == "table") then 
			varList[k] = fTableDupNoUser(k, _G[k])
		else
			--dtrace("info ["..k.."] "..type(_G[k]).."\n")
			varList[k] = _G[k]
		end
	end

	return
	{
	fnList		= fnList,
	varList		= varList,
	}
end

--------------------------------------------------------------------------------------------------------------
function Packet(dest, src, cmd, arg) 

	local pkt = {}
	pkt.header = 
	{
	dest	= dest,
	src	= src,
	cmd	= cmd,
	}
	pkt.arg = arg

	return pkt
end
--------------------------------------------------------------------------------------------------------------
-- send somthing out into the big bad world
function Send(pkt)

	local serial = pluto.persist(perms, pkt )

	SendQueue(pkt.header.dest, pkt.header.cmd, serial)
end

return nil
