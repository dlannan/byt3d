--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 1:18 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
------------------------------------------------------------------------------------------------------------
-- I think this is supposed to be the Node for the RenderModule
NODEID      = 0x200
OBJECTID    = 0x001

------------------------------------------------------------------------------------------------------------
-- Testing framework
package.path 		= package.path..";tests/?.lua;byt3d/?.lua;byt3d/?.lua"
msg                 = print

------------------------------------------------------------------------------------------------------------

require("byt3d/fmad/Common/fAssert")
require("byt3d/fmad/Common/fMath")

require("byt3d/fmad/Network/ServerClient")
require("byt3d/fmad/Network/MultiCast")

require("byt3d/fmad/Render/fDevice")
require("byt3d/fmad/Render/fShader")
require("byt3d/fmad/Render/fRealize")
require("byt3d/fmad/Render/fCamera")
require("byt3d/fmad/Render/fRender")

require("byt3d/fmad/Render/fObject")

require("byt3d/fmad/Render/fMaterial")
require("byt3d/fmad/Render/fFrame")
require("byt3d/fmad/Render/fTriMesh")
require("byt3d/fmad/Render/fLine")

require("pluto")

------------------------------------------------------------------------------------------------------------

assimp = require("byt3d/scripts/utils/assimp")
------------------------------------------------------------------------------------------------------------

require 'Test.More'
plan(2)

------------------------------------------------------------------------------------------------------------
function server_testCall()

    ok(true, "serverTestCalled")
end

------------------------------------------------------------------------------------------------------------
function client_testCall()

    ok(true, "clientTestCalled")
end

------------------------------------------------------------------------------------------------------------
function server_create_test( test )

    local server = fServer_Create(80, "server_testCall", "Test")
    ok(server ~= nil, "Server is valid")
    -- keep server alive
    return server
end

------------------------------------------------------------------------------------------------------------
function client_connect_test()

    local client = fServer_Connect("client_testCall", 80, "localhost", "Test")
    ok(client ~= nil, "Client is valid")
end


------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- Ugly Windoze...

function NetworkTests()

    WS2Init()
    local start_time = os.clock()
    local the_server = server_create_test()

    local RenderNet		= lMultiCast_Create(
    {
        McGroup		= "224.0.0.20",
        Port		= "1234",
    }, 1)

    local try_connect = 0
    local int_clock = 0
    local diff = os.clock() - start_time

    while( diff < 10.000 ) do

        if try_connect == 0 then
            client_connect_test()
            try_connect = 1
        end

        diff = os.clock() - start_time
        if( math.floor(diff) ~= int_clock ) then
            ftrace("time: ", os.clock())
            int_clock = math.floor(diff)
        end
    end
end

------------------------------------------------------------------------------------------------------------

function create_device_test()

    local Device	= lDevice_Create(
        {
            DisplayWidth	= 1024,
            DisplayHeight	= 480,

            MaxWidth	= 2048,
            MaxHeight	= 1024,

            fps		= 60.0,
        })
    ok(Device ~= nil, "Device is valid")

    return Device
end

-----------------------------------------------------------------------------------------------------------
local camera_pool = {}

function create_camera_test(scene, N)
    -----------------------------------------------------------------------------------------------------------
    -- camera
    -----------------------------------------------------------------------------------------------------------
    local proj  = fMat44_Projection( 90.0, 1.333, 1.0, 1000.0 )   -- Projection
    local iproj = fMat44_iProjection( 90.0, 1.333, 1.0, 1000.0 )  -- iProjection

    local camPtr = ffi.new("fCamera_t[1]")
    local cam1 = camPtr[0]
    cam1.Local2World    = fMat44_Identity()
    cam1.iLocal2World   = fMat44_Identity()
    cam1.View           = fMat44_Identity()
    cam1.iView          = fMat44_Identity()
    cam1.Projection     = proj
    cam1.iProjection     = iproj

    local newCamPtr = fObject_Get( scene.RenderList, fObj.fObject_Camera, NODEID, 0x00001 )
    local newCam = newCamPtr[0]
    newCam.Object = camPtr
    fObjectList_CameraSet( scene.RenderList, newCamPtr )
    table.insert(camera_pool, camPtr)
    return newCam
end

-----------------------------------------------------------------------------------------------------------

 function LoadTriMesh(scene, filename)

    local Model = fmadLoadModel(scene.RenderList, filename)

    msg("loaded model ["..filename.."]\n");
--    msg(" Faces: "..#Model.Face.."\n")
--    msg(" Verts: "..#Model.Vertex.."\n")

    return Model
end

-----------------------------------------------------------------------------------------------------------

function LoadTexture( filename)

    local f = io.open(filename, "rb")
    if (f == nil) then
        msg("unable to open texture ["..filename.."]\n")
        return nil
    end

    local buf = f:read("*all")
    f:close()

    msg("loaded texture ["..filename.."] "..(#buf/1024).."KB\n")

    return buf
end

------------------------------------------------------------------------------------------------------------

function create_scene_test(RenderNet)

    -- scene list
    local Scene		= {
        SceneID         = 0x0001,
        StreamWidth     = 1024,
        StreamHeight    = 768,
        StreamAspect    = 1.333,
        StreamFPS       = 60.0,
        StreamKbps      = 2000,
        ClearColor      = { r=255.0, g=255.0, b=0.0, a=1.0 },
        Stats           = { TimeAccCount = 0 }
    }

    Scene.SceneName     = "Test1"

    -- build local objects
    Scene.RenderList    = lObjectList_Create()
    Scene.Realizer		= lRealize_Create(RenderNet, Scene.RenderList)

    -- encoder
--    Scene.Encoder		= lEncode_Setup(
--        {
--            fmt	= "flv",
--            width	= Scene.StreamWidth,
--            height	= Scene.StreamHeight,
--            aspect	= Scene.StreamAspect,
--            fps	    = Scene.StreamFPS,
--            Kbps	= Scene.StreamKbps,
--            maxsize	= 4*1024*1024,
--        })

    -- set the scene id
    lRealize_SceneIDSet(Scene.Realizer, Scene.SceneID)

    -- start rendering
    Scene.State		= "RENDER"

    -- Load a trimesh
    Scene.TriMesh = {}
    Scene.TriMesh["Canon"] = LoadTriMesh(Scene, "byt3d/data/models/Brendan/Canon.dae")

    return Scene
end

------------------------------------------------------------------------------------------------------------

function frame_draw_test(m, dt, scene)

    fMultiCast_Update( m.RenderNet )

    local sRender = os.clock()
    local Frame = lFrame_Begin(
        {
            Device		= m.Device,
            Width		= scene.StreamWidth,
            Height		= scene.StreamHeight,
            Aspect		= scene.StreamAspect,
--            Readback	= m.Encode_FrameBuffer(Scene.Encoder),
            Scanout		= m.Scanout,
            ObjectList	= scene.RenderList,
            ClearColor	= scene.ClearColor,
        })

    -- actuall render
    m.Render(m, Frame, scene.RenderList)

    -- readback
--    local sRead = os.clock()
--    Frame = lFrame_Readback(Frame)

    -- frame encoding
--    local sEncode = os.clock()
--    lEncode(L, Frame, Scene, dt)
--    local eEncode = os.clock()

    -- release resources
    lFrame_End(Frame, scene.Stats)

    -- curiousy flip
    if (m.Scanout) then
        lDevice_Flip(m.Device, false)
    end

    local eRender = os.clock()

    m.RenderTime = m.RenderTime + (eRender-sRender)
    m.RenderCount = m.RenderCount + 1
end

-----------------------------------------------------------------------------------------------------------

function DoRender( m, Frame, ObjectList )

    -- renders a scene with a view
    -- bin the objects
    local RList = lObjectList_Sort(ObjectList)

    -- geometry pass
    Render_GeometryBegin(Frame)

    -- tri soup meshs
    lTriMesh_Render(
            {
                Frame		= Frame,
                ObjectList	= RList,
                Mode		= "GEOMETRY"
            })

--    -- skins render
--    m.Skin_Render(
--            {
--                Frame		= Frame,
--                ObjectList	= SortList,
--                Mode		= "GEOMETRY"
--            })

    -- linez
    lLine_Render(
            {
                Frame		= Frame,
                ObjectList	= RList,
                Mode		= "GEOMETRY"
            })

--    -- height maps
--    m.HeightMap_Render(
--            {
--                Frame		= Frame,
--                ObjectList	= SortList,
--                Mode		= "GEOMETRY"
--            })

    Render_GeometryEnd(Frame)

    -- resolve
    Render_Resolve(Frame)
end

------------------------------------------------------------------------------------------------------------

function RenderDeviceTests()

    WS2Init()

    local start_time = os.clock()
    local int_clock = 0
    local diff = os.clock() - start_time

    local dev = create_device_test()

    local m_render = {
        Device  = dev,
        Scanout = true,

        Render          = DoRender,
        RenderTime      = 0.0,
        RenderCount     = 0,
        RenderNet		= lMultiCast_Create(
        {
            McGroup		= "224.0.0.20",
            Port		= "1234",
        }, 1)
    }

    local scene = create_scene_test( m_render.RenderNet )
    local cam = create_camera_test( scene, m_render.RenderNet )


    while( diff < 10.000 ) do

        diff = os.clock() - start_time

        frame_draw_test(m_render, diff, scene)

        if( math.floor(diff) ~= int_clock ) then
            ftrace("time: %f\n", os.clock())
            int_clock = math.floor(diff)
        end
    end
end

------------------------------------------------------------------------------------------------------------

-- NetworkTests()
RenderDeviceTests()

------------------------------------------------------------------------------------------------------------
