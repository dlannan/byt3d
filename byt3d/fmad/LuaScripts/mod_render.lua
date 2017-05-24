-------------------------------------------------------------------------------------------------------------
--
-- fmad llc 2008 
--
-- lua side render interface 
--
-------------------------------------------------------------------------------------------------------------
return
{
-- dynamic libs
library = 
{
	"libX11.so",
	"libGL.so",
	"libglut.so",
	"libCg.so",
	"libCgGL.so",
	"libcuda.so",
}
,
main = function()
return
{
--##########################################################################################################
-- setup/interface functions
-----------------------------------------------------------------------------------------------------------
-- do module setup
Setup = function(self, arg)

	self.TargetWidth	= 640
	self.TargetHeight	= 320
	self.TargetFPS		= 30

	self.RTMPServerGID	= assert(arg.RTMPServerGID, "no rtmp server gid")
	self.RTMPServerUpdate	= 20*5		-- rate to update with rtmp server 

	-- dispatch commands

	self.Dispatch.Add(self.Dispatch, "Ping",		self.Packet_Ping, self,			"ping me")
	self.Dispatch.Add(self.Dispatch, "StreamCreate",	self.Packet_StreamCreate, self,		"create a render a stream")
	self.Dispatch.Add(self.Dispatch, "StreamPing",		self.Packet_StreamPing, self,		"create a render a stream")
	self.Dispatch.Add(self.Dispatch, "RenderTile",		self.Packet_RenderTile, self,		"someone asking to render a specific tile")

	self.FrameCount 	= 0
	self.HeaderCount 	= 0
	self.LastUpdate		= time_sec() 
	self.StatUpdate		= time_sec() 
	self.Scanout		= arg.Scanout

	self.StreamHeartKick	= 60 

	-- tile render queue

	self.TileQueue		= fFIFO:new()

	-- stats

	self.RenderCount	= 0
	self.RenderTime		= 0.0
	self.EncodeTime		= 0.0
	self.NetTime		= 0.0

	self.TimeTile		= 0.0
	self.RenderNet		= fMultiCast_Create(
	{
		McGroup		= arg.RenderNet.Group, 
		Port		= arg.RenderNet.Port, 
	}) 
	
	-- scene list 

	self.Scene		= {}

	-- setup device 

	self.Device		= self.Device_Create(
	{
		DisplayWidth	= 1024,
		DisplayHeight	= 480,

		MaxWidth	= 2048,
		MaxHeight	= 1024,

		fps		= self.TargetFPS,
	});

	-- random cookie

	self.Cookie		= GenerateCookie(128) 
end
,
-----------------------------------------------------------------------------------------------------------
-- update cycle 
Update = function(self)
	
	-- render net packet dispatch

	local sMulti = time_sec();

	fMultiCast_Update( self.RenderNet )

	local eMulti = time_sec();
	self.NetTime = self.NetTime + (eMulti - sMulti)

	-- check if encoder threads have finished any frames 

	local pkt = self.Encode_Update()
	if (pkt != nil) then

		local Scene = assert(self.Scene[pkt.SceneName], "invalid scene name ["..pkt.SceneName.."]")
		Send(Packet(Scene.RTMPServerGID, self.gid, "RenderFrame", 
		{
			name	= Scene.StreamName,
			width	= self.TargetWidth, 
			height	= self.TargetHeight, 
			flv	= pkt.data,
			key	= pkt.key, 
			pos	= 1, 
			ts	= pkt.ts,
		}))

		-- add encode time

		self.EncodeTime = self.EncodeTime + pkt.EncodeTime 
	end

	-- update streams 
	local t = time_sec()
	for SceneName,Scene in pairs(self.Scene) do 
		self.Stream_Update(self, Scene, t)
	end

	-- finally collect, should be after latency sensitive items
	-- as it can take undefined amounts of time

	collectgarbage()
end
,
-----------------------------------------------------------------------------------------------------------
-- renders a scene with a view
Render = function(self, Frame, ObjectList)

	-- bin the objects

	self.ObjectList_Sort(ObjectList)

	-- geometry pass 

	self.Render_GeometryBegin(Frame);

		-- tri soup meshs

		self.TriMesh_Render(
		{
			Frame		= Frame,
			ObjectList	= ObjectList, 
			Mode		= "GEOMETRY"
		})

		-- skins render 

		self.Skin_Render(
		{
			Frame		= Frame,
			ObjectList	= ObjectList, 
			Mode		= "GEOMETRY"
		})


		-- linez

		self.Line_Render(
		{
			Frame		= Frame,
			ObjectList	= ObjectList, 
			Mode		= "GEOMETRY"
		})

		-- height maps 

		self.HeightMap_Render(
		{
			Frame		= Frame,
			ObjectList	= ObjectList, 
			Mode		= "GEOMETRY"
		})

	self.Render_GeometryEnd(Frame);
	-- for each light

	local LightList = self.ObjectList_LightList(ObjectList)
	for k, Light in pairs(LightList) do 

		-- light is set to cast shadows ? 

		if (self.LightDir_ShadowEnable(Light)) then

			-- render shadow maps

			self.Render_ShadowBegin(Frame, "ShadowMap0")

				-- static meshs

				self.TriMesh_Render(
				{
					Frame		= Frame, 
					ObjectList	= ObjectList, 
					Mode		= "SHADOWMAP", 
					Light		= Light
				})

				-- skins 

				self.Skin_Render(
				{
					Frame		= Frame, 
					ObjectList	= ObjectList, 
					Mode		= "SHADOWMAP", 
					Light		= Light
				})

				-- height maps 

				self.HeightMap_Render(
				{
					Frame		= Frame,
					ObjectList	= ObjectList, 
					Mode		= "SHADOWMAP",
					Light		= Light
				})



			self.Render_ShadowEnd(Frame)
		end

		-- render into l buffer

		self.Render_LightBegin(Frame)

			self.LightDir_Render(Frame, ObjectList, Light);

		self.Render_LightEnd(Frame)
	end

	-- ambient occlusion (on opaque geom)

	self.Render_AmbientOcclusion(Frame)

	-- translucent tris (dont apply AO on them) 

	self.Render_Translucent(Frame, ObjectList);

	-- bloom it

	self.Render_Bloom(Frame)

	-- render particle system 

	self.Render_ParticleBegin(Frame);

		-- all particle systems

		--self.Particle_Render(Frame, ParticleList, "")

	self.Render_ParticleEnd(Frame);

	-- resolve

	self.Render_Resolve(Frame);

	-- aa

	self.Render_AA(Frame);

	return Frame
end
,
-----------------------------------------------------------------------------------------------------------
-- frame encoder
Encode = function(self, Frame, Scene, t)

	if (Scene.Encoder == nil) then return end
	local sEncode = time_sec()

	-- resend critical data 

	if ((Scene.RTMPServerFrame % self.RTMPServerUpdate) == 0) then

		-- send stream header info

		Send(Packet(self.RTMPServerGID, self.gid, "RenderHeader", 
		{
			name		= Scene.StreamName,
			CodecHeader 	= self.Encode_AVCC(Scene.Encoder),
			TargetFPS	= self.TargetFPS,
		}))

	end
	Scene.RTMPServerFrame = Scene.RTMPServerFrame + 1

	-- queue frame for encoding (will drop the frame if the queue is full)
	self.Encode_Frame(Scene.Encoder, Frame, Scene.SceneName, t)

	-- encode time
	if (Scene.Stats.TimeAccEncode == nil) then Scene.Stats.TimeAccEncode = 0 end 
	--Scene.Stats.TimeAccEncode = Scene.Stats.TimeAccEncode + (eEncode - sEncode)

	-- frame count
	if (Scene.Stats.FrameCount == nil) then Scene.Stats.FrameCount = 0 end 
	Scene.Stats.FrameCount = Scene.Stats.FrameCount + 1
end
,
--##########################################################################################################
-- module commands
--##########################################################################################################
-----------------------------------------------------------------------------------------------------------
Packet_Ping = function(self, pkt)

	local t = time_sec()	

	local dt = (t - self.StatUpdate) 
	if (dt == 0) then dt = 0.0001 end

	local RenderCount	= self.RenderCount 
	if (RenderCount == 0) then RenderCount = 1 end

	local MC 		= fMultiCast_Stats()
	local RS 		= self.Device_Stats(self.Device)
	local EN 		= self.Encode_Stats()

	local FPS		= RenderCount / dt 

	local PacketCount 	= MC.PacketCount / RenderCount 
	local EncodeMS		= 1e3 * (self.EncodeTime / RenderCount)
	local Load		= (self.RenderTime+self.EncodeTime) / dt 
	local RenderLoad	= self.RenderTime / dt 
	local RenderMS		= 1e3 * (self.RenderTime / RenderCount)
	local NetworkMS		= 1e3 * (self.NetTime / RenderCount)
	local NetLoad		= self.NetTime / dt 
	local TileLoad		= self.TimeTile / dt 

	local RenderGeomMS	= 1e3 * RS.Geometry
	local RenderLightMS	= 1e3 * RS.Light
	local RenderShadowMS	= 1e3 * RS.Shadow
	local RenderPostMS	= 1e3 * RS.Post
	local RenderReadMS	= 1e3 * RS.Read

	local ooRMS = 1.0 / RenderMS
	if (RenderMS == 0) then ooRMS = 1.0 end

	local RenderGeom	= RenderGeomMS * ooRMS 
	local RenderLight	= RenderLightMS * ooRMS 
	local RenderShadow	= RenderShadowMS * ooRMS
	local RenderPost	= RenderPostMS * ooRMS
	local RenderRead	= RenderReadMS * ooRMS

	local RenderEncode	= self.EncodeTime*1e3 * ooRMS 

	local Vertex		= RS.Vertex / RenderCount
	local Tri		= RS.Tri / RenderCount

	self.StatUpdate		= t;

if true then

	--dtrace("Pk:%-3i Render:%0.2f(G:%0.2f(%.3f) L:%0.2f(%.3f) S:%0.2f(%0.3f) P:%0.2f(%.3f) R:%0.2f(%0.3f) E:%0.2f(%.3f)] Load[R:%0.3f N:%0.3f T:%0.3f] fps:%0.1f vtx:%0.fK Tri:%0.fK\n",
	ftrace("%04i Pk:%-3i Rnd:%0.2f(G:%0.2f(%.3f) L:%0.2f(%.3f) S:%0.2f(%0.3f) P:%0.2f(%.3f) R:%0.2f(%0.3f) E:%0.2f(%.3f)] Load[R:%0.3f] fps:%0.1f vtx:%0.fK Tri:%0.fK\n",
			RenderCount,
			PacketCount, 
			RenderMS, 
			RenderGeomMS,	RenderGeom,
			RenderLightMS,	RenderLight,
			RenderShadowMS,	RenderShadow,
			RenderPostMS,	RenderPost,
			RenderReadMS,	RenderRead,
			EncodeMS,	RenderEncode,
			RenderLoad,	--NetLoad, TileLoad, 
			FPS, Vertex/1000, Tri/1000
	)
end

	self.RenderCount	= 0
	self.RenderTime		= 0
	self.EncodeTime		= 0
	self.NetTime		= 0
	self.TimeTile		= 0

	-- general stats

	pkt.arg.Stats =
	{
	["FPS"]			= FPS,
	["Load"]		= Load,
	["LoadRender"]		= RenderLoad,
	["LoadNet"]		= NetLoad,
	["LoadTile"]		= TileLoad,

	["PacketCount"]		= PacketCount,
	["EncodeMs"]		= EncodeMS,
	["RenderMs"]		= RenderMS,
	["NetworkMs"]		= NetworkMS,
	["EncodeDrop"]		= EN.FrameDrop,

	Stream			= {}
	}

	-- per stream stats 

	for Name,Scene in pairs(self.Scene) do

		local ooF = SafeRecip(Scene.Stats.FrameCount)

		-- noramlize on a per frame basis 
		local S = {}
		for i,j in pairs(Scene.Stats) do
			S[i] = j * ooF
		end

		-- other info
		S.FrameCount	= Scene.Stats.FrameCount
		S.State		= Scene.State
		S.StreamName	= Scene.StreamName
		S.KPixel	= Scene.StreamWidth*Scene.StreamHeight / 1024

		if (EN.Scene[Name] != nil) then
			S.EncodeMs	= EN.Scene[Name].Time / EN.Scene[Name].Count
			S.EncodeDrop	= EN.Scene[Name].Drop
		end

		pkt.arg.Stats.Stream[Scene.StreamName] = S
		Scene.Stats = {}
	end

	pkt.arg.Cookie = self.Cookie
	Send(Packet(pkt.arg.gid, self.gid, pkt.arg.path, pkt.arg))
end
,
-----------------------------------------------------------------------------------------------------------
-- sends back the render network object id
Packet_StreamCreate = function(self, pkt)

	-- create it if its brand new 
	if (self.Scene[pkt.arg.SceneName] == nil) then

		-- create struct 
	
		self.Scene[pkt.arg.SceneName] =
		{
			State		= "CREATE",
			SceneName	= pkt.arg.SceneName,
			StreamName	= pkt.arg.StreamName,
			StreamWidth	= pkt.arg.StreamWidth,
			StreamHeight	= pkt.arg.StreamHeight,
			StreamAspect	= pkt.arg.StreamAspect,
			StreamFPS	= pkt.arg.StreamFPS,
			StreamKbps	= pkt.arg.StreamKbps,
			ClearColor	= pkt.arg.ClearColor,

			RTMPServerFrame	= 0,
			RTMPServerGID	= pkt.arg.RTMPServerGID,
			SceneID		= pkt.arg.SceneID,

			-- init all time stamps 
		
			StartTS		= time_sec(),
			LastTS		= time_sec(),
			DumpTS		= time_sec(),
			RequestTS	= time_sec(),
			WorldTS		= time_sec(),
			FrameLast	= 0,
			DrawTS		= 0,

			Stats		= {},
		}
	else
		-- shouldnt need to do anything, either in create/render or collect mode
		fAssert(self.Scene[pkt.arg.SceneName].State != "COLLECT")	
	end

	-- tell cosmos the stream has been created

	pkt.arg.Ack.RenderNodeGID = self.gid
	Send(Packet(pkt.arg.Ack.GID, self.gid, pkt.arg.Ack.Path, pkt.arg.Ack))

	-- send back Net ID for world to connect to

	pkt.arg.RenderNodeGID	= self.gid 
	pkt.arg.RenderNetID	= fMultiCast_ObjectID(self.RenderNet)
	--ftrace("[%-30s] send render net id:"..pkt.arg.RenderNetID.."\n", pkt.arg.StreamName)

	Send(Packet(pkt.arg.ReplyGID, self.gid, pkt.arg.ReplyCmd, pkt.arg)) 
end
,
-----------------------------------------------------------------------------------------------------------
-- do the work of creating the stream
Stream_Create = function(self, Scene)

	ftrace("stream ["..Scene.SceneName.."] create\n")

	-- build local objects

	Scene.RenderList	= self.ObjectList_Create()
	Scene.Realizer		= self.Realize_Create(self.RenderNet, Scene.RenderList)

	-- encoder

	Scene.Encoder		= self.Encode_Setup(
				{
					fmt	= "flv",
					width	= Scene.StreamWidth,
					height	= Scene.StreamHeight, 
					aspect	= Scene.StreamAspect, 
					fps	= Scene.StreamFPS, 
					Kbps	= Scene.StreamKbps, 
					maxsize	= 4*1024*1024,
				})

	-- set the scene id

	self.Realize_SceneIDSet(Scene.Realizer, Scene.SceneID)

	-- start rendering 

	Scene.State		= "RENDER"
end
,
-----------------------------------------------------------------------------------------------------------
-- release resources
Stream_Destroy = function(self, Scene)

	if (Scene == nil) then return end

	if (Scene.Encoder != nil) then

		self.Encode_Close(Scene.Encoder)
		Scene.Encoder = nil
	end

	--self.ObjectList_Destroy(Scene.RenderList)

	self.Realize_Destroy(Scene.Realizer)

	-- remove from scene list
	self.Scene[Scene.SceneName] = nil
end
,
-----------------------------------------------------------------------------------------------------------
-- world -> cosmos -> render node.stream ping 
Packet_StreamPing = function(self, pkt)

	-- check cookie matches

	local Scene = assert(self.Scene[pkt.arg.SceneName], "invalid scene name ["..pkt.arg.SceneName.."]\n")

	-- its a different stream, so collect it

	if (Scene.Cookie != pkt.arg.Cookie) and (Scene.Cookie != nil) then
		print("stream cookie invalid, collecting\n")
		self.Scene[Scene.SceneName] = nil
		return
	end
	Scene.Cookie	= pkt.arg.Cookie

	-- world -> RN (world active)
	if (pkt.arg.World == true) then
		Scene.WorldTS = time_sec()
	end

	-- RTMP(cosmos) -> RN (requestor)
	if (pkt.arg.Request == true ) then
		Scene.RequestTS = time_sec()
	end

	-- back at ya

	Send(Packet(pkt.arg.Ack.GID, self.gid, pkt.arg.Ack.Path, pkt.arg))
end
,
-----------------------------------------------------------------------------------------------------------
-- collect any redundant streams
Stream_Collect = function(self, t, Scene)

	if ((t-Scene.RequestTS) > self.StreamHeartKick) then

		print("stream collect ["..Scene.SceneName.."]["..Scene.StreamName.."] (no requestor)\n")

		Scene.State = "COLLECT"
		return
	end

	if ( (t-Scene.WorldTS) > self.StreamHeartKick) then

		print("stream collect ["..Scene.SceneName.."]["..Scene.StreamName.."] (no world)\n")

		Scene.State = "COLLECT"
		return
	end
end
,
-----------------------------------------------------------------------------------------------------------
Stream_Draw = function(self, dt, Scene)

	local sRender = time_sec()

	local Frame = self.Frame_Begin(
	{
		Device		= self.Device, 
		Width		= Scene.StreamWidth, 
		Height		= Scene.StreamHeight, 
		Aspect		= Scene.StreamAspect, 
		Readback	= self.Encode_FrameBuffer(Scene.Encoder),
		Scanout		= self.Scanout,
		ObjectList	= Scene.RenderList,
		ClearColor	= Scene.ClearColor,
	})
		-- actuall render

		self.Render(self, Frame, Scene.RenderList)

		-- readback
		local sRead = time_sec();
	
		self.Frame_Readback(Frame);

		-- frame encoding

		local sEncode = time_sec()
		self.Encode(self, Frame, Scene, dt)
		local eEncode = time_sec()

		-- release resources

	self.Frame_End(Frame, Scene.Stats)

	-- curiousy flip

	if (self.Scanout) then
		self.Device_Flip(self.Device, false)
	end

	local eRender = time_sec()

	self.RenderTime = self.RenderTime + (eRender-sRender)
	self.RenderCount = self.RenderCount + 1
end
,
-----------------------------------------------------------------------------------------------------------
-- top level stream function
Stream_Update = function(self, Scene, t)

	-- time for next frame ?

	local frame	= math.floor((t - Scene.StartTS)*Scene.StreamFPS)
	if (frame == Scene.FrameLast) then return end

	-- time delta in frame rate units

	local dFrame	= frame - Scene.FrameLast 
	local dt	= dFrame*(1.0/Scene.StreamFPS)

	--dtrace("("..frame..") %0.4fms %i draw: %0.4f\n", ((t - Scene.LastTS)*1e3), dFrame, Scene.DrawTS*1e3) 

	Scene.LastTS	= Scene.LastTS + dFrame*(1.0/Scene.StreamFPS);
	Scene.FrameLast = frame

	-- trace what its doing
	--if ( (t-Scene.DumpTS) > 1) then
	--	Scene.DumpTS = t
	--	dtrace("Stream[%-60s] [%-10s]\n", Scene.SceneName.."@"..Scene.StreamName, Scene.State)
	--end

	-- execute state
	local Fn = 
	{
	-- create a stream
	["CREATE"] = function()
		self.Stream_Create(self, Scene)
	end
	,
	-- frame rendering 
	["RENDER"] = function()

		self.Stream_Draw(self, dt, Scene)
		self.Stream_Collect(self, t, Scene)	

		Scene.DrawTS = time_sec() - t
	end
	,
	["COLLECT"] = function()
		self.Stream_Destroy(self, Scene)
	end
	,
	["default"] = function() end,
	}
	setmetatable(Fn, { __index = function(t, k) return t["default"] end } )
	Fn[Scene.State]()
end
,
-----------------------------------------------------------------------------------------------------------
Packet_RenderTile = function(self, pkt)

	--dtrace("render tile ["..type(pkt.arg.RealizeCamera).."]\n")
	self.TileQueue:push(
	{
		Width 		= pkt.arg.Width;
		Height 		= pkt.arg.Height;
		ReplyGID	= pkt.arg.ReplyGID,
		ReplyCmd	= pkt.arg.ReplyCmd,
		Camera		= pkt.arg.RealizeCamera,
		Data		= pkt.arg,
	})
end
,
}
end
}
