-------------------------------------------------------------------------------------------------------------
--
-- fmad llc 2008 
--
-- lua world server 
--
-------------------------------------------------------------------------------------------------------------

return
{
-- dynamic libs
library = 
{
}
,
main = function()
return
{
--##########################################################################################################
-- setup/interface functions
-----------------------------------------------------------------------------------------------------------
-- do module setup
Setup = function(self, arg, inc)

	-- dispatch commands

	self.Dispatch.Add(self.Dispatch, "Ping",			self.Packet_ping, self,				"ping me")
	self.Dispatch.Add(self.Dispatch, "SceneAdd",			self.Packet_SceneAdd, self,			"creates a new scene")

	self.Dispatch.Add(self.Dispatch, "HostAdd",			self.Packet_HostAdd, self,			"send packet to scene object")
	self.Dispatch.Add(self.Dispatch, "HostDel",			self.Packet_HostDel, self,			"send packet to scene object")
	self.Dispatch.Add(self.Dispatch, "HostSerialize",		self.Packet_HostSerialize, self,		"send packet to scene object")
	self.Dispatch.Add(self.Dispatch, "HostDeserialize",		self.Packet_HostDeserialize, self,		"send packet to scene object")
	self.Dispatch.Add(self.Dispatch, "HostURL",			self.Packet_HostURL, self,			"returns the host name of a url")
	self.Dispatch.Add(self.Dispatch, "HostInfo",			self.Packet_HostInfo, self,			"returns the host name of a url")
	self.Dispatch.Add(self.Dispatch, "HostList",			self.Packet_HostList, self,			"returns the host name of a url")
	self.Dispatch.Add(self.Dispatch, "HostLibrary",			self.Packet_HostLibrary, self,			"returns the host name of a url")

	self.Dispatch.Add(self.Dispatch, "SceneObjectPacket",		self.Packet_SceneObjectPacket, self,		"send packet to scene object")
	self.Dispatch.Add(self.Dispatch, "SceneObjectQuery",		self.Packet_SceneObjectQuery, self,		"requests query operation on a scene")
	self.Dispatch.Add(self.Dispatch, "SceneObjectVariableSet",	self.Packet_SceneObjectVariableSet, self,	"requests set a variable in a scene object")
	self.Dispatch.Add(self.Dispatch, "SceneObjectVariableDelete",	self.Packet_SceneObjectVariableDelete, self,	"requests delete a variable in a scene object")
	self.Dispatch.Add(self.Dispatch, "SceneObjectVariableCreate",	self.Packet_SceneObjectVariableCreate, self,	"requests create a variable in a scene object")
	self.Dispatch.Add(self.Dispatch, "SceneObjectFunctionSet",	self.Packet_SceneObjectFunctionSet, self,	"sets the functions code")
	self.Dispatch.Add(self.Dispatch, "SceneObjectSourceGet",	self.Packet_SceneObjectSourceGet, self,		"requests gets source code")
	self.Dispatch.Add(self.Dispatch, "SceneObjectSourceSet",	self.Packet_SceneObjectSourceSet, self,		"requests sets source code") 
	self.Dispatch.Add(self.Dispatch, "SceneList",			self.Packet_SceneList, self,			"requests full scene object list")

	self.Dispatch.Add(self.Dispatch, "SceneObjectDynamicInfo",	self.Packet_SceneObjectDynamicInfo, self,	"requests dynamics info on an object")

	self.Dispatch.Add(self.Dispatch, "SceneSerialize",		self.Packet_SceneSerialize, self,		"saves the scene somewhere")
	self.Dispatch.Add(self.Dispatch, "SceneDeserialize",		self.Packet_SceneDeserialize, self,		"saves the scene somewhere")

	self.Dispatch.Add(self.Dispatch, "NodeAdd",			self.Packet_NodeAdd, self,			"adds a new node object") 
	self.Dispatch.Add(self.Dispatch, "NodeDel",			self.Packet_NodeDel, self,			"deletes a node from the hierarchy")
	self.Dispatch.Add(self.Dispatch, "NodeObjectAdd",		self.Packet_NodeObjectAdd, self,		"adds a new object to an existing node")
	self.Dispatch.Add(self.Dispatch, "NodeCollisionGen",		self.Packet_NodeCollisionGen, self,		"adds a new object to an existing node")
	self.Dispatch.Add(self.Dispatch, "NodeControllerSet",		self.Packet_NodeControllerSet, self,		"adds a new object to an existing node")
	self.Dispatch.Add(self.Dispatch, "NodeDynamicInfo",		self.Packet_NodeDynamicInfo, self,		"adds a new object to an existing node")
	self.Dispatch.Add(self.Dispatch, "NodeInfo",			self.Packet_NodeInfo, self,			"adds a new object to an existing node")
	self.Dispatch.Add(self.Dispatch, "NodeLock",			self.Packet_NodeLock, self,			"adds a new object to an existing node")

	self.Dispatch.Add(self.Dispatch, "ObjectAdd",			self.Packet_ObjectAdd, self,			"adds a new object to a scene")
	self.Dispatch.Add(self.Dispatch, "ObjectDel",			self.Packet_ObjectDel, self,			"adds a new object to a scene")
	self.Dispatch.Add(self.Dispatch, "ObjectInfo",			self.Packet_ObjectInfo, self,			"adds a new object to a scene")
	self.Dispatch.Add(self.Dispatch, "ViewAdd",			self.Packet_ViewAdd, self,			"adds a new renderable view")
	self.Dispatch.Add(self.Dispatch, "ViewInfo",			self.Packet_ViewInfo, self,			"adds a new renderable view")
	self.Dispatch.Add(self.Dispatch, "ViewAdd_RenderNode",		self.Packet_ViewAdd_RenderNode, self,		"reply for render node alloc")
	self.Dispatch.Add(self.Dispatch, "GlobalVar",			self.Packet_GlobalVar, self,			"updates a global variable")
	self.Dispatch.Add(self.Dispatch, "RenderTile",			self.Packet_RenderTile, self,			"requests to render a map/tile")

	self.Dispatch.Add(self.Dispatch, "ScenePing",			self.Packet_ScenePing, self,			"requests to render a map/tile")

	self.Dispatch.Add(self.Dispatch, "StreamPingAck",		self.Packet_StreamPingAck, self,			"requests to render a map/tile")
	self.Dispatch.Add(self.Dispatch, "StreamCreateAck",		self.Packet_StreamCreateAck, self,	"render node returns rnet id")

	self.FrameCount 	= 0
	self.PushFetchDt	= 0

	-- stats

	self.LastStat 		= time_sec();
	self.SceneTime		= 0
	self.SceneTimeUpdate	= 0
	self.SceneTimeRender	= 0
	self.NetTime		= 0
	self.RequestKick	= 120 

	-- render node heartbeat  and discconnect timeouts

	self.RenderNodeHeartConnect	= 1.0	-- 1sec attempt to connect to render node 
	self.RenderNodeHeartBeat	= 3.0	-- 3sec heart beat to render node 
	self.RenderNodeHeartDisconnect	= 30.0	-- 10sec disconnect if heartbeat fails

	-- render node interface

	self.RenderNetGroup	= arg.RenderNet.Group 
	self.RenderNetPort	= arg.RenderNet.Port 
	self.RenderNetLoop	= arg.RenderNet.Loop 
	self.RenderNet		= fMultiCast_Create(
	{
		McGroup		= self.RenderNetGroup, 
		Port		= self.RenderNetPort, 
		Loop		= self.RenderNetLoop, 
	})
	self.RenderNetMcID	= self.SceneCache_MultiCastID()
	self.SceneCache		= self.SceneCache_Create(self.RenderNet)

	self.ExternNet		= fUniCast_Create( { Port=4444 } )
	--self.SceneExternal	= self.SceneExternal_Create(self.ExternNet)

	-- render node list

	self.RenderNode		= {}

	-- map render server

	self.RenderMapGID	= arg.RenderMapGID 	

	-- default storage location

	self.SceneStoreRoot	= arg.SceneStoreRoot

	-- Cosmos server

	self.CosmosGID		= arg.CosmosGID

	-- http fetch server
	
	self.HTTPFetchGID	= arg.HTTPFetchGID

	-- default null scene

	self.SceneInc		= 1		-- unique id for every new scene
	self.Scene		= {}
	self.ScenePing		= time_sec()	-- last ping time
	self.UpdateTime		= 0 		-- amount of time spent in update e.g load
	self.UpdateCount	= 0 		-- number of update cycles 
	self.DumpTS		= time_sec()

	-- load in scene objects

	for k,v in pairs(arg.SceneObject) do

		local bPath = fBase.."/"..v
		msg("SceneObject  ["..k.."] : "..bPath.."\n")

		local f = io.open(bPath)
		if (f == nil) then msg("Scene Object ["..k.."] could not be found\n") continue end

		-- load the binary

		local bin = f:read("*all")
		f:close()

		-- jit it
		self.SceneObject_Define(k, bin)
	end

	-- load in image formats

	for k,v in pairs(arg.SceneImage) do

		local bPath = fBase.."/"..v
		msg("SceneImage  ["..k.."] : "..bPath.."\n")

		local f = io.open(bPath)
		if (f == nil) then msg("Scene Object ["..k.."] could not be found\n") continue end

		-- load the binary

		local bin = f:read("*all")
		f:close()

		-- jit it
		self.Image_Define(k, bin)
	end
	self.Image_Dump()
end
,
-----------------------------------------------------------------------------------------------------------
-- update cycle 
Update = function(self)

	local sUpdate = time_sec()

	-- network

	self.Update_Network(self)

	-- scene 

	for SceneName,Scene in pairs(self.Scene) do

		-- update the actual scene
	
		self.Update_Scene(self, SceneName, Scene)
	end

	-- update streams which are registered on this world node 

	self.Update_Stream(self)

	-- profile

	local eUpdate = time_sec()
	self.UpdateTime		= self.UpdateTime + (eUpdate - sUpdate)
	self.UpdateCount	= self.UpdateCount + 1

	usleep(1000)
	collect()

	--RandomHang(self)
end
,
-----------------------------------------------------------------------------------------------------------
-- updates the network
Update_Network = function(self)

	local sNet = time_sec();

	-- update render network

	fUniCast_Update(self.ExternNet)
	fMultiCast_Update(self.RenderNet)

	self.SceneCache_Update(self.SceneCache)

	local eNet = time_sec();

	-- while theres external msgs

	self.NetTime = self.NetTime + (eNet - sNet)
end
,
-----------------------------------------------------------------------------------------------------------
-- update render nodes with scene objects 
Update_Realize = function(self, SceneName, Scene)
	local sSceneRender = time_sec()

	-- send out object list & xforms
	-- xforms have priority over everything else

	self.SceneObject_Realize(Scene.Obj, Scene.ID, self.SceneCache, Scene.Obj, "NETWORK")

	-- next priority is the view nodes
	-- render all views

	for ViewName, View in pairs(Scene.ViewList) do
	
		-- make sure its online

		if (View.Online == false) then continue end

		-- fetch the camera

		local Camera = self.Scene_ObjectFind(Scene.Obj, View.Camera)
		if (Camera == nil) then
			msg("WARNING: ViewAdd unable to find camera["..View.Camera.."]\n")
			continue
		end

		-- send camera info

		self.SceneObject_Realize(Scene.Obj, Scene.ID, self.SceneCache, Camera, "NETWORK")

		-- send individual objects

		self.FrameCount = self.FrameCount + 1; 
	end

	-- last priority is streaming data, geometry/textures

	self.Scene_Realize(Scene.Obj, Scene.ID, self.SceneCache,
		{
		["TriMesh"]		= true, 
		["Skin"]		= true, 
		["Icon"]		= true, 
		["HeightMap"]		= true, 
		["LightDir"]		= true, 
		["Material"]		= true, 
		["Texture"]		= true, 
		["SplineCatmull"]	= true, 
		}
	)

	local eSceneRender = time_sec()
	self.SceneTimeRender	= self.SceneTimeRender + (eSceneRender - sSceneRender)
end
,
-----------------------------------------------------------------------------------------------------------
-- process packets originating from scene objects
Scene_MessageProcess = function(self, Scene)

	while (true) do

		-- fetch a msg

		local m = self.Scene_MessagePop(Scene.Obj)
		if (m == nil) then break end

		--ftrace("message ["..m.Cmd.."]\n");

		-- deocde raw lua source into a table 
		local LuaString = function()

			local code,err = loadstring(m.Data)
			if (err != nil) then
				msg("world external update code invalid ["..err.."]\n")
				return nil;
			end
			return code
		end

		-- decode serialized ata into a table 
		local LuaDeserialize = function()
			return pluto.unpersist(unperms, m.Data)
		end

		-- execute command 

		local cmd =
		{
		["SendPacket"]	= function()
			local pkt = LuaDeserialize()
			--ftrace("send packet ["..pkt.header.dest..":"..pkt.header.cmd.."]\n")
			Send(pkt)
		end
		,
		["HTTPGet"]	= function()

			local info = LuaDeserialize()
			ftrace("HTTPGet URL["..info.HttpURL.."] return obj  ["..info.ObjectURL.."] local["..info.LocalPath.."]\n")
			ftrace("["..self.HTTPFetchGID.."]\n")

			Send(Packet(self.HTTPFetchGID, self.gid, "HTTPGet",
			{
				URL	= info.HttpURL,
				Mode	= info.Mode,
				Reply	=
				{
					gid		= self.gid,
					path		= "SceneObjectPacket",
					SceneName	= info.SceneName,
					URL		= info.ObjectURL,
					Cmd		= info.Cmd,
					Data		=
					{
						LocalPath	= info.LocalPath,
						Image		= nil,
					}
				}
			}))
		end
		,
		["default"]	= function()
			ftrace("Scene_MessageProcess: unknown command ["..m.Cmd.."]\n")
		end
		}
		setmetatable(cmd, { __index = function(t, k) return t["default"] end } )
		cmd[m.Cmd]()
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- helper returns the scene & object specified by a path paket
PacketScene = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],				"invalid scene ["..pkt.arg.SceneName.."]")

	return Scene
end
,
-----------------------------------------------------------------------------------------------------------
-- helper returns the scene & object specified by a path paket
PacketSceneObjectPath = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Obj	= assert(self.Scene_ObjectFind(Scene.Obj, pkt.arg.URL),	"unable to find object ["..pkt.arg.URL.."]")
	return Obj, Scene
end
,
--##########################################################################################################
-- module commands
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
Packet_ping = function(self, pkt)

	-- total elapsed time 

	local t = time_sec()
	local Elapsed = t - self.ScenePing
	self.ScenePing = t

	local UpdateCount = sel(self.UpdateCount == 0, 1, self.UpdateCount)

	-- update stats

	pkt.arg.Stats = 
	{
	Total		= self.UpdateTime / UpdateCount,
	Load		= self.UpdateTime / Elapsed, 
	Scene	= {},
	}

	for Name,Scene in pairs(self.Scene) do 

		local Total	=  Scene.Stats.TimeTotal

		pkt.arg.Stats.Scene[Name]	=
		{
		State		= Scene.State,
		Total		= Total,
		Load		= Total / Elapsed,
		Message		= Scene.Stats.TimeMessage,
		Scene		= Scene.Stats.TimeScene,
		Realize		= Scene.Stats.TimeRealize,
		Request		= t - Scene.RequestTS, 
		}

		-- reset
		
		Scene.Stats.TimeTotal		= 0
		Scene.Stats.TimeMessage		= 0
		Scene.Stats.TimeScene		= 0
		Scene.Stats.TimeRealize		= 0
	end
	Send(Packet(pkt.arg.gid, self.gid, pkt.arg.path, pkt.arg))

	-- reset

	self.NetTime		= 0
	self.UpdateTime		= 0
	self.UpdateCount	= 0
end
,
--##########################################################################################################
-- Scene objects 
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
-- creates a new scene
Packet_SceneAdd = function(self, pkt)

	msg("create new scene ["..pkt.arg.SceneName.."]\n");

	-- create internal object

	local Obj = self.Scene_Create(
	{
		Name		= pkt.arg.SceneName, 
		Cache		= self.SceneCache,
		Extern		= self.SceneExternal,
		ExternNet	= self.ExternNet,
		RenderNet	= self.RenderNet,
	})

	-- scene structure

	self.Scene[pkt.arg.SceneName]					= 
	{
		State				= "CREATE",
		SceneName			= pkt.arg.SceneName,
		ID				= self.SceneInc ,
		Obj				= Obj, 
		ViewList			= {}, -- list of all views in this scene
		RenderList			= {}, -- list of all render nodes for this scene 
		UpdateTime			= time_sec(),
		UpdateRate			= 1/30, 
		Cookie				= GenerateCookie(128),
		DumpTS				= time_sec(),
		RequestTS			= time_sec(),
		Stats				=
		{
			TimeTotal						= 0,
			TimeMessage						= 0,
			TimeScene						= 0,
			TimeRealize						= 0,
		},
	}

	self.SceneInc = self.SceneInc + 1 

	-- send back ack
	if (pkt.arg.Ack == nil) then return end

	pkt.arg.Ack.WorldGID = self.gid
	Send(Packet(pkt.arg.Ack.GID, self.gid, pkt.arg.Ack.Path, pkt.arg.Ack))
end
,
-----------------------------------------------------------------------------------------------------------
-- retreive scene list
Packet_SceneList = function(self, pkt)

	ftrace("fetch scene list ["..pkt.arg.SceneName.."]\n")

	local Scene = assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]\n")
	local list = self.Scene_List(Scene.Obj) 

if false then
	function Dump(list)

		-- print objects
		for k,v in pairs(list.Object) do
			ftrace("    ["..k.."] type:"..v.Type.." name["..v.Name.."] path["..v.Path.."]\n")
		end

		-- recurse
		for k,v in pairs(list.Child) do
			print(k)
			Dump(v)
		end
	end
	for k,v in pairs(list) do
		print(k)
		Dump(v)
	end
end
	-- pack WWW reply 
	if (pkt.arg.WWWReply != nil) then 

		local WWW = pkt.arg.WWWReply
		Send(Packet(WWW.GID, self.gid, WWW.Path, 
		{
			id	= WWW.ID,	
			data	= LuaToJs(list),
		}))
	end
end
,

-----------------------------------------------------------------------------------------------------------
-- checks the specified scene exists and is active, and ping back
Packet_ScenePing = function(self, pkt)

	local Scene = assert(self.Scene[pkt.arg.SceneName], "ScenePing ["..pkt.arg.SceneName.."] does not exists\n")

	-- set last update time

	Scene.RequestTS		= time_sec()
	Scene.State		= "ONLINE"

	pkt.arg.Cookie		= Scene.Cookie

	-- ping back

	Send(Packet(pkt.arg.Ack.GID, self.gid, pkt.arg.Ack.Path, pkt.arg))
end
,
-------------------------------------------------------------------------------------------------------------
-- updates a single scene list
Update_Scene = function(self, SceneName, Scene)

	local t = time_sec()

-- debug
--if ( (t - Scene.DumpTS) > 1) then
--	Scene.DumpTS = t
--	ftrace("[%-40s] [%-10s] %f\n", SceneName, Scene.State, (t-Scene.RequestTS))
--end

	local Fn = 
	{
	["CREATE"] = function()
	end
	,
	-- world is online so update everyhing per normal 
	["ONLINE"] = function()

		-- process messages

		local sMsg = time_sec();

			self.Scene_MessageProcess(self, Scene)

		Scene.Stats.TimeMessage = Scene.Stats.TimeMessage + (time_sec() - sMsg)

		-- limit update rate

		local t = time_sec()
		if ((t-Scene.UpdateTime) < Scene.UpdateRate) then return end
		Scene.UpdateTime = t;

		local sScene = time_sec()

		-- update state/everything 

		local sSceneUpdate = time_sec()

			self.Scene_Update(self.Device, Scene.Obj)

		Scene.Stats.TimeScene = Scene.Stats.TimeScene + time_sec() - sSceneUpdate 

		-- is there atleast 1 valid view/render node ?
		local sRealize = time_sec()	

		local ValidView = false
		for k,View in pairs(Scene.ViewList) do
			if (View.State == "ONLINE") then ValidView = true end
		end

		-- if there is atleast 1 valid view then update the render nodes

		if (ValidView == true) then 
			self.Update_Realize(self, SceneName, Scene)
		end

		local eScene = time_sec()
		Scene.Stats.TimeRealize = Scene.Stats.TimeRealize + eScene - sRealize
		Scene.Stats.TimeTotal = Scene.Stats.TimeTotal + eScene - sMsg 
	end
	,
	-- remove the scene
	["COLLECT"] = function()
		self.Scene[Scene.SceneName] = nil
	end
	,
	}
	Fn[Scene.State]()

	-- check for collection

	if ( (t - Scene.RequestTS) > self.RequestKick) then
		ftrace("Scene ["..Scene.SceneName.."] COLLECT (not requestor)\n")
		Scene.State = "COLLECT"
	end
end
,
--##########################################################################################################
-- host 
--##########################################################################################################
Packet_HostAdd = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")
	local HostName	= pkt.arg.HostName

	ftrace("[%-30s] host add ["..HostName.."]\n", Scene.SceneName) 
	if (self.Scene_HostFind(Scene.Obj, HostName) != nil) then
		ftrace("[%-30s] host ["..HostName.."] already exists. deleting\n", Scene.SceneName);
		self.Scene_HostDel(Scene.Obj, HostName)
	end
	self.Scene_HostAdd(Scene.Obj, HostName)
end
,
-----------------------------------------------------------------------------------------------------------
-- delete an entire host
Packet_HostDel = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")
	local HostName	= pkt.arg.HostName

	ftrace("[%-30s] host del ["..HostName.."]\n", Scene.SceneName) 

	self.Scene_HostDel(Scene.Obj, HostName)
end
,
-----------------------------------------------------------------------------------------------------------
-- serialize a host object 
Packet_HostSerialize = function(self, pkt)

	local HostName	= pkt.arg.HostName

	ftrace("[%-30s] serialize host ["..HostName.."]\n");

	local Scene 	= self.PacketScene(self, pkt) 
	local Host	= assert(self.Scene_HostFind(Scene.Obj, HostName), "invalid host name ["..HostName.."]")

	local NodeTop	= self.Scene_HostRoot(Host); 
	local TopPath	= pkt.arg.NodePath

	-- where to store it
	local StorePath = sel(pkt.arg.StorePath == nil, self.SceneStoreRoot, pkt.arg.StorePath)
	local StoreFile = StorePath.."/"..pkt.arg.StoreName..".lib"

	ftrace("-------------serialize host hierarchy -> ["..StoreFile.."]-------------\n");
	local SceneSerial = 
	{
	Name		= pkt.arg.SceneName,
	NodeList	= {},
	ObjectList	= {},
	}

	-- node hierarchy

	ftrace("Node\n")
	local NodeList = self.Scene_NodeTrace(NodeTop);
	for k,v in ipairs(NodeList) do

		-- ignore top level node
		--if (v == NodeTop) then continue end

		local node		= self.Scene_NodeSerialize(TopPath, v)
		local serial		= pluto.persist(perms, node)
		local compress		= fCompress(serial)
		SceneSerial.NodeList[k] = compress

		ftrace("   serialize node [%-30s:%-20s] ratio %f %i lock:["..node.Locked.."]\n", node.Path, node.Parent, #compress / #serial, #serial)

		--ftrace("node ["..node.Controller.."]\n")
		--for k,v in pairs(node.Child) do
		--	ftrace("node ["..node.Name.."] child ["..k.."]\n")
		--end
	end

	-- object list

	ftrace("Object\n")
	local ObjectList = self.Scene_NodeTraceObject(NodeTop)
	for k,v in ipairs(ObjectList) do

		local obj	= self.SceneObject_Serialize(v)
		local serial	= pluto.persist(perms, obj)
		local compress	= fCompress(serial)
		SceneSerial.ObjectList[k] = compress

		ftrace("  serialize obj   [%-30s:%-20s] object %f %iKB\n", obj.Path, obj.Name, #compress/#serial, #compress/1024)
	end

	-- serialize the whole lot

	local serial = pluto.persist(perms, SceneSerial)

	-- store to disk somewhere

	local f = io.open(StoreFile, "wb")
	if (f == nil) then
		ftrace("unable to open file ["..StoreFile.."]\n")
		return
	end
	f:write(serial)
	f:close();
end
,
-----------------------------------------------------------------------------------------------------------
-- deserialize a node hierarchy  into a host
Packet_HostDeserialize = function(self, pkt)

	local TimeStart = time_sec()

	local HostName	= pkt.arg.HostName
	local Scene 	= self.PacketScene(self, pkt) 

	-- if host exists then delete it

	if (self.Scene_HostFind(Scene.Obj, HostName) != nil) then
		--ftrace("[%-30s] deleting host ["..HostName.."]\n", pkt.arg.SceneName)
		self.Scene_HostDel(Scene.Obj, HostName)
		--ftrace("[%-30s] deleting host done ["..HostName.."]\n", pkt.arg.SceneName)
	end

	-- create host first

	local Host	= assert(self.Scene_HostAdd(Scene.Obj, HostName), "failed to create host ["..HostName.."]")

	-- host root node

	local Node	= self.Scene_HostRoot(Host) 

	local StorePath = sel(pkt.arg.StorePath == nil, self.SceneStoreRoot, pkt.arg.StorePath)
	local FileName	= StorePath.."/"..pkt.arg.StoreName..".lib"
	local SceneName	= Scene.SceneName
	local PathTop	= pkt.arg.NodePath

	--ftrace("deserialzing ["..SceneName.."] object ["..FileName.."]\n")

	-- load the file

	local f = io.open(FileName, "rb")
	if (f == nil) then
		if (pkt.arg.Reply != nil) then
			pkt.arg.Reply.Status		= "FAIL"
			pkt.arg.Reply.Info		= "No file named ["..FileName.."]\n"
			Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply)) 
		end
		ftrace("status ["..pkt.arg.StatusGID.."]\n")
		ftrace("Packet_NodeDeseiralize: failed to open file ["..FileName.."]\n");
		return
	end
	local serial = f:read("*all")
	if (#serial == 0) then
		if (pkt.arg.Reply != nil) then
			pkt.arg.Reply.Status 		= "FAIL"
			pkt.arg.Reply.Info		= "file read failed ["..FileName.."]\n"
			Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply)) 
		end
		ftrace("Packet_sceneDeseiralize: file ["..pkt.arg.SceneStore.."] is invalid\n");
		return
	end
	f:close();
	--ftrace("packed sized "..(#serial/1024).."KB \n")

	-- top level deserialize

	local Info = pluto.unpersist(unperms, serial)

	-- create the objects first

	local ObjectList = {}
	--ftrace("deserialize objects\n")
	for k,v in pairs(Info.ObjectList) do

		local decomp		= fDecompress(v)
		local obj		= pluto.unpersist(unperms, decomp)
		ObjectList[obj.ID]	= obj

		-- create the object

		local pkt 		= { arg = pluto.unpersist(unperms, obj.LVM) }
		pkt.arg.SceneName	= SceneName
		pkt.arg.Type 		= obj.Type
		pkt.arg.Name		= obj.Name
		pkt.arg.URL		= "object://"..HostName..":"..obj.Type.."/"..obj.Path
		self.Packet_ObjectAdd(self, pkt)
		--ftrace("    [%-20s] object %i %s [%s] done\n", obj.Name, obj.ID, obj.Type, pkt.arg.URL);
	end

	-- link in the hierarchy 

	--ftrace("deserialize Node\n");
	local NodeList = {}
	for k,v in pairs(Info.NodeList) do

		local decomp		= fDecompress(v)
		local node		= pluto.unpersist(unperms, decomp)

		NodeList[node.ID]	= node
		--ftrace("    [%-40s] parent ["..node.Parent.."] controller ["..node.Controller.."] locked ["..node.Locked.."]\n", node.Name)

		local pkt 		= { arg = {} }
		pkt.arg.SceneName	= SceneName
		pkt.arg.URL		= "node://"..HostName..node.Parent.."/"..node.Name
		pkt.arg.Object		= {}
		pkt.arg.Controller	= node.Controller
		pkt.arg.Locked		= node.Locked

		for k,v in pairs(node.Child) do
			local obj = ObjectList[v]
			if (obj == nil) then
				ftrace("unable to find object id["..v.."]\n");
				continue;
			end
			pkt.arg.Object[k] = "object://"..HostName.."/"..obj.Path
			--ftrace("        Object ["..k.."] ["..obj.Path.."]\n")
		end

		-- cant create a hosts root node, thus the test
		if (node.Name != "/") then	self.Packet_NodeAdd(self, pkt)
		else				self.Packet_NodeObjectAdd(self, pkt)
		end
	end
	--ftrace("deserialzing ["..pkt.arg.SceneName.."] done\n")

	-- tell whoever requested its all good

	if (pkt.arg.Reply != nil) then
		pkt.arg.Reply.Status		= "OK" 
		Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply)) 
	end
	local TimeEnd = time_sec()
	ftrace("deserialzing ["..pkt.arg.SceneName.."] done %0.4fms\n", (TimeEnd - TimeStart)*1e3)
end
,
-----------------------------------------------------------------------------------------------------------
-- returns the host name of a url 
Packet_HostURL = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")

	ftrace("[%-30s] find host ["..pkt.arg.NodeURL.."]\n", Scene.SceneName)
	local Node	= self.Scene_NodeFind(Scene.Obj, pkt.arg.NodeURL) 
	if (Node == nil) then
		ftrace("[%-30s] HostURl name unable to find node ["..pkt.arg.NodeURL.."]\n", Scene.SceneName) 
		return 
	end

	-- get host name

	local HostName = assert(self.Scene_NodeHostName(Node), "invald node")
	ftrace("[%-30s] host name url ["..pkt.arg.NodeURL.."] hostname ["..HostName.."]\n", Scene.SceneName) 

	-- send back

	pkt.arg.HostName = HostName
	Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg))
end
,
-----------------------------------------------------------------------------------------------------------
-- returns infoa bout a host 
Packet_HostInfo = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")

	ftrace("[%-30s] host info ["..pkt.arg.HostName.."]\n", Scene.SceneName)
	local Host	= self.Scene_HostFind(Scene.Obj, pkt.arg.HostName) 

	pkt.arg.Reply.Valid = sel(Host == nil, false, true) 

	Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply))
end
,
-----------------------------------------------------------------------------------------------------------
-- returns list of all hosts in the scene 
Packet_HostList = function(self, pkt)
	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")
	ftrace("[%-30s] host list\n", Scene.SceneName)

	pkt.arg.Reply.List	= self.Scene_HostList(Scene.Obj)
	Send(Packet(pkt.arg.Reply.GID, self.gid, pkt.arg.Reply.Path, pkt.arg.Reply))
end
,
-----------------------------------------------------------------------------------------------------------
-- returns list of library objects 
Packet_HostLibrary = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName], "invalid scene ["..pkt.arg.SceneName.."]")
	ftrace("[%-30s] host library\n", Scene.SceneName)

	local Dir	= dirlist(self.SceneStoreRoot)
	local L		= {}
	for i,j in pairs(Dir) do
		local p = j:split("%.")
		if (p[2] != "lib") then continue end

		--ftrace("["..p[1].."]\n")
		L[#L + 1] = p[1] 
	end
	pkt.arg.Reply.List = L 
	Send(Packet(pkt.arg.Reply.GID, self.gid, pkt.arg.Reply.Path, pkt.arg.Reply))
end
,
--##########################################################################################################
-- Node  
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
-- adds a new node
Packet_NodeAdd = function(self, pkt)

	local info = assert(self.Scene_ParseURL(pkt.arg.URL), "invalid node add url ["..pkt.arg.URL.."]\n")
	info.Scene	= pkt.arg.SceneName

	local Scene = assert(self.Scene[info.Scene],				"invalid scene ["..info.Scene.."]")
	--ftrace("[%-30s] node add ["..pkt.arg.URL.."] parent ["..info.Parent.."]\n", Scene.SceneName) 

	-- indicate activity
	Scene.RequestTS = time_sec()

	-- delete any previous node
	local NodePath	= info.Path 
	local Node	= self.Scene_NodeFind(Scene.Obj, info) 
	if (Node != nil) then
		--ftrace("node add, deleteing old node\n")
		self.Scene_NodeDestroy(Scene.Obj, Node)
		--ftrace("node add, deleteing old node done\n")
	end

	-- create the node

	local Node = self.Scene_NodeCreate(
	{
		Scene	= Scene.Obj,
		Name	= info.Name, 
		Host	= info.Host, 
		Locked	= pkt.arg.Locked,
	})

	-- attach node 
	local ParentURL = "node://"..info.Host..info.Parent
	local parent = assert(self.Scene_NodeFind(Scene.Obj, ParentURL), "NodeAdd failed to find parent ["..ParentURL.."]")
	self.Scene_NodeAttach(
	{
		Scene	= Scene.Obj,
		Parent	= parent,
		Child	= Node
	})

	-- what kind of object is this ? 
	for Name,ObjectURL in pairs(pkt.arg.Object) do

		--ftrace("[%-30s]    [%-30s] URL ["..ObjectURL.."]\n", info.Scene, Name)

		-- find the object 

		local Object	= assert(self.Scene_ObjectFind(Scene.Obj, ObjectURL), "invalid object ["..ObjectURL.."]")

		-- add it

		self.Scene_NodeObjectAdd(
		{
			Scene		= Scene.Obj, 
			Node		= Node, 
			Object		= Object, 
			Name		= Name, 
		})
	end

	-- if theres a host link ? 
	if (pkt.arg.HostLink != nil) then

		--ftrace("node host link ["..pkt.arg.HostLink.."]\n")

		self.Scene_NodeHostLink(
		{
			Scene 		= Scene.Obj, 
			Node 		= Node, 
			HostName	= pkt.arg.HostLink,
		})
	end
	--self.Scene_NodeDump(Scene.Obj, "node add ["..pkt.arg.NodeName.."]")
	
	-- controller set ? 
        --ftrace("controller ["..pkt.arg.Controller.."]\n")
	if (pkt.arg.Controller != nil) then
		self.Scene_NodeControllerSet(Node, pkt.arg.Controller)
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- deletes a node 
Packet_NodeDel = function(self, pkt)

	local info = assert(self.Scene_ParseURL(pkt.arg.URL), "invalid node add url ["..pkt.arg.URL.."]\n")
	info.Scene	= pkt.arg.SceneName

	local Scene = assert(self.Scene[info.Scene],				"invalid scene ["..info.Scene.."]")
	--ftrace("[%-30s] node del ["..pkt.arg.URL.."]\n", Scene.SceneName) 

	local Node	= self.Scene_NodeFind(Scene.Obj, info) 
	if (Node == nil) then
		ftrace("[%-30s] NodeDelnode does not exist ["..info.URL.."]\n")
		return
	end

	-- delete it

	self.Scene_NodeDestroy(Scene.Obj, Node)

	-- status update if asked 
	if (pkt.arg.WWW != nil) then 

		Send(Packet(pkt.arg.WWW.gid, self.gid, pkt.arg.WWW.path, 
		{
			id	= pkt.arg.WWW.id,
			data	= "OK", 
		}))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- adds an object to an existing node 
Packet_NodeObjectAdd = function(self, pkt)

	--ftrace("[%-30s] node object add Node["..pkt.arg.URL.."]\n", pkt.arg.SceneName)

	-- get the scene

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.URL),	"Node ["..pkt.arg.URL.."] does not exists")

	-- add objects in list 

	for Name,ObjectURL in pairs(pkt.arg.Object) do

		--ftrace("[%-30s]    [%-30s] URL ["..ObjectURL.."]\n", pkt.arg.SceneName, Name)

		-- find the object 

		local Object	= assert(self.Scene_ObjectFind(Scene.Obj, ObjectURL), "invalid object ["..ObjectURL.."]")

		-- add it

		self.Scene_NodeObjectAdd(
		{
			Scene		= Scene.Obj, 
			Node		= Node, 
			Object		= Object, 
			Name		= Name, 
		})
	end
	
	-- controller set ? 
        --ftrace("controller ["..pkt.arg.Controller.."]\n")
	if (pkt.arg.Controller != nil) then
		self.Scene_NodeControllerSet(Node, pkt.arg.Controller)
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- generate a sphere hierarchy for the specify node level
Packet_NodeCollisionGen = function(self, pkt)

	ftrace("[%-30s] generate node collision tree for ["..pkt.arg.URL.."]\n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.URL),	"Node ["..pkt.arg.URL.."] does not exists")

	-- extract raw trimesh data 

	-- extract tri soup 

	local TriSoup = self.Scene_NodeTriSoup(Scene.Obj, Node, {recurse=true} )
	ftrace("tri soup ["..#TriSoup.."] ["..type(TriSoup).."]\n")

	-- send to sphere tree gen process

	Send(Packet(self.CosmosGID, self.gid, "SphereTreeGen", 
	{
		URL		= pkt.arg.URL,	
		TriSoup 	= TriSoup,
		WWW		= pkt.arg.WWW,
	}))
end
,
-----------------------------------------------------------------------------------------------------------
-- fetch dynamics info for the node 
Packet_NodeDynamicInfo = function(self, pkt)

	ftrace("[%-30s] fetch dynamics info for ["..pkt.arg.NodeURL.."]\n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],				"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.NodeURL),	"Node ["..pkt.arg.NodeURL.."] does not exists")

	-- get dynmaics object

	local DynamicObject	= self.Scene_NodeDynamicGet(Node)

	local info = {Status = "no dynamics object"}
	if (DynamicObject != nil) then

		-- get collision info

		info = self.SceneObject_UserControl(pkt.arg.NodeURL, Node, DynamicObject, { collision = true })
		info.Status = "OK"
	end

	-- send to web 

	if (pkt.arg.WWW != nil) then

		pkt.arg.WWW.data = LuaToJs(info)
		Send(Packet(pkt.arg.WWW.gid, self.gid, pkt.arg.WWW.path, pkt.arg.WWW))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- set which node object is the controller for this node (e.g. if there are multiple) 
Packet_NodeControllerSet = function(self, pkt)

	ftrace("[%-30s] node set controller["..pkt.arg.URL.."] contoller ["..pkt.arg.Controller.."]\n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.URL),	"Node ["..pkt.arg.URL.."] does not exists")

	self.Scene_NodeControllerSet(Node, pkt.arg.Controller)
end
,
-----------------------------------------------------------------------------------------------------------
-- gets general information about the node 
Packet_NodeInfo = function(self, pkt)

	ftrace("[%-30s] node info ["..pkt.arg.URL.."] \n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= self.Scene_NodeFind(Scene.Obj, pkt.arg.URL)

	if (Node != nil) then
		pkt.arg.Reply.Info = self.Scene_NodeInfo(Node)
	end
	Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply))
end
,
-----------------------------------------------------------------------------------------------------------
-- sets a nodes lock state 
Packet_NodeLock = function(self, pkt)

	local Lock = sel(pkt.arg.Lock == "true", true, false) 

	ftrace("[%-30s] node lock ["..pkt.arg.URL.."] lock:"..Lock.."\n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Node	= assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.URL),	"unable to find node ["..pkt.arg.URL.."]")

	self.Scene_NodeLock(Node, Lock) 

	if (pkt.arg.WWW != nil) then 

		ftrace("www gid ["..pkt.arg.WWW.gid.."]\n")
		Send(Packet(pkt.arg.WWW.gid, self.gid, pkt.arg.WWW.path, 
		{
			id	= pkt.arg.WWW.id,
			data	= "OK", 
		}))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- creates a new object 
Packet_ObjectAdd = function(self, pkt)

	--ftrace("[%-30s] object create ["..pkt.arg.URL.."]\n", pkt.arg.SceneName)

	local info	= assert(self.Scene_ParseURL(pkt.arg.URL), "invalid object add url ["..pkt.arg.URL.."]\n")
	info.Scene	= pkt.arg.SceneName

	local Scene	= assert(self.Scene[info.Scene],		"invalid scene ["..info.Scene.."]")

	-- indicate activity
	Scene.RequestTS = time_sec()

	-- make sure it has a type
	assert(info.Type, "invald object type")
	assert(info.Type != "", "invald object type")

	-- object already defined ? 

	local Object	= self.Scene_ObjectFind(Scene.Obj, info)

	-- check if its already here

	if (Object != nil) then

		--ftrace("[%-30s] WARNING: ["..pkt.arg.URL.."] already exists. overwriting\n", pkt.arg.SceneName)

		-- free

		self.SceneObject_Destroy(info, self.Device, Scene.Obj, Object) 
	end

	-- create it natively

	pkt.arg.Host	= info.Host
	pkt.arg.Parent	= info.Parent
	pkt.arg.Path	= info.Path
	pkt.arg.Name	= info.Name

	self.SceneObject_Create(info, self.Device, Scene.Obj, pluto.persist(perms, {arg=pkt.arg}) )

	--ftrace("[%-30s] object create ["..pkt.arg.URL.."] done\n", pkt.arg.SceneName)
end
,
-----------------------------------------------------------------------------------------------------------
-- deletesa an object 
Packet_ObjectDel = function(self, pkt)

	--ftrace("[%-30s] object del ["..pkt.arg.URL.."]\n", pkt.arg.SceneName)

	local info = assert(self.Scene_ParseURL(pkt.arg.URL), "invalid object add url ["..pkt.arg.URL.."]\n")
	info.Scene	= pkt.arg.SceneName

	local Scene	= assert(self.Scene[info.Scene],		"invalid scene ["..info.Scene.."]")

	-- object already defined ? 

	local Object	= self.Scene_ObjectFind(Scene.Obj, info)
	if (Object == nil) then
		
		ftrace("[%-30s] ["..pkt.arg.URL.."] does not exist\n", pkt.arg.SceneName)
		return
	end

	-- delete it 

	self.SceneObject_Destroy(info, self.Device, Scene.Obj, Object) 
end
,
-----------------------------------------------------------------------------------------------------------
-- gets general information about an object 
Packet_ObjectInfo = function(self, pkt)

	ftrace("[%-30s] object info ["..pkt.arg.URL.."] \n", pkt.arg.SceneName)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],			"invalid scene ["..pkt.arg.SceneName.."]")
	local Object	= self.Scene_ObjectFind(Scene.Obj, pkt.arg.URL)

	if (Object != nil) then
		pkt.arg.Reply.Info	= self.SceneObject_Info(Object) 
	else
		ftrace("object does not exist!\n")
	end
	Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply))
end
,
--##########################################################################################################
-- Streams 
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
-- world -> cosmos (register the view) cosmos waits untill someone wants the stream before instancing a render node 
StreamCreate = function(self, View) 

	local Scene = assert(self.Scene[View.SceneName], "scene["..View.SceneName.."] does not exists")
	--ftrace("stream create ["..View.SceneName.."]\n")

	-- view already online & created

	if (View.State == "ONLINE") then return end
	-- set views RenderNet object ID 

	Send(Packet(self.CosmosGID, self.gid, "StreamCreate", 
	{
		ReplyGID	= self.gid,
		ReplyCmd	= "StreamCreateAck",

		Group		= self.RendernetGroup,
		Port		= self.RendernetPort,
		SceneName	= View.SceneName,
		ViewName	= View.ViewName,
		SceneID		= Scene.ID,

		StreamName	= View.StreamName,
		StreamWidth	= View.StreamWidth,
		StreamHeight	= View.StreamHeight,
		StreamFPS	= View.StreamFPS,
		StreamKbps	= View.StreamKbps,
		StreamAspect	= View.StreamAspect,
		
		ClearColor	= View.ClearColor,
		Cookie		= View.Cookie,
	}))

	View.State = "OFFLINE"
end
,
-----------------------------------------------------------------------------------------------------------
-- render node -> world (enable multicast ID)
Packet_StreamCreateAck = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],		"invalid scene name ["..pkt.arg.SceneName.."]")
	local View	= assert(Scene.ViewList[pkt.arg.ViewName],	"invalid view name ["..pkt.arg.ViewName.."]")

	ftrace("RenderNode: RenderNode["..pkt.arg.RenderNodeGID.."] ["..View.SceneName.."@"..View.StreamName.."] ONLINE\n");

	-- delete previous stream

	if (View.State != "OFFLINE") then 
		msg("reset render node stream\n");
		self.StreamDestroy(self, View) 
	end

	-- update ok

	View.State		= "ONLINE" 

	-- reset time stamps 

	View.CheckTS		= time_sec()			-- when to send stream hearbeats 
	View.PingTS		= time_sec()			-- case where 2nd time round it gets diconncetd, the PingTime will be(old time) so over and the collecter will kick it
	View.RequestTS		= time_sec()			-- last time someone requested this stream

	-- enable the multicast network id 

	View.RenderGID		= pkt.arg.RenderGID
	View.RenderNetID	= pkt.arg.RenderNetID

	-- enable a netid

	self.SceneCache_EnableID(self.SceneCache, View.RenderNetID)

	-- reset crcr for net id / scene id

	self.SceneCache_ResetSceneID(self.SceneCache, View.RenderNetID, pkt.arg.SceneID)

	ftrace("render net id ["..View.RenderNetID.."] SceneID["..pkt.arg.SceneID.."]\n")

end
,
-----------------------------------------------------------------------------------------------------------
-- render node update cycle. World.Collect(world -> render node -> world.PingAck) 
StreamPing = function(self, View) 

	if (View.State != "ONLINE") then return end

	local Scene = assert(self.Scene[View.SceneName], "scene["..View.SceneName.."] does not exists")

	-- set views RenderNet object ID 

	Send(Packet(self.CosmosGID, self.gid, "StreamPing", 
	{
		Ack =
		{
			GID	= self.gid,
			Path	= "StreamPingAck",
		}
		,
		SceneName	= View.SceneName,
		StreamName	= View.StreamName,
		ViewName	= View.ViewName,
		Cookie		= View.Cookie,
		World		= true,
	}))
end
,
-----------------------------------------------------------------------------------------------------------
-- World.StreamPing->cosmos->RN->World.StreamPingAck
Packet_StreamPingAck = function(self, pkt)

	local Scene	= assert(self.Scene[pkt.arg.SceneName],		"invalid scene name ["..pkt.arg.SceneName.."]")
	local View	= assert(Scene.ViewList[pkt.arg.ViewName],	"invalid view name ["..pkt.arg.ViewName.."]")

	if (View.State != "ONLINE") then return end
	View.PingTS	= time_sec()
end
,
-----------------------------------------------------------------------------------------------------------
-- remove a render stream
StreamDestroy = function(self, View)

	if (View.State == "OFFLINE") then return end

	msg("RenderNode: ["..View.SceneName.."@"..View.StreamName.."] OFFLINE\n");

	View.State	= "OFFLINE" 
	self.SceneCache_DisableID(self.SceneCache, View.RenderNetID)
end
,
-----------------------------------------------------------------------------------------------------------
-- sends out heartbeats to all registered streams 
Update_Stream = function(self)

	local t = time_sec()

	local Dump = false
	if ( (t-self.DumpTS) > 1) then
		self.DumpTS = t
		Dump = true
	end

	for SceneName,Scene in pairs(self.Scene) do

		for ViewName,View in pairs(Scene.ViewList) do

			--if Dump then
			--	ftrace("world load [%-40s] [%-10s] Stream[%-30s] ping:%.4f\n", ViewName.."@"..View.SceneName, View.State, View.StreamName, t - View.PingTS)
			--end
		
			-- no gid assigned yet so skiip
			local Fn = 
			{
			-- rn/scene not up? (e.g. no one is requesting the stream)
			["OFFLINE"] = function()
				if ((t - View.OnlineTime) > 1.0) then
					self.StreamCreate(self, View)
					View.OnlineTime = time_sec()
				end
			end
			,
			["ONLINE"] = function()

				-- time to send heart beat ? 
				if ((t - View.CheckTS) > self.RenderNodeHeartBeat) then
					View.CheckTS = t 
					self.StreamPing(self, View)
				end

				-- stream ping timedout, so set to offline 

				if ((t - View.PingTS) > self.RenderNodeHeartDisconnect) then

					ftrace("stream ["..View.ViewName..":"..View.StreamName.."] OFFLINE (ping timeout)\n")
					View.State = "COLLECT"	
				end
			end
			,
			["COLLECT"] = function()
				-- delete the stream
				self.StreamDestroy(self, View)
			end
			,
			["default"] = function()
			end
			}
			setmetatable(Fn, { __index = function(t, k) return t["default"] end } )
			Fn[View.State]()
		end
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- creates a new view object. view objects are always rendered out 
Packet_ViewAdd = function(self, pkt)

	-- fetch the scene

	local Scene = self.PacketScene(self, pkt) 

	-- if view exists ? 
	if (Scene.ViewList[pkt.arg.Name] != nil) then
		local View = Scene.ViewList[pkt.arg.Name]
		--self.RenderNode_StreamDestroy(self, View) 
	end

	ftrace("[%-30s] view add ["..pkt.arg.Encode.Width.."x"..pkt.arg.Encode.Height.."]\n", Scene.SceneName)

	-- create a view

	Scene.ViewList[pkt.arg.Name] = 
	{
		State		= "OFFLINE", 
		OnlineTime	= time_sec(), 
		Camera		= pkt.arg.CameraPath,	
		CameraNode	= pkt.arg.CameraNode,	
		Image		= pkt.arg.Image,
		Encode 		= pkt.arg.Encode,
		SceneName	= pkt.arg.SceneName,
		ViewName	= pkt.arg.Name,

		StreamName	= pkt.arg.StreamName,
		StreamWidth	= pkt.arg.Encode.Width,
		StreamHeight	= pkt.arg.Encode.Height,
		StreamAspect	= pkt.arg.Encode.Aspect,
		StreamFPS	= pkt.arg.Encode.FPS,
		StreamKbps	= pkt.arg.Encode.Kbps,
		ClearColor	= pkt.arg.ClearColor,

		Cookie		= GenerateCookie(128),

		CheckTS		= time_sec(),			-- when to send stream hearbeats 
		PingTS		= time_sec(),			-- case where 2nd time round it gets diconncetd, the PingTime will be(old time) so over and the collecter will kick it
		RequestTS	= time_sec(),			-- last time someone requested this stream
	}
end
,
-----------------------------------------------------------------------------------------------------------
-- retreives info about the view 
Packet_ViewInfo = function(self, pkt)

	-- fetch the scene

	local Scene = self.PacketScene(self, pkt) 
	ftrace("[%-30s] view info\n", Scene.SceneName)

	-- find the view 

	local View		= assert(Scene.ViewList[pkt.arg.ViewName], "invalid view named ["..pkt.arg.ViewName.."]")

	-- camera obj

	local Node		= assert(self.Scene_NodeFind(Scene.Obj, View.CameraNode), "invalid camera node ["..View.CameraNode.."]")

	-- get view node  
	
	local Info 		= self.Scene_NodeInfo(Node)

	Info.StreamName		= View.StreamName
	Info.StreamWidth	= View.StreamWidth
	Info.StreamHeight	= View.StreamHeight

	-- send back

	pkt.arg.Reply.Info = Info
	Send(Packet(pkt.arg.Reply.gid, self.gid, pkt.arg.Reply.path, pkt.arg.Reply))
end
,
--##########################################################################################################
--  scene manipulation
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
-- updates a global variable
-- all globals can be accessed by SceneObject lua stats via function calls
Packet_GlobalVar = function(self, pkt)

	local Scene = self.PacketScene(self, pkt) 

	-- set it 

	self.Scene_GlobalSet(Scene.Obj, pkt.arg.Key, pkt.arg.Value)
end
,
-----------------------------------------------------------------------------------------------------------
-- forwards message to a scene object
Packet_SceneObjectPacket = function(self, pkt)

	--ftrace("scene object packet\n")

	local Obj, Scene = self.PacketSceneObjectPath(self, pkt) 
	--ftrace("[%-30s] object ["..pkt.arg.URL.."] scene object packet ["..pkt.arg.Cmd.."]\n", Scene.SceneName)

	-- serialize and send 

	local serial = pluto.persist(perms, { packet=pkt.arg.Data } )
	self.SceneObject_Packet(Scene.Obj, Obj, pkt.arg.Cmd, serial) 

	-- send OK to back 
	if (pkt.arg.WWWReply != nil) then 

		local WWW = pkt.arg.WWWReply
		Send(Packet(WWW.GID, self.gid, WWW.Path, 
		{
			id	= WWW.ID,	
			data	= "OK", 
		}))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- fetchs list of all objects within a specified area
Packet_SceneObjectQuery = function(self, pkt)

	--ftrace("scene["..pkt.arg.SceneName.."] ObjectQuery\n")
	local Scene = self.PacketScene(self, pkt)

	-- extract world space info for the object
	local query = self.Scene_QueryBox(Scene.Obj, pkt.arg.ObjectType) 

	-- process it 

	-- fetch user control values
	local List = {}
	for k,v in pairs(query) do
		--ftrace("["..k.."] "..v.Type.." : "..type(List[k]).."\n");
		List[k] = self.SceneObject_UserControl(k, v.Node, v.Obj, {})
	end

	-- add parent data
	for k,v in pairs(pkt.arg.AuxInfo) do

		-- default dont overwrite
		if (List[k] != nil) then continue end

		List[k] = v
	end

	-- pack WWW reply 

	if (pkt.arg.WWWReply != nil) then 

		local WWW = pkt.arg.WWWReply
		Send(Packet(WWW.GID, self.gid, WWW.Path, 
		{
			id	= WWW.ID,	
			data	= LuaToJs(List),
		}))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- retreive info about a specific object
Packet_SceneObjectInfo = function(self, pkt)

	local Obj,Scene = self.PacketSceneObjectPath(self, pkt) 
	local Node = assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.NodePath),	"Node ["..pkt.arg.NodePath.."] does not exists")

	-- extract top level info

	pkt.arg.info = self.SceneObject_Info(Node, Obj)

	-- and forward

	Send(Packet(pkt.arg.ReplyGID, self.gid, pkt.arg.ReplyCmd, pkt.arg))
end
,
-----------------------------------------------------------------------------------------------------------
-- sets a specific value in a variable 
Packet_SceneObjectVariableSet = function(self, pkt)

	local Obj = assert(self.PacketSceneObjectPath(self, pkt), "SceneObjectVariableSet: invalid")

	--ftrace("variable set ["..pkt.arg.URL.."] ["..pkt.arg.Var.."]\n")

	-- var type

	local vtype = self.SceneObject_VariableType(Obj, pkt.arg.Var)
	local convert = 
	{
	["boolean"]	= function(a) 
		if (type(a) == "string") then 
			return sel(a == "true", true, false) 
		elseif (type(a) == "boolean") then 
			return a
		else
			fAssert(false, "undefined boolean type ["..type(a).."]")
		end
		end, 
	["string"]	= function(a) return tostring(a) end, 
	["number"]	= function(a) return tonumber(a) end, 
	["function"]	= function(a) return a end, 
	}
	setmetatable(convert, { __index = function(t, k) return function(a) ftrace("unsupported type conversion\n") return nil end end } )

	-- extract top level info

	local info = self.SceneObject_VariableSet(Obj, pkt.arg.Var, convert[vtype](pkt.arg.Value))
end
,
-----------------------------------------------------------------------------------------------------------
-- delete a specific value in a variable 
Packet_SceneObjectVariableDelete = function(self, pkt)

	local Obj = self.PacketSceneObjectPath(self, pkt)

	-- extract top level info

	local info = self.SceneObject_VariableDelete(Obj, pkt.arg.Var) 
end
,
-----------------------------------------------------------------------------------------------------------
-- creates a specific value in a variable 
Packet_SceneObjectVariableCreate = function(self, pkt)

	local Obj = self.PacketSceneObjectPath(self, pkt) 

	-- extract top level info

	self.SceneObject_VariableCreate(Obj, pkt.arg.Var) 
end
,
-----------------------------------------------------------------------------------------------------------
-- fetch source for entire object 
Packet_SceneObjectSourceGet = function(self, pkt)

	local Obj = self.PacketSceneObjectPath(self, pkt) 

	ftrace("get object ["..pkt.arg.URL.."] source \n")

	-- request 

	local Source = self.SceneObject_SourceGet(Obj)

	ftrace(" source\n"..Source.."\n")

	-- send directly yo www 
	if (pkt.arg.WWWReply != nil) then 

		local WWW = pkt.arg.WWWReply
		Send(Packet(WWW.GID, self.gid, WWW.Path, 
		{
			id	= WWW.ID,	
			data	= Source,
		}))
	end

	-- send reply packet 
	if (pkt.arg.Reply != nil) then 

		pkt.arg.Reply.Source = Source 
		Send(Packet(pkt.arg.Reply.GID, self.gid, pkt.arg.Reply.Path, pkt.arg.Reply))
	end

end
,
-----------------------------------------------------------------------------------------------------------
-- sets the source 
Packet_SceneObjectSourceSet = function(self, pkt)

	local Obj = self.PacketSceneObjectPath(self, pkt) 

	ftrace("set source for ["..pkt.arg.URL.."] source \n")

	-- request 

	local msg = self.SceneObject_SourceSet(Obj, pkt.arg.Source)

	ftrace("set ["..msg.."]\n")

	-- send directly yo www 

	if (pkt.arg.WWWReply != nil) then 

		local WWW = pkt.arg.WWWReply
		Send(Packet(WWW.GID, self.gid, WWW.Path, 
		{
			id	= WWW.ID,	
			data	= msg, 
		}))
	end
end
,
-----------------------------------------------------------------------------------------------------------
-- fetch the source for a scene object
--Packet_SceneObjectFnSourceFetch = function(self, pkt)
--
--	local Obj = self.PacketSceneObjectPath(self, pkt) 
--
--	-- request 
--
--	pkt.arg.source = self.SceneObject_FnSourceGet(Obj, pkt.arg.FnName)
--
--	-- send back
--
--	Send(Packet(pkt.arg.ReplyGID, self.gid, pkt.arg.ReplyCmd, pkt.arg))
--end
--,
-----------------------------------------------------------------------------------------------------------
-- update the function 
--Packet_SceneObjectFnUpdate = function(self, pkt)
--
--	local Obj = self.PacketSceneObjectPath(self, pkt) 
--
--	-- set new source 
--
--	self.SceneObject_FnSourceSet(Obj, pkt.arg.FnName, pkt.arg.Code)
--end
--,
-----------------------------------------------------------------------------------------------------------
-- set the function value 
Packet_SceneObjectFunctionSet = function(self, pkt)

	local Obj = self.PacketSceneObjectPath(self, pkt) 

	-- serialize it

	local serial = pluto.persist(perms, { fn = pkt.arg.Value})

	--local t = pluto.unpersist(unperms, serial)
	--for k,v in pairs(t) do
	--	ftrace("["..k.."]\n");
	--end

	self.SceneObject_FunctionSet(Obj, pkt.arg.Var, serial); 
end
,
-----------------------------------------------------------------------------------------------------------
-- retreive dynamics info about a specific object
Packet_SceneObjectDynamicInfo = function(self, pkt)

	local Obj,Scene = self.PacketSceneObjectPath(self, pkt) 
	local Node = assert(self.Scene_NodeFind(Scene.Obj, pkt.arg.NodePath),	"Node ["..pkt.arg.NodePath.."] does not exists")

	-- extract top level info

	pkt.arg.info = self.SceneObject_Dynamic(Node, Obj)

	-- and forward

	Send(Packet(pkt.arg.ReplyGID, self.gid, pkt.arg.ReplyCmd, pkt.arg))
end
,
-----------------------------------------------------------------------------------------------------------
-- serialize the scene 
Packet_SceneSerialize = function(self, pkt)

	local Scene = self.PacketScene(self, pkt) 

	-- where to store it

	local StoreFile = self.SceneStoreRoot.."/"..pkt.arg.StoreName

	msg("-------------serialize scene -> ["..StoreFile.."]-------------\n");
	local SceneSerial = 
	{
	Name		= pkt.arg.SceneName,
	NodeList	= {},
	ObjectList	= {},
	}

	-- node hierarchy

	ftrace("Node\n")
	local NodeList = self.Scene_NodeList(Scene.Obj)
	for k,v in ipairs(NodeList) do

		local node = self.Scene_NodeSerialize(v)

		-- flatten

		local serial = pluto.persist(perms, node)

		-- compress

		local compress = fCompress(serial)

		ftrace("[%-30s:%-20s] ratio %f %i\n", node.Path, node.Parent, #compress / #serial, #serial)

		SceneSerial.NodeList[k] = compress
	end

	-- object list

	ftrace("Object\n")
	local ObjectList = self.Scene_ObjectList(Scene.Obj)
	for k,v in ipairs(ObjectList) do

		local obj = self.SceneObject_Serialize(v)

		local serial = pluto.persist(perms, obj)

		local compress = fCompress(serial)

		ftrace("[%-30s:%-20s] object %f %iKB\n", obj.Path, obj.Name, #compress/#serial, #compress/1024)

		SceneSerial.ObjectList[k] = compress
	end

	-- serialize the whole lot

	local serial = pluto.persist(perms, SceneSerial)

	-- store to disk somewhere

	local f = io.open(StoreFile, "wb")
	if (f == nil) then
		ftrace("unable to open file ["..StoreFile.."]\n")
		return
	end
	f:write(serial)
	f:close();

	ftrace("serialize %iKB %iMB\n", (#serial/1024), (#serial/(1024*1024)) )
end
,
-----------------------------------------------------------------------------------------------------------
-- deserialize the scene 
Packet_SceneDeserialize = function(self, pkt)

	local SceneName = pkt.arg.SceneName

	local FileName = self.SceneStoreRoot.."/"..pkt.arg.SceneStore

	ftrace("deserialzing ["..pkt.arg.SceneName.."]\n")

	-- scene already active

	if (self.Scene[pkt.arg.SceneName] != nil) then

		-- tell whoever requested its all good
		if (pkt.arg.StatusGID != nil) then

			ftrace("send status\n");

			pkt.arg.Status = "OK"
			Send(Packet(pkt.arg.StatusGID, self.gid, pkt.arg.StatusCmd, pkt.arg)) 
		end

		ftrace("Scene["..pkt.arg.SceneName.."] already loaded\n");
		return
	end

	-- create the scene

	self.Packet_SceneAdd(self, { arg = { SceneName = pkt.arg.SceneName }} ) 

	-- load the file

	local f = io.open(FileName, "rb")
	if (f == nil) then

		if (pkt.arg.StatusGID != nil) then

			pkt.arg.Status		= "FAIL"
			pkt.arg.Info		= "No file named ["..FileName.."]\n"
			Send(Packet(pkt.arg.StatusGID, self.gid, pkt.arg.StatusCmd, pkt.arg)) 

		end
		ftrace("status ["..pkt.arg.StatusGID.."]\n")
		ftrace("Packet_sceneDeseiralize: failed to open file ["..FileName.."]\n");
		return
	end
	local serial = f:read("*all")
	if (#serial == 0) then

		if (pkt.arg.StatusGID != nil) then

			pkt.arg.Status 		= "FAIL"
			pkt.arg.Info		= "file read failed ["..FileName.."]\n"
			Send(Packet(pkt.arg.StatusGID, self.gid, pkt.arg.StatusCmd, pkt.arg)) 
		end

		ftrace("Packet_sceneDeseiralize: file ["..pkt.arg.SceneStore.."] is invalid\n");
		return
	end
	f:close();

	ftrace("serial "..(#serial/1024).."KB \n")

	-- top level deserialize

	local Info = pluto.unpersist(unperms, serial)

	-- tell whoever requested its all good

	if (pkt.arg.StatusGID != nil) then
		pkt.arg.Status		= "LOADING"
		Send(Packet(pkt.arg.StatusGID, self.gid, pkt.arg.StatusCmd, pkt.arg))
	end


	-- create the objects first

	local ObjectList = {}
	for k,v in pairs(Info.ObjectList) do

		local decomp = fDecompress(v)

		local obj = pluto.unpersist(unperms, decomp)

		ObjectList[obj.ID] = obj

		--ftrace("[%-30s:%-20s] object %i %s\n", obj.Path, obj.Name, obj.ID, obj.Type);

		-- create the object

		local pkt 		= { arg = pluto.unpersist(unperms, obj.LVM) }
		pkt.arg.SceneName	= SceneName
		pkt.arg.Type 		= obj.Type
		pkt.arg.Name		= obj.Name

		self.Packet_ObjectAdd(self, pkt)
	end

	-- link in the hierarchy 

	local NodeList = {}
	for k,v in pairs(Info.NodeList) do

		local decomp = fDecompress(v)

		local node = pluto.unpersist(unperms, decomp)

		NodeList[node.ID] = node

		local pkt 		= { arg = {} }
		pkt.arg.SceneName	= SceneName
		pkt.arg.NodeName	= node.Name 
		pkt.arg.NodeParent	= node.Parent
		pkt.arg.Object		= { } 

		for k,v in ipairs(node.Child) do

			local obj = ObjectList[v]
			if (obj == nil) then
				ftrace("unable to find object id["..v.."]\n");
				continue;
			end

			pkt.arg.Object[obj.Key] =
			{
				Type = obj.Type,
				Name = obj.Name,
			}
		end

		ftrace("["..node.Name.."] parent ["..node.Parent.."]\n")
		self.Packet_NodeAdd(self, pkt)
	end

	ftrace("deserialzing ["..pkt.arg.SceneName.."] done\n")

	-- tell whoever requested its all good
	if (pkt.arg.StatusGID != nil) then

		pkt.arg.Status		= "OK" 
		Send(Packet(pkt.arg.StatusGID, self.gid, pkt.arg.StatusCmd, pkt.arg)) 
	end
end
,
--##########################################################################################################
--  tiles 
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
-- render a tile node
Packet_RenderTile = function(self, pkt)

	sTile = time_sec()

	local Scene = assert(self.Scene[pkt.arg.SceneName], "invalid scene name ["..pkt.arg.SceneName.."]")

	-- directions 

	local viewDirection = 
	{
	["xy"] = { x= 0.0, y= 0.0, z=1.0},	-- front 
	["xz"] = { x= 0.0, y=-1.0, z=0.0},	-- top
	["zy"] = { x=-1.0, y= 0.0, z=0.0},	-- right  (need +u axis == +x axis)
	}

	local viewUp = 
	{
	["xy"] = { x= 0.0, y= 1.0, z=  0.0},	-- front 
	["xz"] = { x= 0.0, y= 0.0, z=  1.0},	-- top
	["zy"] = { x= 0.0, y= 1.0, z=  0.0},	-- right 
	}
	
	-- build a node + controller + camera, and attach to the root. its a bit excessive
	-- when you can just have a world space camera object or something, but this keeps
	-- the camera code cleaner, and this isnt highly perf critical... for now 

	-- create lookat controller
	local LookAt = self.SceneObject_Create("ControllerLookAt", self.Device, Scene.Obj, pluto.persist(perms, {arg=
	{
		Name		= "DummyTileRenderController",
		Position	= pkt.arg.WorldPos,
		Target		= 
		{
			x = pkt.arg.WorldPos.x + viewDirection[pkt.arg.View].x,
			y = pkt.arg.WorldPos.y + viewDirection[pkt.arg.View].y,
			z = pkt.arg.WorldPos.z + viewDirection[pkt.arg.View].z,
		},
		Up		= viewUp[pkt.arg.View], 
	}}))

	-- create camera

	local Camera = self.SceneObject_Create("Camera", self.Device, Scene.Obj, pluto.persist(perms, {arg=
	{
		Name 		= "tile render camera",
		FOV		= 90.0,
		CameraMode	= "static",

		Projection	= "orthographic",
		OrthoWidth	= pkt.arg.OrthoWidth, 
		OrthoHeight	= pkt.arg.OrthoHeight, 
	}}))

	-- node and bind 

	local Node = self.Scene_NodeCreate(
	{
		Scene = Scene.Obj,
		Name = "DummyTileRenderNode",
	})
	self.Scene_NodeAttach(
	{
		Scene 		= Scene.Obj,
		Parent 		= self.Scene_NodeFind(Scene.Obj, "/"), 
		Child		= Node,
	})
	self.Scene_NodeObjectAdd(
	{
		Scene		= Scene.Obj,
		Node		= Node, 
		Object		= Camera, 
		Name		= "cam",
	})
	self.Scene_NodeObjectAdd(
	{
		Scene		= Scene.Obj,
		Node		= Node, 
		Object		= LookAt, 
		Name		= "lookat",
	})
	self.Scene_Update(self.Device, Scene.Obj)		-- bit harsh, as only want to update this node, but its the simplest way for the moment 

	-- finally...realize the camera encodes all xforms just in the camera object, no need for the others

	local stream = self.SceneObject_Realize(Scene.Obj, Scene.ID, self.SceneCache, Camera, "TABLE")
	if (stream == nil) then return end

	-- send request to rn
	-- note pkt continas private data, so forward all data and add some bits

	local arg 		= pkt.arg
	arg.ReplyGID		= pkt.arg.ReplyGID
	arg.ReplyCmd		= pkt.arg.ReplyCmd
	arg.RealizeCamera	= stream[1]
	arg.Width		= pkt.arg.TileWidth 
	arg.Height		= pkt.arg.TileHeight
	Send(Packet(self.RenderMapGID, self.gid, "RenderTile", arg))

	-- free the crap 

	self.Scene_NodeDestroy(Scene.Obj, Node)		-- hmm needs to be this order for now
	self.SceneObject_Destroy("Camera", self.Device, Scene.Obj, Camera) 
	self.SceneObject_Destroy("ControllerLookAt", self.Device, Scene.Obj, LookAt) 
end
,
}
end
}
